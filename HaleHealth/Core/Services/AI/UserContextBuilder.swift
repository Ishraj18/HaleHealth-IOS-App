import Foundation

/// Everything the app knows about the user, assembled into one Codable value.
/// This is the payload a future Vaidya AI prompt consumes — and, until then,
/// the precise definition of "what the app knows". Keys are stable; new
/// knowledge is added as new optional fields.
struct UserContext: Codable, Equatable, Sendable {

    struct PlanBlock: Codable, Equatable, Sendable {
        let id: String
        let kind: String
        let title: String
        let startMinutes: Int
        let done: Bool
    }

    struct TrendWindow: Codable, Equatable, Sendable {
        let days: Int
        let daysWithData: Int
        let completionRate: Double
        let daysKept: Int
        let meditationMinutes: Int
        let drinksLogged: Int
        let averageSteps: Int?
        let highAQIDays: Int

        init(_ trends: Trends) {
            days = trends.windowDays
            daysWithData = trends.daysWithData
            completionRate = trends.completionRate
            daysKept = trends.daysKept
            meditationMinutes = trends.meditationMinutes
            drinksLogged = trends.drinksLogged
            averageSteps = trends.averageSteps
            highAQIDays = trends.highAQIDays
        }
    }

    let generatedAt: Date
    let day: String

    // Who they are (questionnaire-derived)
    let goals: [String]
    let chronotype: String?
    let intention: String?
    let mind: String?
    let fitness: Int?
    let dailyBudgetMinutes: Int?

    // Today
    let aqi: Int?
    let aqiCategory: String?
    let streak: Int
    let todayPlan: [PlanBlock]
    let todayCompletionRatio: Double
    let stepsToday: Int?
    let workoutsToday: Int?
    let meditationMinutesToday: Int

    // History
    let lastWeek: TrendWindow
    let lastMonth: TrendWindow

    /// Stable, pretty-printed JSON — the exact string a prompt would embed.
    func promptJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}

/// Pure assembly of a `UserContext` from explicit inputs — no stores, no
/// clocks beyond the passed values, fully unit-testable. `AppState` provides
/// the convenience that reads the live stores.
struct UserContextBuilder {

    func build(
        day: String,
        profile: RoutineProfile?,
        routine: DailyRoutine?,
        completion: RoutineCompletion,
        streak: Int,
        aqi: AQIReading?,
        todaySnapshot: DailySnapshot?,
        weekSnapshots: [DailySnapshot],
        monthSnapshots: [DailySnapshot],
        now: Date = Date()
    ) -> UserContext {
        let blocks = (routine?.blocks ?? []).map { block in
            UserContext.PlanBlock(
                id: block.id,
                kind: block.kind.rawValue,
                title: block.title,
                startMinutes: block.startMinutes,
                done: completion.completedBlockIDs.contains(block.id)
            )
        }
        let doneCount = blocks.filter(\.done).count

        return UserContext(
            generatedAt: now,
            day: day,
            goals: (profile?.goals ?? []).map(\.rawValue),
            chronotype: profile?.chronotype.rawValue,
            intention: profile?.intention.rawValue,
            mind: profile?.mind.rawValue,
            fitness: profile?.fitness,
            dailyBudgetMinutes: profile?.budgetMinutes,
            aqi: aqi?.value,
            aqiCategory: aqi.map(\.category.rawValue),
            streak: streak,
            todayPlan: blocks,
            todayCompletionRatio: blocks.isEmpty ? 0 : Double(doneCount) / Double(blocks.count),
            stepsToday: todaySnapshot?.steps,
            workoutsToday: todaySnapshot?.workouts,
            meditationMinutesToday: todaySnapshot?.meditationMinutes ?? 0,
            lastWeek: .init(TrendCalculator.trends(over: 7, from: weekSnapshots)),
            lastMonth: .init(TrendCalculator.trends(over: 30, from: monthSnapshots))
        )
    }
}

extension AppState {
    /// The live context — the one call a future Vaidya AI feature makes before
    /// composing a prompt.
    func currentUserContext() -> UserContext {
        let routineStore = RoutineStore.shared
        let history = HistoryStore.shared
        return UserContextBuilder().build(
            day: Date().hhISODate,
            profile: routineStore.profile,
            routine: routineStore.routine,
            completion: routineStore.completion,
            streak: routineStore.streak.count,
            aqi: currentAQI,
            todaySnapshot: history.today,
            weekSnapshots: history.recent(days: 7),
            monthSnapshots: history.recent(days: 30)
        )
    }
}
