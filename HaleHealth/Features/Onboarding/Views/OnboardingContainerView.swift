import SwiftUI
import HaleDesignSystem

/// Hosts the onboarding flow and owns its ViewModel. Driven by `viewModel.step`;
/// toasts are presented at this level so they persist across step changes.
struct OnboardingContainerView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(appState: AppState, mode: OnboardingMode = .fullOnboarding) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(appState: appState, mode: mode))
    }

    var body: some View {
        ZStack {
            switch viewModel.step {
            case .welcome:
                WelcomeScreen(viewModel: viewModel)
                    .transition(.opacity)
            case .goals:
                GoalSelectionScreen(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .auth:
                AuthScreen(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .hhToast($viewModel.toast)
    }
}

#Preview {
    OnboardingContainerView(appState: .preview)
}
