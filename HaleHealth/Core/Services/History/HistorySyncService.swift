import Foundation
import Supabase

/// Sync boundary for the daily history record. Local-first: the store never
/// waits on these; failures are logged by the caller and retried implicitly
/// the next time the snapshot changes (every push carries the full row).
protocol HistorySyncServiceProtocol: AnyObject {
    func pushSnapshot(_ snapshot: DailySnapshot, userId: UUID) async throws
    /// All snapshots for days >= `since` ("yyyy-MM-dd"), any order.
    func pullSnapshots(since day: String, userId: UUID) async throws -> [DailySnapshot]
}

final class SupabaseHistorySyncService: HistorySyncServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    private struct Row: Codable {
        var userId: UUID?
        let day: String
        let blocksTotal: Int
        let blocksCompleted: Int
        let meditationSessions: Int
        let meditationMinutes: Int
        let drinksLogged: Int
        let steps: Int?
        let workouts: Int?
        let aqi: Int?
        let mood: String?
        let streakCount: Int

        enum CodingKeys: String, CodingKey {
            case day, steps, workouts, aqi, mood
            case userId = "user_id"
            case blocksTotal = "blocks_total"
            case blocksCompleted = "blocks_completed"
            case meditationSessions = "meditation_sessions"
            case meditationMinutes = "meditation_minutes"
            case drinksLogged = "drinks_logged"
            case streakCount = "streak_count"
        }

        init(_ snapshot: DailySnapshot, userId: UUID) {
            self.userId = userId
            day = snapshot.day
            blocksTotal = snapshot.blocksTotal
            blocksCompleted = snapshot.blocksCompleted
            meditationSessions = snapshot.meditationSessions
            meditationMinutes = snapshot.meditationMinutes
            drinksLogged = snapshot.drinksLogged
            steps = snapshot.steps
            workouts = snapshot.workouts
            aqi = snapshot.aqi
            mood = snapshot.mood
            streakCount = snapshot.streakCount
        }

        func toDomain() -> DailySnapshot {
            var snapshot = DailySnapshot(day: day)
            snapshot.blocksTotal = blocksTotal
            snapshot.blocksCompleted = blocksCompleted
            snapshot.meditationSessions = meditationSessions
            snapshot.meditationMinutes = meditationMinutes
            snapshot.drinksLogged = drinksLogged
            snapshot.steps = steps
            snapshot.workouts = workouts
            snapshot.aqi = aqi
            snapshot.mood = mood
            snapshot.streakCount = streakCount
            return snapshot
        }
    }

    func pushSnapshot(_ snapshot: DailySnapshot, userId: UUID) async throws {
        do {
            try await client.from("daily_snapshots")
                .upsert(Row(snapshot, userId: userId), onConflict: "user_id,day")
                .execute()
        } catch { throw APIError.supabaseError(error.localizedDescription) }
    }

    func pullSnapshots(since day: String, userId: UUID) async throws -> [DailySnapshot] {
        do {
            let rows: [Row] = try await client.from("daily_snapshots")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("day", value: day)
                .execute().value
            return rows.map { $0.toDomain() }
        } catch { throw APIError.supabaseError(error.localizedDescription) }
    }
}

/// No-op sync for previews/tests and the signed-out state.
final class MockHistorySyncService: HistorySyncServiceProtocol {
    func pushSnapshot(_ snapshot: DailySnapshot, userId: UUID) async throws {}
    func pullSnapshots(since day: String, userId: UUID) async throws -> [DailySnapshot] { [] }
}
