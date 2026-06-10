import Foundation

/// Questionnaire answers that drive routine generation. Versioned so a future
/// quiz revision can migrate or invalidate stored profiles.
struct RoutineProfile: Codable, Equatable, Sendable {
    enum Chronotype: String, Codable, CaseIterable { case lark, owl, flexible }
    enum Mind: String, Codable, CaseIterable { case calm, foggy, anxious, scattered }
    enum Exercise: String, Codable, CaseIterable { case never, sometimes, regularly }
    enum MovePref: String, Codable, CaseIterable { case morning, evening, flexible }
    enum Intention: String, Codable, CaseIterable { case energy, calm, discipline, glow }

    var chronotype: Chronotype = .flexible
    var wakeMinutes: Int = 7 * 60          // minutes from midnight
    var goals: [UserProfile.BodyGoal] = []
    var fitness: Int = 2                   // 1…4
    var mind: Mind = .calm
    var budgetMinutes: Int = 30            // daily self-time budget
    var exercise: Exercise = .sometimes
    var movePref: MovePref = .flexible
    var sleepQuality: Int = 2              // 1…4
    var intention: Intention = .energy
    var quizVersion: Int = 1
}

/// One scheduled activity in a daily routine.
struct RoutineBlock: Identifiable, Codable, Equatable, Sendable {
    enum Kind: String, Codable {
        case wake, hydrate, meditate, drink, meal, workout, walk, journal, windDown, sleep
    }

    let id: String                 // stable per kind+slot, keys completion state
    let kind: Kind
    let title: String
    let detail: String             // the one-line "why"
    let startMinutes: Int          // minutes from midnight
    let durationMinutes: Int
    let productID: ProductID?      // set for drink blocks

    var timeLabel: String {
        let h = startMinutes / 60, m = startMinutes % 60
        let hour12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour12, m, h < 12 ? "AM" : "PM")
    }

    var iconName: String {
        switch kind {
        case .wake: return "sun.horizon.fill"
        case .hydrate: return "drop.fill"
        case .meditate: return "leaf.fill"
        case .drink: return "cup.and.saucer.fill"
        case .meal: return "fork.knife"
        case .workout: return "figure.run"
        case .walk: return "figure.walk"
        case .journal: return "book.closed.fill"
        case .windDown: return "moon.stars.fill"
        case .sleep: return "bed.double.fill"
        }
    }
}

/// A generated day plan. Recomputed from profile + AQI rather than stored.
struct DailyRoutine: Codable, Equatable, Sendable {
    let blocks: [RoutineBlock]
    let themeLine: String          // intention-toned headline
    let generatedAt: Date
}

/// Per-day check-off state.
struct RoutineCompletion: Codable, Equatable, Sendable {
    var day: String                // "yyyy-MM-dd"
    var completedBlockIDs: Set<String> = []
}
