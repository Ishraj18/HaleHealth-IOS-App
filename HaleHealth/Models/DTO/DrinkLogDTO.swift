import Foundation

/// Read model for a `drink_logs` row.
struct DrinkLogDTO: Decodable, Sendable {
    let id: UUID
    let userId: UUID
    let productId: String
    let loggedAt: String?
    let aqiAtLogTime: Int?
    let moodEmoji: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case userId = "user_id"
        case productId = "product_id"
        case loggedAt = "logged_at"
        case aqiAtLogTime = "aqi_at_log_time"
        case moodEmoji = "mood_emoji"
    }

    func toDomain() -> DrinkLog? {
        guard let productID = ProductID(rawValue: productId) else { return nil }
        return DrinkLog(
            id: id,
            userId: userId,
            productId: productID,
            loggedAt: loggedAt.flatMap(DateParsing.date(fromTimestamp:)) ?? Date(),
            aqiAtLogTime: aqiAtLogTime,
            moodEmoji: moodEmoji,
            notes: notes
        )
    }
}

/// Write model for inserting a drink log — server fills `id` and `logged_at`.
struct DrinkLogInsert: Encodable, Sendable {
    let userId: UUID
    let productId: String
    let aqiAtLogTime: Int?
    let moodEmoji: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case userId = "user_id"
        case productId = "product_id"
        case aqiAtLogTime = "aqi_at_log_time"
        case moodEmoji = "mood_emoji"
    }

    init(_ log: DrinkLog) {
        userId = log.userId
        productId = log.productId.rawValue
        aqiAtLogTime = log.aqiAtLogTime
        moodEmoji = log.moodEmoji
        notes = log.notes
    }
}
