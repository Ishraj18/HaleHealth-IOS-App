import Foundation

extension UserProfile {
    /// A representative profile for previews and tests.
    static var preview: UserProfile {
        UserProfile(
            id: UUID(),
            displayName: "Ish",
            email: "ish@halehealth.in",
            phone: nil,
            bodyGoals: [.lungHealth, .skinRepair],
            streakCount: 14,
            lastLogDate: Date(),
            createdAt: Date()
        )
    }
}

extension AppState {
    /// A fully-mocked `AppState` for SwiftUI previews — authenticated, with a
    /// "Very Unhealthy" mock AQI so recommendation logic is exercised.
    static var preview: AppState {
        let session = UserSession()
        session.set(profile: .preview)
        let state = AppState(
            authService: MockAuthService(),
            databaseService: MockDatabaseService(),
            aqiService: MockAQIService(mockAQI: 218),
            productCatalog: .shared,
            userSession: session
        )
        state.currentAQI = AQIReading(value: 218, station: "Gurgaon Sector 51", fetchedAt: Date())
        state.aqiLoadState = .loaded
        return state
    }
}
