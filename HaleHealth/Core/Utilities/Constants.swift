import Foundation

/// App-wide constant values that are not visual tokens (those live in the
/// design system) and not secrets (those live in `AppConfig`).
enum Constants {

    enum UserDefaultsKey {
        static let onboardingComplete = "onboarding_complete"
        static let healthSyncEnabled = "health_sync_enabled"
        static let routineRemindersEnabled = "routine_reminders_enabled"
    }

    enum AQI {
        static let cacheTTLSeconds: TimeInterval = 900 // 15 minutes
    }

    enum Health {
        /// Steps that count as the day's walk for auto-completion.
        static let walkStepThreshold = 3000
    }

    enum Brand {
        static let city = "Gurgaon"
        static let supportEmail = "hello@halehealth.in"
    }
}
