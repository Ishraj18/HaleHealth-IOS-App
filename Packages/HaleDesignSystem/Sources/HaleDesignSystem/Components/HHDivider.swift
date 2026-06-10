import SwiftUI

/// A branded divider — a thin border-coloured rule, optionally with a centred,
/// tracked label.
public struct HHDivider: View {
    private let label: String?

    public init(label: String? = nil) {
        self.label = label
    }

    public var body: some View {
        if let label {
            HStack(spacing: HHSpacing.md) {
                rule
                Text(label)
                    .hhFont(.hhOverline)
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .hhText(.secondary)
                    .fixedSize()
                rule
            }
        } else {
            rule
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(Color.hhBorder)
            .frame(height: 1)
    }
}

#Preview {
    VStack(spacing: HHSpacing.xl) {
        HHDivider()
        HHDivider(label: "Also consider today")
    }
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
