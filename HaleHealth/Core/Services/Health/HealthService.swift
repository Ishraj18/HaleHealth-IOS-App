import Foundation
import HealthKit
import OSLog

/// Feature switch for HealthKit. When disabled, no HealthKit API is touched and
/// the entitlement should be removed from CODE_SIGN_ENTITLEMENTS.
enum HealthFeature {
    static let enabled = true
}

/// Stand-in used while `HealthFeature.enabled == false`. Reports unavailable
/// and never instantiates HKHealthStore.
final class DisabledHealthService: HealthServiceProtocol {
    var isAvailable: Bool { false }
    func requestAuthorization() async throws {
        throw APIError.notConfigured("Health sync is disabled in this build.")
    }
    func todayWorkoutCount() async -> Int { 0 }
    func todaySteps() async -> Int { 0 }
    func lastWakeMinutes() async -> Int? { nil }
}

/// Read-only health signals used to auto-complete routine blocks and adapt the
/// day's anchors. All methods degrade to nil/zero when data is unavailable.
protocol HealthServiceProtocol: AnyObject {
    var isAvailable: Bool { get }
    func requestAuthorization() async throws
    func todayWorkoutCount() async -> Int
    func todaySteps() async -> Int
    /// Last observed wake time as minutes from midnight (from sleepAnalysis).
    func lastWakeMinutes() async -> Int?
}

final class HealthKitService: HealthServiceProtocol {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        [HKObjectType.workoutType(),
         HKQuantityType(.stepCount),
         HKCategoryType(.sleepAnalysis)]
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw APIError.notConfigured("Health data isn't available on this device.") }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            throw APIError.unknown(error)
        }
    }

    func todayWorkoutCount() async -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: samples?.count ?? 0)
            }
            store.execute(query)
        }
    }

    func todaySteps() async -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(.stepCount),
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, stats, _ in
                let steps = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                cont.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    func lastWakeMinutes() async -> Int? {
        // Sleep samples from the last 18h; wake time = end of the latest asleep sample.
        let start = Date().addingTimeInterval(-18 * 3600)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: HKCategoryType(.sleepAnalysis), predicate: predicate,
                                      limit: 16, sortDescriptors: [sort]) { _, samples, _ in
                let asleep = (samples as? [HKCategorySample])?.first {
                    HKCategoryValueSleepAnalysis.allAsleepValues
                        .map(\.rawValue).contains($0.value)
                }
                guard let end = asleep?.endDate, Calendar.current.isDateInToday(end) else {
                    cont.resume(returning: nil)
                    return
                }
                let mins = Calendar.current.component(.hour, from: end) * 60
                         + Calendar.current.component(.minute, from: end)
                cont.resume(returning: mins)
            }
            store.execute(query)
        }
    }
}

final class MockHealthService: HealthServiceProtocol {
    var isAvailable: Bool { true }
    func requestAuthorization() async throws {}
    func todayWorkoutCount() async -> Int { 1 }
    func todaySteps() async -> Int { 4200 }
    func lastWakeMinutes() async -> Int? { 7 * 60 + 40 }
}
