import Combine
import SwiftUI

/// The five root tabs. Labels lean into the brand's Hindi vocabulary.
enum Tab: Int, CaseIterable, Identifiable {
    case today = 0
    case shield
    case hawa
    case ritual
    case profile

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .today:   return "Aaj"
        case .shield:  return "Shield"
        case .hawa:    return "Hawa"
        case .ritual:  return "Ritual"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .today:   return "sun.horizon"
        case .shield:  return "shield"
        case .hawa:    return "wind"
        case .ritual:  return "circle.dotted"
        case .profile: return "person"
        }
    }
}

/// Owns the active tab and an independent navigation path per tab, so each tab
/// preserves its own stack when switching — matching native iOS behaviour.
@MainActor
final class TabRouter: ObservableObject {
    @Published var activeTab: Tab = {
        #if DEBUG
        // UI-test/dev hook: launch directly into a tab, e.g. HH_TAB=ritual.
        if let raw = ProcessInfo.processInfo.environment["HH_TAB"] {
            switch raw {
            case "shield": return .shield
            case "hawa": return .hawa
            case "ritual": return .ritual
            case "profile": return .profile
            default: break
            }
        }
        #endif
        return .today
    }()
    @Published var todayPath = NavigationPath()
    @Published var shieldPath = NavigationPath()
    @Published var hawaPath = NavigationPath()
    @Published var ritualPath = NavigationPath()
    @Published var profilePath = NavigationPath()

    func navigate(to tab: Tab) {
        activeTab = tab
    }

    func popToRoot(for tab: Tab) {
        switch tab {
        case .today:   todayPath.reset()
        case .shield:  shieldPath.reset()
        case .hawa:    hawaPath.reset()
        case .ritual:  ritualPath.reset()
        case .profile: profilePath.reset()
        }
    }
}
