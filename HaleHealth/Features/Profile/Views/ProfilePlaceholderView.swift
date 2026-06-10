import SwiftUI
import HaleDesignSystem

/// Phase 1 placeholder for the profile screen. Shows the signed-in user and a
/// working sign-out (handy for exercising the auth loop) ahead of the full
/// Phase 2 profile.
struct ProfilePlaceholderView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var session: UserSession

    var body: some View {
        VStack(spacing: HHSpacing.lg) {
            if let profile = session.profile {
                VStack(spacing: HHSpacing.xs) {
                    Text(profile.displayName)
                        .hhFont(.hhDisplay2)
                        .hhText(.display)
                    Text(profile.email)
                        .hhFont(.hhBody)
                        .hhText(.secondary)
                }
                .padding(.top, HHSpacing.xl)
            }

            HHEmptyState(
                title: "Profile",
                subtitle: "Subscriptions, orders and settings arrive soon.",
                systemImage: "person"
            )

            Spacer()

            HHButton("Sign out", style: .secondary) {
                Task { await appState.signOut() }
            }
            .padding(.horizontal, HHSpacing.xl)
            .padding(.bottom, HHSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hhScreenBackground()
        .navigationTitle(Tab.profile.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let state = AppState.preview
    return NavigationStack { ProfilePlaceholderView() }
        .environmentObject(state)
        .environmentObject(state.userSession)
}
