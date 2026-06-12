import SwiftUI
import OSLog
import HaleDesignSystem

/// The Ritual tab home. No routine yet → an inviting build-your-routine state;
/// routine exists → today's timeline, read straight from `RoutineStore` (the
/// single place plans are generated).
struct RitualHomeView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var store = RoutineStore.shared
    @State private var showQuiz = false
    @State private var isRevealing = false
    @State private var celebration = 0
    @AppStorage(Constants.UserDefaultsKey.healthSyncEnabled) private var healthSyncEnabled = false
    @AppStorage(Constants.UserDefaultsKey.routineRemindersEnabled) private var remindersEnabled = false

    var body: some View {
        ZStack {
            Group {
                if isRevealing {
                    generatingState
                } else if let routine = store.routine {
                    timeline(routine)
                } else {
                    emptyState
                }
            }
            HHConfettiView(trigger: celebration)
                .ignoresSafeArea()
        }
        .hhScreenBackground()
        .navigationTitle(Tab.ritual.label)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showQuiz) {
            RoutineQuizView(initialGoals: appState.userSession.profile?.bodyGoals ?? []) { profile in
                showQuiz = false
                appState.updateBodyGoals(profile.goals)   // keep profiles.body_goals current
                reveal(profile)
            }
        }
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: HHSpacing.lg) {
            Spacer()
            HHEmptyState(
                title: "Your ritual, designed for you",
                subtitle: "Ten quick questions about your goals, your body and your mind — and we'll shape a complete daily routine around them, drinks included.",
                systemImage: "circle.dotted"
            )
            HHButton("Build my routine", style: .primary) { showQuiz = true }
                .padding(.horizontal, HHSpacing.xl)
            Spacer()
        }
    }

    private var generatingState: some View {
        VStack(spacing: HHSpacing.lg) {
            HHLoadingView(message: "Shaping your day…")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func timeline(_ routine: DailyRoutine) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HHSpacing.md) {
                if store.isWakeShifted, let block = routine.blocks.first {
                    Text("You woke around \(block.timeLabel) — today's plan adjusted.")
                        .hhFont(.hhCaption)
                        .hhText(.secondary)
                }

                RoutineTimelineView(routine: routine, store: store) {
                    celebration += 1
                }

                if !healthSyncEnabled && appState.healthService.isAvailable {
                    healthCard
                }

                remindersToggle(routine)

                HHButton("Retake the questionnaire", style: .text) { showQuiz = true }
                    .padding(.top, HHSpacing.sm)
            }
            .padding(HHSpacing.lg)
        }
        .task {
            store.rolloverIfNeeded()
            await appState.syncHealthIntoRitual()
        }
    }

    private var healthCard: some View {
        HHCard {
            VStack(alignment: .leading, spacing: HHSpacing.sm) {
                Text("Sync with Apple Health")
                    .hhFont(.hhHeading)
                    .hhText(.primary)
                Text("Workouts and walks check themselves off, and your day adapts to when you actually woke.")
                    .hhFont(.hhCaption)
                    .hhText(.secondary)
                HHButton("Connect Health", style: .secondary) {
                    Task {
                        do {
                            try await appState.healthService.requestAuthorization()
                            healthSyncEnabled = true
                            await appState.syncHealthIntoRitual()
                        } catch {
                            Log.app.error("Health auth failed: \(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
            }
        }
    }

    private func remindersToggle(_ routine: DailyRoutine) -> some View {
        HHCard {
            Toggle(isOn: Binding(
                get: { remindersEnabled },
                set: { enable in
                    remindersEnabled = enable
                    Task {
                        if enable {
                            guard await RoutineNotificationService.shared.requestPermission() else {
                                remindersEnabled = false
                                return
                            }
                            await RoutineNotificationService.shared.schedule(for: routine)
                        } else {
                            await RoutineNotificationService.shared.cancelAll()
                        }
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Block reminders")
                        .hhFont(.hhHeading)
                        .hhText(.primary)
                    Text("A gentle nudge at each block's time.")
                        .hhFont(.hhCaption)
                        .hhText(.secondary)
                }
            }
            .tint(.hhWarmSaffron)
        }
    }

    // MARK: -

    /// Brief considered pause before the reveal — the engine itself is instant.
    private func reveal(_ profile: RoutineProfile) {
        isRevealing = true
        Task {
            do { try await Task.sleep(nanoseconds: 1_400_000_000) } catch {}
            withAnimation(.hhSpring) {
                store.saveProfile(profile)
                isRevealing = false
            }
        }
    }
}

#Preview {
    NavigationStack { RitualHomeView() }
        .environmentObject(AppState.preview)
}
