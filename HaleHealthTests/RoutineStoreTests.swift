import XCTest
@testable import HaleHealth

/// Lifecycle tests for the store that owns today's plan: generation, restore,
/// completion, drink-log dedup, streak keeping/breaking, day re-keying.
@MainActor
final class RoutineStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "RoutineStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private var sampleProfile: RoutineProfile {
        var profile = RoutineProfile()
        profile.goals = [.gutHealth]
        profile.mind = .anxious
        return profile
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        defaults.set(try! JSONEncoder().encode(value), forKey: key)
    }

    private func isoDate(daysAgo: Int) -> String {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!.hhISODate
    }

    // MARK: - Plan generation & restore

    func testSaveProfileGeneratesPlanImmediately() {
        let store = RoutineStore(defaults: defaults)
        XCTAssertNil(store.routine)
        store.saveProfile(sampleProfile)
        XCTAssertNotNil(store.routine)
        XCTAssertFalse(store.routine!.blocks.isEmpty)
    }

    func testPlanIsRestoredAcrossRelaunch() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)
        let originalIDs = store.routine!.blocks.map(\.id)

        let relaunched = RoutineStore(defaults: defaults)
        XCTAssertEqual(relaunched.routine?.blocks.map(\.id), originalIDs)
    }

    func testAQIChangeRegeneratesPlanWithoutLosingCompletion() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)
        store.markDone("wake")

        store.updateAQI(AQIReading(value: 250, station: "Test", fetchedAt: Date()))

        XCTAssertEqual(store.routine?.blocks.first { $0.id == "drink-morning" }?.productID, .saans)
        XCTAssertNotNil(store.routine?.blocks.first { $0.id == "drink-afternoon" })
        XCTAssertTrue(store.isDone("wake"), "Completion must survive regeneration")
    }

    func testWakeShiftFlagAndReanchoring() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)
        XCTAssertFalse(store.isWakeShifted)

        store.updateObservedWake(sampleProfile.wakeMinutes + 120)
        XCTAssertTrue(store.isWakeShifted)
        XCTAssertEqual(store.routine?.blocks.first { $0.id == "wake" }?.startMinutes,
                       sampleProfile.wakeMinutes + 120)
    }

    // MARK: - Completion

    func testToggleAndProgress() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)
        let total = store.routine!.blocks.count

        store.toggle("wake")
        XCTAssertTrue(store.isDone("wake"))
        XCTAssertEqual(store.progress, 1.0 / Double(total), accuracy: 0.001)

        store.toggle("wake")
        XCTAssertFalse(store.isDone("wake"))
        XCTAssertEqual(store.progress, 0, accuracy: 0.001)
    }

    func testMarkDoneByKindChecksMeditateBlock() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)   // anxious mind → meditate block exists
        store.markDone(kind: .meditate)
        XCTAssertTrue(store.isDone("meditate"))
    }

    func testShouldLogDrinkIsTrueExactlyOncePerDay() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)

        XCTAssertTrue(store.shouldLogDrink("drink-morning"))
        XCTAssertFalse(store.shouldLogDrink("drink-morning"), "Re-toggling must not log twice")

        // Survives a relaunch — the guard is persisted with the day.
        let relaunched = RoutineStore(defaults: defaults)
        XCTAssertFalse(relaunched.shouldLogDrink("drink-morning"))
    }

    // MARK: - Streak

    func testStreakIncrementsOncePerDayAtThreshold() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)

        XCTAssertFalse(store.recordProgress(0.5), "Below threshold must not count")
        XCTAssertTrue(store.recordProgress(0.75))
        XCTAssertEqual(store.streak.count, 1)
        XCTAssertFalse(store.recordProgress(1.0), "A day counts once")
        XCTAssertEqual(store.streak.count, 1)
    }

    func testStreakSurvivesWhenYesterdayWasKept() {
        encode(RoutineStore.Streak(count: 6, lastKeptDay: isoDate(daysAgo: 1)), key: "routine_streak")
        let store = RoutineStore(defaults: defaults)
        XCTAssertEqual(store.streak.count, 6)
    }

    func testStreakBreaksAfterAMissedDay() {
        encode(RoutineStore.Streak(count: 6, lastKeptDay: isoDate(daysAgo: 3)), key: "routine_streak")
        let store = RoutineStore(defaults: defaults)
        XCTAssertEqual(store.streak.count, 0)
    }

    // MARK: - Day re-keying

    func testStaleCompletionResetsOnLaunch() {
        encode(RoutineCompletion(day: isoDate(daysAgo: 1), completedBlockIDs: ["wake", "hydrate"]),
               key: "routine_completion")
        let store = RoutineStore(defaults: defaults)
        XCTAssertEqual(store.completion.day, Date().hhISODate)
        XCTAssertTrue(store.completion.completedBlockIDs.isEmpty)
    }

    func testLegacyCompletionWithoutLoggedDrinksStillDecodes() {
        // Simulates a record persisted before loggedDrinkBlockIDs existed.
        let legacyJSON = #"{"day":"\#(Date().hhISODate)","completedBlockIDs":["wake"]}"#
        defaults.set(Data(legacyJSON.utf8), forKey: "routine_completion")
        let store = RoutineStore(defaults: defaults)
        XCTAssertEqual(store.completion.completedBlockIDs, ["wake"])
        XCTAssertTrue(store.completion.loggedDrinkBlockIDs.isEmpty)
    }

    func testClearAllLocalWipesEverything() {
        let store = RoutineStore(defaults: defaults)
        store.saveProfile(sampleProfile)
        store.toggle("wake")
        store.recordProgress(1.0)

        store.clearAllLocal()

        XCTAssertNil(store.profile)
        XCTAssertNil(store.routine)
        XCTAssertTrue(store.completion.completedBlockIDs.isEmpty)
        XCTAssertEqual(store.streak.count, 0)
    }
}
