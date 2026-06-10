import Combine
import Foundation

/// Holds the authenticated user's profile and auth flag. Owned by `AppState`,
/// which forwards its changes so the whole app reacts to sign-in/out.
@MainActor
final class UserSession: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isAuthenticated: Bool = false

    func set(profile: UserProfile) {
        self.profile = profile
        self.isAuthenticated = true
    }

    func clear() {
        self.profile = nil
        self.isAuthenticated = false
    }
}
