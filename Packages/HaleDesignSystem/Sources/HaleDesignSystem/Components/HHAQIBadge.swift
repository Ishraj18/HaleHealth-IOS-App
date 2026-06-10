import SwiftUI

/// Capsule badge showing an AQI value and its category, tinted by the category
/// colour. Used in the Today header. Takes primitives (the app derives the
/// category label and colour from its `AQIReading` domain model).
public struct HHAQIBadge: View {
    private let value: Int
    private let category: String
    private let hexColor: String

    public init(value: Int, category: String, hexColor: String) {
        self.value = value
        self.category = category
        self.hexColor = hexColor
    }

    private var tint: Color { Color(hex: hexColor) }

    public var body: some View {
        HStack(spacing: HHSpacing.xs) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text("AQI \(value)")
                .hhFont(.hhLabel)
                .hhText(.primary)
            Text(category)
                .hhFont(.hhCaption)
                .foregroundStyle(tint)
        }
        .padding(.horizontal, HHSpacing.sm)
        .padding(.vertical, HHSpacing.xs)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.30), lineWidth: 1))
    }
}

#Preview {
    VStack(spacing: HHSpacing.md) {
        HHAQIBadge(value: 42, category: "Good", hexColor: "#27AE60")
        HHAQIBadge(value: 168, category: "Unhealthy", hexColor: "#E74C3C")
        HHAQIBadge(value: 318, category: "Hazardous", hexColor: "#7B241C")
    }
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
