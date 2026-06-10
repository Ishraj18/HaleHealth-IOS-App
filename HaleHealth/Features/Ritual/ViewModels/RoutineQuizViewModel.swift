import Combine
import SwiftUI
import HaleDesignSystem

/// Drives the routine questionnaire: a fixed sequence of single/multi-choice
/// steps that fill a draft `RoutineProfile`.
@MainActor
final class RoutineQuizViewModel: ObservableObject {
    struct Option: Identifiable {
        let id: String
        let label: String
        let caption: String?
        let apply: (inout RoutineProfile) -> Void
        let isSelected: (RoutineProfile) -> Bool
    }

    struct Step {
        let title: String
        let subtitle: String
        let multiSelect: Bool
        let options: [Option]
    }

    @Published var stepIndex = 0
    @Published var draft = RoutineProfile()

    let steps: [Step]

    var isLastStep: Bool { stepIndex == steps.count - 1 }
    var currentStep: Step { steps[stepIndex] }
    var canAdvance: Bool {
        // The goals step requires at least one pick; others always have a default.
        !currentStep.multiSelect || !draft.goals.isEmpty
    }

    init(initialGoals: [UserProfile.BodyGoal] = []) {
        steps = Self.buildSteps()
        draft.goals = initialGoals   // seeded from onboarding's saved goals
    }

    func select(_ option: Option) {
        withAnimation(.hhSnappy) { option.apply(&draft) }
    }

    func next() {
        guard canAdvance else { return }
        withAnimation(.hhSpring) { stepIndex = min(stepIndex + 1, steps.count - 1) }
    }

    func back() {
        withAnimation(.hhSpring) { stepIndex = max(stepIndex - 1, 0) }
    }

    // MARK: - Question definitions

    private static func buildSteps() -> [Step] {
        func single(_ id: String, _ label: String, _ caption: String? = nil,
                    apply: @escaping (inout RoutineProfile) -> Void,
                    selected: @escaping (RoutineProfile) -> Bool) -> Option {
            Option(id: id, label: label, caption: caption, apply: apply, isSelected: selected)
        }

        return [
            Step(title: "Are you a morning person?",
                 subtitle: "Your routine bends around your natural clock.",
                 multiSelect: false,
                 options: [
                    single("lark", "Yes — mornings are mine", "Up with the light",
                           apply: { $0.chronotype = .lark }, selected: { $0.chronotype == .lark }),
                    single("owl", "No — I come alive at night", "Slow starts, late focus",
                           apply: { $0.chronotype = .owl }, selected: { $0.chronotype == .owl }),
                    single("flex", "Somewhere in between", nil,
                           apply: { $0.chronotype = .flexible }, selected: { $0.chronotype == .flexible })
                 ]),

            Step(title: "When do you usually wake?",
                 subtitle: "We anchor the whole day to this.",
                 multiSelect: false,
                 options: [330, 390, 450, 510].map { mins in
                    let h = mins / 60, m = mins % 60
                    let label = String(format: "%d:%02d AM%@", h, m, mins == 510 ? " or later" : "")
                    return single("wake\(mins)", label, nil,
                                  apply: { $0.wakeMinutes = mins }, selected: { $0.wakeMinutes == mins })
                 }),

            Step(title: "What does your body need most?",
                 subtitle: "Pick what matters — your drinks follow your answer.",
                 multiSelect: true,
                 options: UserProfile.BodyGoal.allCases.map { goal in
                    single(goal.rawValue, goal.displayName, nil,
                           apply: { p in
                               if let i = p.goals.firstIndex(of: goal) { p.goals.remove(at: i) }
                               else { p.goals.append(goal) }
                           },
                           selected: { $0.goals.contains(goal) })
                 }),

            Step(title: "How fit are you right now?",
                 subtitle: "Honest answers build routines you'll actually keep.",
                 multiSelect: false,
                 options: [(1, "Just starting", "Movement feels like effort"),
                           (2, "Getting there", "Active some weeks"),
                           (3, "Reasonably fit", "Regular movement"),
                           (4, "Very fit", "Training is part of life")].map { lvl, label, cap in
                    single("fit\(lvl)", label, cap,
                           apply: { $0.fitness = lvl }, selected: { $0.fitness == lvl })
                 }),

            Step(title: "How is your mind these days?",
                 subtitle: "This shapes the quiet parts of your routine.",
                 multiSelect: false,
                 options: [(RoutineProfile.Mind.calm, "Mostly calm"),
                           (.foggy, "Foggy, low focus"),
                           (.anxious, "Anxious, wound up"),
                           (.scattered, "Scattered, too many tabs open")].map { mind, label in
                    single(mind.rawValue, label, nil,
                           apply: { $0.mind = mind }, selected: { $0.mind == mind })
                 }),

            Step(title: "How much time can you give yourself?",
                 subtitle: "Daily, just for you. Be realistic.",
                 multiSelect: false,
                 options: [(15, "15 minutes"), (30, "30 minutes"), (60, "1 hour"), (90, "90+ minutes")].map { mins, label in
                    single("budget\(mins)", label, nil,
                           apply: { $0.budgetMinutes = mins }, selected: { $0.budgetMinutes == mins })
                 }),

            Step(title: "Do you exercise currently?",
                 subtitle: "We meet you where you are.",
                 multiSelect: false,
                 options: [(RoutineProfile.Exercise.never, "Not really"),
                           (.sometimes, "Sometimes"),
                           (.regularly, "Regularly")].map { ex, label in
                    single(ex.rawValue, label, nil,
                           apply: { $0.exercise = ex }, selected: { $0.exercise == ex })
                 }),

            Step(title: "When do you prefer to move?",
                 subtitle: "Workouts land where you'll actually do them.",
                 multiSelect: false,
                 options: [(RoutineProfile.MovePref.morning, "Morning"),
                           (.evening, "Evening"),
                           (.flexible, "Whenever it fits")].map { pref, label in
                    single(pref.rawValue, label, nil,
                           apply: { $0.movePref = pref }, selected: { $0.movePref == pref })
                 }),

            Step(title: "How is your sleep?",
                 subtitle: "Everything else is built on this.",
                 multiSelect: false,
                 options: [(1, "Poor — restless nights"), (2, "Inconsistent"),
                           (3, "Decent"), (4, "Deep and regular")].map { lvl, label in
                    single("sleep\(lvl)", label, nil,
                           apply: { $0.sleepQuality = lvl }, selected: { $0.sleepQuality == lvl })
                 }),

            Step(title: "What's your main intention?",
                 subtitle: "One word that tunes the whole plan.",
                 multiSelect: false,
                 options: [(RoutineProfile.Intention.energy, "Energy", "Steady, all-day fuel"),
                           (.calm, "Calm", "A quieter baseline"),
                           (.discipline, "Discipline", "Keep small promises"),
                           (.glow, "Glow", "Repair from within")].map { intent, label, cap in
                    single(intent.rawValue, label, cap,
                           apply: { $0.intention = intent }, selected: { $0.intention == intent })
                 })
        ]
    }
}
