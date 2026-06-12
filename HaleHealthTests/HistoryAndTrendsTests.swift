import XCTest
@testable import HaleHealth

/// The daily record and the aggregations computed over it.
@MainActor
final class HistoryAndTrendsTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "HistoryTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func isoDate(daysAgo: Int) -> String {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!.hhISODate
    }

    private func snapshot(daysAgo: Int, _ mutate: (inout DailySnapshot) -> Void = { _ in }) -> DailySnapshot {
        var snap = DailySnapshot(day: isoDate(daysAgo: daysAgo))
        mutate(&snap)
        return snap
    }

    // MARK: - HistoryStore

    func testUpdateTodayPersistsAcrossRelaunch() {
        let store = HistoryStore(defaults: defaults)
        store.updateToday { $0.drinksLogged += 1 }
        store.updateToday { $0.meditationMinutes += 10 }

        let relaunched = HistoryStore(defaults: defaults)
        XCTAssertEqual(relaunched.today?.drinksLogged, 1)
        XCTAssertEqual(relaunched.today?.meditationMinutes, 10)
    }

    func testRecentReturnsOldestFirstAndSkipsMissingDays() {
        let store = HistoryStore(defaults: defaults)
        store.updateDay(isoDate(daysAgo: 4)) { $0.drinksLogged = 4 }
        store.updateDay(isoDate(daysAgo: 0)) { $0.drinksLogged = 1 }

        let recent = store.recent(days: 7)
        XCTAssertEqual(recent.map(\.drinksLogged), [4, 1])
    }

    func testBindMirrorsRoutineCompletionIntoSnapshot() {
        let history = HistoryStore(defaults: defaults)
        let routineStore = RoutineStore(defaults: defaults)
        history.bind(to: routineStore)

        var profile = RoutineProfile()
        profile.goals = [.immunity]
        routineStore.saveProfile(profile)
        routineStore.toggle("wake")
        routineStore.toggle("hydrate")

        XCTAssertEqual(history.today?.blocksTotal, routineStore.routine?.blocks.count)
        XCTAssertEqual(history.today?.blocksCompleted, 2)
    }

    func testClearLocalWipesHistory() {
        let store = HistoryStore(defaults: defaults)
        store.updateToday { $0.drinksLogged = 3 }
        store.clearLocal()
        XCTAssertNil(store.today)
        XCTAssertTrue(HistoryStore(defaults: defaults).snapshots.isEmpty)
    }

    // MARK: - TrendCalculator

    func testEmptyWindowProducesEmptyTrends() {
        let trends = TrendCalculator.trends(over: 7, from: [])
        XCTAssertEqual(trends.daysWithData, 0)
        XCTAssertEqual(trends.completionRate, 0)
        XCTAssertNil(trends.averageSteps)
    }

    func testCompletionRateAveragesOnlyDaysWithAPlan() {
        let days = [
            snapshot(daysAgo: 2) { $0.blocksTotal = 10; $0.blocksCompleted = 10 },  // 1.0
            snapshot(daysAgo: 1) { $0.blocksTotal = 10; $0.blocksCompleted = 5 },   // 0.5
            snapshot(daysAgo: 0) { $0.drinksLogged = 1 }                            // no plan — excluded
        ]
        let trends = TrendCalculator.trends(over: 7, from: days)
        XCTAssertEqual(trends.completionRate, 0.75, accuracy: 0.001)
        XCTAssertEqual(trends.daysWithData, 3)
    }

    func testDaysKeptUsesStreakThreshold() {
        let days = [
            snapshot(daysAgo: 2) { $0.blocksTotal = 10; $0.blocksCompleted = 7 },   // 0.7 — kept
            snapshot(daysAgo: 1) { $0.blocksTotal = 10; $0.blocksCompleted = 6 },   // 0.6 — not kept
        ]
        XCTAssertEqual(TrendCalculator.trends(over: 7, from: days).daysKept, 1)
    }

    func testStepAverageIgnoresDaysWithoutHealthData() {
        let days = [
            snapshot(daysAgo: 2) { $0.steps = 8000 },
            snapshot(daysAgo: 1),                       // Health off that day
            snapshot(daysAgo: 0) { $0.steps = 4000 },
        ]
        XCTAssertEqual(TrendCalculator.trends(over: 7, from: days).averageSteps, 6000)
    }

    func testHighAQIDaysCountsAbove200() {
        let days = [
            snapshot(daysAgo: 2) { $0.aqi = 250 },
            snapshot(daysAgo: 1) { $0.aqi = 180 },
            snapshot(daysAgo: 0) { $0.aqi = 320 },
        ]
        XCTAssertEqual(TrendCalculator.trends(over: 7, from: days).highAQIDays, 2)
    }

    func testMeditationAndDrinksSumAcrossWindow() {
        let days = [
            snapshot(daysAgo: 1) { $0.meditationMinutes = 10; $0.meditationSessions = 1; $0.drinksLogged = 2 },
            snapshot(daysAgo: 0) { $0.meditationMinutes = 5; $0.meditationSessions = 1; $0.drinksLogged = 1 },
        ]
        let trends = TrendCalculator.trends(over: 7, from: days)
        XCTAssertEqual(trends.meditationMinutes, 15)
        XCTAssertEqual(trends.meditationSessions, 2)
        XCTAssertEqual(trends.drinksLogged, 3)
    }
}
