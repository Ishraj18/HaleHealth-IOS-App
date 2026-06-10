import OSLog
import UIKit

/// UIApplication delegate, attached via `@UIApplicationDelegateAdaptor`. Phase 1
/// wires it purely so APNs registration lands here in Phase 2 without
/// restructuring the entry point.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Log.app.info("HaleHealth launched (\(String(describing: BuildConfiguration.current), privacy: .public)).")
        return true
    }

    // MARK: - Phase 2 hooks (APNs)

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // TODO(Phase 2): forward the APNs token to Supabase for push delivery.
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Log.app.debug("APNs device token: \(token, privacy: .private)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Log.app.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }
}
