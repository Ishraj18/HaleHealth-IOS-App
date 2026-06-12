import Foundation
import OSLog
import Supabase

/// Email/password authentication via Supabase. The session is persisted by the
/// SDK (keychain) and survives app relaunches; users stay signed in until they
/// explicitly sign out.
final class SupabaseAuthService: AuthServiceProtocol {
    private let client: SupabaseClient
    private let lock = NSLock()
    private var _cachedUserId: UUID?

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    var currentUserId: UUID? { lock.withLock { _cachedUserId } }
    var isAuthenticated: Bool { currentUserId != nil }

    private func setUserId(_ id: UUID?) {
        lock.withLock { _cachedUserId = id }
    }

    func signUp(email: String, password: String) async throws -> UserProfile {
        try requireConfigured()
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            guard response.session != nil else {
                // Email confirmation is still enabled server-side.
                throw APIError.authFailed(
                    "Account created — but email confirmation is enabled in Supabase. Disable it (Authentication → Providers → Email) or confirm via the email we sent."
                )
            }
            setUserId(response.user.id)
            return Self.baseProfile(from: response.user, fallbackEmail: email)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.authFailed(Self.friendlyMessage(error))
        }
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        try requireConfigured()
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            setUserId(session.user.id)
            return Self.baseProfile(from: session.user, fallbackEmail: email)
        } catch {
            throw APIError.authFailed(Self.friendlyMessage(error))
        }
    }

    /// Deep-link the OAuth web flow returns to. Must be allowlisted in the
    /// Supabase dashboard (Authentication → URL Configuration → Redirect URLs).
    static let oauthRedirectURL = URL(string: "halehealth://auth-callback")

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> UserProfile {
        try requireConfigured()
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
            )
            setUserId(session.user.id)
            var profile = Self.baseProfile(from: session.user, fallbackEmail: session.user.email ?? "")
            // Apple only provides the name on the very first authorization.
            if let fullName, !fullName.isEmpty { profile.displayName = fullName }
            return profile
        } catch {
            throw APIError.authFailed(Self.friendlyMessage(error))
        }
    }

    func signInWithGoogle() async throws -> UserProfile {
        try requireConfigured()
        do {
            let session = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: Self.oauthRedirectURL
            )
            setUserId(session.user.id)
            return Self.baseProfile(from: session.user, fallbackEmail: session.user.email ?? "")
        } catch {
            throw APIError.authFailed(Self.friendlyMessage(error))
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw APIError.authFailed(error.localizedDescription)
        }
        setUserId(nil)
    }

    func fetchCurrentProfile() async throws -> UserProfile? {
        guard AppConfig.isSupabaseConfigured else { return nil }
        do {
            var session = try await client.auth.session   // refreshes if expired
            // Never restore a dead session: a stale token makes every RLS
            // write fail as anonymous. Refresh it, or treat as signed out.
            if session.isExpired {
                session = try await client.auth.refreshSession()
            }
            setUserId(session.user.id)
            return Self.baseProfile(from: session.user, fallbackEmail: session.user.email ?? "")
        } catch {
            Log.auth.debug("No restorable Supabase session: \(error.localizedDescription, privacy: .public)")
            setUserId(nil)
            return nil
        }
    }

    // MARK: - Helpers

    private func requireConfigured() throws {
        guard AppConfig.isSupabaseConfigured else {
            throw APIError.notConfigured(
                "Add your Supabase keys to Config/Secrets.xcconfig to sign in."
            )
        }
    }

    private static func friendlyMessage(_ error: Error) -> String {
        let raw = error.localizedDescription
        if raw.localizedCaseInsensitiveContains("invalid login credentials") {
            return "Email or password didn't match. Try again, or create an account."
        }
        if raw.localizedCaseInsensitiveContains("already registered") {
            return "That email already has an account — switch to Login."
        }
        return raw
    }

    private static func baseProfile(from user: User, fallbackEmail: String) -> UserProfile {
        let email = user.email ?? fallbackEmail
        // Identity providers (Google/Apple) put the real name and photo in
        // user metadata — use them; fall back to the email's local part only
        // for plain email/password accounts.
        let metadataName = ["full_name", "name"].lazy
            .compactMap { user.userMetadata[$0]?.stringValue }
            .first { !$0.isEmpty }
        let avatar = ["avatar_url", "picture"].lazy
            .compactMap { user.userMetadata[$0]?.stringValue }
            .first { !$0.isEmpty }
        let localPart = email.split(separator: "@").first.map(String.init) ?? "Friend"
        return UserProfile(
            id: user.id,
            displayName: metadataName ?? localPart.capitalized,
            email: email,
            phone: nil,
            bodyGoals: [],
            streakCount: 0,
            lastLogDate: nil,
            createdAt: Date(),
            avatarURL: avatar
        )
    }
}
