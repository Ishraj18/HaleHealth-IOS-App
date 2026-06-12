import XCTest
@testable import HaleHealth

/// The rule-based personal copy: every line must be explainable by the rules
/// pinned here.
final class InsightEngineTests: XCTestCase {

    private func trends(
        days: Int = 7,
        withData: Int,
        completionRate: Double = 0,
        daysKept: Int = 0,
        meditationMinutes: Int = 0,
        meditationSessions: Int = 0,
        highAQIDays: Int = 0
    ) -> Trends {
        Trends(windowDays: days, daysWithData: withData, completionRate: completionRate,
               daysKept: daysKept, meditationMinutes: meditationMinutes,
               meditationSessions: meditationSessions, drinksLogged: 0,
               averageSteps: nil, highAQIDays: highAQIDays)
    }

    func testBrandNewUserGetsOnlyTheFirstDaysLine() {
        let insights = InsightEngine.insights(
            week: trends(withData: 1), month: trends(days: 30, withData: 1),
            streak: 0, intention: nil, goals: []
        )
        XCTAssertEqual(insights.map(\.id), ["first-days"])
    }

    func testStreakLeadsWhenPresent() {
        let insights = InsightEngine.insights(
            week: trends(withData: 5, completionRate: 0.9, daysKept: 5),
            month: trends(days: 30, withData: 5),
            streak: 6, intention: .calm, goals: []
        )
        XCTAssertEqual(insights.first?.id, "streak")
        XCTAssertTrue(insights.first!.text.contains("Day 6"))
    }

    func testHighCompletionWeekIsCelebrated() {
        let insights = InsightEngine.insights(
            week: trends(withData: 6, completionRate: 0.85, daysKept: 5),
            month: trends(days: 30, withData: 6),
            streak: 0, intention: nil, goals: []
        )
        XCTAssertTrue(insights.contains { $0.id == "completion-high" })
        XCTAssertTrue(insights.first { $0.id == "completion-high" }!.text.contains("85%"))
    }

    func testHeavyAirSpeaksToLungGoal() {
        let insights = InsightEngine.insights(
            week: trends(withData: 5, highAQIDays: 3),
            month: trends(days: 30, withData: 5),
            streak: 0, intention: nil, goals: [.lungHealth]
        )
        let air = insights.first { $0.id == "air" }
        XCTAssertNotNil(air)
        XCTAssertTrue(air!.text.contains("lung-first"))
    }

    func testNeverMoreThanThreeInsights() {
        let insights = InsightEngine.insights(
            week: trends(withData: 7, completionRate: 0.9, daysKept: 7,
                         meditationMinutes: 40, meditationSessions: 5, highAQIDays: 4),
            month: trends(days: 30, withData: 20, daysKept: 15),
            streak: 12, intention: .discipline, goals: [.lungHealth]
        )
        XCTAssertLessThanOrEqual(insights.count, 3)
    }
}
