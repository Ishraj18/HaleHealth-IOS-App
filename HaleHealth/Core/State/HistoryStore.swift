import Combine
import Foundation
import OSLog

/// The app's memory: one `DailySnapshot` per day, written incrementally as
/// signals arrive (block checks, drinks, meditation, Health, AQI). Local-first
/// in UserDefaults with fire-and-forget Supabase sync — the record trends and
/// personal insights are computed from, and the history a future AI reads.
@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var snapshots: [String: DailySnapshot]   // keyed by "yyyy-MM-dd"

    /// Days of history kept on-device. Server keeps everything.
    static let retentionDays = 120

    private let defaults: UserDefaults
    private static let key = "daily_snapshots"

    private var sync: HistorySyncServiceProtocol?
    private var userId: UUID?
    private var cancellables = Set<AnyCancellable>()
    private var isBound = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key),
           let stored = try? JSONDecoder().decode([String: DailySnapshot].self, from: data) {
            self.snapshots = stored
        } else {
            self.snapshots = [:]
        }
    }

    // MARK: - Reading

    /// Snapshots for the last `days` days ending today, oldest first. Days the
    /// app never saw are absent — callers decide whether absence means zero.
    func recent(days: Int) -> [DailySnapshot] {
        let calendar = Calendar.current
        return (0..<days).compactMap { offset -> DailySnapshot? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return snapshots[date.hhISODate]
        }.reversed()
    }

    var today: DailySnapshot? { snapshots[Date().hhISODate] }

    // MARK: - Writing

    /// Mutates today's snapshot in place, creating it on first touch.
    func updateToday(_ mutate: (inout DailySnapshot) -> Void) {
        updateDay(Date().hhISODate, mutate)
    }

    func updateDay(_ day: String, _ mutate: (inout DailySnapshot) -> Void) {
        var snapshot = snapshots[day] ?? DailySnapshot(day: day)
        mutate(&snapshot)
        snapshot.updatedAt = Date()
        snapshots[day] = snapshot
        persist()
        pushRemote(snapshot)
    }

    // MARK: - Bindings

    /// Mirrors the routine store into the daily record: plan size, completed
    /// count and streak update the snapshot for the completion's own day, so
    /// nothing extra is required at call sites that toggle blocks.
    func bind(to routineStore: RoutineStore) {
        guard !isBound else { return }
        isBound = true
        routineStore.$completion
            .combineLatest(routineStore.$routine, routineStore.$streak)
            .sink { [weak self] completion, routine, streak in
                self?.updateDay(completion.day) { snapshot in
                    if let routine { snapshot.blocksTotal = routine.blocks.count }
                    snapshot.blocksCompleted = completion.completedBlockIDs.count
                    snapshot.streakCount = streak.count
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync lifecycle

    /// Attaches Supabase sync: pulls the last 90 days to backfill days this
    /// device never saw (local snapshots always win — they are the device of
    /// record), then pushes today's state.
    func configure(userId: UUID, sync: HistorySyncServiceProtocol) {
        self.userId = userId
        self.sync = sync
        Task {
            do {
                let since = Calendar.current.date(byAdding: .day, value: -90, to: Date())!.hhISODate
                let remote = try await sync.pullSnapshots(since: since, userId: userId)
                for snapshot in remote where snapshots[snapshot.day] == nil {
                    snapshots[snapshot.day] = snapshot
                }
                persist()
                if let today { pushRemote(today) }
            } catch {
                Log.app.error("History sync failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func detachSync() {
        sync = nil
        userId = nil
    }

    /// Full local wipe on sign-out so the next account starts clean.
    func clearLocal() {
        snapshots = [:]
        defaults.removeObject(forKey: Self.key)
    }

    // MARK: -

    private func persist() {
        prune()
        guard let data = try? JSONEncoder().encode(snapshots) else {
            Log.app.error("HistoryStore failed to encode snapshots")
            return
        }
        defaults.set(data, forKey: Self.key)
    }

    private func prune() {
        guard snapshots.count > Self.retentionDays,
              let cutoffDate = Calendar.current.date(byAdding: .day, value: -Self.retentionDays, to: Date())
        else { return }
        let cutoff = cutoffDate.hhISODate
        snapshots = snapshots.filter { $0.key >= cutoff }
    }

    private func pushRemote(_ snapshot: DailySnapshot) {
        guard let sync, let userId else { return }
        Task {
            do { try await sync.pushSnapshot(snapshot, userId: userId) }
            catch { Log.app.error("Snapshot push failed: \(error.localizedDescription, privacy: .public)") }
        }
    }
}
