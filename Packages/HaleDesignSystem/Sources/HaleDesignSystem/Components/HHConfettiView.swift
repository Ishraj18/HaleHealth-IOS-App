import SwiftUI

/// Brand-coloured celebration burst — leaves and petals rather than paper
/// confetti. Re-fires whenever `trigger` changes to a new non-zero value.
public struct HHConfettiView: View {
    private let trigger: Int
    @State private var particles: [Particle] = []
    @State private var startDate = Date()

    public init(trigger: Int) {
        self.trigger = trigger
    }

    private struct Particle {
        let x: Double         // 0…1 horizontal origin
        let vx: Double        // horizontal drift
        let vy: Double        // initial upward velocity
        let spin: Double
        let size: Double
        let colorIndex: Int
        let isLeaf: Bool
        let delay: Double
    }

    private static let palette: [Color] = [
        .hhWarmSaffron, .hhMutedSage, .hhDustyGold, .hhForestGreen, .hhChamakAccent
    ]

    public var body: some View {
        TimelineView(.animation(paused: particles.isEmpty)) { timeline in
            Canvas { context, canvasSize in
                let t = timeline.date.timeIntervalSince(startDate)
                guard t < 3.2 else { return }
                for p in particles {
                    let pt = t - p.delay
                    guard pt > 0 else { continue }
                    let x = p.x * canvasSize.width + p.vx * pt * 90
                    let y = canvasSize.height * 0.45 - p.vy * pt * 140 + 220 * pt * pt
                    guard y < canvasSize.height + 20 else { continue }
                    let alpha = max(0, 1 - pt / 2.6)
                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(p.spin * pt * 4))
                    ctx.opacity = alpha
                    let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size * (p.isLeaf ? 1.6 : 0.7))
                    let shape = p.isLeaf
                        ? Path(ellipseIn: rect)
                        : Path(roundedRect: rect, cornerRadius: p.size * 0.2)
                    ctx.fill(shape, with: .color(Self.palette[p.colorIndex % Self.palette.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, newValue in
            guard newValue != 0 else { return }
            startDate = Date()
            particles = (0..<60).map { i in
                Particle(
                    x: .random(in: 0.15...0.85),
                    vx: .random(in: -1.4...1.4),
                    vy: .random(in: 1.2...2.4),
                    spin: .random(in: -2...2),
                    size: .random(in: 6...12),
                    colorIndex: i,
                    isLeaf: Bool.random(),
                    delay: .random(in: 0...0.25)
                )
            }
        }
    }
}

#Preview {
    struct Host: View {
        @State private var n = 0
        var body: some View {
            ZStack {
                Color.hhBackground.ignoresSafeArea()
                VStack { Spacer(); HHButton("Celebrate") { n += 1 }.padding(HHSpacing.lg) }
                HHConfettiView(trigger: n)
            }
        }
    }
    return Host()
}
