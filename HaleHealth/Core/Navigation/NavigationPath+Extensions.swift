import SwiftUI

extension NavigationPath {
    var isAtRoot: Bool { isEmpty }

    mutating func reset() {
        self = NavigationPath()
    }
}
