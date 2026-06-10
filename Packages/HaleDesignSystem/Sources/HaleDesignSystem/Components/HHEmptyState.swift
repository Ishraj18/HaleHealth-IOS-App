import SwiftUI

/// Shown whenever a list or section has no data. Title reads in display italic,
/// subtitle in secondary body — calm rather than alarming.
public struct HHEmptyState: View {
    private let title: String
    private let subtitle: String
    private let systemImage: String?

    public init(
        title: String,
        subtitle: String,
        systemImage: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    public var body: some View {
        VStack(spacing: HHSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.hhMutedSage)
                    .padding(.bottom, HHSpacing.xs)
            }
            Text(title)
                .hhFont(.hhDisplayItalic)
                .hhText(.display)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .hhFont(.hhBody)
                .hhText(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(HHSpacing.lg)
    }
}

#Preview {
    HHEmptyState(
        title: "No rituals yet",
        subtitle: "Your daily ritual ring will appear here once you log your first drink.",
        systemImage: "circle.dotted"
    )
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
