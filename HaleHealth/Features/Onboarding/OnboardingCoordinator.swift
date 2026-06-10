import Foundation

/// The linear onboarding steps.
enum OnboardingStep: Equatable {
    case welcome
    case goals
    case auth
}

/// Whether the flow is a first-run onboarding (collect goals, then auth) or a
/// re-login (auth only — goals already stored).
enum OnboardingMode: Equatable {
    case fullOnboarding
    case reLogin
}
