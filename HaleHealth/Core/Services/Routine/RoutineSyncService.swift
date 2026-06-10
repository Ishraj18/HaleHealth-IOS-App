import Foundation
import Supabase

/// Sync boundary for routine state. Local-first: the store never waits on these.
protocol RoutineSyncServiceProtocol: AnyObject {
    func pushProfile(_ profile: RoutineProfile, userId: UUID) async throws
    func pullProfile(userId: UUID) async throws -> RoutineProfile?
    func pushCompletion(_ completion: RoutineCompletion, userId: UUID) async throws
    func pullCompletion(day: String, userId: UUID) async throws -> RoutineCompletion?
    /// Registers `day` as kept; returns the server's streak count.
    func keepStreak(day: String) async throws -> Int
}

final class SupabaseRoutineSyncService: RoutineSyncServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    private struct ProfileRow: Codable {
        let userId: UUID
        let answers: RoutineProfile
        let quizVersion: Int
        enum CodingKeys: String, CodingKey {
            case answers
            case userId = "user_id"
            case quizVersion = "quiz_version"
        }
    }

    private struct CompletionRow: Codable {
        let userId: UUID
        let day: String
        let completedBlocks: [String]
        enum CodingKeys: String, CodingKey {
            case day
            case userId = "user_id"
            case completedBlocks = "completed_blocks"
        }
    }

    func pushProfile(_ profile: RoutineProfile, userId: UUID) async throws {
        do {
            try await client.from("routine_profiles")
                .upsert(ProfileRow(userId: userId, answers: profile, quizVersion: profile.quizVersion),
                        onConflict: "user_id")
                .execute()
        } catch { throw APIError.supabaseError(error.localizedDescription) }
    }

    func pullProfile(userId: UUID) async throws -> RoutineProfile? {
        do {
            let rows: [ProfileRow] = try await client.from("routine_profiles")
                .select().eq("user_id", value: userId.uuidString).limit(1)
                .execute().value
            return rows.first?.answers
        } catch { throw APIError.supabaseError(error.localizedDescription) }
    }

    func pushCompletion(_ completion: RoutineCompletion, userId: UUID) async throws {
        do {
            try await client.from("routine_completions")
                .upsert(CompletionRow(userId: userId, day: completion.day,
                                      completedBlocks: Array(completion.completedBlockIDs)),
                        onConflict: "user_id,day")
                .execute()
        } catch { throw APIError.supabaseError(error.localizedDescription) }
    }

    func pullCompletion(day: String, userId: UUID) async throws -> RoutineCompletion? {
        do {
            let rows: [CompletionRow] = try await client.from("routine_completions")
                .select().eq("user_id", value: userId.uuidString).eq("day", value: day).limit(1)
                .execute().value
            guard let row = rows.first else { return nil }
            return RoutineCompletion(day: row.day, completedBlockIDs: Set(row.completedBlocks))
        } catch { throw APIError.supabaseError(error.localizedDescription) }
    }

    func keepStreak(day: String) async throws -> Int {
        do {
            return try await client.rpc("keep_streak", params: ["p_day": day]).execute().value
        } catch { throw APIError.supabaseError(error.localizedDescription) }
    }
}

/// No-op sync for previews/tests and the signed-out state.
final class MockRoutineSyncService: RoutineSyncServiceProtocol {
    func pushProfile(_ profile: RoutineProfile, userId: UUID) async throws {}
    func pullProfile(userId: UUID) async throws -> RoutineProfile? { nil }
    func pushCompletion(_ completion: RoutineCompletion, userId: UUID) async throws {}
    func pullCompletion(day: String, userId: UUID) async throws -> RoutineCompletion? { nil }
    func keepStreak(day: String) async throws -> Int { 1 }
}
