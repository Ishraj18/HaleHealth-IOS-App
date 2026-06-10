import SwiftUI

// Single source of truth for every colour in the app. If the brand palette
// changes, it changes here and propagates everywhere. No raw hex outside the
// design-system token files.
public extension Color {

    // MARK: Brand primaries
    static let hhForestGreen    = Color(hex: "#1C3A2A")
    static let hhWarmSaffron    = Color(hex: "#C8873A")
    static let hhCreamParchment = Color(hex: "#F5F0E8")
    static let hhWarmCharcoal   = Color(hex: "#2C2C2C")
    static let hhMutedSage      = Color(hex: "#7A9E8A")
    static let hhDustyGold      = Color(hex: "#B8960C")

    // MARK: Semantic
    static let hhBackground    = Color(hex: "#F5F0E8") // always parchment in light
    static let hhSurface       = Color.white.opacity(0.7)
    static let hhTextPrimary   = Color(hex: "#2C2C2C")
    static let hhTextSecondary = Color(hex: "#7A9E8A")
    static let hhBorder        = Color(hex: "#E0D9CC")

    // MARK: AQI semantic colours
    static let hhAQIGood          = Color(hex: "#27AE60")
    static let hhAQIModerate      = Color(hex: "#F1C40F")
    static let hhAQISensitive     = Color(hex: "#E67E22")
    static let hhAQIUnhealthy     = Color(hex: "#E74C3C")
    static let hhAQIVeryUnhealthy = Color(hex: "#8E44AD")
    static let hhAQIHazardous     = Color(hex: "#7B241C")

    // MARK: Product accent colours (one per SKU)
    static let hhSaansAccent  = Color(hex: "#4A7C59")
    static let hhChamakAccent = Color(hex: "#D4956A")
    static let hhPachakAccent = Color(hex: "#8B6914")
    static let hhSafaiAccent  = Color(hex: "#5C7A3E")
    static let hhRakshaAccent = Color(hex: "#7B4A8C")
    static let hhTejasAccent  = Color(hex: "#2E6B8A")
}
