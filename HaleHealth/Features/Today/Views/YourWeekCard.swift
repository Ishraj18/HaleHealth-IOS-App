import SwiftUI
import HaleDesignSystem

/// The personal pulse on the Today screen: the user's own week — ritual kept,
/// breath taken, drinks logged — and a few lines that could only be theirs.
/// Entirely rule-based (TrendCalculator + InsightEngine), entirely offline.
struct YourWeekCard: View {
    @ObservedObject private var history = HistoryStore.shared
    @ObservedObject private var routineStore = RoutineStore.shared

    var body: some View {
        let week = TrendCalculator.trends(over: 7, from: history.recent(days: 7))
        let month = TrendCalculator.trends(over: 30, from: history.recent(days: 30))
        let insights = InsightEngine.insights(
            week: week,
            month: month,
            streak: routineStore.streak.count,
            intention: routineStore.profile?.intention,
            goals: routineStore.profile?.goals ?? []
        )

        HHCard {
            VStack(alignment: .leading, spacing: HHSpacing.md) {
                Text("Your week")
                    .hhFont(.hhHeading)
                    .hhText(.primary)

                if week.daysWithData > 1 {
                    HStack(spacing: 0) {
                        stat(value: "\(Int((week.completionRate * 100).rounded()))%",
                             label: "ritual kept", accent: .hhForestGreen)
                        stat(value: "\(week.meditationMinutes)",
                             label: "breath min", accent: .hhMutedSage)
                        stat(value: "\(week.drinksLogged)",
                             label: "drinks", accent: .hhWarmSaffron)
                    }
                }

                VStack(alignment: .leading, spacing: HHSpacing.sm) {
                    ForEach(insights) { insight in
                        HStack(alignment: .top, spacing: HHSpacing.sm) {
                            Image(systemName: insight.icon)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.hhDustyGold)
                                .frame(width: 18)
                                .padding(.top, 2)
                            Text(insight.text)
                                .hhFont(.hhCaption)
                                .hhText(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func stat(value: String, label: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .hhFont(.hhDisplay2)
                .foregroundStyle(accent)
            Text(label)
                .hhFont(.hhOverline)
                .tracking(0.8)
                .textCase(.uppercase)
                .hhText(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    YourWeekCard()
        .padding()
        .background(Color.hhBackground)
}
