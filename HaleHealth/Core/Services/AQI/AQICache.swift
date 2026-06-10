import Foundation

/// In-memory cache for the latest AQI reading. It is only ever touched from
/// inside `AQIService` (an actor), so it needs no internal synchronisation.
final class AQICache {
    private(set) var current: AQIReading?
    private var lastFetched: Date?
    private let ttlSeconds: TimeInterval

    init(ttlSeconds: TimeInterval = Constants.AQI.cacheTTLSeconds) {
        self.ttlSeconds = ttlSeconds
    }

    var isStale: Bool {
        guard let lastFetched else { return true }
        return Date().timeIntervalSince(lastFetched) > ttlSeconds
    }

    func set(_ reading: AQIReading) {
        current = reading
        lastFetched = Date()
    }

    func invalidate() {
        lastFetched = nil
    }
}
