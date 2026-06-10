import SwiftUI
import HaleDesignSystem

/// Onboarding screen 1 — a full-bleed forest-green welcome.
struct WelcomeScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.hhForestGreen.ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: HHSpacing.md) {
                    Text("Hale Health")
                        .hhFont(.hhDisplay1)
                        .foregroundStyle(Color.hhCreamParchment)

                    Rectangle()
                        .fill(Color.hhMutedSage)
                        .frame(width: 80, height: 1)

                    Text("Rooted in tradition. Built for Delhi.")
                        .hhFont(.hhDisplayItalic)
                        .foregroundStyle(Color.hhMutedSage)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                HHButton("Begin", style: .primary) {
                    viewModel.advanceFromWelcome()
                }
                .padding(.horizontal, HHSpacing.xl)
                .padding(.bottom, HHSpacing.xxl)
            }
        }
    }
}

#Preview {
    WelcomeScreen(viewModel: OnboardingViewModel(appState: .preview))
}
