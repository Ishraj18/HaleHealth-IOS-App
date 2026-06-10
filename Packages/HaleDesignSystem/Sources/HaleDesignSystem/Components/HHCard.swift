import SwiftUI

/// The base card surface every content card in the app is built on.
public struct HHCard<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    public init(
        padding: CGFloat = HHSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(padding: padding)
    }
}

#Preview {
    HHCard {
        VStack(alignment: .leading, spacing: HHSpacing.sm) {
            Text("Today's ritual")
                .hhFont(.hhHeading)
                .hhText(.primary)
            Text("A calm, parchment surface that everything else stacks onto.")
                .hhFont(.hhBody)
                .hhText(.secondary)
        }
    }
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
