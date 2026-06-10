import SwiftUI
import UIKit
import HaleDesignSystem

/// The hero card on Today: the primary product recommendation with its AQI
/// context sentence. Image-forward, with the product's accent stripe.
struct RecommendationCard: View {
    let product: Product
    let contextSentence: String

    private var accent: Color { Color(product: product) }

    var body: some View {
        HHCard(padding: HHSpacing.lg) {
            HStack(alignment: .top, spacing: HHSpacing.md) {
                VStack(alignment: .leading, spacing: HHSpacing.sm) {
                    Text("Today's shield")
                        .hhFont(.hhOverline)
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundStyle(accent)
                    Text(product.hindiName)
                        .hhFont(.hhDisplay1)
                        .hhText(.primary)
                    Text(product.englishName)
                        .hhFont(.hhSubheading)
                        .hhText(.secondary)
                    if !contextSentence.isEmpty {
                        Text(contextSentence)
                            .hhFont(.hhBody)
                            .hhText(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, HHSpacing.xs)
                    }
                }
                Spacer(minLength: HHSpacing.sm)
                productMark
            }
        }
        .overlay(alignment: .leading) {
            Capsule()
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, HHSpacing.lg)
        }
    }

    @ViewBuilder private var productMark: some View {
        if let image = UIImage(named: product.imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 96)
        } else {
            ZStack {
                Circle().fill(accent.opacity(0.14))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(accent)
            }
            .frame(width: 72, height: 72)
        }
    }
}

#Preview {
    RecommendationCard(
        product: ProductCatalog.shared.product(for: .saans)!,
        contextSentence: "AQI 218, Very Unhealthy. Prioritise Saans today."
    )
    .padding(HHSpacing.lg)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.hhBackground)
}
