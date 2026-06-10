import Foundation

extension String {
    /// True if the string contains any Devanagari character. Useful for deciding
    /// when to apply the display serif vs. the body sans, etc.
    var hhContainsDevanagari: Bool {
        unicodeScalars.contains { (0x0900...0x097F).contains($0.value) }
    }

    /// A time-of-day Hindi (romanised) greeting for the given hour.
    static func hhGreeting(forHour hour: Int) -> String {
        switch hour {
        case 5..<12:  return "Subah ki shubhkamnaen"
        case 12..<17: return "Dopahar ki shubhkamnaen"
        case 17..<21: return "Shaam ka salaam"
        default:      return "Raat ka salaam"
        }
    }
}
