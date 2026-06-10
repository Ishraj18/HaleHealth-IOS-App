import AuthenticationServices
import SwiftUI
import HaleDesignSystem

/// Onboarding screen 3 — email/password auth with a Login ↔ Sign-up toggle,
/// plus native Sign in with Apple and Google (Supabase OAuth web flow).
/// All logic lives in `OnboardingViewModel`.
struct AuthScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.hhAtmosphere) private var atmosphere

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HHSpacing.lg) {
                VStack(alignment: .leading, spacing: HHSpacing.sm) {
                    Text("Your ritual starts here.")
                        .hhFont(.hhDisplay2)
                        .hhText(.display)
                    Text(viewModel.authMode == .signUp
                         ? "Create your account — you'll stay signed in."
                         : "Welcome back. Log in to continue.")
                        .hhFont(.hhBody)
                        .hhText(.secondary)
                }

                VStack(spacing: HHSpacing.md) {
                    HHTextField(
                        "you@example.com",
                        text: $viewModel.email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never
                    )
                    HHTextField(
                        "Password",
                        text: $viewModel.password,
                        textContentType: viewModel.authMode == .signUp ? .newPassword : .password,
                        isSecure: true,
                        autocapitalization: .never,
                        submitLabel: .go
                    )
                    if let hint = viewModel.passwordHint {
                        Text(hint)
                            .hhFont(.hhCaption)
                            .hhText(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HHButton(
                        viewModel.submitTitle,
                        style: .primary,
                        isLoading: viewModel.isSubmitting,
                        isEnabled: viewModel.canSubmit
                    ) {
                        Task { await viewModel.submit() }
                    }

                    HHButton(
                        viewModel.authMode == .signUp
                            ? "Already have an account? Log in"
                            : "New here? Create an account",
                        style: .text
                    ) {
                        viewModel.toggleAuthMode()
                    }
                }

                HHDivider(label: "or")

                VStack(spacing: HHSpacing.sm) {
                    if AppleSignInFeature.enabled {
                        SignInWithAppleButton(.signIn) { request in
                            viewModel.prepareAppleRequest(request)
                        } onCompletion: { result in
                            viewModel.handleAppleCompletion(result)
                        }
                        .signInWithAppleButtonStyle(atmosphere.isNight ? .white : .black)
                        .frame(height: 52)
                        .clipShape(Capsule())
                    }

                    googleButton
                }
                .disabled(viewModel.isSubmitting)

                #if DEBUG
                HHButton("Skip verification (dev)", style: .text, isEnabled: viewModel.emailLooksValid) {
                    viewModel.continueWithoutVerification()
                }
                #endif
            }
            .padding(HHSpacing.lg)
        }
        .hhScreenBackground()
    }

    private var googleButton: some View {
        Button {
            Task { await viewModel.signInWithGoogle() }
        } label: {
            HStack(spacing: HHSpacing.sm) {
                Text("G")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#4285F4"))
                Text("Sign in with Google")
                    .hhFont(.hhLabel)
            }
            .hhText(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(atmosphere.surfaceFill, in: Capsule())
            .overlay(Capsule().stroke(atmosphere.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Sign up") {
    AuthScreen(viewModel: OnboardingViewModel(appState: .preview))
}

#Preview("Login") {
    AuthScreen(viewModel: OnboardingViewModel(appState: .preview, mode: .reLogin))
}
