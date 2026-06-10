import Foundation

struct UserProfile: Codable, Equatable, Sendable {
    var id: UUID
    var displayName: String
    var email: String
    var phone: String?
    var bodyGoals: [BodyGoal]
    var streakCount: Int
    var lastLogDate: Date?
    var createdAt: Date

    enum BodyGoal: String, Codable, CaseIterable, Sendable, Identifiable {
        case lungHealth   = "lung_health"
        case skinRepair   = "skin_repair"
        case gutHealth    = "gut_health"
        case liverDetox   = "liver_detox"
        case immunity     = "immunity"
        case brainClarity = "brain_clarity"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .lungHealth:   return "Lung Health"
            case .skinRepair:   return "Skin Repair"
            case .gutHealth:    return "Gut Health"
            case .liverDetox:   return "Liver Detox"
            case .immunity:     return "Immunity"
            case .brainClarity: return "Brain Clarity"
            }
        }

        /// The SKU most associated with this goal.
        var associatedProduct: ProductID {
            switch self {
            case .lungHealth:   return .saans
            case .skinRepair:   return .chamak
            case .gutHealth:    return .pachak
            case .liverDetox:   return .safai
            case .immunity:     return .raksha
            case .brainClarity: return .tejas
            }
        }
    }
}
