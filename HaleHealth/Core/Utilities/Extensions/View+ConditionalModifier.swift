import SwiftUI

extension View {
    /// Conditionally applies a transform. Prefixed `hhIf` to avoid colliding
    /// with any other `if` helper in the dependency graph.
    @ViewBuilder
    func hhIf<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
