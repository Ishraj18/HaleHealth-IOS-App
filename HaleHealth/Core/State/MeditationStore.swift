import Combine
import Foundation
import OSLog
import Supabase

/// Local-first record of completed sittings; lifetime count feeds the tulsi
/// sprout. Remote insert is fire-and-forget when a session exists.
@MainActor
final class MeditationStore: ObservableObject {
    static let shared = MeditationStore()

    @Published private(set) var lifetimeSessions: Int

    private let defaults: UserDefaults
    private static let countKey = "meditation_lifetime_sessions"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lifetimeSessions = defaults.integer(forKey: Self.countKey)
    }

    func clearLocal() {
        lifetimeSessions = 0
        defaults.removeObject(forKey: Self.countKey)
    }

    func record(_ session: MeditationSession, userId: UUID?) {
        lifetimeSessions += 1
        defaults.set(lifetimeSessions, forKey: Self.countKey)

        guard let userId, AppConfig.isSupabaseConfigured else { return }
        struct Row: Encodable {
            let userId: UUID, patternId: String, durationSeconds: Int
            let breathCycles: Int, aqiAtStart: Int?
            enum CodingKeys: String, CodingKey {
                case userId = "user_id", patternId = "pattern_id"
                case durationSeconds = "duration_seconds"
                case breathCycles = "breath_cycles", aqiAtStart = "aqi_at_start"
            }
        }
        let row = Row(userId: userId, patternId: session.patternID,
                      durationSeconds: session.durationSeconds,
                      breathCycles: session.breathCycles, aqiAtStart: session.aqiAtStart)
        Task {
            do {
                try await SupabaseClientProvider.shared
                    .from("meditation_sessions").insert(row).execute()
            } catch {
                Log.app.error("Meditation sync failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
