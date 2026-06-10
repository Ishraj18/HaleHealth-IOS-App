import Foundation

/// Persistence boundary over Supabase Postgres.
protocol DatabaseServiceProtocol: AnyObject {
    func saveProfile(_ profile: UserProfile) async throws
    func fetchProfile(userId: UUID) async throws -> UserProfile?
    func saveDrinkLog(_ log: DrinkLog) async throws
    func fetchDrinkLogs(userId: UUID, limit: Int) async throws -> [DrinkLog]
    func fetchInsights(tags: [String]) async throws -> [Insight]
}
