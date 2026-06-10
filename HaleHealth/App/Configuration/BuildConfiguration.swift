import Foundation

/// The active build configuration. Staging is reserved for Phase 2 (a separate
/// `.xcconfig`/scheme); the enum exists now so feature code can branch on it
/// without later refactors.
enum BuildConfiguration {
    case debug
    case staging
    case release

    static var current: BuildConfiguration {
        #if DEBUG
        return .debug
        #elseif STAGING
        return .staging
        #else
        return .release
        #endif
    }

    var isDebug: Bool { self == .debug }
}
