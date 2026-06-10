import SwiftUI

/// The living canvas. An atmosphere is computed from the hour of day (and,
/// subtly, the air outside) and injected app-wide; screens and components read
/// it instead of fixed surface/text tokens, so the whole app keeps Delhi's
/// clock — pale gold at dawn, amber at dusk, deep forest at night.
public struct HHAtmosphere: Equatable, Sendable {
    public enum Phase: String, Sendable {
        case bhor      // dawn 5–8
        case din       // day 8–17
        case sandhya   // dusk 17–20
        case raat      // night 20–5
    }

    public let phase: Phase
    /// 0…1 haze strength from the day's AQI, used for the canvas wash.
    public let haze: Double
    /// Hex tint of the haze wash (AQI category colour), nil when air is clean.
    public let hazeTintHex: String?

    public init(phase: Phase, haze: Double = 0, hazeTintHex: String? = nil) {
        self.phase = phase
        self.haze = min(max(haze, 0), 1)
        self.hazeTintHex = hazeTintHex
    }

    public static func current(hour: Int, aqi: Int?, aqiTintHex: String?) -> HHAtmosphere {
        let phase: Phase
        switch hour {
        case 5..<8:   phase = .bhor
        case 8..<17:  phase = .din
        case 17..<20: phase = .sandhya
        default:      phase = .raat
        }
        let haze = aqi.map { max(0, min(Double($0 - 150) / 300.0, 0.5)) } ?? 0
        return HHAtmosphere(phase: phase, haze: haze, hazeTintHex: haze > 0 ? aqiTintHex : nil)
    }

    public var isNight: Bool { phase == .raat }

    // MARK: - Canvas

    public var canvas: Color {
        switch phase {
        case .bhor:    return Color(hex: "#F8F0DC")   // pale gold dawn
        case .din:     return Color(hex: "#F5F0E8")   // parchment baseline
        case .sandhya: return Color(hex: "#F4E9D6")   // amber dusk
        case .raat:    return Color(hex: "#16241C")   // deep forest night
        }
    }

    /// Top-of-screen wash colour for the canvas gradient.
    public var canvasWash: Color {
        if let hazeTintHex { return Color(hex: hazeTintHex).opacity(0.05 + haze * 0.07) }
        switch phase {
        case .bhor:    return Color(hex: "#E9C988").opacity(0.18)
        case .din:     return .clear
        case .sandhya: return Color(hex: "#C8873A").opacity(0.10)
        case .raat:    return Color(hex: "#0C1611").opacity(0.55)
        }
    }

    // MARK: - Roles

    public var textDisplay: Color { isNight ? Color(hex: "#EDE6D4") : .hhForestGreen }
    public var textPrimary: Color { isNight ? Color(hex: "#E5DECB") : .hhTextPrimary }
    public var textSecondary: Color { isNight ? Color(hex: "#8FAE9B") : .hhTextSecondary }
    public var surfaceFill: Color { isNight ? Color.white.opacity(0.07) : Color.white.opacity(0.85) }
    public var fieldFill: Color { isNight ? Color.white.opacity(0.06) : .hhCreamParchment }
    public var border: Color { isNight ? Color.white.opacity(0.12) : .hhBorder }
    public var watermark: Color { isNight ? Color(hex: "#EDE6D4").opacity(0.05) : Color.hhForestGreen.opacity(0.05) }
}

// MARK: - Environment

private struct HHAtmosphereKey: EnvironmentKey {
    static let defaultValue = HHAtmosphere(phase: .din)
}

public extension EnvironmentValues {
    var hhAtmosphere: HHAtmosphere {
        get { self[HHAtmosphereKey.self] }
        set { self[HHAtmosphereKey.self] = newValue }
    }
}

// MARK: - Text roles

/// Semantic text colouring that follows the atmosphere. Use instead of fixed
/// `.foregroundStyle(Color.hhTextPrimary)` on atmosphere-aware screens.
public enum HHTextRole { case display, primary, secondary }

private struct HHTextModifier: ViewModifier {
    @Environment(\.hhAtmosphere) private var atmosphere
    let role: HHTextRole

    func body(content: Content) -> some View {
        let color: Color = switch role {
        case .display:   atmosphere.textDisplay
        case .primary:   atmosphere.textPrimary
        case .secondary: atmosphere.textSecondary
        }
        return content.foregroundStyle(color)
    }
}

public extension View {
    func hhText(_ role: HHTextRole) -> some View {
        modifier(HHTextModifier(role: role))
    }
}

// MARK: - Watermark

/// An oversized Devanagari glyph laid behind content at whisper opacity —
/// the print-shop signature of the brand.
private struct HHWatermarkModifier: ViewModifier {
    @Environment(\.hhAtmosphere) private var atmosphere
    let glyph: String
    let size: CGFloat
    let alignment: Alignment

    func body(content: Content) -> some View {
        content.background(alignment: alignment) {
            Text(glyph)
                .font(.custom("CormorantGaramond-SemiBold", size: size))
                .foregroundStyle(atmosphere.watermark)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

public extension View {
    func hhWatermark(_ glyph: String, size: CGFloat = 160, alignment: Alignment = .topTrailing) -> some View {
        modifier(HHWatermarkModifier(glyph: glyph, size: size, alignment: alignment))
    }
}

// MARK: - Paper grain

/// A static field of near-invisible flecks that reads as paper stock.
/// Drawn once per size — no animation, negligible cost.
public struct HHPaperGrain: View {
    @Environment(\.hhAtmosphere) private var atmosphere

    public init() {}

    public var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x9E3779B97F4A7C15
            func rnd() -> Double {
                seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
                return Double(seed % 10_000) / 10_000
            }
            let fleck = atmosphere.isNight ? Color.white : Color(hex: "#5B4F3B")
            for _ in 0..<900 {
                let rect = CGRect(x: rnd() * size.width, y: rnd() * size.height,
                                  width: 0.8 + rnd(), height: 0.8 + rnd())
                var ctx = context
                ctx.opacity = 0.015 + rnd() * 0.02
                ctx.fill(Path(ellipseIn: rect), with: .color(fleck))
            }
        }
        .allowsHitTesting(false)
    }
}
