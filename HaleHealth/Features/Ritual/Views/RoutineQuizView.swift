import SwiftUI
import HaleDesignSystem

/// The routine questionnaire — one question per screen, progress dots, the same
/// visual language as onboarding.
struct RoutineQuizView: View {
    @StateObject private var viewModel: RoutineQuizViewModel
    @Environment(\.hhAtmosphere) private var atmosphere
    let onComplete: (RoutineProfile) -> Void

    init(initialGoals: [UserProfile.BodyGoal] = [], onComplete: @escaping (RoutineProfile) -> Void) {
        _viewModel = StateObject(wrappedValue: RoutineQuizViewModel(initialGoals: initialGoals))
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            progressDots
                .padding(.top, HHSpacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: HHSpacing.lg) {
                    VStack(alignment: .leading, spacing: HHSpacing.sm) {
                        Text(viewModel.currentStep.title)
                            .hhFont(.hhDisplay2)
                            .hhText(.display)
                        Text(viewModel.currentStep.subtitle)
                            .hhFont(.hhBody)
                            .hhText(.secondary)
                    }

                    VStack(spacing: HHSpacing.sm) {
                        ForEach(viewModel.currentStep.options) { option in
                            optionRow(option)
                        }
                    }
                }
                .padding(HHSpacing.lg)
                .id(viewModel.stepIndex) // re-trigger transition per step
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            footer
        }
        .hhScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.stepIndex > 0 {
                ToolbarItem(placement: .topBarLeading) {
                    Button { viewModel.back() } label: {
                        Image(systemName: "chevron.left").hhText(.display)
                    }
                }
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: HHSpacing.sm) {
            ForEach(0..<viewModel.steps.count, id: \.self) { i in
                Capsule()
                    .fill(i <= viewModel.stepIndex ? Color.hhWarmSaffron : Color.hhBorder)
                    .frame(width: i == viewModel.stepIndex ? 20 : 6, height: 6)
                    .animation(.hhSnappy, value: viewModel.stepIndex)
            }
        }
    }

    private func optionRow(_ option: RoutineQuizViewModel.Option) -> some View {
        let selected = option.isSelected(viewModel.draft)
        return Button { viewModel.select(option) } label: {
            HStack(spacing: HHSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .hhFont(.hhHeading)
                        .hhText(.primary)
                    if let caption = option.caption {
                        Text(caption)
                            .hhFont(.hhCaption)
                            .hhText(.secondary)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Color.hhForestGreen : Color.hhBorder)
            }
            .padding(HHSpacing.md)
            .background(
                selected ? Color.hhMutedSage.opacity(0.18) : atmosphere.surfaceFill,
                in: RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
                    .stroke(selected ? Color.hhForestGreen : Color.hhBorder, lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HHButton(viewModel.isLastStep ? "Create my routine" : "Next",
                 style: .primary, isEnabled: viewModel.canAdvance) {
            if viewModel.isLastStep {
                onComplete(viewModel.draft)
            } else {
                viewModel.next()
            }
        }
        .padding(HHSpacing.lg)
        .background(atmosphere.canvas)
    }
}

#Preview {
    NavigationStack { RoutineQuizView { _ in } }
}
