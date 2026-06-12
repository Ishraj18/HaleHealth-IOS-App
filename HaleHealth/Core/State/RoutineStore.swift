import Combine
import Foundation
import OSLog

/// Owns the routine profile, **today's generated plan**, and per-day completion
/// state. The plan is generated in exactly one place — here — so Today, Ritual
/// and Shuddhi always agree on what today looks like. Local-first (UserDefaults
/// JSON) so it works offline and with the dev login bypass; Supabase sync is
/// fire-and-forget.
@MainActor
final class RoutineStore: ObservableObject {
    /// Shared instance so Ritual, Today and Shuddhi read the same state.
    static let shared = RoutineStore()

    @Published private(set) var profile: RoutineProfile?
    @Published private(set) var completion: RoutineCompletion
    @Published private(set) var streak: Streak
    /// Today's plan — the single source of truth. Views never generate their own.
    @Published private(set) var routine: DailyRoutine?

    /// Local streak record. Becomes a cache of the server value once sync lands.
    struct Streak: Codable, Equatable {
        var count: Int = 0
        var lastKeptDay: String?    // "yyyy-MM-dd" of the last day that counted
    }

    /// A day "counts" once this share of blocks is complete.
    static let keepThreshold = 0.7

    private let defaults: UserDefaults
    private let engine: RoutineEngineProtocol
    /// Deterministic engine used for the instant plan and as the safety net
    /// should an async engine (future Vaidya AI) fail.
    private let fallbackEngine = RuleBasedRoutineEngine()
    private static let profileKey = "routine_profile"
    private static let completionKey = "routine_completion"
    private static let streakKey = "routine_streak"
    private static let planKey = "routine_plan"

    // Generation context, updated as signals arrive.
    private(set) var currentAQI: AQIReading?
    private(set) var observedWakeMinutes: Int?

    private var generationTask: Task<Void, Never>?

    // Sync (attached once a real session exists; absent for previews/dev bypass)
    private var sync: RoutineSyncServiceProtocol?
    private var userId: UUID?

    /// Today's plan persisted with its day key — relaunches restore the exact
    /// plan instantly, and the stored copy is the day's snapshot of record.
    private struct StoredPlan: Codable {
        let day: String
        let routine: DailyRoutine
    }

    init(defaults: UserDefaults = .standard, engine: RoutineEngineProtocol = RuleBasedRoutineEngine()) {
        self.defaults = defaults
        self.engine = engine
        self.profile = Self.load(RoutineProfile.self, key: Self.profileKey, from: defaults)
        let today = Date().hhISODate
        let stored = Self.load(RoutineCompletion.self, key: Self.completionKey, from: defaults)
        // Completion state resets each new day.
        self.completion = (stored?.day == today) ? stored! : RoutineCompletion(day: today)
        var streak = Self.load(Streak.self, key: Self.streakKey, from: defaults) ?? Streak()
        // Missing a full day (yesterday never kept) breaks the streak.
        if Self.isStreakGapped(streak, today: today) { streak.count = 0 }
        self.streak = streak
        restoreOrGeneratePlan(today: today)
    }

    var hasRoutine: Bool { profile != nil }

    /// True when Health observed a wake far enough from the planned one that
    /// today's plan re-anchored around it.
    var isWakeShifted: Bool {
        guard let profile, let observedWakeMinutes else { return false }
        return abs(observedWakeMinutes - profile.wakeMinutes) > RuleBasedRoutineEngine.wakeShiftThresholdMinutes
    }

    // MARK: - Generation (the single point)

    /// Feeds a fresh AQI reading into the plan. No-op when unchanged.
    func updateAQI(_ reading: AQIReading?) {
        guard reading != currentAQI else { return }
        currentAQI = reading
        regeneratePlan()
    }

    /// Feeds the Health-observed wake time into the plan. No-op when unchanged.
    func updateObservedWake(_ minutes: Int?) {
        guard minutes != observedWakeMinutes else { return }
        observedWakeMinutes = minutes
        regeneratePlan()
    }

