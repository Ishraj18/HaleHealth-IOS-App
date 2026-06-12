import Foundation

/// Everything a routine engine may consider beyond the questionnaire answers.
/// Grows over time (health signals, history, trends) without changing the
/// protocol — new inputs are new optional fields, absent inputs degrade cleanly.
struct GenerationContext: Equatable, Sendable {
    /// Live air quality, when a reading exists.
    var aqi: AQIReading?
    /// Wake time observed by Apple Health today (minutes from midnight).
    var observedWakeMinutes: Int?

    static let empty = GenerationContext()
}

/// The generation seam. Async + throwing so an AI-backed engine (Vaidya) can
/// satisfy it later; `RuleBasedRoutineEngine` satisfies it synchronously and
/// remains the deterministic, offline fallback behind any future engine.
protocol RoutineEngineProtocol {
    func generate(from profile: RoutineProfile, context: GenerationContext) async throws -> DailyRoutine
}

/// Deterministic, offline routine generator. Pure function of (profile, context)
/// — fully unit-testable.
///
/// Block IDs are **semantic slots** ("drink-morning", "movement"), never derived
/// from times: completion state stored against an ID must survive the plan
/// re-anchoring around an observed wake time or an AQI change mid-day.
struct RuleBasedRoutineEngine: RoutineEngineProtocol {

    /// Health-observed wake times within this distance of the planned wake keep
    /// the planned anchor; beyond it, the day re-anchors to reality.
    static let wakeShiftThresholdMinutes = 45

    /// The wake anchor the plan is built on: the profile's answer unless Health
    /// observed a materially different wake today.
    static func effectiveWakeMinutes(profile: RoutineProfile, observed: Int?) -> Int {
        guard let observed, abs(observed - profile.wakeMinutes) > wakeShiftThresholdMinutes else {
            return profile.wakeMinutes
        }
        return observed
    }

    func generate(from p: RoutineProfile, context: GenerationContext) -> DailyRoutine {
        var blocks: [RoutineBlock] = []
        let aqi = context.aqi
        let wake = Self.effectiveWakeMinutes(profile: p, observed: context.observedWakeMinutes)
        let highAQI = (aqi?.value ?? 0) > 200

        // ── Morning anchors ──────────────────────────────────────────
        blocks.append(block("wake", .wake, "Rise", wakeLine(p), at: wake, mins: 5))
        blocks.append(block("hydrate", .hydrate, "Warm water", "Rehydrate before anything else — your body has fasted all night.", at: wake + 5, mins: 5))

        if includeMeditation(p) {
            blocks.append(block("meditate", .meditate, "Meditate", meditationLine(p), at: wake + 10, mins: meditationLength(p)))
        }

        // ── Morning drink (AQI can override the goal drink) ──────────
        let morning = morningProduct(p, highAQI: highAQI, aqi: aqi)
        blocks.append(block("drink-morning", .drink, "Morning \(morning.romanName)", drinkLine(morning, highAQI: highAQI, aqi: aqi),
                            at: wake + 10 + (includeMeditation(p) ? meditationLength(p) : 0), mins: 10,
                            product: morning.id))

        blocks.append(block("breakfast", .meal, "Breakfast", "Eat within 90 minutes of waking to steady morning energy.", at: wake + 60, mins: 25))

        // ── Movement ─────────────────────────────────────────────────
        if p.exercise != .never || p.fitness >= 3 {
            let am = p.movePref == .morning || (p.movePref == .flexible && p.chronotype == .lark)
            let start = am ? wake + 110 : 18 * 60
            blocks.append(block("movement", .workout, workoutTitle(p), workoutLine(p, highAQI: highAQI),
                                at: start, mins: workoutLength(p)))
        } else {
            blocks.append(block("movement", .walk, "Gentle walk", highAQI ? "Keep it short or indoors today — the air is heavy." : "Ten easy minutes. Movement is the habit; intensity comes later.",
                                at: wake + 110, mins: 10))
        }

        // ── Midday ───────────────────────────────────────────────────
        blocks.append(block("lunch", .meal, "Lunch", "Your biggest meal — digestion is strongest at midday.", at: 13 * 60, mins: 30))

        // Second drink: the goal drink if AQI displaced it, else hydration nudge.
        if highAQI, let goalProduct = goalDrink(p), goalProduct.id != morning.id {
            blocks.append(block("drink-afternoon", .drink, "Afternoon \(goalProduct.romanName)",
                                "Back to your goal: \(goalProduct.englishName.lowercased()), once the morning shield is done.",
                                at: 16 * 60, mins: 10, product: goalProduct.id))
        }

        // ── Evening ──────────────────────────────────────────────────
        blocks.append(block("dinner", .meal, "Light dinner", "Finish 2–3 hours before sleep so rest goes to repair, not digestion.", at: 19 * 60 + 30, mins: 30))

        if includeJournaling(p) {
            blocks.append(block("journal", .journal, "Journal", journalLine(p), at: 21 * 60, mins: 10))
        }

        let sleepAt = sleepTime(p)
        blocks.append(block("wind-down", .windDown, "Wind down", windDownLine(p), at: sleepAt - 45, mins: 30))
        blocks.append(block("sleep", .sleep, "Lights out", "Same time nightly — consistency beats duration.", at: sleepAt, mins: 5))

        return DailyRoutine(
            blocks: blocks.sorted { $0.startMinutes < $1.startMinutes },
            themeLine: themeLine(p),
            generatedAt: Date()
        )
    }

