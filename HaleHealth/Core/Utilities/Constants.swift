import Foundation

/// App-wide constant values that are not visual tokens (those live in the
/// design system) and not secrets (those live in `AppConfig`).
enum Constants {

    enum UserDefaultsKey {
        static let onboardingComplete = "onboarding_complete"
        static let selectedGoals = "selected_goals"
    }

    enum AQI {
        static let cacheTTLSeconds: TimeInterval = 900 // 15 minutes
    }

    enum Brand {
        static let city = "Gurgaon"
        static let supportEmail = "hello@halehealth.in"
    }
}
