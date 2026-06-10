import SwiftUI
import HaleDesignSystem

/// The air-quality intelligence screen: a large AQI dial, the category scale,
/// and what today's air means for the body — tied back to the products.
struct HawaView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showShuddhi = false
    @State private var dialBreath = false

    var body: some View {
        ScrollView {
            VStack(spacing: HHSpacing.lg) {
                switch appState.aqiLoadState {
                case .loaded where appState.currentAQI != nil:
                    content(appState.currentAQI!)
                case .failed(let message):
                    HHCard {
                        HHEmptyState(title: "Air quality unavailable", subtitle: message, systemImage: "wind")
                    }
                default:
                    HHLoadingView(message: "Reading the Gurgaon air…")
                        .padding(.top, HHSpacing.section)
                }
            }
            .padding(HHSpacing.lg)
            .hhWatermark("हवा", size: 200, alignment: .topLeading)
        }
        .hhScreenBackground()
        .navigationTitle(Tab.hawa.label)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await appState.loadAQI() }
        .fullScreenCover(isPresented: $showShuddhi) {
            ShuddhiSetupView()
        }
    }

    /// The doorway into the clearing — copy adapts to the day's air.
    private var shuddhiCard: some View {
        Button { showShuddhi = true } label: {
            HStack(spacing: HHSpacing.md) {
                ZStack {
                    Circle().fill(Color.hhCreamParchment.opacity(0.15))
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(Color.hhCreamParchment)
                }
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shuddhi")
                        .hhFont(.hhHeading)
                        .foregroundStyle(Color.hhCreamParchment)
                    Text(shuddhiLine)
                        .hhFont(.hhCaption)
                        .foregroundStyle(Color.hhMutedSage)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.hhMutedSage)
            }
            .padding(HHSpacing.md)
            .background(Color.hhForestGreen, in: RoundedRectangle(cornerRadius: HHRadius.md, style: .continuous))
            .hhShadow()
        }
        .buttonStyle(.plain)
    }

    private var shuddhiLine: String {
        guard let aqi = appState.currentAQI, aqi.value > 100 else {
            return "Clear your air. A guided breathing clearing."
        }
        return "The air is heavy today. Clear yours — \(MeditationStore.shared.lifetimeSessions) sittings so far."
    }

    @ViewBuilder private func content(_ aqi: AQIReading) -> some View {
        let tint = Color(aqiCategory: aqi.category)

        shuddhiCard

        // Dial
        HHCard(padding: HHSpacing.lg) {
            VStack(spacing: HHSpacing.md) {
                ZStack {
                    Circle()
                        .trim(from: 0.1, to: 0.9)
                        .stroke(Color.hhBorder.opacity(0.6), style: .init(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(90))
                    Circle()
                        .trim(from: 0.1, to: 0.1 + 0.8 * min(Double(aqi.value) / 400, 1))
                        .stroke(tint, style: .init(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(90))
                        .animation(.hhSpring, value: aqi.value)
                    VStack(spacing: 2) {
                        Text("\(aqi.value)")
                            .hhFont(.hhDisplay1, lineSpacing: 0)
                            .hhText(.primary)
                        Text(aqi.category.rawValue)
                            .hhFont(.hhLabel)
                            .foregroundStyle(tint)
                            .multilineTextAlignment(.center)
                    }
                    .padding(HHSpacing.lg)
                }
                .frame(width: 200, height: 200)
                .scaleEffect(dialBreath ? 1.0 : 0.93)
                .opacity(dialBreath ? 1 : 0.6)
                .onAppear { withAnimation(.hhSpring.delay(0.1)) { dialBreath = true } }

                Text(aqi.station)
                    .hhFont(.hhCaption)
                    .hhText(.secondary)
                Text("Updated \(aqi.fetchedAt.formatted(date: .omitted, time: .shortened))")
                    .hhFont(.hhOverline)
                    .tracking(0.6)
                    .hhText(.secondary)
            }
            .frame(maxWidth: .infinity)
        }

        // Category scale
        HHCard {
            VStack(alignment: .leading, spacing: HHSpacing.sm) {
                HHDivider(label: "The scale")
                ForEach(scale, id: \.0) { range, label, hex in
                    HStack(spacing: HHSpacing.sm) {
                        Circle().fill(Color(hex: hex)).frame(width: 10, height: 10)
                        Text(range).hhFont(.hhLabel).hhText(.primary)
                            .frame(width: 70, alignment: .leading)
                        Text(label).hhFont(.hhCaption).hhText(.secondary)
                        Spacer()
                    }
                    .opacity(label == aqi.category.rawValue ? 1 : 0.55)
                }
            }
        }

        // What it means + products
        VStack(alignment: .leading, spacing: HHSpacing.sm) {
            HHDivider(label: "Your shield today")
            if let primary = appState.productCatalog.product(for: aqi.primaryRecommendation) {
                HHProductCard(product: primary)
            }
            if let secondary = appState.productCatalog.product(for: aqi.secondaryRecommendation) {
                HHProductCard(product: secondary)
            }
        }
    }

    private var scale: [(String, String, String)] {
        [("0–50", "Good", "#27AE60"),
         ("51–100", "Moderate", "#F1C40F"),
         ("101–150", "Unhealthy for Sensitive Groups", "#E67E22"),
         ("151–200", "Unhealthy", "#E74C3C"),
         ("201–300", "Very Unhealthy", "#8E44AD"),
         ("300+", "Hazardous", "#7B241C")]
    }
}

#Preview {
    NavigationStack { HawaView() }
        .environmentObject(AppState.preview)
}
