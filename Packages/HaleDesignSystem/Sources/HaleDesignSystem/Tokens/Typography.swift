import SwiftUI

/// PostScript names of the bundled font faces. Verified against each `.ttf`'s
/// `name` table so `Font.custom` resolves them instead of silently falling
/// back to the system font.
enum HHFontFace: String {
    case cormorantRegular  = "CormorantGaramond-Regular"
    case cormorantSemiBold = "CormorantGaramond-SemiBold"
    case cormorantItalic   = "CormorantGaramond-Italic"
    case jakartaRegular    = "PlusJakartaSans-Regular"
    case jakartaMedium     = "PlusJakartaSans-Medium"
    case jakartaSemiBold   = "PlusJakartaSans-SemiBold"
}

enum HHTypography {
    /// Builds a custom font, guaranteeing the bundled fonts are registered
    /// first (idempotent). `relativeTo:` opts the type ramp into Dynamic Type
    /// so it scales with the user's accessibility text size.
    static func font(_ face: HHFontFace, _ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        _ = HaleDesignSystem.bootstrap
        return Font.custom(face.rawValue, size: size, relativeTo: style)
    }
}

public extension Font {
    // MARK: Display — Cormorant Garamond
    static var hhDisplay1: Font { HHTypography.font(.cormorantSemiBold, 36, relativeTo: .largeTitle) }
    static var hhDisplay2: Font { HHTypography.font(.cormorantRegular, 28, relativeTo: .title) }
    static var hhDisplay3: Font { HHTypography.font(.cormorantRegular, 22, relativeTo: .title2) }
    static var hhDisplayItalic: Font { HHTypography.font(.cormorantItalic, 18, relativeTo: .title3) }

    // MARK: Body — Plus Jakarta Sans
    static var hhHeading: Font { HHTypography.font(.jakartaSemiBold, 18, relativeTo: .headline) }
    static var hhSubheading: Font { HHTypography.font(.jakartaMedium, 15, relativeTo: .subheadline) }
    static var hhBody: Font { HHTypography.font(.jakartaRegular, 15, relativeTo: .body) }
    static var hhCaption: Font { HHTypography.font(.jakartaRegular, 12, relativeTo: .caption) }
    static var hhLabel: Font { HHTypography.font(.jakartaMedium, 13, relativeTo: .footnote) }
    static var hhOverline: Font { HHTypography.font(.jakartaMedium, 11, relativeTo: .caption2) } // ALL CAPS, tracked
}
