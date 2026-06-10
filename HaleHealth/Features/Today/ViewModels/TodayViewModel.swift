import Combine
import SwiftUI

/// Drives the Today screen: greeting, live AQI, and the recommendation logic.
@MainActor
final class TodayViewModel: ObservableObject {
    @Published var aqi: AQIReading?
    @Published var recommendedProduct: Product?
    @Published var secondaryProduct: Product?
    @Published var greeting: String = ""
    @Published var loadState: LoadState = .idle

    private let catalog: ProductCatalog
    private let aqiService: AQIServiceProtocol
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.catalog = appState.productCatalog
        self.aqiService = appState.aqiService
        self.aqi = appState.currentAQI
        buildGreeting()
        buildRecommendations()
        if appState.currentAQI != nil { loadState = .loaded }
    }

    func refresh() async {
        loadState = .loading
        do {
            let reading = try await aqiService.fetchCurrentAQI()
            aqi = reading
            appState.currentAQI = reading // keep shared AQI in sync for Hawa
            buildRecommendations()
            loadState = .loaded
        } catch {
            let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
            loadState = .failed(message)
        }
    }

    /// Adopts whatever AppState already loaded (e.g. AppCoordinator's launch fetch).
    func syncFromAppState() {
        guard let shared = appState.currentAQI else { return }
        aqi = shared
        buildRecommendations()
        loadState = .loaded
    }

    var aqiContextSentence: String {
        guard let aqi, let product = recommendedProduct else { return "" }
        switch aqi.category {
        case .good:
            return "Clean air in Gurgaon today. A good day for \(product.englishName)."
        case .moderate:
            return "AQI is moderate today. \(product.romanName) keeps your \(product.bodySystem.displayName) supported."
        case .unhealthyForSensitive, .unhealthy:
            return "AQI \(aqi.value) today. Your \(product.bodySystem.displayName) is under strain — \(product.romanName) helps."
        case .veryUnhealthy:
            return "AQI \(aqi.value), Very Unhealthy. Prioritise \(product.romanName) today."
        case .hazardous:
            return "AQI \(aqi.value), Hazardous. \(product.romanName) is your primary defence today."
        }
    }

    private func buildRecommendations() {
        guard let aqi else { return }
        recommendedProduct = catalog.product(for: aqi.primaryRecommendation)
        secondaryProduct = catalog.product(for: aqi.secondaryRecommendation)
    }

    private func buildGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        greeting = String.hhGreeting(forHour: hour)
    }
}
