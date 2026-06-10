import Foundation

/// Mirrors a future `products` table row. Unused in Phase 1 (the catalog is
/// static), but defined now so swapping to a remote fetch needs no new types —
/// only a service method and a `toDomain()` call.
struct ProductDTO: Codable, Sendable {
    let id: String
    let hindiName: String
    let romanName: String
    let englishName: String
    let tagline: String
    let accentColor: String
    let bodySystem: String
    let keyIngredients: [String]
    let priceRupees: Int
    let imageName: String

    enum CodingKeys: String, CodingKey {
        case id, tagline
        case hindiName = "hindi_name"
        case romanName = "roman_name"
        case englishName = "english_name"
        case accentColor = "accent_color"
        case bodySystem = "body_system"
        case keyIngredients = "key_ingredients"
        case priceRupees = "price_rupees"
        case imageName = "image_name"
    }

    func toDomain() -> Product? {
        guard
            let productID = ProductID(rawValue: id),
            let system = Product.BodySystem(rawValue: bodySystem)
        else { return nil }
        return Product(
            id: productID,
            hindiName: hindiName,
            romanName: romanName,
            englishName: englishName,
            tagline: tagline,
            accentColor: accentColor,
            bodySystem: system,
            keyIngredients: keyIngredients,
            priceRupees: priceRupees,
            imageName: imageName
        )
    }
}
