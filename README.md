# Hale Health — iOS

Premium Ayurvedic functional-beverage app for **Hale Health India** (Gurgaon,
Delhi NCR). This repository is the **Phase 1 foundation**: the architecture,
design system, navigation, service layer, onboarding, and a working Today
screen — built so every future feature slots in without rework.

- **Bundle id:** `com.halehealthindia.app`
- **Min iOS:** 17.0 · **Swift:** 5 language mode · **UI:** SwiftUI only
- **Xcode:** 16+ (built/verified on Xcode 26)

---

## Project layout

```
HaleHealth.xcodeproj          Native project (Xcode 16 synchronized folders)
Config/                       Build configuration (NOT in the synced target folder)
  Debug.xcconfig              Base config → includes Secrets.xcconfig
  Release.xcconfig            Base config → includes Secrets.xcconfig
  Secrets.xcconfig.example    Template — copy to Secrets.xcconfig (git-ignored)
  Info.plist                  Physical Info.plist (build-setting injected keys)
Packages/
  HaleDesignSystem/           Local SPM package: tokens, components, fonts
HaleHealth/                   App target (synchronized folder — drop files in, no pbxproj edits)
  App/                        Entry point, AppDelegate, AppConfig, BuildConfiguration
  Core/
    DesignSystem/             App-side adapters bridging domain → design-system components
    Navigation/               AppCoordinator, TabRouter, deep-link stub
    Services/                 Protocols + Supabase/AQI implementations + Mocks
    State/                    AppState, UserSession, ProductCatalog
    Utilities/                Extensions, Constants, Logger
  Features/                   Onboarding, Today, Shield, Hawa, Ritual, Shuddhi, Profile
  Models/                     Domain models + DTOs
HaleHealthTests/              Unit tests (engine, stores, trends, insights, AI context)
supabase/schema.sql           Database schema + RLS policies
supabase/migrations/          Run in order after schema.sql (002 → 003 → 004)
```

> **Synchronized folders:** the app target uses Xcode 16's file-system
> synchronized groups. Any file added under `HaleHealth/` is included
> automatically — no `project.pbxproj` editing to add files. `Config/` lives
> *outside* the synced folder on purpose, so `Info.plist` isn't double-copied.

---

## Getting started

### 1. Secrets

Credentials are injected into `Info.plist` at build time from a git-ignored
xcconfig — never hardcoded, never committed.

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
```

Then fill in `Config/Secrets.xcconfig`:

```
SUPABASE_URL = https:/$()/YOUR-PROJECT-REF.supabase.co
SUPABASE_ANON_KEY = <your supabase anon key>
AQICN_TOKEN = <your aqicn token>   # https://aqicn.org/data-platform/token/
```

> ⚠️ The `$()` in `SUPABASE_URL` is required: xcconfig treats `//` as a comment,
> so it would otherwise truncate the URL at `https:`. The empty `$()` emits a
> literal `//`. See `Secrets.xcconfig.example` for the full note.

The app builds and runs **without** these (a clean checkout produces no
warnings) — network features simply surface a friendly "not configured" state
until you add real keys.

### 2. Supabase

Create a Supabase project and run [`supabase/schema.sql`](supabase/schema.sql)
in the SQL editor, then each file in `supabase/migrations/` in order
(`002_routines.sql`, `003_meditation.sql`, `004_history.sql`). Enable
**Email OTP** auth (Authentication → Providers → Email → "Email OTP"). The
schema enables RLS on every user-owned table and auto-creates a `profiles` row
on signup.

### 3. Build & run

```bash
xcodebuild build -scheme HaleHealth -destination 'generic/platform=iOS Simulator'
```

Or open `HaleHealth.xcodeproj` in Xcode and run. Fonts are bundled in the design
system package and register at launch — no setup needed.

### 4. Tests

```bash
xcodebuild test -scheme HaleHealth -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
```

Or **⌘U** in Xcode. The `HaleHealthTests` target covers the routine engine
rules, store lifecycle (completion, streaks, day rollover, drink-log dedup),
the history/trends layer, the insight engine, and the AI context builder.

---

## Architecture notes

- **Design tokens & components** live in the `HaleDesignSystem` SPM package and
  are **presentation-only** (no domain knowledge). Components take primitives;
  the app maps `Product`/`AQIReading` onto them via adapters in
  `Core/DesignSystem/DomainComponentAdapters.swift`. Every visual value comes
  from a token — no hardcoded colours/fonts/spacing outside the package.
- **State:** one root `AppState` (`@EnvironmentObject`) owns services and shared
  state. ViewModels (`@MainActor final class … ObservableObject`) hold service
  **protocols**, never concrete types, so mocks inject cleanly into previews.
- **Services** are protocol-first (`AuthServiceProtocol`,
  `DatabaseServiceProtocol`, `AQIServiceProtocol`). `AQIService` is an `actor`
  for race-free caching.
- **Navigation:** `NavigationStack` per tab, paths held in `TabRouter` so each
  tab preserves its own stack.
- **Errors:** all funnel through `APIError`; nothing is swallowed with `try?`.
- **Routine plan:** generated in exactly one place (`RoutineStore`) from
  profile + `GenerationContext` (AQI, Health-observed wake). Block IDs are
  semantic slots (`drink-morning`), so completion state survives regeneration.
  `RoutineEngineProtocol` is async/throwing — a future AI engine slots in
  behind it; the rule engine stays the deterministic fallback.
- **History:** `HistoryStore` keeps one `DailySnapshot` per day (plan size,
  completions, meditation, drinks, Health, AQI), local-first with Supabase
  sync (`daily_snapshots`, `routine_days`). `TrendCalculator` + `InsightEngine`
  turn it into the Today screen's personal "Your week" card;
  `UserContextBuilder` assembles the same record into the JSON payload a
  future Vaidya AI prompt consumes.

### Concurrency

The app target uses the **classic Swift 5 concurrency** model
(`SWIFT_APPROACHABLE_CONCURRENCY = NO`, `SWIFT_DEFAULT_ACTOR_ISOLATION =
nonisolated`): `@MainActor` is applied explicitly to UI state, services are
nonisolated/actors. Migrating to Swift 6 strict concurrency is deliberately
deferred to keep this foundation predictable.

---

## Phase scope

**Built now:** project scaffolding, design system + fonts, navigation, Supabase
service layer (behind protocols), onboarding (3 screens, persisted), 5-tab bar,
10 core components, a functional Today screen (live AQI + recommendation logic).

**Hooks left open for Phase 2/3 (no rework needed):** `AppDelegate` (APNs),
`DeepLinkHandler`, `orders`/`subscriptions` tables, HealthKit usage strings,
order flow, Vaidya AI chat, workouts, subscriptions.

---

## Fonts

Cormorant Garamond and Plus Jakarta Sans (both SIL OFL) are bundled in
`Packages/HaleDesignSystem/Sources/HaleDesignSystem/Resources/Fonts` and
registered at runtime via Core Text. PostScript names are verified against the
`Font.custom(...)` references in `Typography.swift`.
