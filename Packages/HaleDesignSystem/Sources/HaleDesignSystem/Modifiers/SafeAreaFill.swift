import SwiftUI

private struct HHScreenBackground: ViewModifier {
    @Environment(\.hhAtmosphere) private var atmosphere
    let override: Color?

    func body(content: Content) -> some View {
        content
            .background {
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
            // The navigation bar wears the canvas (with the top wash baked
            // in), so screens with a system title blend seamlessly instead of
            // flashing system white — the same treatment MainTabView gives the
            // tab bar. No-op on screens that hide their bar (Today) or sit
            // outside a stack.
            .toolbarBackground(override ?? atmosphere.canvasTop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(override == nil ? (atmosphere.isNight ? .dark : .light) : nil,
                                for: .navigationBar)
    }
}

public extension View {
    /// Fills the whole screen — safe areas included — with the living canvas:
    /// the atmosphere's colour for this hour of Delhi's day, a soft wash, and
    /// paper grain, and dresses the navigation bar in the same canvas so
    /// titled screens blend instead of showing a white system bar. Pass a
    /// colour to opt out of the atmosphere (e.g. branded full-bleed screens).
    func hhScreenBackground(_ color: Color? = nil) -> some View {
        modifier(HHScreenBackground(override: color))
    }
}
