import Foundation

/// A logged drink. Created in Phase 2's Ritual flow; the model and its Supabase
/// table exist now so the schema is stable from day one.
struct DrinkLog: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    let productId: ProductID
    let loggedAt: Date
    let aqiAtLogTime: Int?
    let moodEmoji: String?
    let notes: String?
}
