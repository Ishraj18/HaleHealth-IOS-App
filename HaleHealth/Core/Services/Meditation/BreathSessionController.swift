import Combine
import CoreHaptics
import Foundation
import OSLog
import UIKit

/// Drives a breathing session: a phase state machine on a fine timer, with
/// breathing haptics. Pure of any view code; the session screen just renders
/// its published state.
@MainActor
final class BreathSessionController: ObservableObject {
    enum State: Equatable { case ready, running, paused, finished }

    @Published private(set) var state: State = .ready
    @Published private(set) var phaseIndex = 0
    @Published private(set) var phaseProgress: Double = 0   // 0…1 within phase
    @Published private(set) var cycleCount = 0
    @Published private(set) var remainingSeconds: Int

    let pattern: BreathPattern
    let totalSeconds: Int

    private var timer: AnyCancellable?
    private var phaseElapsed: Double = 0
    private var totalElapsed: Double = 0
    private var haptics: CHHapticEngine?
    private let tickInterval = 1.0 / 30.0

    var currentPhase: BreathPattern.Phase { pattern.phases[phaseIndex] }
    /// 0…1 share of the session done — drives the haze clearing.
    var clearProgress: Double { min(totalElapsed / Double(totalSeconds), 1) }
    var expectedCycles: Int { max(1, Int(Double(totalSeconds) / pattern.cycleSeconds)) }

    init(pattern: BreathPattern, minutes: Int) {
        self.pattern = pattern
        self.totalSeconds = minutes * 60
        self.remainingSeconds = minutes * 60
        prepareHaptics()
    }

    func start() {
        guard state == .ready || state == .paused else { return }
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true
        playHaptic(for: currentPhase)
        timer = Timer.publish(every: tickInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func stop() {
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        haptics?.stop()
        if state != .finished { state = .ready }
    }

    private func tick() {
        phaseElapsed += tickInterval
        totalElapsed += tickInterval
        remainingSeconds = max(0, totalSeconds - Int(totalElapsed))
        phaseProgress = min(phaseElapsed / currentPhase.seconds, 1)

        if phaseElapsed >= currentPhase.seconds {
            phaseElapsed = 0
            phaseProgress = 0
            let next = (phaseIndex + 1) % pattern.phases.count
            if next == 0 { cycleCount += 1 }
            phaseIndex = next
            playHaptic(for: currentPhase)
        }

        if totalElapsed >= Double(totalSeconds) {
            timer = nil
            state = .finished
            UIApplication.shared.isIdleTimerDisabled = false
            haptics?.stop()
        }
    }

    // MARK: - Haptics (breathes with you; silent no-op when unsupported)

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            haptics = try CHHapticEngine()
            try haptics?.start()
        } catch {
            Log.app.debug("Haptics unavailable: \(error.localizedDescription, privacy: .public)")
            haptics = nil
        }
    }

    private func playHaptic(for phase: BreathPattern.Phase) {
        guard let haptics else { return }
        let curve: [(Double, Float)]
        switch phase.kind {
        case .inhale:           curve = [(0, 0.1), (phase.seconds, 0.8)]   // swell
        case .exhale:           curve = [(0, 0.8), (phase.seconds, 0.0)]   // fade
        case .hold, .holdEmpty: return                                      // stillness
        }
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)],
                relativeTime: 0, duration: phase.seconds
            )
            let ramp = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: curve.map { .init(relativeTime: $0.0, value: $0.1) },
                relativeTime: 0
            )
            let hapticPattern = try CHHapticPattern(events: [event], parameterCurves: [ramp])
            try haptics.makePlayer(with: hapticPattern).start(atTime: 0)
        } catch {
            Log.app.debug("Haptic pattern failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
