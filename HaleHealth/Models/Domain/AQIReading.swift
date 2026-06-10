import Foundation

/// A single air-quality reading. The recommendation logic lives here so both the
/// Today screen and (later) the Hawa screen reason about AQI identically.
struct AQIReading: Codable, Equatable, Sendable {
    let value: Int
    let station: String
    let fetchedAt: Date

    var category: AQICategory {
        switch value {
        case ..<0:      return .good
        case 0...50:    return .good
        case 51...100:  return .moderate
        case 101...150: return .unhealthyForSensitive
        case 151...200: return .unhealthy
        case 201...300: return .veryUnhealthy
        default:        return .hazardous
        }
    }

    /// The primary product to recommend based purely on AQI value.
    var primaryRecommendation: ProductID {
        switch value {
        case ...100:    return .tejas   // clean air — focus on mental clarity
        case 101...150: return .raksha  // moderate stress — boost immunity
        default:        return .saans   // lung stress and above — lung defence first
        }
    }

    var secondaryRecommendation: ProductID {
        switch value {
        case ...100:    return .pachak
        case 101...150: return .chamak
        case 151...200: return .raksha
        default:        return .safai   // high pollution raises liver toxin load
        }
    }
}

enum AQICategory: String, Sendable {
    case good                  = "Good"
    case moderate              = "Moderate"
    case unhealthyForSensitive = "Unhealthy for Sensitive Groups"
    case unhealthy             = "Unhealthy"
    case veryUnhealthy         = "Very Unhealthy"
    case hazardous             = "Hazardous"

    /// A shorter label for compact UI like the AQI badge.
    var shortLabel: String {
        switch self {
        case .good:                  return "Good"
        case .moderate:              return "Moderate"
        case .unhealthyForSensitive: return "Sensitive"
        case .unhealthy:             return "Unhealthy"
        case .veryUnhealthy:         return "Very Unhealthy"
        case .hazardous:             return "Hazardous"
        }
    }

    /// Hex colour for this category. The domain owns the value; the UI converts
    /// it to a `Color` (these mirror the design system's AQI tokens).
    var hexColor: String {
        switch self {
        case .good:                  return "#27AE60"
        case .moderate:              return "#F1C40F"
        case .unhealthyForSensitive: return "#E67E22"
        case .unhealthy:             return "#E74C3C"
        case .veryUnhealthy:         return "#8E44AD"
        case .hazardous:             return "#7B241C"
        }
    }
}
