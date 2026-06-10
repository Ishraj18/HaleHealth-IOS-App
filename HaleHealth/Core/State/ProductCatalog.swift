import Combine
import Foundation

/// Single source of truth for product data in Phase 1. In Phase 2 this is
/// replaced by a Supabase fetch (`ProductDTO.toDomain()`), with this static
/// catalog as the offline fallback.
@MainActor
final class ProductCatalog: ObservableObject {
    static let shared = ProductCatalog()

    let products: [Product]

    init(products: [Product]? = nil) {
        self.products = products ?? Self.staticProducts
    }

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id }
    }

    func products(for bodySystem: Product.BodySystem) -> [Product] {
        products.filter { $0.bodySystem == bodySystem }
    }

    // MARK: - The City Shield Collection

    /// Nonisolated so non-UI code (e.g. the routine engine) can read the same data.
    nonisolated static let staticProducts: [Product] = [
        Product(
            id: .saans, hindiName: "सांस", romanName: "Saans",
            englishName: "Lung Cleanse",
            tagline: "For the city you breathe",
            accentColor: "#4A7C59",
            bodySystem: .lung,
            keyIngredients: ["Tulsi", "Mulethi", "Ginger", "Pineapple"],
            priceRupees: 180,
            imageName: "product_saans"
        ),
        Product(
            id: .chamak, hindiName: "चमक", romanName: "Chamak",
            englishName: "Skin Repair",
            tagline: "A clearer glow, daily",
            accentColor: "#D4956A",
            bodySystem: .skin,
            keyIngredients: ["Amla", "Turmeric", "Carrot", "Mint"],
            priceRupees: 180,
            imageName: "product_chamak"
        ),
        Product(
            id: .pachak, hindiName: "पाचक", romanName: "Pachak",
            englishName: "Gut Guardian",
            tagline: "Digest the day with ease",
            accentColor: "#8B6914",
            bodySystem: .gut,
            keyIngredients: ["Ajwain", "Jeera", "Ginger", "Lemon"],
            priceRupees: 180,
            imageName: "product_pachak"
        ),
        Product(
            id: .safai, hindiName: "सफ़ाई", romanName: "Safai",
            englishName: "Liver Detox",
            tagline: "A clean slate, from within",
            accentColor: "#5C7A3E",
            bodySystem: .liver,
            keyIngredients: ["Beetroot", "Wheatgrass", "Neem", "Amla"],
            priceRupees: 180,
            imageName: "product_safai"
        ),
        Product(
            id: .raksha, hindiName: "रक्षा", romanName: "Raksha",
            englishName: "Immunity Shield",
            tagline: "Your daily shield",
            accentColor: "#7B4A8C",
            bodySystem: .immunity,
            keyIngredients: ["Giloy", "Amla", "Ginger", "Honey"],
            priceRupees: 180,
            imageName: "product_raksha"
        ),
        Product(
            id: .tejas, hindiName: "तेजस", romanName: "Tejas",
            englishName: "Brain Fog Clearer",
            tagline: "Clarity, uncluttered",
            accentColor: "#2E6B8A",
            bodySystem: .brain,
            keyIngredients: ["Brahmi", "Gotu Kola", "Mint", "Green Apple"],
            priceRupees: 180,
            imageName: "product_tejas"
        )
    ]
}
