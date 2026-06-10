import SwiftUI

/// The app's motion vocabulary. Transitions use `.hhSpring` unless explicitly
/// overridden — `.default` is never used directly.
public extension Animation {
    static let hhSpring = Animation.spring(response: 0.45, dampingFraction: 0.78)
    static let hhSnappy = Animation.spring(response: 0.30, dampingFraction: 0.82)
    static let hhGentle = Animation.easeInOut(duration: 0.35)
}
