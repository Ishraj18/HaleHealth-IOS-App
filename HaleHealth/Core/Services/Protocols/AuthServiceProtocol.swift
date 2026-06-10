import Foundation

/// Authentication boundary. ViewModels and `AppState` depend on this protocol,
/// never on the concrete Supabase implementation, so a mock can be injected in
/// tests and previews without touching production code.
protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    var currentUserId: UUID? { get }

    /// Creates an account and (with email confirmation disabled in Supabase)
    /// returns an immediately-active session's base profile.
    func signUp(email: String, password: String) async throws -> UserProfile
    func signIn(email: String, password: String) async throws -> UserProfile

    /// Native Sign in with Apple: exchanges an Apple identity token (and the
    /// raw nonce used to request it) for a Supabase session.
    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> UserProfile

    /// Google via Supabase's OAuth web flow (ASWebAuthenticationSession).
    func signInWithGoogle() async throws -> UserProfile

    func signOut() async throws

    /// Returns the auth-derived base profile if a stored session exists (the
    /// SDK keeps it in the keychain across launches), refreshing if needed.
    /// The full profile (goals, streak) is fetched via `DatabaseServiceProtocol`.
    func fetchCurrentProfile() async throws -> UserProfile?
}
