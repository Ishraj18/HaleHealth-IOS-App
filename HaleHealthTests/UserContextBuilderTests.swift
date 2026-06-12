import XCTest
@testable import HaleHealth

/// The AI context payload: what a future Vaidya prompt sees must be exactly
/// what the stores know.
final class UserContextBuilderTests: XCTestCase {

    private func makeContext() -> UserContext {
        var profile = RoutineProfile()
        profile.goals = [.lungHealth, .gutHealth]
        profile.intention = .energy
        let routine = RuleBasedRoutineEngine().generate(
            from: profile,
            context: GenerationContext(aqi: AQIReading(value: 250, station: "Test", fetchedAt: Date()))
        )
        var completion = RoutineCompletion(day: "2026-06-12")
        completion.completedBlockIDs = ["wake", "hydrate"]

        var today = DailySnapshot(day: "2026-06-12")
        today.steps = 5400
        today.meditationMinutes = 10

        return UserContextBuilder().build(
            day: "2026-06-12",
            profile: profile,
            routine: routine,
            completion: completion,
            streak: 4,
            aqi: AQIReading(value: 250, station: "Test", fetchedAt: Date()),
            todaySnapshot: today,
            weekSnapshots: [today],
            monthSnapshots: [today],
            now: Date(timeIntervalSince1970: 1_780_000_000)
        )
    }

    func testContextMirrorsProfileAndToday() {
        let context = makeContext()
        XCTAssertEqual(context.goals, ["lung_health", "gut_health"])
        XCTAssertEqual(context.intention, "energy")
        XCTAssertEqual(context.aqi, 250)
        XCTAssertEqual(context.streak, 4)
        XCTAssertEqual(context.stepsToday, 5400)
        XCTAssertEqual(context.meditationMinutesToday, 10)
    }

    func testPlanBlocksCarryDoneFlags() {
        let context = makeContext()
        XCTAssertTrue(context.todayPlan.first { $0.id == "wake" }!.done)
        XCTAssertFalse(context.todayPlan.first { $0.id == "drink-morning" }!.done)
        let doneCount = context.todayPlan.filter(\.done).count
        XCTAssertEqual(context.todayCompletionRatio,
                       Double(doneCount) / Double(context.todayPlan.count), accuracy: 0.001)
    }

    func testPromptJSONIsValidAndStable() throws {
        let json = makeContext().promptJSON()
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        XCTAssertNotNil(object)
        XCTAssertNotNil(object?["todayPlan"])
        XCTAssertNotNil(object?["lastWeek"])
        XCTAssertNotNil(object?["lastMonth"])
        // Stable output: encoding twice yields the identical string.
        XCTAssertEqual(json, makeContext().promptJSON())
    }

    func testEmptyStateBuildsWithoutCrashing() {
        let context = UserContextBuilder().build(
            day: "2026-06-12", profile: nil, routine: nil,
            completion: RoutineCompletion(day: "2026-06-12"), streak: 0,
            aqi: nil, todaySnapshot: nil, weekSnapshots: [], monthSnapshots: []
        )
        XCTAssertTrue(context.todayPlan.isEmpty)
        XCTAssertEqual(context.todayCompletionRatio, 0)
        XCTAssertTrue(context.goals.isEmpty)
    }
}
