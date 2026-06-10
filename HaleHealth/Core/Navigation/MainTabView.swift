import SwiftUI
import HaleDesignSystem

/// The five-tab shell. Each tab is its own `NavigationStack` bound to a path in
/// `TabRouter`, so tab stacks are preserved across switches.
struct MainTabView: View {
    @EnvironmentObject private var tabRouter: TabRouter
    @EnvironmentObject private var appState: AppState
    @Environment(\.hhAtmosphere) private var atmosphere

    var body: some View {
        TabView(selection: $tabRouter.activeTab) {
            NavigationStack(path: $tabRouter.todayPath) {
                TodayView(appState: appState)
            }
            .tabItem { Label(Tab.today.label, systemImage: Tab.today.icon) }
            .tag(Tab.today)

            NavigationStack(path: $tabRouter.shieldPath) {
                ShieldView()
            }
            .tabItem { Label(Tab.shield.label, systemImage: Tab.shield.icon) }
            .tag(Tab.shield)

            NavigationStack(path: $tabRouter.hawaPath) {
                HawaView()
            }
            .tabItem { Label(Tab.hawa.label, systemImage: Tab.hawa.icon) }
            .tag(Tab.hawa)

            NavigationStack(path: $tabRouter.ritualPath) {
                RitualHomeView()
            }
            .tabItem { Label(Tab.ritual.label, systemImage: Tab.ritual.icon) }
            .tag(Tab.ritual)

            NavigationStack(path: $tabRouter.profilePath) {
                ProfilePlaceholderView()
            }
            .tabItem { Label(Tab.profile.label, systemImage: Tab.profile.icon) }
            .tag(Tab.profile)
        }
        .tint(.hhWarmSaffron)
        .onChange(of: tabRouter.activeTab) { _, _ in Haptics.tap() }
        .toolbarBackground(atmosphere.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(atmosphere.isNight ? .dark : .light, for: .tabBar)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.preview)
        .environmentObject(AppState.preview.userSession)
        .environmentObject(TabRouter())
}
