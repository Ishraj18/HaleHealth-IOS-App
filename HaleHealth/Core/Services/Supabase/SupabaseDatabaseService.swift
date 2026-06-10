import Foundation
import Supabase

/// Postgres persistence via Supabase PostgREST. All row-level security is
/// enforced server-side; these methods assume an authenticated session.
final class SupabaseDatabaseService: DatabaseServiceProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func saveProfile(_ profile: UserProfile) async throws {
        do {
            try await client
                .from("profiles")
                .upsert(UserProfileUpsert(profile), onConflict: "id")
                .execute()
        } catch {
            throw APIError.supabaseError(error.localizedDescription)
        }
    }

    func fetchProfile(userId: UUID) async throws -> UserProfile? {
        do {
            let rows: [UserProfileDTO] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            return rows.first?.toDomain()
        } catch {
            throw APIError.supabaseError(error.localizedDescription)
        }
    }

    func saveDrinkLog(_ log: DrinkLog) async throws {
        do {
            try await client
                .from("drink_logs")
                .insert(DrinkLogInsert(log))
                .execute()
        } catch {
            throw APIError.supabaseError(error.localizedDescription)
        }
    }

    func fetchDrinkLogs(userId: UUID, limit: Int) async throws -> [DrinkLog] {
        do {
            let rows: [DrinkLogDTO] = try await client
                .from("drink_logs")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("logged_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            return rows.compactMap { $0.toDomain() }
        } catch {
            throw APIError.supabaseError(error.localizedDescription)
        }
    }

    func fetchInsights(tags: [String]) async throws -> [Insight] {
        do {
            let rows: [Insight] = try await client
                .from("insights")
                .select()
                .execute()
                .value
            guard !tags.isEmpty else { return rows }
            let wanted = Set(tags)
            return rows.filter { !wanted.isDisjoint(with: $0.tags) }
        } catch {
            throw APIError.supabaseError(error.localizedDescription)
        }
    }
}
