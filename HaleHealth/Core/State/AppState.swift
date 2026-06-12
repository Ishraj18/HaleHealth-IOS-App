import Combine
import Foundation
import OSLog

/// Coarse async load state used across feature ViewModels.
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

/// The single root state object, injected at the app entry point. Every feature
/// reads from it; no feature owns state another feature needs. Services are held
/// here as protocols so ViewModels access them via the environment.
@MainActor
final class AppState: ObservableObject {

    // Session
    let userSession: UserSession
    @Published var hasCompletedOnboarding: Bool
    /// True while the stored session is being restored at launch. The
    /// coordinator shows a splash instead of flashing the login screen.
    @Published var isRestoringSession = true

    // Shared AQI (Today + Hawa tabs)
    @Published var currentAQI: AQIReading?
    @Published var aqiLoadState: LoadState = .idle

    // Services (injected)
    let authService: AuthServiceProtocol
    let databaseService: DatabaseServiceProtocol
    let aqiService: AQIServiceProtocol
    let healthService: HealthServiceProtocol
    let productCatalog: ProductCatalog
    lazy var routineSyncService: RoutineSyncServiceProtocol = SupabaseRoutineSyncService()
    lazy var historySyncService: HistorySyncServiceProtocol = SupabaseHistorySyncService()

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(
        authService: AuthServiceProtocol = SupabaseAuthService(),
        databaseService: DatabaseServiceProtocol = SupabaseDatabaseService(),
        aqiService: AQIServiceProtocol = AQIService(),
        healthService: HealthServiceProtocol? = nil,
        productCatalog: ProductCatalog? = nil,
        userSession: UserSession? = nil,
        defaults: UserDefaults = .standard
    ) {
        // `.shared` / `UserSession()` are resolved here (in the MainActor-isolated
        // init body) rather than as default arguments, which are nonisolated.
        self.authService = authService
        self.databaseService = databaseService
        self.aqiService = aqiService
        self.healthService = healthService
            ?? (HealthFeature.enabled ? HealthKitService() : DisabledHealthService())
        self.productCatalog = productCatalog ?? .shared
        self.userSession = userSession ?? UserSession()
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Constants.UserDefaultsKey.onboardingComplete)

        // Re-publish nested session changes so any view observing AppState
        // re-renders on sign-in/out.
        self.userSession.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Every routine change flows into the daily history record.
        HistoryStore.shared.bind(to: RoutineStore.shared)

