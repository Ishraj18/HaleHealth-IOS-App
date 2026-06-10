import Foundation

/// Air-quality boundary. The concrete `AQIService` is an actor; this protocol's
/// single async requirement is satisfiable by both an actor and the mock class.
protocol AQIServiceProtocol: AnyObject {
    func fetchCurrentAQI() async throws -> AQIReading
}
