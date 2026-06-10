import Foundation

/// Stable identifier for each City Shield SKU. Raw values match the `product_id`
/// strings persisted in Supabase (`drink_logs.product_id`, etc.).
enum ProductID: String, Codable, CaseIterable, Sendable, Identifiable {
    case saans
    case chamak
    case pachak
    case safai
    case raksha
    case tejas

    var id: String { rawValue }
}

/// A City Shield product. The canonical domain model the UI reasons about;
/// distinct from `ProductDTO` (which mirrors Supabase column names).
struct Product: Identifiable, Codable, Equatable, Sendable {
    let id: ProductID
    let hindiName: String        // "सांस"
    let romanName: String        // "Saans"
    let englishName: String      // "Lung Cleanse"
    let tagline: String
    let accentColor: String      // hex string; converted to Color at the UI layer
    let bodySystem: BodySystem
    let keyIngredients: [String]
    let priceRupees: Int
    let imageName: String        // asset-catalog name

    enum BodySystem: String, Codable, Sendable {
        case lung, skin, gut, liver, immunity, brain

        var displayName: String {
            switch self {
            case .lung:     return "lungs"
            case .skin:     return "skin"
            case .gut:      return "gut"
            case .liver:    return "liver"
            case .immunity: return "immunity"
            case .brain:    return "mind"
            }
        }
    }
}