        #if DEBUG
        applyUITestStateIfNeeded()
        #endif
    }

    #if DEBUG
    /// Lets UI tests / manual QA launch straight into an authenticated state by
    /// setting `HH_UITEST=main` in the environment. Never compiled into release.
    private func applyUITestStateIfNeeded() {
        guard ProcessInfo.processInfo.environment["HH_UITEST"] == "main" else { return }
        hasCompletedOnboarding = true
        userSession.set(profile: .preview)
        currentAQI = AQIReading(value: 218, station: "Gurgaon Sector 51", fetchedAt: Date())
        aqiLoadState = .loaded
    }
    #endif

    // MARK: - AQI

    func loadAQI() async {
        aqiLoadState = .loading
        do {
            let reading = try await aqiService.fetchCurrentAQI()
            setAQI(reading)
        } catch {
            let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
            aqiLoadState = .failed(message)
            Log.aqi.error("AQI load failed: \(message, privacy: .public)")
        }
    }

    /// The single entry point for a fresh AQI reading: shared state for the
    /// Today/Hawa screens, the routine plan's generation context, and the
    /// day's history record.
    func setAQI(_ reading: AQIReading) {
        currentAQI = reading
        aqiLoadState = .loaded
        RoutineStore.shared.updateAQI(reading)
        HistoryStore.shared.updateToday { $0.aqi = reading.value }
    }

    // MARK: - Health → ritual

    /// Reads today's Health signals into the ritual: the wake anchor shifts to
    /// when the user actually woke, and movement blocks check themselves off.
    /// No-op until the user enables Health sync.
    func syncHealthIntoRitual() async {
        guard defaults.bool(forKey: Constants.UserDefaultsKey.healthSyncEnabled),
              healthService.isAvailable else { return }
        let store = RoutineStore.shared
        store.rolloverIfNeeded()
        store.updateObservedWake(await healthService.lastWakeMinutes())
        let workouts = await healthService.todayWorkoutCount()
        let steps = await healthService.todaySteps()
        if workouts > 0 { store.markDone(kind: .workout) }
        if steps >= Constants.Health.walkStepThreshold { store.markDone(kind: .walk) }
        HistoryStore.shared.updateToday {
            $0.steps = steps
            $0.workouts = workouts
        }
    }

    // MARK: - Auth lifecycle

    /// Restores the stored session at launch (the SDK keeps it in the keychain),
    /// so users stay signed in across app closes until they sign out explicitly.
    func restoreSession() async {
        defer { isRestoringSession = false }
        let base: UserProfile?
        do {
            base = try await authService.fetchCurrentProfile()
        } catch {
            Log.auth.debug("Session restore skipped: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard let base else { return }

        let merged = await mergedWithDatabase(base)
        let resolved = applyingIdentity(base, to: merged)
        userSession.set(profile: resolved)
        attachRoutineSync(for: resolved)
        // Heal the stored row when fresher identity data changed something
        // (e.g. a pre-existing email-derived name replaced by Google's name).
        if resolved != merged {
            do { try await databaseService.saveProfile(resolved) }
            catch { Log.auth.error("Profile heal failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    /// Single auth entry point for both modes: authenticates, merges the stored
    /// profile row, applies onboarding goals (sign-up), persists, attaches sync.
    func authenticate(email: String, password: String, isSignUp: Bool,
                      onboardingGoals: [UserProfile.BodyGoal]) async throws {
        let base = isSignUp
            ? try await authService.signUp(email: email, password: password)
            : try await authService.signIn(email: email, password: password)
        await finalizeSession(base: base, onboardingGoals: onboardingGoals)
    }

    func authenticateWithApple(idToken: String, nonce: String, fullName: String?,
                               onboardingGoals: [UserProfile.BodyGoal]) async throws {
        let base = try await authService.signInWithApple(idToken: idToken, nonce: nonce, fullName: fullName)
        await finalizeSession(base: base, onboardingGoals: onboardingGoals)
    }

    func authenticateWithGoogle(onboardingGoals: [UserProfile.BodyGoal]) async throws {
        let base = try await authService.signInWithGoogle()
        await finalizeSession(base: base, onboardingGoals: onboardingGoals)
    }

    /// Shared post-auth path for every provider: merge the stored profile row,
    /// apply onboarding goals, persist, attach sync. The trigger-created row can
    /// have empty fields on first sign-in — auth-derived values fill the gaps.
    private func finalizeSession(base: UserProfile, onboardingGoals: [UserProfile.BodyGoal]) async {
        var resolved = applyingIdentity(base, to: await mergedWithDatabase(base))
        if !onboardingGoals.isEmpty && resolved.bodyGoals.isEmpty {
            resolved.bodyGoals = onboardingGoals
        }
        userSession.set(profile: resolved)
        completeOnboarding()
        attachRoutineSync(for: resolved)
        do {
            try await databaseService.saveProfile(resolved)
        } catch {
            // Auth succeeded; a failed profile write shouldn't block entry.
            Log.auth.error("Profile save after auth failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Updates the user's body goals (e.g. after retaking the routine quiz).
    func updateBodyGoals(_ goals: [UserProfile.BodyGoal]) {
        guard var profile = userSession.profile else { return }
        profile.bodyGoals = goals
        userSession.set(profile: profile)
        guard authService.isAuthenticated else { return }
        Task {
            do { try await databaseService.saveProfile(profile) }
            catch { Log.auth.error("Goal update save failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    private func mergedWithDatabase(_ base: UserProfile) async -> UserProfile {
        do {
            if let full = try await databaseService.fetchProfile(userId: base.id) {
                return full
            }
        } catch {
            Log.auth.debug("Profile fetch failed: \(error.localizedDescription, privacy: .public)")
        }
        return base
    }

    /// Identity-provider data (Google/Apple metadata) beats stale stored values:
    /// there is no in-app name editing yet, so the provider's name and photo are
    /// always the freshest truth. A name merely derived from the email keeps
    /// whatever the stored row has.
    private func applyingIdentity(_ base: UserProfile, to stored: UserProfile) -> UserProfile {
        var resolved = stored
        let emailFallback = base.email.split(separator: "@").first.map { String($0).capitalized } ?? ""
        if !base.displayName.isEmpty, base.displayName != emailFallback {
            resolved.displayName = base.displayName
        }
        if resolved.displayName.isEmpty { resolved.displayName = base.displayName }
        if resolved.email.isEmpty { resolved.email = base.email }
        if let avatar = base.avatarURL { resolved.avatarURL = avatar }
        return resolved
    }

    /// Connects the routine + history stores to Supabase for the signed-in user.
    func attachRoutineSync(for profile: UserProfile) {
        RoutineStore.shared.configure(
            userId: profile.id,
            sync: routineSyncService,
            serverStreak: profile.streakCount
        )
        HistoryStore.shared.configure(userId: profile.id, sync: historySyncService)
    }

    /// Persists a checked-off drink block as a DrinkLog (fire-and-forget) and
    /// counts it in the day's history record.
    func logDrink(_ productID: ProductID) {
        HistoryStore.shared.updateToday { $0.drinksLogged += 1 }
        guard let userId = userSession.profile?.id, authService.isAuthenticated else { return }
        let log = DrinkLog(id: UUID(), userId: userId, productId: productID,
                           loggedAt: Date(), aqiAtLogTime: currentAQI?.value,
                           moodEmoji: nil, notes: nil)
        Task {
            do { try await databaseService.saveDrinkLog(log) }
            catch { Log.app.error("Drink log failed: \(error.localizedDescription, privacy: .public)") }
        }
    }

    #if DEBUG
    /// DEBUG-only: enters the app with a locally-built profile and **no** Supabase
    /// session. Used by the "skip verification" dev path while the email OTP
    /// template is being configured. No database write is attempted — there's no
    /// `auth.uid()` to satisfy RLS, so persistence is intentionally skipped.
    func enterAppLocally(profile: UserProfile, markOnboardingComplete: Bool) {
        userSession.set(profile: profile)
        if markOnboardingComplete { completeOnboarding() }
        Log.auth.debug("Entered app locally (dev bypass) for \(profile.email, privacy: .private).")
    }
    #endif

    func completeOnboarding() {
        defaults.set(true, forKey: Constants.UserDefaultsKey.onboardingComplete)
        hasCompletedOnboarding = true
    }

    func signOut() async {
        do {
            try await authService.signOut()
        } catch {
            Log.auth.error("Sign out failed: \(error.localizedDescription, privacy: .public)")
        }
        userSession.clear()
        // Wipe device-local caches so the next account doesn't inherit them.
        RoutineStore.shared.detachSync()
        RoutineStore.shared.clearAllLocal()
        MeditationStore.shared.clearLocal()
        HistoryStore.shared.detachSync()
        HistoryStore.shared.clearLocal()
    }
}
