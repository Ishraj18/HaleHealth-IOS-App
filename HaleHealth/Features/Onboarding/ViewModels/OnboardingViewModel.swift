import AuthenticationServices
import Combine
import CryptoKit
import SwiftUI
import OSLog
import HaleDesignSystem

/// Sign in with Apple needs the `com.apple.developer.applesignin` entitlement,
/// which requires a paid Apple Developer membership. Flip to `true` and add the
/// entitlement back to Config/HaleHealth.entitlements once enrolled.
enum AppleSignInFeature {
    static let enabled = false
}

/// Drives the entire onboarding/auth flow. All flow logic lives here; the
/// screens only bind to this state.
@MainActor
final class OnboardingViewModel: ObservableObject {
    enum AuthMode { case signIn, signUp }

    @Published var step: OnboardingStep
    @Published var selectedGoals: Set<UserProfile.BodyGoal> = []

    // Auth substate
    @Published var email = ""
    @Published var password = ""
    @Published var authMode: AuthMode
    @Published var isSubmitting = false
    @Published var toast: HHToastData?

    let mode: OnboardingMode
    private let appState: AppState

    init(appState: AppState, mode: OnboardingMode = .fullOnboarding) {
        self.appState = appState
        self.mode = mode
        self.step = (mode == .reLogin) ? .auth : .welcome
        // Fresh onboarding defaults to creating an account; re-login to login.
        self.authMode = (mode == .reLogin) ? .signIn : .signUp
    }

    // MARK: - Derived state

    var canContinueGoals: Bool { !selectedGoals.isEmpty }

    var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var emailLooksValid: Bool {
        let value = trimmedEmail
        return value.contains("@") && value.contains(".") && value.count >= 6
    }

    var passwordLooksValid: Bool {
        authMode == .signUp ? password.count >= 8 : !password.isEmpty
    }

    var canSubmit: Bool { emailLooksValid && passwordLooksValid }

    var submitTitle: String { authMode == .signUp ? "Create account" : "Log in" }

    var passwordHint: String? {
        authMode == .signUp && !password.isEmpty && password.count < 8
            ? "At least 8 characters." : nil
    }

    func isSelected(_ goal: UserProfile.BodyGoal) -> Bool {
        selectedGoals.contains(goal)
    }

    /// The product whose Hindi name we surface beneath a goal.
    func product(for goal: UserProfile.BodyGoal) -> Product? {
        appState.productCatalog.product(for: goal.associatedProduct)
    }

    // MARK: - Navigation between steps

    func toggle(_ goal: UserProfile.BodyGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func advanceFromWelcome() {
        withAnimation(.hhSpring) { step = .goals }
    }

    func advanceFromGoals() {
        guard canContinueGoals else { return }
        withAnimation(.hhSpring) { step = .auth }
    }

    func toggleAuthMode() {
        withAnimation(.hhSnappy) {
            authMode = (authMode == .signUp) ? .signIn : .signUp
        }
    }

    // MARK: - Auth

    func submit() async {
        guard canSubmit, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await appState.authenticate(
                email: trimmedEmail,
                password: password,
                isSignUp: authMode == .signUp,
                onboardingGoals: selectedGoals.sorted { $0.rawValue < $1.rawValue }
            )
        } catch {
            toast = HHToastData(message: errorMessage(error), style: .error)
        }
    }

    private var sortedGoals: [UserProfile.BodyGoal] {
        mode == .fullOnboarding ? selectedGoals.sorted { $0.rawValue < $1.rawValue } : []
    }

    // MARK: - Sign in with Apple

    private var currentNonce: String?

    /// Configures the Apple request: scopes + a hashed single-use nonce that
    /// Supabase later verifies against the raw value.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256Hex(nonce)
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task { await completeApple(authorization) }
        case .failure(let error):
            // User-cancelled sheets are not errors worth surfacing.
            if (error as? ASAuthorizationError)?.code != .canceled {
                toast = HHToastData(message: error.localizedDescription, style: .error)
            }
        }
    }

    private func completeApple(_ authorization: ASAuthorization) async {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8),
            let nonce = currentNonce
        else {
            toast = HHToastData(message: "Apple sign-in returned no identity token.", style: .error)
            return
        }
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await appState.authenticateWithApple(
                idToken: idToken, nonce: nonce,
                fullName: fullName.isEmpty ? nil : fullName,
                onboardingGoals: sortedGoals
            )
        } catch {
            toast = HHToastData(message: errorMessage(error), style: .error)
        }
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await appState.authenticateWithGoogle(onboardingGoals: sortedGoals)
        } catch {
            // ASWebAuthenticationSession cancellation surfaces as an error; skip it.
            let message = errorMessage(error)
            if !message.localizedCaseInsensitiveContains("cancel") {
                toast = HHToastData(message: message, style: .error)
            }
        }
    }

    // MARK: - Nonce helpers

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "Unable to generate secure nonce")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    #if DEBUG
    /// DEBUG-only: skip auth entirely and enter the app using just the email.
    func continueWithoutVerification() {
        guard emailLooksValid, !isSubmitting else { return }
        let address = trimmedEmail
        let name = address.split(separator: "@").first.map { String($0).capitalized } ?? "Friend"
        let profile = UserProfile(
            id: UUID(), displayName: name, email: address, phone: nil,
            bodyGoals: mode == .fullOnboarding ? selectedGoals.sorted { $0.rawValue < $1.rawValue } : [],
            streakCount: 0, lastLogDate: nil, createdAt: Date()
        )
        appState.enterAppLocally(profile: profile, markOnboardingComplete: mode == .fullOnboarding)
    }
    #endif

    private func errorMessage(_ error: Error) -> String {
        (error as? APIError)?.errorDescription ?? error.localizedDescription
    }
}
