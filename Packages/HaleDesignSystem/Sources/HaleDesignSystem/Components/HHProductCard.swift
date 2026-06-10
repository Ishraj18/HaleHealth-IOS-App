import SwiftUI
import UIKit

/// Standard product card used in grids and carousels.
///
/// Presentation-only: it takes primitive values rather than a domain `Product`,
/// so the design system stays a leaf dependency. The app adds a `Product`
/// convenience initializer via an extension. Product imagery is looked up in the
/// **main** bundle (the app's asset catalog); a botanical mark is shown when the
/// asset is missing, so the card never renders blank.
public struct HHProductCard: View {
    private let hindiName: String
    private let romanName: String
    private let englishName: String
    private let accentColorHex: String
    private let imageName: String?
    private let priceRupees: Int?

    public init(
        hindiName: String,
        romanName: String,
        englishName: String,
        accentColorHex: String,
        imageName: String? = nil,
        priceRupees: Int? = nil
    ) {
        self.hindiName = hindiName
        self.romanName = romanName
        self.englishName = englishName
        self.accentColorHex = accentColorHex
        self.imageName = imageName
        self.priceRupees = priceRupees
    }

    private var accent: Color { Color(hex: accentColorHex) }

    public var body: some View {
        HStack(alignment: .top, spacing: HHSpacing.md) {
            Capsule()
                .fill(accent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: HHSpacing.xs) {
                Text(romanName.uppercased())
                    .hhFont(.hhOverline)
                    .tracking(0.8)
                    .foregroundStyle(accent)
                Text(hindiName)
                    .hhFont(.hhDisplay3)
                    .hhText(.primary)
                Text(englishName)
                    .hhFont(.hhCaption)
                    .hhText(.secondary)
                if let priceRupees {
                    Text("₹\(priceRupees)")
                        .hhFont(.hhLabel)
                        .foregroundStyle(Color.hhDustyGold)
                        .padding(.top, HHSpacing.xs)
                }
            }

            Spacer(minLength: HHSpacing.sm)

            productMark
        }
        .cardStyle()
    }

    @ViewBuilder private var productMark: some View {
        if let imageName, let image = UIImage(named: imageName, in: .main, with: nil) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 78)
        } else {
            ZStack {
                Circle().fill(accent.opacity(0.14))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(accent)
            }
            .frame(width: 60, height: 60)
        }
    }
}

#Preview {
    VStack(spacing: HHSpacing.md) {
        HHProductCard(hindiName: "सांस", romanName: "Saans",
                      englishName: "Lung Cleanse",
                      accentColorHex: "#4A7C59", priceRupees: 180)
        HHProductCard(hindiName: "रक्षा", romanName: "Raksha",
                      englishName: "Immunity Shield",
                      accentColorHex: "#7B4A8C", priceRupees: 180)
    }
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
