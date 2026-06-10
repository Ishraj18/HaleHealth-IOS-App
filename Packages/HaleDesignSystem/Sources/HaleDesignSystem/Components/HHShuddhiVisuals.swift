import SwiftUI

// The Shuddhi meditation visuals: a living haze that clears as you breathe,
// a botanical breathing mandala, and a tulsi sprout that grows with practice.
// All presentation-only — fed by primitives, no domain knowledge.

/// Drifting smoke particles tinted by the day's air. `density` 0…1 sets how
/// heavy the haze starts; `cleared` 0…1 thins it away as the session advances.
public struct HHHazeLayer: View {
    private let tintHex: String
    private let density: Double
    private let cleared: Double

    public init(tintHex: String, density: Double, cleared: Double) {
        self.tintHex = tintHex
        self.density = min(max(density, 0), 1)
        self.cleared = min(max(cleared, 0), 1)
    }

    private struct Mote {
        let seedX, seedY, size, speed, phase, baseAlpha: Double
    }

    private static let motes: [Mote] = (0..<64).map { i in
        var rng = SeededRandom(seed: UInt64(i * 7919 + 13))
        return Mote(seedX: rng.next(), seedY: rng.next(),
                    size: 40 + rng.next() * 120,
                    speed: 0.3 + rng.next() * 0.8,
                    phase: rng.next() * .pi * 2,
                    baseAlpha: 0.05 + rng.next() * 0.16)
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let tint = Color(hex: tintHex)
                let visible = (1 - cleared) * density
                guard visible > 0.01 else { return }
                for m in Self.motes {
                    let x = (m.seedX + sin(t * 0.05 * m.speed + m.phase) * 0.12)
                        .truncatingRemainder(dividingBy: 1)
                    let y = (m.seedY + t * 0.008 * m.speed)
                        .truncatingRemainder(dividingBy: 1.2) - 0.1
                    let rect = CGRect(
                        x: x * size.width - m.size / 2,
                        y: y * size.height - m.size / 2,
                        width: m.size, height: m.size * 0.7
                    )
                    var ctx = context
                    ctx.opacity = m.baseAlpha * visible
                    ctx.addFilter(.blur(radius: 18))
                    ctx.fill(Path(ellipseIn: rect), with: .color(tint))
                }
            }
        }
        .allowsHitTesting(false)
        .animation(.hhGentle, value: cleared)
    }
}

/// Concentric leaf rings that swell on the inhale and settle on the exhale.
/// `breath` 0…1 is the current breath amount (0 = empty lungs, 1 = full).
public struct HHBreathMandala: View {
    private let breath: Double
    private let accentHex: String

    public init(breath: Double, accentHex: String) {
        self.breath = min(max(breath, 0), 1)
        self.accentHex = accentHex
    }

    public var body: some View {
        let accent = Color(hex: accentHex)
        let scale = 0.72 + breath * 0.28
        ZStack {
            ring(leaves: 6, radius: 96, leafLength: 56, color: accent.opacity(0.18),
                 rotation: breath * 8, scale: scale)
            ring(leaves: 6, radius: 64, leafLength: 48, color: accent.opacity(0.34),
                 rotation: -breath * 12 + 30, scale: scale)
            ring(leaves: 6, radius: 34, leafLength: 40, color: accent.opacity(0.55),
                 rotation: breath * 16, scale: scale)
            Circle()
                .fill(Color.hhCreamParchment.opacity(0.9))
                .frame(width: 36 + breath * 18)
                .shadow(color: accent.opacity(0.5), radius: 18 * breath + 6)
        }
        .frame(width: 280, height: 280)
    }

    private func ring(leaves: Int, radius: CGFloat, leafLength: CGFloat,
                      color: Color, rotation: Double, scale: Double) -> some View {
        ZStack {
            ForEach(0..<leaves, id: \.self) { i in
                Ellipse()
                    .fill(color)
                    .frame(width: leafLength * 0.42, height: leafLength)
                    .offset(y: -radius * scale)
                    .rotationEffect(.degrees(Double(i) / Double(leaves) * 360))
            }
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
    }
}

/// A tulsi sprig that carries one leaf per completed session (capped visually).
public struct HHTulsiSprout: View {
    private let leaves: Int

    public init(leaves: Int) {
        self.leaves = max(0, leaves)
    }

    public var body: some View {
        let shown = min(leaves, 12)
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Color.hhMutedSage)
                .frame(width: 3, height: 60)
            ForEach(0..<shown, id: \.self) { i in
                let side: CGFloat = i % 2 == 0 ? 1 : -1
                let height = CGFloat(i) / CGFloat(max(shown, 1)) * 44
                Ellipse()
                    .fill(Color.hhMutedSage.opacity(0.55 + Double(i) * 0.03))
                    .frame(width: 18, height: 9)
                    .rotationEffect(.degrees(Double(side) * -35))
                    .offset(x: side * 11, y: -10 - height)
            }
        }
        .frame(height: 72, alignment: .bottom)
    }
}

/// Tiny deterministic RNG so the haze field is stable across renders.
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> Double {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return Double(state % 10_000) / 10_000
    }
}

#Preview {
    ZStack {
        Color.hhForestGreen.ignoresSafeArea()
        HHHazeLayer(tintHex: "#E67E22", density: 0.9, cleared: 0.2)
        VStack(spacing: 40) {
            HHBreathMandala(breath: 0.7, accentHex: "#4A7C59")
            HHTulsiSprout(leaves: 7)
        }
    }
}
