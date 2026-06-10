import Foundation
import OSLog

/// Fetches the current AQI from AQICN (waqi.info), caching for 15 minutes.
/// Modelled as an actor so the cache is race-free without explicit locking.
actor AQIService: AQIServiceProtocol {
    private let token: String
    private let station: String
    private let session: URLSession
    private let cache = AQICache()

    init(
        token: String = AppConfig.aqicnToken,
        station: String = AppConfig.aqiStation,
        session: URLSession = .shared
    ) {
        self.token = token
        self.station = station
        self.session = session
    }

    func fetchCurrentAQI() async throws -> AQIReading {
        if let cached = cache.current, !cache.isStale {
            return cached
        }

        guard AppConfig.isAQIConfigured else {
            throw APIError.notConfigured(
                "Add your AQICN token to Config/Secrets.xcconfig to see live air quality."
            )
        }

        guard let url = URL(string: "https://api.waqi.info/feed/\(station)/?token=\(token)") else {
            throw APIError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.networkUnavailable
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let dto: AQIResponseDTO
        do {
            dto = try JSONDecoder().decode(AQIResponseDTO.self, from: data)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingFailed(error.localizedDescription)
        }

        let reading = try dto.toDomain()
        cache.set(reading)
        Log.aqi.info("Fetched AQI \(reading.value, privacy: .public) for \(reading.station, privacy: .public)")
        return reading
    }
}
