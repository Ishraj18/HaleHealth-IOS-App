import SwiftUI
import HaleDesignSystem

/// The clearing itself. The day's haze hangs in the air and thins with every
/// breath; the mandala breathes with you; the tulsi grows when you finish.
struct ShuddhiSessionView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var controller: BreathSessionController
    @ObservedObject private var meditationStore = MeditationStore.shared
    @Environment(\.scenePhase) private var scenePhase
    /// `completed` is true only when the sitting ran to its end.
    let onDone: (_ completed: Bool) -> Void

    init(pattern: BreathPattern, minutes: Int, onDone: @escaping (_ completed: Bool) -> Void) {
        _controller = StateObject(wrappedValue: BreathSessionController(pattern: pattern, minutes: minutes))
        self.onDone = onDone
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.hhForestGreen, Color(hex: "#0F241A")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            HHHazeLayer(
                tintHex: appState.currentAQI?.category.hexColor ?? "#7A9E8A",
                density: hazeDensity,
                cleared: controller.clearProgress
            )
            .ignoresSafeArea()

            if controller.state == .finished {
                finishedView
            } else {
                sessionView
            }
        }
        .onDisappear { controller.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { controller.pause() } else if controller.state == .paused { controller.start() }
        }
        .onChange(of: controller.state) { _, state in
            if state == .finished { recordSession() }
        }
    }

    private var hazeDensity: Double {
        guard let aqi = appState.currentAQI else { return 0.4 }
        return min(0.25 + Double(aqi.value) / 350.0, 1)
    }

    /// 0 = lungs empty, 1 = full — what the mandala renders.
    private var breathAmount: Double {
        switch controller.currentPhase.kind {
        case .inhale:    return controller.phaseProgress
        case .hold:      return 1
        case .exhale:    return 1 - controller.phaseProgress
        case .holdEmpty: return 0
        }
    }

    private var sessionView: some View {
        VStack(spacing: HHSpacing.xl) {
            HStack {
                Spacer()
                Button { controller.stop(); onDone(false) } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Color.hhMutedSage.opacity(0.7))
                        .padding(HHSpacing.md)
                }
            }

            Spacer()

            HHBreathMandala(breath: breathAmount, accentHex: controller.pattern.accentHex)
                .animation(.linear(duration: 1.0 / 30.0), value: breathAmount)

            if controller.state == .ready {
                // Nothing moves until the user chooses to begin.
                VStack(spacing: HHSpacing.md) {
                    Text("जब तैयार हों")
                        .hhFont(.hhDisplay2)
                        .foregroundStyle(Color.hhCreamParchment)
                    Text("\(controller.pattern.name) · \(controller.totalSeconds / 60) minutes")
                        .hhFont(.hhCaption)
                        .foregroundStyle(Color.hhMutedSage)
                    HHButton("Begin", style: .primary) {
                        withAnimation(.hhGentle) { controller.start() }
                    }
                    .frame(width: 200)
                }
            } else {
                VStack(spacing: HHSpacing.xs) {
                    Text(controller.currentPhase.hindi)
                        .hhFont(.hhDisplay2)
                        .foregroundStyle(Color.hhCreamParchment)
                        .id(controller.phaseIndex)
                        .transition(.opacity)
                    Text(controller.currentPhase.english)
                        .hhFont(.hhCaption)
                        .foregroundStyle(Color.hhMutedSage)
                }
                .animation(.hhGentle, value: controller.phaseIndex)
            }

            Spacer()

            VStack(spacing: HHSpacing.sm) {
                HHTulsiSprout(leaves: meditationStore.lifetimeSessions)
                Text(timeLabel)
                    .hhFont(.hhOverline)
                    .tracking(1)
                    .foregroundStyle(Color.hhMutedSage.opacity(0.8))
            }
            .padding(.bottom, HHSpacing.lg)
        }
        .padding(HHSpacing.lg)
    }

    private var finishedView: some View {
        VStack(spacing: HHSpacing.lg) {
            Spacer()
            HHTulsiSprout(leaves: meditationStore.lifetimeSessions)
                .scaleEffect(1.4)
            Text("Saaf.")
                .hhFont(.hhDisplay1)
                .foregroundStyle(Color.hhCreamParchment)
            Text("\(controller.totalSeconds / 60) minutes · \(controller.cycleCount) breaths")
                .hhFont(.hhBody)
                .foregroundStyle(Color.hhMutedSage)
            Spacer()
            HHButton("Return", style: .primary) { onDone(true) }
                .padding(.horizontal, HHSpacing.xl)
                .padding(.bottom, HHSpacing.xl)
        }
        .transition(.opacity)
    }

    private var timeLabel: String {
        String(format: "%d:%02d", controller.remainingSeconds / 60, controller.remainingSeconds % 60)
    }

    private func recordSession() {
        Haptics.success()
        meditationStore.record(
            MeditationSession(
                patternID: controller.pattern.id,
                durationSeconds: controller.totalSeconds,
                breathCycles: controller.cycleCount,
                aqiAtStart: appState.currentAQI?.value,
                completedAt: Date()
            ),
            userId: appState.userSession.profile?.id
        )
        // Auto-check today's meditate block on the shared plan.
        RoutineStore.shared.markDone(kind: .meditate)
    }
}

#Preview {
    ShuddhiSessionView(pattern: .all[0], minutes: 3) { _ in }
        .environmentObject(AppState.preview)
}
