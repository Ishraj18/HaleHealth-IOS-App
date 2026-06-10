import SwiftUI

/// The card surface treatment — padded, rounded, lightly translucent fill with
/// a soft shadow. `HHCard` is built on this, and feature code can apply it to
/// bespoke layouts that still need to read as a card.
public struct CardStyle: ViewModifier {
    @Environment(\.hhAtmosphere) private var atmosphere
    var padding: CGFloat
    var cornerRadius: CGFloat
    var fill: Color?          // nil = follow the atmosphere
    var shadow: HHShadowStyle

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                fill ?? atmosphere.surfaceFill,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .hhShadow(atmosphere.isNight ? HHShadow.subtle : shadow)
    }
}

public extension View {
    func cardStyle(
        padding: CGFloat = HHSpacing.md,
        cornerRadius: CGFloat = HHRadius.md,
        fill: Color? = nil,
        shadow: HHShadowStyle = HHShadow.card
    ) -> some View {
        modifier(CardStyle(
            padding: padding,
            cornerRadius: cornerRadius,
            fill: fill,
            shadow: shadow
        ))
    }
}
