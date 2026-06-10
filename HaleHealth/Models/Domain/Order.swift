import Foundation

/// Order domain model. The Razorpay/checkout flow is Phase 2; this type and the
/// `orders` table exist now purely so the data layer doesn't need reworking.
struct Order: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let userId: UUID
    let items: [OrderItem]
    let totalPaise: Int
    let status: Status
    let deliveryDate: Date?
    let createdAt: Date

    struct OrderItem: Codable, Equatable, Sendable {
        let productId: ProductID
        let quantity: Int
        let unitPricePaise: Int
    }

    enum Status: String, Codable, Sendable {
        case pending, paid, shipped, delivered, cancelled
    }
}
