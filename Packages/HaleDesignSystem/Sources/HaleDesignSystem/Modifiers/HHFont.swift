import SwiftUI

/// Applies a design-system font together with a consistent line spacing in a
/// single call, so callers never set `.font` and `.lineSpacing` separately.
public struct HHFontModifier: ViewModifier {
    let font: Font
    let lineSpacing: CGFloat

    public func body(content: Content) -> some View {
        content
            .font(font)
            .lineSpacing(lineSpacing)
    }
}

public extension View {
    func hhFont(_ font: Font, lineSpacing: CGFloat = 4) -> some View {
        modifier(HHFontModifier(font: font, lineSpacing: lineSpacing))
    }
}
