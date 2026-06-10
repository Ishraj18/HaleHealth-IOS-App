import SwiftUI
import HaleDesignSystem

// Bridges between domain models and the presentation-only design-system
// components. The design system stays free of domain knowledge; this thin app
// layer maps a `Product`/`AQIReading` onto the components' primitive parameters.

extension HHProductCard {
    init(product: Product) {
        self.init(
            hindiName: product.hindiName,
            romanName: product.romanName,
            englishName: product.englishName,
            accentColorHex: product.accentColor,
            imageName: product.imageName,
            priceRupees: product.priceRupees
        )
    }
}

extension HHAQIBadge {
    init(reading: AQIReading) {
        self.init(
            value: reading.value,
            category: reading.category.shortLabel,
            hexColor: reading.category.hexColor
        )
    }
}

extension Color {
    /// The accent colour for a product.
    init(product: Product) {
        self.init(hex: product.accentColor)
    }

    /// The semantic colour for an AQI category.
    init(aqiCategory: AQICategory) {
        self.init(hex: aqiCategory.hexColor)
    }
}
