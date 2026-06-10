import Foundation
import OSLog

/// Phase 2 hook. Maps push-notification / universal-link URLs onto in-app
/// routes. Stubbed now so `AppDelegate` and the scene wiring already reference a
/// real handler — only the URL-parsing body is added in Phase 2.
@MainActor
final class DeepLinkHandler {
    private let tabRouter: TabRouter

    init(tabRouter: TabRouter) {
        self.tabRouter = tabRouter
    }

    /// In-app destinations a deep link can resolve to. Extended in Phase 2
    /// (orders, subscriptions, Vaidya chat, …).
    enum DeepLink: Equatable {
        case today
        case product(ProductID)
    }

    func handle(_ url: URL) {
        // TODO(Phase 2): parse e.g. halehealth://product/saans into a DeepLink.
        Log.app.debug("Deep link received (no-op in Phase 1): \(url.absoluteString, privacy: .public)")
    }

    func handle(_ link: DeepLink) {
        switch link {
        case .today:    tabRouter.navigate(to: .today)
        case .product:  tabRouter.navigate(to: .shield)
        }
    }
}
