import XCTest
@testable import HaleHealth

/// The engine is a pure function of (profile, context) — these tests pin down
/// the rules the rest of the app (and future AI engines) rely on.
final class RoutineEngineTests: XCTestCase {

    private let engine = RuleBasedRoutineEngine()

    private func aqi(_ value: Int) -> AQIReading {
        AQIReading(value: value, station: "Test", fetchedAt: Date())
    }

    // MARK: - Stable semantic IDs

    func testBlockIDsAreSemanticSlots() {
        var profile = RoutineProfile()
        profile.goals = [.gutHealth]
        profile.mind = .anxious            // forces meditate + journal blocks
        let routine = engine.generate(from: profile, context: .empty)
        let ids = Set(routine.blocks.map(\.id))

        XCTAssertTrue(ids.contains("wake"))
        XCTAssertTrue(ids.contains("hydrate"))
        XCTAssertTrue(ids.contains("drink-morning"))
        XCTAssertTrue(ids.contains("movement"))
        XCTAssertTrue(ids.contains("wind-down"))
        XCTAssertTrue(ids.contains("sleep"))
        // No ID may encode a start time — that's what made completion fragile.
        for id in ids {
            XCTAssertNil(Int(id.split(separator: "-").last.map(String.init) ?? "x"),
                         "Block ID \(id) appears to encode a time")
        }
    }

    func testBlockIDsSurviveWakeShift() {
        var profile = RoutineProfile()
        profile.goals = [.lungHealth]
        let planned = engine.generate(from: profile, context: .empty)
        let shifted = engine.generate(
            from: profile,
            context: GenerationContext(aqi: nil, observedWakeMinutes: profile.wakeMinutes + 120)
        )
        XCTAssertEqual(Set(planned.blocks.map(\.id)), Set(shifted.blocks.map(\.id)),
                       "A wake shift must re-time blocks, never re-key them")
    }

    // MARK: - Wake anchoring

    func testObservedWakeWithinThresholdKeepsPlannedAnchor() {
        var profile = RoutineProfile()
        profile.wakeMinutes = 420
        let routine = engine.generate(
            from: profile,
            context: GenerationContext(aqi: nil, observedWakeMinutes: 450) // 30 min off
        )
        XCTAssertEqual(routine.blocks.first { $0.id == "wake" }?.startMinutes, 420)
    }

    func testObservedWakeBeyondThresholdReanchorsDay() {
        var profile = RoutineProfile()
        profile.wakeMinutes = 420
        let routine = engine.generate(
            from: profile,
            context: GenerationContext(aqi: nil, observedWakeMinutes: 540) // 2h off
        )
        XCTAssertEqual(routine.blocks.first { $0.id == "wake" }?.startMinutes, 540)
        XCTAssertEqual(routine.blocks.first { $0.id == "hydrate" }?.startMinutes, 545)
    }

    // MARK: - AQI rules

    func testHighAQIDisplacesGoalDrinkToSaansAndAddsAfternoonDrink() {
        var profile = RoutineProfile()
        profile.goals = [.gutHealth]   // goal drink is Pachak
        let routine = engine.generate(from: profile, context: GenerationContext(aqi: aqi(250)))

        let morning = routine.blocks.first { $0.id == "drink-morning" }
        XCTAssertEqual(morning?.productID, .saans, "AQI > 200 puts lung defence first")

        let afternoon = routine.blocks.first { $0.id == "drink-afternoon" }
        XCTAssertEqual(afternoon?.productID, .pachak, "The displaced goal drink returns in the afternoon")
    }

    func testCleanAirKeepsGoalDrinkAndNoAfternoonDrink() {
        var profile = RoutineProfile()
        profile.goals = [.gutHealth]
        let routine = engine.generate(from: profile, context: GenerationContext(aqi: aqi(80)))

        XCTAssertEqual(routine.blocks.first { $0.id == "drink-morning" }?.productID, .pachak)
        XCTAssertNil(routine.blocks.first { $0.id == "drink-afternoon" })
    }

    // MARK: - Conditional blocks

    func testMeditationIncludedForUnsettledMindExcludedForCalmShortBudget() {
        var anxious = RoutineProfile()
        anxious.mind = .anxious
        anxious.budgetMinutes = 15
        XCTAssertTrue(engine.generate(from: anxious, context: .empty).blocks.contains { $0.id == "meditate" })

        var calm = RoutineProfile()
        calm.mind = .calm
        calm.intention = .energy
        calm.budgetMinutes = 15
        XCTAssertFalse(engine.generate(from: calm, context: .empty).blocks.contains { $0.id == "meditate" })
    }

    func testNonExercisersGetWalkNotWorkout() {
        var profile = RoutineProfile()
        profile.exercise = .never
        profile.fitness = 1
        let movement = engine.generate(from: profile, context: .empty).blocks.first { $0.id == "movement" }
        XCTAssertEqual(movement?.kind, .walk)

        var trained = RoutineProfile()
        trained.exercise = .regularly
        trained.fitness = 4
        let workout = engine.generate(from: trained, context: .empty).blocks.first { $0.id == "movement" }
        XCTAssertEqual(workout?.kind, .workout)
    }

    func testBlocksAreSortedByStartTime() {
        var profile = RoutineProfile()
        profile.goals = [.immunity]
        let starts = engine.generate(from: profile, context: .empty).blocks.map(\.startMinutes)
        XCTAssertEqual(starts, starts.sorted())
    }
}
