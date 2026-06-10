import SwiftUI

public extension Color {
    /// Creates a colour from a hex string such as `"#1C3A2A"` or `"1C3A2A"`.
    /// Non-hex characters are ignored, so `"#"` prefixes are tolerated.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red   = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue  = Double(value & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
