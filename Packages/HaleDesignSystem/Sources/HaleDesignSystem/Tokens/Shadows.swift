import SwiftUI

/// A named shadow definition. Using a value type (rather than SwiftUI's opaque
/// `Shadow`) lets us carry the offset and apply it consistently via `hhShadow`.
public struct HHShadowStyle: Equatable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

public enum HHShadow {
    public static let subtle = HHShadowStyle(color: .black.opacity(0.04), radius: 6,  x: 0, y: 2)
    public static let card   = HHShadowStyle(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    public static let float  = HHShadowStyle(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
}

public extension View {
    /// Applies a named design-system shadow. Defaults to the standard card shadow.
    func hhShadow(_ style: HHShadowStyle = HHShadow.card) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
