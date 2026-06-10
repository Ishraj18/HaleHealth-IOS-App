import SwiftUI

/// Small capsule label used for AQI categories, product tags, and the like.
public struct HHPillBadge: View {
    private let text: String
    private let textColor: Color
    private let backgroundColor: Color

    public init(
        _ text: String,
        textColor: Color = .white,
        backgroundColor: Color
    ) {
        self.text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        Text(text)
            .hhFont(.hhOverline)
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(textColor)
            .padding(.horizontal, HHSpacing.sm)
            .padding(.vertical, HHSpacing.xs)
            .background(backgroundColor, in: Capsule())
    }
}

#Preview {
    HStack(spacing: HHSpacing.sm) {
        HHPillBadge("Lung Cleanse", backgroundColor: .hhSaansAccent)
        HHPillBadge("Detox", backgroundColor: .hhSafaiAccent)
        HHPillBadge("New", textColor: .hhWarmCharcoal, backgroundColor: .hhDustyGold.opacity(0.3))
    }
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
