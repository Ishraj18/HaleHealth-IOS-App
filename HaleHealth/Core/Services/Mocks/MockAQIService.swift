import Foundation

/// Returns a fixed AQI reading for previews and tests. Defaults to 218 (a
/// typical "Very Unhealthy" Gurgaon winter afternoon).
final class MockAQIService: AQIServiceProtocol {
    var mockAQI: Int

    init(mockAQI: Int = 218) {
        self.mockAQI = mockAQI
    }

    func fetchCurrentAQI() async throws -> AQIReading {
        AQIReading(value: mockAQI, station: "Gurgaon Sector 51", fetchedAt: Date())
    }
}
