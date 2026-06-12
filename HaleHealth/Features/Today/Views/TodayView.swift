import SwiftUI
import HaleDesignSystem

/// The Today tab — the one fully-built feature screen in Phase 1. Shows the live
/// Gurgaon AQI and the product recommendation derived from it.
struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tabRouter: TabRouter
    @ObservedObject private var routineStore = RoutineStore.shared

    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: TodayViewModel(appState: appState))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HHSpacing.lg) {
                header

                primarySection

                if let secondary = viewModel.secondaryProduct {
                    secondarySection(secondary)
                }

                ritualCard

                YourWeekCard()
            }
            .padding(HHSpacing.lg)
            .hhWatermark("आज", size: 170, alignment: .topTrailing)
        }
        .hhScreenBackground()
        .overlay(alignment: .top) {
            if let aqi = viewModel.aqi {
                HHHazeLayer(
                    tintHex: aqi.value > 100 ? aqi.category.hexColor : "#7A9E8A",
                    density: aqi.value > 100 ? 0.16 : 0.08,
                    cleared: 0
                )
                .frame(height: 220)
                .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
            }
        }
        .toolbar(.hidden, for: .navigationBar) // Today has its own header
        .refreshable { await viewModel.refresh() }
        .task {
            routineStore.rolloverIfNeeded()
            viewModel.syncFromAppState()
            if viewModel.aqi == nil { await viewModel.refresh() }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: HHSpacing.xs) {
                Text(viewModel.greeting)
                    .hhFont(.hhDisplay2)
                    .hhText(.display)
                Text(Constants.Brand.city)
                    .hhFont(.hhOverline)
                    .tracking(1)
                    .textCase(.uppercase)
                    .hhText(.secondary)
            }
            Spacer()
            if let aqi = viewModel.aqi {
                HHAQIBadge(reading: aqi)
            }
        }
    }

    @ViewBuilder private var primarySection: some View {
        if let product = viewModel.recommendedProduct {
            RecommendationCard(product: product, contextSentence: viewModel.aqiContextSentence)
        } else {
            switch viewModel.loadState {
            case .loading, .idle:
                HHCard {
                    HHLoadingView(message: "Reading the Gurgaon air…")
                        .frame(height: 120)
                }
            case .failed(let message):
                HHCard {
                    HHEmptyState(
                        title: "Air quality unavailable",
                        subtitle: message,
                        systemImage: "wind"
                    )
                }
            case .loaded:
                EmptyView()
            }
        }
    }

    /// Live ritual ring + next block once a routine exists; otherwise a nudge
    /// into the Ritual tab. Reads the shared plan — never generates its own.
    @ViewBuilder private var ritualCard: some View {
        if let routine = routineStore.routine {
            Button { tabRouter.navigate(to: .ritual) } label: {
                HHCard {
                    HStack(spacing: HHSpacing.md) {
                        HHStreakRing(
                            progress: routineStore.progress(for: routine),
                            streak: routineStore.streak.count,
                            size: 72
                        )
                        VStack(alignment: .leading, spacing: HHSpacing.xs) {
                            if let next = routineStore.nextBlock(in: routine) {
                                Text("Next up · \(next.timeLabel)")
                                    .hhFont(.hhOverline)
                                    .tracking(0.8)
                                    .textCase(.uppercase)
                                    .hhText(.secondary)
                                Text(next.title)
                                    .hhFont(.hhHeading)
                                    .hhText(.primary)
                            } else {
                                Text("All done for today")
                                    .hhFont(.hhHeading)
                                    .hhText(.display)
                                Text("Every block complete. Shabash.")
                                    .hhFont(.hhCaption)
                                    .hhText(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.hhBorder)
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            Button { tabRouter.navigate(to: .ritual) } label: {
                HHCard {
                    HHEmptyState(
                        title: "Build your ritual",
                        subtitle: "Ten questions. A complete daily routine, drinks included.",
                        systemImage: "circle.dotted"
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func secondarySection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: HHSpacing.sm) {
            HHDivider(label: "Also consider today")
            HHProductCard(product: product)
        }
    }
}

#Preview {
    let state = AppState.preview
    return NavigationStack {
        TodayView(appState: state)
    }
    .environmentObject(state)
    .environmentObject(state.userSession)
    .environmentObject(TabRouter())
}
