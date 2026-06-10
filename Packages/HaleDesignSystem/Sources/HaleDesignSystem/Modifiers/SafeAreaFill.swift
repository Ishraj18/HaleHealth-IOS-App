import SwiftUI

private struct HHScreenBackground: ViewModifier {
    @Environment(\.hhAtmosphere) private var atmosphere
    let override: Color?

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                (override ?? atmosphere.canvas)
                if override == nil {
                    LinearGradient(
                        colors: [atmosphere.canvasWash, .clear],
                        startPoint: .top, endPoint: .center
                    )
                    HHPaperGrain()
                }
            }
            .ignoresSafeArea()
            .animation(.hhGentle, value: atmosphere)
        }
    }
}

public extension View {
    /// Fills the whole screen — safe areas included — with the living canvas:
    /// the atmosphere's colour for this hour of Delhi's day, a soft wash, and
    /// paper grain. Pass a colour to opt out of the atmosphere (e.g. branded
    /// full-bleed screens).
    func hhScreenBackground(_ color: Color? = nil) -> some View {
        modifier(HHScreenBackground(override: color))
    }
}