    /// Regenerates today's plan from the current profile + context. The rule
    /// engine produces a plan instantly; a custom (async) engine then refines
    /// it when its result lands, falling back to the rule plan on failure.
    func regeneratePlan() {
        generationTask?.cancel()
        guard let profile else {
            adopt(nil)
            return
        }
        let context = GenerationContext(aqi: currentAQI, observedWakeMinutes: observedWakeMinutes)
        adopt(fallbackEngine.generate(from: profile, context: context))
        guard !(engine is RuleBasedRoutineEngine) else { return }
        generationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let plan = try await self.engine.generate(from: profile, context: context)
                guard !Task.isCancelled else { return }
                self.adopt(plan)
            } catch {
                Log.app.error("Routine engine failed; keeping rule-based plan: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func adopt(_ plan: DailyRoutine?) {
        routine = plan
        guard let plan else {
            defaults.removeObject(forKey: Self.planKey)
            return
        }
        persist(StoredPlan(day: completion.day, routine: plan), key: Self.planKey)
        pushPlanRemote(plan)
        rescheduleRemindersIfEnabled(plan)
    }

    private func restoreOrGeneratePlan(today: String) {
        if let stored = Self.load(StoredPlan.self, key: Self.planKey, from: defaults), stored.day == today {
            routine = stored.routine
        } else if profile != nil {
            regeneratePlan()
        }
    }

    private func rescheduleRemindersIfEnabled(_ plan: DailyRoutine) {
        guard defaults.bool(forKey: Constants.UserDefaultsKey.routineRemindersEnabled) else { return }
        Task { await RoutineNotificationService.shared.schedule(for: plan) }
    }

    // MARK: - Day rollover

    /// Re-keys state when the calendar day changes while the app stays alive
    /// (the init-time check only covers relaunches). Safe to call often.
    func rolloverIfNeeded() {
        let today = Date().hhISODate
        guard completion.day != today else { return }
        completion = RoutineCompletion(day: today)
        persist(completion, key: Self.completionKey)
        if Self.isStreakGapped(streak, today: today) {
            streak.count = 0
            persist(streak, key: Self.streakKey)
        }
        regeneratePlan()
    }

    private static func isStreakGapped(_ streak: Streak, today: String) -> Bool {
        guard let last = streak.lastKeptDay, last != today else { return false }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!.hhISODate
        return last != yesterday
    }

    // MARK: - Sync lifecycle

    /// Attaches Supabase sync for the signed-in user: pulls a remote profile if
    /// none exists locally, then pushes local state. Local always wins when both
    /// exist (the device the user actually answered on is the truth).
    func configure(userId: UUID, sync: RoutineSyncServiceProtocol, serverStreak: Int?) {
        self.userId = userId
        self.sync = sync
        if let serverStreak, serverStreak > streak.count {
            streak.count = serverStreak
            persist(streak, key: Self.streakKey)
        }
        Task {
            do {
                if let local = profile {
                    try await sync.pushProfile(local, userId: userId)
                } else if let remote = try await sync.pullProfile(userId: userId) {
                    profile = remote
                    persist(remote, key: Self.profileKey)
                    regeneratePlan()
                }
                // Union-merge today's completions so no device loses checks.
                if let remote = try await sync.pullCompletion(day: completion.day, userId: userId) {
                    completion.completedBlockIDs.formUnion(remote.completedBlockIDs)
                    persist(completion, key: Self.completionKey)
                }
                try await sync.pushCompletion(completion, userId: userId)
            } catch {
                Log.app.error("Routine sync failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func detachSync() {
        sync = nil
        userId = nil
    }

    // MARK: - Profile

    func saveProfile(_ newProfile: RoutineProfile) {
        profile = newProfile
        persist(newProfile, key: Self.profileKey)
        pushProfileRemote(newProfile)
        regeneratePlan()
    }

    func clearProfile() {
        profile = nil
        defaults.removeObject(forKey: Self.profileKey)
        adopt(nil)
    }

    /// Full local wipe on sign-out so the next account starts clean.
    func clearAllLocal() {
        clearProfile()
        completion = RoutineCompletion(day: Date().hhISODate)
        streak = Streak()
        currentAQI = nil
        observedWakeMinutes = nil
        defaults.removeObject(forKey: Self.completionKey)
        defaults.removeObject(forKey: Self.streakKey)
        defaults.removeObject(forKey: Self.planKey)
    }

    // MARK: - Completion

    func toggle(_ blockID: String) {
        rolloverIfNeeded()
        if completion.completedBlockIDs.contains(blockID) {
            completion.completedBlockIDs.remove(blockID)
        } else {
            completion.completedBlockIDs.insert(blockID)
        }
        persist(completion, key: Self.completionKey)
        pushCompletionRemote(completion)
    }

    /// Idempotent completion used by Health auto-sync.
    func markDone(_ blockID: String) {
        guard !completion.completedBlockIDs.contains(blockID) else { return }
        completion.completedBlockIDs.insert(blockID)
        persist(completion, key: Self.completionKey)
        pushCompletionRemote(completion)
    }

    /// Marks every block of `kind` in today's plan done — Health auto-sync
    /// (workouts, walks) and Shuddhi (meditate) complete by kind, never by
    /// regenerating their own plan copy.
    func markDone(kind: RoutineBlock.Kind) {
        guard let routine else { return }
        for block in routine.blocks where block.kind == kind {
            markDone(block.id)
        }
    }

    func isDone(_ blockID: String) -> Bool {
        completion.completedBlockIDs.contains(blockID)
    }

    /// True exactly once per drink block per day — the caller may write a
    /// drink log only when this returns true, so re-toggling can't duplicate.
    func shouldLogDrink(_ blockID: String) -> Bool {
        guard !completion.loggedDrinkBlockIDs.contains(blockID) else { return false }
        completion.loggedDrinkBlockIDs.insert(blockID)
        persist(completion, key: Self.completionKey)
        return true
    }

    func progress(for routine: DailyRoutine) -> Double {
        guard !routine.blocks.isEmpty else { return 0 }
        let done = routine.blocks.filter { isDone($0.id) }.count
        return Double(done) / Double(routine.blocks.count)
    }

    /// Progress through today's plan (0 when no plan exists yet).
    var progress: Double {
        routine.map { progress(for: $0) } ?? 0
    }

    /// The next unchecked block at or after the current time (else the first
    /// unchecked one) — powers the Today "next up" card.
    func nextBlock(in routine: DailyRoutine) -> RoutineBlock? {
        let now = Calendar.current.component(.hour, from: Date()) * 60
                + Calendar.current.component(.minute, from: Date())
        let pending = routine.blocks.filter { !isDone($0.id) }
        return pending.first { $0.startMinutes >= now } ?? pending.first
    }

    /// Records today as "kept" the first time progress crosses the threshold.
    /// Returns true when the streak just incremented (caller celebrates).
    @discardableResult
    func recordProgress(_ progress: Double) -> Bool {
        let today = Date().hhISODate
        guard progress >= Self.keepThreshold, streak.lastKeptDay != today else { return false }
        streak.count += 1
        streak.lastKeptDay = today
        persist(streak, key: Self.streakKey)
        // Server is authoritative when signed in — adopt its count if it differs.
        if let sync, userId != nil {
            Task {
                do {
                    let server = try await sync.keepStreak(day: today)
                    if server != streak.count {
                        streak.count = server
                        persist(streak, key: Self.streakKey)
                    }
                } catch {
                    Log.app.error("Streak sync failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        return true
    }

    // MARK: - Remote push (fire-and-forget, errors logged)

    private func pushProfileRemote(_ value: RoutineProfile) {
        guard let sync, let userId else { return }
        Task {
            do { try await sync.pushProfile(value, userId: userId) }
            catch { Log.app.error("Profile push failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    private func pushCompletionRemote(_ value: RoutineCompletion) {
        guard let sync, let userId else { return }
        Task {
            do { try await sync.pushCompletion(value, userId: userId) }
            catch { Log.app.error("Completion push failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    /// Snapshots the day's plan server-side so history can answer "what was
    /// recommended that day", not just "what was checked".
    private func pushPlanRemote(_ plan: DailyRoutine) {
        guard let sync, let userId else { return }
        let day = completion.day
        Task {
            do { try await sync.pushPlan(plan, day: day, userId: userId) }
            catch { Log.app.error("Plan push failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    // MARK: -

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            Log.app.error("RoutineStore failed to encode \(key, privacy: .public)")
            return
        }
        defaults.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
