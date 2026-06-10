import Combine
import SwiftUI
import HaleDesignSystem

/// Root view. Switches between onboarding, re-login, and the main tab bar based
/// on `AppState`, and owns the long-lived `AppState` / `TabRouter`.
struct AppCoordinator: View {
    @StateObject private var appState = AppState()
    @StateObject private var tabRouter = TabRouter()
    @State private var atmosphere = HHAtmosphere(phase: .din)

    var body: some View {
        content
            .environmentObject(appState)
            .environmentObject(appState.userSession)
            .environmentObject(tabRouter)
            .environment(\.hhAtmosphere, atmosphere)
            .tint(.hhWarmSaffron)
            .animation(.hhSpring, value: appState.hasCompletedOnboarding)
            .animation(.hhSpring, value: appState.userSession.isAuthenticated)
            .task {
                refreshAtmosphere()
                await appState.restoreSession()
                await appState.loadAQI()
            }
            .onChange(of: appState.currentAQI) { _, _ in refreshAtmosphere() }
            .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { _ in
                refreshAtmosphere()   // keep the canvas on Delhi's clock
            }
    }

    private func refreshAtmosphere() {
        let next = HHAtmosphere.current(
            hour: Calendar.current.component(.hour, from: Date()),
            aqi: appState.currentAQI?.value,
            aqiTintHex: appState.currentAQI?.category.hexColor
        )
        if next != atmosphere {
            withAnimation(.hhGentle) { atmosphere = next }
        }
    }

    @ViewBuilder private var content: some View {
        if appState.isRestoringSession && appState.hasCompletedOnboarding {
            // Keep signed-in users out of the login screen while the stored
            // session restores — no flash, no accidental re-auth.
            VStack(spacing: HHSpacing.lg) {
                Text("Hale Health")
                    .hhFont(.hhDisplay1)
                    .hhText(.display)
                HHLoadingView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .hhScreenBackground()
        } else if !appState.hasCompletedOnboarding {
            OnboardingContainerView(appState: appState, mode: .fullOnboarding)
        } else if !appState.userSession.isAuthenticated {
            // Onboarding completed previously but the session is gone (signed
            // out / expired): re-login without re-asking goals.
            OnboardingContainerView(appState: appState, mode: .reLogin)
        } else {
            MainTabView()
        }
    }
}

#Preview("Onboarding") {
    AppCoordinator()
}
