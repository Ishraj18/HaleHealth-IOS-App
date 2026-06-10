import Foundation

/// Read model for a `profiles` row. Dates arrive as strings (Postgres `date` /
/// `timestamptz`) and are parsed leniently so a column-type quirk can never
/// crash a fetch.
struct UserProfileDTO: Decodable, Sendable {
    let id: UUID
    let displayName: String?
    let email: String?
    let phone: String?
    let bodyGoals: [String]?
    let streakCount: Int?
    let lastLogDate: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case displayName = "display_name"
        case bodyGoals = "body_goals"
        case streakCount = "streak_count"
        case lastLogDate = "last_log_date"
        case createdAt = "created_at"
    }

    func toDomain() -> UserProfile {
        UserProfile(
            id: id,
            displayName: displayName ?? "",
            email: email ?? "",
            phone: phone,
            bodyGoals: (bodyGoals ?? []).compactMap(UserProfile.BodyGoal.init(rawValue:)),
            streakCount: streakCount ?? 0,
            lastLogDate: lastLogDate.flatMap(DateParsing.date(fromISODate:)),
            createdAt: createdAt.flatMap(DateParsing.date(fromTimestamp:)) ?? Date()
        )
    }
}

/// Write model for upserting a profile — only writable columns. It never sends
/// `created_at`/`updated_at`, so an upsert can't overwrite server-managed values.
struct UserProfileUpsert: Encodable, Sendable {
    let id: UUID
    let displayName: String
    let email: String
    let phone: String?
    let bodyGoals: [String]
    let streakCount: Int
    let lastLogDate: String?

    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case displayName = "display_name"
        case bodyGoals = "body_goals"
        case streakCount = "streak_count"
        case lastLogDate = "last_log_date"
    }

    init(_ profile: UserProfile) {
        id = profile.id
        displayName = profile.displayName
        email = profile.email
        phone = profile.phone
        bodyGoals = profile.bodyGoals.map(\.rawValue)
        streakCount = profile.streakCount
        lastLogDate = profile.lastLogDate?.hhISODate
    }
}

/// Shared lenient date parsing for DTOs.
enum DateParsing {
    static func date(fromISODate string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    static func date(fromTimestamp string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
