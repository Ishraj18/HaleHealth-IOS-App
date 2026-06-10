import SwiftUI
import UIKit
import HaleDesignSystem

@main
struct HaleHealthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        _ = HaleDesignSystem.bootstrap   // register bundled fonts before the first frame
        Appearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
        }
    }
}

/// UIKit appearance configuration, applied once at launch. This is the only
/// place the app touches UIKit directly (per the SwiftUI-only rule).
private enum Appearance {
    static func configure() {
        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(Color.hhCreamParchment)
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.hhMutedSage)

        let navBar = UINavigationBarAppearance()
        navBar.configureWithTransparentBackground()
        navBar.backgroundColor = UIColor(Color.hhCreamParchment)
        navBar.titleTextAttributes = [.foregroundColor: UIColor(Color.hhForestGreen)]
        navBar.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.hhForestGreen)]
        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
    }
}
