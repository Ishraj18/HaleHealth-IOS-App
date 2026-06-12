import Foundation

/// One day of the user's life as the app saw it — the historical record that
/// trends, personal insights and future AI personalization read from. Written
/// incrementally through the day (every signal upserts), one row per day.
struct DailySnapshot: Codable, Equatable, Sendable {
    var day: String                 // "yyyy-MM-dd"
    var blocksTotal: Int = 0        // size of that day's generated plan
    var blocksCompleted: Int = 0
    var meditationSessions: Int = 0
    var meditationMinutes: Int = 0
    var drinksLogged: Int = 0
    var steps: Int?                 // nil when Health sync is off/unavailable
    var workouts: Int?
    var aqi: Int?                   // last reading seen that day
    var mood: String?               // reserved for the mood-capture UI
    var streakCount: Int = 0
    var updatedAt: Date = Date()

    var completionRatio: Double {
        blocksTotal > 0 ? Double(blocksCompleted) / Double(blocksTotal) : 0
    }

    init(day: String) {
        self.day = day
    }

    private enum CodingKeys: String, CodingKey {
        case day, blocksTotal, blocksCompleted, meditationSessions, meditationMinutes,
             drinksLogged, steps, workouts, aqi, mood, streakCount, updatedAt
    }

    // Tolerant decoding so adding fields later never invalidates stored history.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        day = try c.decode(String.self, forKey: .day)
        blocksTotal = try c.decodeIfPresent(Int.self, forKey: .blocksTotal) ?? 0
        blocksCompleted = try c.decodeIfPresent(Int.self, forKey: .blocksCompleted) ?? 0
        meditationSessions = try c.decodeIfPresent(Int.self, forKey: .meditationSessions) ?? 0
        meditationMinutes = try c.decodeIfPresent(Int.self, forKey: .meditationMinutes) ?? 0
        drinksLogged = try c.decodeIfPresent(Int.self, forKey: .drinksLogged) ?? 0
        steps = try c.decodeIfPresent(Int.self, forKey: .steps)
        workouts = try c.decodeIfPresent(Int.self, forKey: .workouts)
        aqi = try c.decodeIfPresent(Int.self, forKey: .aqi)
        mood = try c.decodeIfPresent(String.self, forKey: .mood)
        streakCount = try c.decodeIfPresent(Int.self, forKey: .streakCount) ?? 0
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
