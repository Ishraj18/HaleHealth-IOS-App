import Foundation

/// A short personal observation derived from the user's own history.
struct PersonalInsight: Equatable, Identifiable, Sendable {
    let id: String           // stable rule id, useful for analytics later
    let icon: String         // SF Symbol
    let text: String
}

/// Deterministic, rule-based insight generation: the user's history in, a few
/// lines that could only be about *them* out. No AI — every line is explainable
/// and testable. A future Vaidya engine can rewrite the copy; the selection
/// logic stays the ground truth.
enum InsightEngine {

    /// Up to three insights, most personal first.
    static func insights(
        week: Trends,
        month: Trends,
        streak: Int,
        intention: RoutineProfile.Intention?,
        goals: [UserProfile.BodyGoal]
    ) -> [PersonalInsight] {
        var results: [PersonalInsight] = []

        // Brand-new users get an honest start, not fake stats.
        guard week.daysWithData > 1 else {
            return [PersonalInsight(
                id: "first-days", icon: "sparkles",
                text: "Your story starts here. Every block you tap is remembered — within a week, this space reads like you."
            )]
        }

        // Streak first — it's the most personal number in the app.
        if streak >= 3 {
            results.append(PersonalInsight(
                id: "streak", icon: "flame.fill",
                text: "Day \(streak) of your ritual. \(streakLine(for: intention))"
            ))
        }

        // Follow-through this week.
        let pct = Int((week.completionRate * 100).rounded())
        if week.completionRate >= 0.8 {
            results.append(PersonalInsight(
                id: "completion-high", icon: "checkmark.seal.fill",
                text: "You kept \(pct)% of your ritual this week — \(week.daysKept) of \(week.daysWithData) days counted. Momentum is yours."
            ))
        } else if week.completionRate >= 0.4 {
            results.append(PersonalInsight(
                id: "completion-mid", icon: "circle.bottomhalf.filled",
                text: "\(pct)% of your ritual kept this week. The morning blocks are the lever — win the first hour, the day follows."
            ))
        } else if week.daysWithData >= 3 {
            results.append(PersonalInsight(
                id: "completion-low", icon: "arrow.counterclockwise",
                text: "A light week — \(pct)% kept. Shrink the ritual before you skip it: even two blocks keeps the thread."
            ))
        }

        // Breathwork.
        if week.meditationMinutes >= 5 {
            results.append(PersonalInsight(
                id: "breath", icon: "leaf.fill",
                text: "\(week.meditationMinutes) minutes of breathwork across \(week.meditationSessions) sitting\(week.meditationSessions == 1 ? "" : "s") this week."
            ))
        }

        // Air context, tied to their goal when it fits.
        if week.highAQIDays >= 2 {
            let lungGoal = goals.contains(.lungHealth)
            results.append(PersonalInsight(
                id: "air", icon: "wind",
                text: lungGoal
                    ? "Heavy air on \(week.highAQIDays) of the last 7 days — your lung-first mornings are doing quiet work."
                    : "Heavy air on \(week.highAQIDays) of the last 7 days. Saans mornings shield first; your goals resume by afternoon."
            ))
        }

        // Month-scale perspective once it exists.
        if month.daysWithData >= 14, month.daysKept >= 10 {
            results.append(PersonalInsight(
                id: "month", icon: "calendar",
                text: "\(month.daysKept) kept days in the last month. This is what a habit looks like from above."
            ))
        }

        return Array(results.prefix(3))
    }

    private static func streakLine(for intention: RoutineProfile.Intention?) -> String {
        switch intention {
        case .energy:     return "Steady fuel, day after day."
        case .calm:       return "The quiet is compounding."
        case .discipline: return "Promises kept, again."
        case .glow:       return "Repair is cumulative."
        case nil:         return "Keep the thread."
        }
    }
}
