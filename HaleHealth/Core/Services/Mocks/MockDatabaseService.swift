import Foundation

/// In-memory database used by previews and tests.
final class MockDatabaseService: DatabaseServiceProtocol {
    func saveProfile(_ profile: UserProfile) async throws {}

    func fetchProfile(userId: UUID) async throws -> UserProfile? { nil }

    func saveDrinkLog(_ log: DrinkLog) async throws {}

    func fetchDrinkLogs(userId: UUID, limit: Int) async throws -> [DrinkLog] { [] }

    func fetchInsights(tags: [String]) async throws -> [Insight] {
        [
            Insight(
                id: 1,
                content: "Tulsi soothes the airways after a high-AQI afternoon.",
                tags: ["lung"],
                season: "all"
            )
        ]
    }
}
