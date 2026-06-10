import Foundation

/// A pre-authored wellness insight, tagged and optionally seasonal. Surfaced on
/// the Today screen in Phase 2; the `insights` table is publicly readable.
struct Insight: Identifiable, Codable, Equatable, Sendable {
    let id: Int
    let content: String
    let tags: [String]
    let season: String
}
