import Foundation

/// Aggregates over a window of daily snapshots. All averages are over days the
/// app actually saw (`daysWithData`), never over the full window — absence of
/// data is not evidence of inactivity.
struct Trends: Equatable, Sendable {
    let windowDays: Int
    let daysWithData: Int
    /// Mean completion ratio across days that had a plan.
    let completionRate: Double
    /// Days where completion crossed the streak-keeping threshold.
    let daysKept: Int
    let meditationMinutes: Int
    let meditationSessions: Int
    let drinksLogged: Int
    /// Mean daily steps across days Health reported; nil when it never did.
    let averageSteps: Int?
    /// Days with AQI above 200 ("Very Unhealthy" and beyond).
    let highAQIDays: Int

    static func empty(windowDays: Int) -> Trends {
        Trends(windowDays: windowDays, daysWithData: 0, completionRate: 0, daysKept: 0,
               meditationMinutes: 0, meditationSessions: 0, drinksLogged: 0,
               averageSteps: nil, highAQIDays: 0)
    }
}

/// Pure aggregation over `DailySnapshot`s — no clocks, no stores, fully
/// unit-testable. Callers pass `HistoryStore.recent(days:)`.
enum TrendCalculator {

    static func trends(over windowDays: Int, from snapshots: [DailySnapshot]) -> Trends {
        guard !snapshots.isEmpty else { return .empty(windowDays: windowDays) }

        let plannedDays = snapshots.filter { $0.blocksTotal > 0 }
        let completionRate = plannedDays.isEmpty ? 0 :
            plannedDays.map(\.completionRatio).reduce(0, +) / Double(plannedDays.count)

        let stepDays = snapshots.compactMap(\.steps)
        let averageSteps = stepDays.isEmpty ? nil : stepDays.reduce(0, +) / stepDays.count

        return Trends(
            windowDays: windowDays,
            daysWithData: snapshots.count,
            completionRate: completionRate,
            daysKept: plannedDays.filter { $0.completionRatio >= RoutineStore.keepThreshold }.count,
            meditationMinutes: snapshots.map(\.meditationMinutes).reduce(0, +),
            meditationSessions: snapshots.map(\.meditationSessions).reduce(0, +),
            drinksLogged: snapshots.map(\.drinksLogged).reduce(0, +),
            averageSteps: averageSteps,
            highAQIDays: snapshots.filter { ($0.aqi ?? 0) > 200 }.count
        )
    }
}