    // MARK: - Block selection rules

    private func includeMeditation(_ p: RoutineProfile) -> Bool {
        p.mind != .calm || p.intention == .calm || p.budgetMinutes >= 60
    }

    private func meditationLength(_ p: RoutineProfile) -> Int {
        p.budgetMinutes >= 60 ? 15 : (p.budgetMinutes >= 30 ? 10 : 5)
    }

    private func includeJournaling(_ p: RoutineProfile) -> Bool {
        p.mind == .scattered || p.mind == .anxious || p.intention == .discipline
    }

    private func workoutLength(_ p: RoutineProfile) -> Int {
        min(15 + p.fitness * 10, max(15, p.budgetMinutes - 10))
    }

    private func workoutTitle(_ p: RoutineProfile) -> String {
        switch p.fitness {
        case 1: return "Easy movement"
        case 2: return "Bodyweight basics"
        case 3: return "Strength session"
        default: return "Full training"
        }
    }

    // MARK: - Drink logic (consistent with the Today screen)

    private func goalDrink(_ p: RoutineProfile) -> Product? {
        guard let goal = p.goals.first else { return nil }
        return ProductCatalogData.product(goal.associatedProduct)
    }

    private func morningProduct(_ p: RoutineProfile, highAQI: Bool, aqi: AQIReading?) -> Product {
        if highAQI, let saans = ProductCatalogData.product(.saans) { return saans }
        if let goal = goalDrink(p) { return goal }
        let fallback = aqi?.primaryRecommendation ?? .raksha
        return ProductCatalogData.product(fallback) ?? ProductCatalogData.all[0]
    }

    // MARK: - Copy

    private func wakeLine(_ p: RoutineProfile) -> String {
        p.chronotype == .owl ? "No alarm-snoozing — feet on the floor, curtains open."
                             : "Catch the early light; it anchors your body clock."
    }

    private func meditationLine(_ p: RoutineProfile) -> String {
        switch p.mind {
        case .anxious:   return "Slow breathing first — five counts in, seven out."
        case .foggy:     return "Eyes closed, follow the breath. Clarity follows stillness."
        case .scattered: return "One anchor: the breath. Everything else can wait."
        case .calm:      return "Keep the streak — calm is a practice, not a mood."
        }
    }

    private func drinkLine(_ product: Product, highAQI: Bool, aqi: AQIReading?) -> String {
        if highAQI, let v = aqi?.value, product.id == .saans {
            return "AQI \(v) today — \(product.keyIngredients.prefix(2).joined(separator: " and ")) ease the airways first."
        }
        return "\(product.tagline). \(product.keyIngredients.prefix(2).joined(separator: " and ")) do the quiet work."
    }

    private func workoutLine(_ p: RoutineProfile, highAQI: Bool) -> String {
        highAQI ? "Train indoors today — the air outside works against you."
                : (p.exercise == .regularly ? "You know the drill. Show up, even on low days."
                                            : "Start smaller than feels impressive. Consistency wins.")
    }

    private func journalLine(_ p: RoutineProfile) -> String {
        p.mind == .anxious ? "Empty the worries onto paper — they shrink in ink."
                           : "Three lines: what happened, what you felt, what's next."
    }

    private func windDownLine(_ p: RoutineProfile) -> String {
        p.sleepQuality <= 2 ? "Screens off, lights low. Your sleep needs the runway."
                            : "Protect the ritual that's already working."
    }

    private func sleepTime(_ p: RoutineProfile) -> Int {
        // Aim ~7.5h before wake; owls get a later floor.
        let ideal = p.wakeMinutes - Int(7.5 * 60) + 24 * 60
        return p.chronotype == .owl ? max(ideal, 23 * 60) : min(ideal, 23 * 60)
    }

    private func themeLine(_ p: RoutineProfile) -> String {
        switch p.intention {
        case .energy:     return "Built for steady, unborrowed energy."
        case .calm:       return "A quieter mind, one block at a time."
        case .discipline: return "Small promises, kept daily."
        case .glow:       return "Repair from within. The glow follows."
        }
    }

    // MARK: -

    private func block(_ slot: String, _ kind: RoutineBlock.Kind, _ title: String, _ detail: String,
                       at start: Int, mins: Int, product: ProductID? = nil) -> RoutineBlock {
        RoutineBlock(id: slot, kind: kind, title: title, detail: detail,
                     startMinutes: start, durationMinutes: mins, productID: product)
    }
}

/// Nonisolated product lookup for the engine (ProductCatalog is @MainActor).
/// Same data source — the catalog's array is exposed via this shim.
enum ProductCatalogData {
    static let all: [Product] = ProductCatalog.staticProducts
    static func product(_ id: ProductID) -> Product? { all.first { $0.id == id } }
}
