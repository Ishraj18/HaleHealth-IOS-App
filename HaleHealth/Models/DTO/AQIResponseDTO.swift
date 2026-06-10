import Foundation

/// Decodes the AQICN (waqi.info) `/feed` response and maps it to `AQIReading`.
struct AQIResponseDTO: Decodable, Sendable {
    let status: String
    let data: Payload

    struct Payload: Decodable, Sendable {
        let aqi: Int
        let city: City
        let time: TimeInfo

        struct City: Decodable, Sendable { let name: String }
        struct TimeInfo: Decodable, Sendable {
            let iso: String?
            let s: String?
        }

        private enum CodingKeys: String, CodingKey { case aqi, city, time }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // `aqi` is normally an Int, but the API returns "-" when a station has
            // no current reading. Surface that as a decoding failure.
            if let intValue = try? container.decode(Int.self, forKey: .aqi) {
                aqi = intValue
            } else {
                let raw = (try? container.decode(String.self, forKey: .aqi)) ?? "-"
                throw APIError.decodingFailed("AQI value unavailable (\(raw))")
            }
            city = try container.decode(City.self, forKey: .city)
            time = try container.decode(TimeInfo.self, forKey: .time)
        }
    }

    func toDomain() throws -> AQIReading {
        guard status == "ok" else { throw APIError.invalidResponse }
        let date = data.time.iso.flatMap(Self.parseISO) ?? Date()
        return AQIReading(value: data.aqi, station: data.city.name, fetchedAt: date)
    }

    private static func parseISO(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}
