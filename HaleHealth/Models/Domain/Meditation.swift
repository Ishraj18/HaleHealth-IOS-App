import Foundation

/// A pranayama-rooted breathing pattern. Static catalog, like products.
struct BreathPattern: Identifiable, Equatable, Sendable {
    enum PhaseKind: Sendable { case inhale, hold, exhale, holdEmpty }

    struct Phase: Equatable, Sendable {
        let kind: PhaseKind
        let hindi: String       // the single guiding word
        let english: String
        let seconds: Double
    }

    let id: String
    let name: String            // roman, e.g. "Saans"
    let subtitle: String
    let accentHex: String
    let phases: [Phase]
    let bestFor: String

    var cycleSeconds: Double { phases.reduce(0) { $0 + $1.seconds } }

    static let all: [BreathPattern] = [
        BreathPattern(
            id: "saans", name: "Saans", subtitle: "Deep belly breath · 4-6",
            accentHex: "#4A7C59",
            phases: [Phase(kind: .inhale, hindi: "साँस लो", english: "Breathe in", seconds: 4),
                     Phase(kind: .exhale, hindi: "साँस छोड़ो", english: "Breathe out", seconds: 6)],
            bestFor: "Heavy-air days"
        ),
        BreathPattern(
            id: "anulom", name: "Anulom Vilom", subtitle: "Alternate nostril · 4-4-4",
            accentHex: "#7B4A8C",
            phases: [Phase(kind: .inhale, hindi: "साँस लो", english: "In — left nostril", seconds: 4),
                     Phase(kind: .hold, hindi: "रोको", english: "Hold", seconds: 4),
                     Phase(kind: .exhale, hindi: "साँस छोड़ो", english: "Out — right nostril", seconds: 4)],
            bestFor: "Finding balance"
        ),
        BreathPattern(
            id: "bhramari", name: "Bhramari", subtitle: "Humming exhale · 4-8",
            accentHex: "#2E6B8A",
            phases: [Phase(kind: .inhale, hindi: "साँस लो", english: "Breathe in", seconds: 4),
                     Phase(kind: .exhale, hindi: "गुनगुनाते हुए छोड़ो", english: "Hum as you breathe out", seconds: 8)],
            bestFor: "Anxious minds"
        ),
        BreathPattern(
            id: "box", name: "Sama Vritti", subtitle: "Box breath · 4-4-4-4",
            accentHex: "#B8960C",
            phases: [Phase(kind: .inhale, hindi: "साँस लो", english: "Breathe in", seconds: 4),
                     Phase(kind: .hold, hindi: "रोको", english: "Hold", seconds: 4),
                     Phase(kind: .exhale, hindi: "साँस छोड़ो", english: "Breathe out", seconds: 4),
                     Phase(kind: .holdEmpty, hindi: "ठहरो", english: "Rest empty", seconds: 4)],
            bestFor: "Steady focus"
        )
    ]
}

/// A completed sitting.
struct MeditationSession: Codable, Equatable, Sendable {
    let patternID: String
    let durationSeconds: Int
    let breathCycles: Int
    let aqiAtStart: Int?
    let completedAt: Date
}
