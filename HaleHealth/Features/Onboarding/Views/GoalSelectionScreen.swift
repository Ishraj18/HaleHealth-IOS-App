import SwiftUI
import HaleDesignSystem

/// Onboarding screen 2 — pick the body systems to protect. Each goal subtly
/// surfaces its associated product's Hindi name.
struct GoalSelectionScreen: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.hhAtmosphere) private var atmosphere

    private let columns = [
        GridItem(.flexible(), spacing: HHSpacing.md),
        GridItem(.flexible(), spacing: HHSpacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: HHSpacing.lg) {
                    header
                    LazyVGrid(columns: columns, spacing: HHSpacing.md) {
                        ForEach(UserProfile.BodyGoal.allCases) { goal in
                            goalCell(goal)
                        }
                    }
                }
                .padding(HHSpacing.lg)
            }

            HHButton("Continue", style: .primary, isEnabled: viewModel.canContinueGoals) {
                viewModel.advanceFromGoals()
            }
            .padding(HHSpacing.lg)
            .background(atmosphere.canvas)
        }
        .hhScreenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: HHSpacing.sm) {
            Text("What do you want to protect?")
                .hhFont(.hhDisplay2)
                .hhText(.display)
            Text("Choose what matters most. Your recommendations adapt to your answer.")
                .hhFont(.hhBody)
                .hhText(.secondary)
        }
    }

    private func goalCell(_ goal: UserProfile.BodyGoal) -> some View {
        let isSelected = viewModel.isSelected(goal)
        let accent = Color(hex: viewModel.product(for: goal)?.accentColor ?? "#7A9E8A")

        return Button {
            withAnimation(.hhSnappy) { viewModel.toggle(goal) }
        } label: {
            HHCard {
                VStack(alignment: .leading, spacing: HHSpacing.xs) {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? Color.hhForestGreen : Color.hhBorder)
                    }
                    Text(goal.displayName)
                        .hhFont(.hhHeading)
                        .hhText(.primary)
                    if let product = viewModel.product(for: goal) {
                        Text(product.hindiName)
                            .hhFont(.hhDisplayItalic)
                            .foregroundStyle(Color.hhMutedSage)
                    }
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(accent)
                        .frame(width: 4)
                        .padding(.vertical, HHSpacing.sm)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalSelectionScreen(viewModel: {
        let vm = OnboardingViewModel(appState: .preview)
        vm.toggle(.lungHealth)
        return vm
    }())
}
