import Foundation

/// In-memory auth used by previews and tests. Always "succeeds".
final class MockAuthService: AuthServiceProtocol {
    private(set) var isAuthenticated: Bool
    private(set) var currentUserId: UUID?

    init(authenticated: Bool = true) {
        self.isAuthenticated = authenticated
        self.currentUserId = authenticated ? UUID() : nil
    }

    private func profile(email: String) -> UserProfile {
        let id = UUID()
        isAuthenticated = true
        currentUserId = id
        return UserProfile(id: id, displayName: "Ish", email: email, phone: nil,
                           bodyGoals: [.lungHealth, .skinRepair], streakCount: 14,
                           lastLogDate: Date(), createdAt: Date())
    }

    func signUp(email: String, password: String) async throws -> UserProfile {
        profile(email: email)
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        profile(email: email)
    }

    func signInWithApple(idToken: String, nonce: String, fullName: String?) async throws -> UserProfile {
        profile(email: "apple@halehealth.in")
    }

    func signInWithGoogle() async throws -> UserProfile {
        profile(email: "google@halehealth.in")
    }

    func signOut() async throws {
        isAuthenticated = false
        currentUserId = nil
    }

    func fetchCurrentProfile() async throws -> UserProfile? { nil }
}
