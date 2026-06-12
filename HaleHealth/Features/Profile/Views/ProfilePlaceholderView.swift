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
                VStack(spacing: HHSpacing.sm) {
                    avatar(for: profile)
                    VStack(spacing: HHSpacing.xs) {
                        Text(profile.displayName)
                            .hhFont(.hhDisplay2)
                            .hhText(.display)
                        Text(profile.email)
                            .hhFont(.hhBody)
                            .hhText(.secondary)
                    }
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

    /// The provider photo when one exists; otherwise the user's initials on a
    /// brand-toned disc.
    @ViewBuilder
    private func avatar(for profile: UserProfile) -> some View {
        let size: CGFloat = 88
        if let urlString = profile.avatarURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    initialsDisc(for: profile, size: size)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.hhBorder, lineWidth: 1))
        } else {
            initialsDisc(for: profile, size: size)
        }
    }

    private func initialsDisc(for profile: UserProfile, size: CGFloat) -> some View {
        let initials = profile.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
        return ZStack {
            Circle().fill(Color.hhMutedSage.opacity(0.25))
            Text(initials.isEmpty ? "🙂" : initials)
                .hhFont(.hhDisplay2)
                .hhText(.display)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    let state = AppState.preview
    return NavigationStack { ProfilePlaceholderView() }
        .environmentObject(state)
        .environmentObject(state.userSession)
}
