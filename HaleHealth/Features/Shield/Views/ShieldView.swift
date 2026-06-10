import SwiftUI
import HaleDesignSystem

/// The City Shield Collection hub — the brand showcase.
struct ShieldView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HHSpacing.lg) {
                VStack(alignment: .leading, spacing: HHSpacing.xs) {
                    Text("The City Shield Collection")
                        .hhFont(.hhDisplay2)
                        .hhText(.display)
                    Text("Six cold-pressed defences, one for each system the city tests.")
                        .hhFont(.hhBody)
                        .hhText(.secondary)
                }

                VStack(spacing: HHSpacing.md) {
                    ForEach(appState.productCatalog.products) { product in
                        NavigationLink(value: product.id) {
                            HHProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(HHSpacing.lg)
            .hhWatermark("ढाल", size: 190, alignment: .topTrailing)
        }
        .hhScreenBackground()
        .navigationTitle(Tab.shield.label)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ProductID.self) { id in
            if let product = appState.productCatalog.product(for: id) {
                ProductDetailView(product: product)
            }
        }
    }
}

/// Single-product page: hero accent treatment, ingredients, AQI relevance.
struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject private var appState: AppState

    private var accent: Color { Color(product: product) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HHSpacing.lg) {
                // Hero
                VStack(alignment: .leading, spacing: HHSpacing.sm) {
                    Text(product.romanName.uppercased())
                        .hhFont(.hhOverline)
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(product.hindiName)
                        .hhFont(.hhDisplay1)
                        .foregroundStyle(.white)
                    Text(product.englishName)
                        .hhFont(.hhSubheading)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(product.tagline)
                        .hhFont(.hhDisplayItalic)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.top, HHSpacing.xs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(HHSpacing.lg)
                .background(accent, in: RoundedRectangle(cornerRadius: HHRadius.lg, style: .continuous))

                // Ingredients
                VStack(alignment: .leading, spacing: HHSpacing.sm) {
                    HHDivider(label: "Key ingredients")
                    FlowingPills(items: product.keyIngredients, color: accent)
                }

                // AQI relevance
                if let aqi = appState.currentAQI {
                    HHCard {
                        HStack(spacing: HHSpacing.md) {
                            HHAQIBadge(reading: aqi)
                            Text(relevance(aqi))
                                .hhFont(.hhCaption)
                                .hhText(.secondary)
                        }
                    }
                }

                // Price + CTA stub
                HHCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("₹\(product.priceRupees)")
                                .hhFont(.hhDisplay3)
                                .hhText(.primary)
                            Text("per 250ml bottle")
                                .hhFont(.hhCaption)
                                .hhText(.secondary)
                        }
                        Spacer()
                        HHButton("Ordering soon", style: .secondary, isEnabled: false) {}
                            .frame(width: 160)
                    }
                }
            }
            .padding(HHSpacing.lg)
        }
        .hhScreenBackground()
        .navigationTitle(product.romanName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func relevance(_ aqi: AQIReading) -> String {
        let recommended = aqi.primaryRecommendation == product.id || aqi.secondaryRecommendation == product.id
        return recommended
            ? "Recommended for today's air — \(product.bodySystem.displayName) support matters at AQI \(aqi.value)."
            : "A steady choice any day; today's air points first to \(aqi.primaryRecommendation.rawValue.capitalized)."
    }
}

/// Simple wrapping pill row for ingredient tags.
private struct FlowingPills: View {
    let items: [String]
    let color: Color

    var body: some View {
        let rows = stride(from: 0, to: items.count, by: 3).map { Array(items[$0..<min($0 + 3, items.count)]) }
        VStack(alignment: .leading, spacing: HHSpacing.sm) {
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: HHSpacing.sm) {
                    ForEach(rows[i], id: \.self) { item in
                        HHPillBadge(item, textColor: color, backgroundColor: color.opacity(0.14))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ShieldView() }
        .environmentObject(AppState.preview)
}
