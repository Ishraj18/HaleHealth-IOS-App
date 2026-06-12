import SwiftUI
import HaleDesignSystem

/// Today's routine as a vertical timeline: time rail on the left, blocks on the
/// right, drink blocks dressed in their product's accent.
struct RoutineTimelineView: View {
    let routine: DailyRoutine
    @ObservedObject var store: RoutineStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.hhAtmosphere) private var atmosphere
    var onCelebrate: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: HHSpacing.md) {
            header

            VStack(spacing: 0) {
                ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { index, block in
                    timelineRow(block, isLast: index == routine.blocks.count - 1)
                }
            }
        }
    }

    private var header: some View {
        let progress = store.progress(for: routine)
        return HHCard {
            HStack(spacing: HHSpacing.md) {
                HHStreakRing(progress: progress, streak: store.streak.count, size: 84)
                VStack(alignment: .leading, spacing: HHSpacing.xs) {
                    Text(routine.themeLine)
                        .hhFont(.hhDisplayItalic)
                        .hhText(.display)
                    Text(progressLabel(progress))
                        .hhFont(.hhCaption)
                        .hhText(.secondary)
                }
            }
        }
    }

    private func progressLabel(_ p: Double) -> String {
        switch p {
        case 0:        return "Your day, laid out. Tap each block as you go."
        case ..<1:     return "\(Int(p * 100))% of today's ritual done."
        default:       return "Every block complete. Shabash. 🌿"
        }
    }

    private func timelineRow(_ block: RoutineBlock, isLast: Bool) -> some View {
        let done = store.isDone(block.id)
        let accent = accentColor(block)

        return HStack(alignment: .top, spacing: HHSpacing.md) {
            // Time rail
            VStack(spacing: 0) {
                Text(block.timeLabel)
                    .hhFont(.hhCaption, lineSpacing: 0)
                    .hhText(.secondary)
                    .frame(width: 64)
                if !isLast {
                    Rectangle()
                        .fill(Color.hhBorder)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, HHSpacing.xs)
                }
            }
            .frame(width: 64)

            // Block card
            Button {
                let wasDone = store.isDone(block.id)
                withAnimation(.hhSpring) { store.toggle(block.id) }
                guard !wasDone else { return }
                Haptics.tap()
                // shouldLogDrink is true once per block per day — re-toggling
                // can't write duplicate drink_logs rows.
                if block.kind == .drink, let pid = block.productID, store.shouldLogDrink(block.id) {
                    appState.logDrink(pid)
                }
                let progress = store.progress(for: routine)
                let streakUp = store.recordProgress(progress)
                if progress >= 1 || streakUp {
                    Haptics.success()
                    onCelebrate()
                }
            } label: {
                HStack(alignment: .top, spacing: HHSpacing.md) {
                    ZStack {
                        Circle().fill(accent.opacity(0.14))
                        Image(systemName: block.iconName)
                            .font(.system(size: 15))
                            .foregroundStyle(accent)
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: HHSpacing.sm) {
                            Text(block.title)
                                .hhFont(.hhHeading, lineSpacing: 0)
                                .hhText(.primary)
                                .strikethrough(done, color: .hhTextSecondary)
                            if let product = block.productID.flatMap(ProductCatalogData.product) {
                                Text(product.hindiName)
                                    .hhFont(.hhDisplayItalic, lineSpacing: 0)
                                    .foregroundStyle(accent)
                            }
                        }
                        Text(block.detail)
                            .hhFont(.hhCaption)
                            .hhText(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(done ? Color.hhForestGreen : Color.hhBorder)
                }
                .padding(HHSpacing.md)
                .background(
                    done ? Color.hhMutedSage.opacity(0.12) : atmosphere.surfaceFill,
                    in: RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous)
                )
                .overlay(alignment: .leading) {
                    UnevenRoundedRectangle(topLeadingRadius: HHRadius.md, bottomLeadingRadius: HHRadius.md)
                        .fill(accent)
                        .frame(width: 3)
                }
                .opacity(done ? 0.75 : 1)
            }
            .buttonStyle(.plain)
            .padding(.bottom, HHSpacing.md)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func accentColor(_ block: RoutineBlock) -> Color {
        if let product = block.productID.flatMap(ProductCatalogData.product) {
            return Color(hex: product.accentColor)
        }
        switch block.kind {
        case .wake, .sleep, .windDown: return .hhDustyGold
        case .meditate, .journal:      return .hhMutedSage
        case .workout, .walk:          return .hhForestGreen
        case .meal, .hydrate:          return .hhWarmSaffron
        case .drink:                   return .hhWarmSaffron
        }
    }
}

#Preview {
    let routine = RuleBasedRoutineEngine().generate(
        from: RoutineProfile(goals: [.lungHealth], mind: .scattered),
        context: GenerationContext(aqi: AQIReading(value: 218, station: "Gurgaon", fetchedAt: Date()))
    )
    return ScrollView {
        RoutineTimelineView(routine: routine, store: RoutineStore())
            .padding(HHSpacing.lg)
    }
    .background(Color.hhBackground)
    .environmentObject(AppState.preview)
}
