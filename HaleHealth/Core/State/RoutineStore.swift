import Combine
import Foundation
import OSLog

/// Owns the routine profile and per-day completion state. Local-first
/// (UserDefaults JSON) so it works offline and with the dev login bypass;
/// Supabase sync attaches here in a later milestone.
@MainActor
final class RoutineStore: ObservableObject {
    /// Shared instance so Ritual and Today read the same state.
    static let shared = RoutineStore()

    @Published private(set) var profile: RoutineProfile?
    @Published private(set) var completion: RoutineCompletion
    @Published private(set) var streak: Streak

    /// Local streak record. Becomes a cache of the server value once sync lands.
    struct Streak: Codable, Equatable {
        var count: Int = 0
        var lastKeptDay: String?    // "yyyy-MM-dd" of the last day that counted
    }

    /// A day "counts" once this share of blocks is complete.
    static let keepThreshold = 0.7

    private let defaults: UserDefaults
    private static let profileKey = "routine_profile"
    private static let completionKey = "routine_completion"
    private static let streakKey = "routine_streak"

    // Sync (attached once a real session exists; absent for previews/dev bypass)
    private var sync: RoutineSyncServiceProtocol?
    private var userId: UUID?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.profile = Self.load(RoutineProfile.self, key: Self.profileKey, from: defaults)
        let today = Date().hhISODate
        let stored = Self.load(RoutineCompletion.self, key: Self.completionKey, from: defaults)
        // Completion state resets each new day.
        self.completion = (stored?.day == today) ? stored! : RoutineCompletion(day: today)
        var streak = Self.load(Streak.self, key: Self.streakKey, from: defaults) ?? Streak()
        // Missing a full day (yesterday never kept) breaks the streak.
        if let last = streak.lastKeptDay, last != today,
           last != Calendar.current.date(byAdding: .day, value: -1, to: Date())!.hhISODate {
            streak.count = 0
        }
        self.streak = streak
    }

    var hasRoutine: Bool { profile != nil }

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

    func saveProfile(_ newProfile: RoutineProfile) {
        profile = newProfile
        persist(newProfile, key: Self.profileKey)
        pushProfileRemote(newProfile)
    }

    func clearProfile() {
        profile = nil
        defaults.removeObject(forKey: Self.profileKey)
    }

    /// Full local wipe on sign-out so the next account starts clean.
    func clearAllLocal() {
        clearProfile()
        completion = RoutineCompletion(day: Date().hhISODate)
        streak = Streak()
        defaults.removeObject(forKey: Self.completionKey)
        defaults.removeObject(forKey: Self.streakKey)
    }

    func toggle(_ blockID: String) {
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

    func isDone(_ blockID: String) -> Bool {
        completion.completedBlockIDs.contains(blockID)
    }

    func progress(for routine: DailyRoutine) -> Double {
        guard !routine.blocks.isEmpty else { return 0 }
        let done = routine.blocks.filter { isDone($0.id) }.count
        return Double(done) / Double(routine.blocks.count)
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
