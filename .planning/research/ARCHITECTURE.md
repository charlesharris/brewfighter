# Architecture Research

**Domain:** Data-driven, UI-heavy collectible brewing RPG, native Swift/SwiftUI, iPhone portrait
**Project:** Brew Fighter
**Researched:** 2026-10-08 (replaces the 2026-10-06 DragonRuby version, which is obsolete)
**Confidence:** MEDIUM-HIGH overall.

- HIGH: Apple API availability (PhaseAnimator, KeyframeAnimator, `withAnimation` completion, Observation, `@Environment(Type.self)` are all iOS 17+; `Observations` async sequence is iOS 26+). Read from Apple documentation text via a markdown mirror (sosumi.ai).
- HIGH: SwiftPM mechanics (`.defaultIsolation`, `Bundle.module`, `.copy` vs `.process`) and Dictionary hash-seed randomization (Swift forums PSA).
- MEDIUM: Xcode 27 / Swift 6.4 / iOS 27 specifics. Secondary sources only (release writeups, forum threads, Nil Coalescing, Point-Free), not Apple primary pages.
- MEDIUM: The persistence and architecture recommendations. They are reasoned synthesis from this project's shape, not an industry standard.
- Items tagged `[VERIFY]` need a spike before a phase depends on them.

> **Environment note.** As of today (2026-10-08) iOS 27, Xcode 27 (Swift 6.4) shipped on 2026-09-14. Uploads must be built with the iOS 27 SDK from April 2027. Xcode 27 needs an Apple Silicon Mac. Brew Fighter will ship on this toolchain, so everything below assumes Xcode 27 / Swift 6 language mode.

---

## Executive Position (the opinionated version)

What carried over from the DragonRuby research, because it is platform-independent and still right:

1. **Three tiers of data, never mixed.** *Content* (immutable authored definitions, bundled JSON), *Profile* (persisted player state, ids only), *Session* (transient runtime state, never saved).
2. **The rules live in a pure domain package with no UI import.** Brewing, palate scoring, statuses, clue policy, lineage and progression are synchronous `(State, Input) -> (State, [Event])` functions over `Sendable` value types. They run headless under `swift test` and a CLI balance harness. This is the biggest quality lever for a game whose value is "the matchup puzzle is genuinely good".
3. **Encounters emit an event log. Presentation replays it.** Rules never wait on animation.
4. **Explainability is architecture.** Brewing and scoring return *ledgers* (per-source contributions), not just totals (design success criterion #2).
5. **Hidden information is a type boundary.** The UI receives a `PatronView`, never the true palate.

What is new for SwiftUI (the decisions this document makes):

6. **Plain "MV" with `@Observable`, not TCA and not MVVM-per-screen.** A small number of `@MainActor @Observable` objects (one `GameStore`, plus one session object per flow) adapt the pure domain to SwiftUI. The pure domain *is* the reducer layer; a framework on top buys a solo dev nothing.
7. **Navigation = custom chunky tab bar over per-tab `NavigationStack`s, with encounters as a `fullScreenCover`.** Modals are driven by one `Modal` enum at the root.
8. **Staged animation = authoritative state advances immediately; a *presentation* state lags behind and catches up beat by beat.** A `PlaybackDirector` task steps beats; `KeyframeAnimator` / `PhaseAnimator` / `Canvas` supply the juice. Skip = apply the remaining events with no animation, landing on the identical end state.
9. **Persistence = a versioned Codable JSON envelope in Application Support, written atomically by an actor.** Not SwiftData. GRDB is the documented escalation path.
10. **Content = JSON files per category in an SPM resource bundle, decoded into typed `Def` structs with phantom-typed ids and validated at load and in CI.**
11. **One local Swift package (`BrewKit`) holds everything that is not SwiftUI. The Xcode app target holds all UI.** Boundaries are enforced by target dependencies, the `package` access modifier `[VERIFY]`, and a lint test.

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│ L4  VIEWS  (App target, SwiftUI)                 reads Store/Session,    │
│  Features: Hub · Brew · Taps · Encounter · Town Map · Collection ·       │
│            Regulars Book · Recipe Tree · Settings · Onboarding           │
│  DesignSystem: Theme · ChunkyButton · AttributeBars · BeerGlassView ·    │
│            PatronPortrait · Meter · Toast · Haptics modifiers            │
├──────────────────────────────────────────────────────────────────────────┤
│ L3  APP MODEL  (App target, @MainActor, @Observable, NOT persisted)      │
│  GameStore (profile slices + intents) · BrewSession · EncounterSession   │
│  Router (per-tab paths, Modal) · PresentationQueue (unlock/reward toasts)│
│  Presentation (pure Swift): EncounterPresentation · BeatScript ·         │
│            PlaybackDirector                                              │
├──────────────────────────────────────────────────────────────────────────┤
│ L2  DOMAIN  (BrewKit/BrewDomain, PURE, nonisolated, Sendable values)     │
│  Brewing · Styles · Palate · Statuses · Encounter · Clues/Knowledge/     │
│  PatronView · Lineage · YeastBank · Regulars · Perks · Codex ·           │
│  Progression · World · Bosses (rule overrides)                           │
├──────────────────────────────────────────────────────────────────────────┤
│ L1  DATA  (BrewKit/BrewModel, BrewContent, BrewPersistence)              │
│  Model: ids · AttributeVector · Defs · Recipe/Beer/Profile · Events ·    │
│         Rng        Content: JSON bundle · loader · validator · tuning    │
│  Persistence: SaveEnvelope · Migrations · ProfileStore (actor)           │
├──────────────────────────────────────────────────────────────────────────┤
│ L0  PLATFORM ADAPTERS (App target, behind small protocols)               │
│  Audio · Haptics (sensoryFeedback) · FileSystem · Clock · StoreKit seam  │
└──────────────────────────────────────────────────────────────────────────┘
 Dependency rule: a layer may use only layers BELOW it. L2 never imports SwiftUI,
 Observation, or Combine. L4 reads L2 only through L3 (exception: pure display math).
 Test/harness tooling (brew-harness, BrewKit tests) sits beside L2 and uses L1+L2 only.
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `BrewfighterApp` (composition root) | Boot: load catalog, load profile, build `GameStore`, install environment, scene-phase save | `@main App`; optional `@State var store: GameStore?` set in `.task` (async load) |
| `GameStore` | Owns the authoritative `Profile` value; exposes narrow, diff-assigned read slices; exposes intent methods (`brew`, `setTap`, `startEncounter`, `finishEncounter`); applies domain events via `Progression`; schedules autosave | `@MainActor @Observable final class` |
| `BrewSession` | Draft recipe + live `BeerPreview` (recomputed once per edit); masks undiscovered traits as "?" | `@Observable`, created per brew-flow; `apply(_ edit: DraftEdit)` |
| `EncounterSession` | Holds *truth* (`EncounterState`, ObservationIgnored) and *shown* (`EncounterPresentation`); runs playback; surfaces `phase` | `@Observable`, created per encounter cover |
| `Router` | Per-tab `NavigationPath`/`[Route]` + root `Modal?` | `@Observable`, `@Environment`-injected |
| `PlaybackDirector` + `BeatScript` | Convert events into timed beats; step them; support skip, Reduce Motion, injected sleep | Pure beat generation + `Task` |
| `DesignSystem` | Reusable chunky UI: buttons, meters, attribute bars, glass, portraits, toasts | SwiftUI `View`s + `ViewModifier`s + `ButtonStyle`s |
| `BrewModel` | Value types shared by every other target: `ID<Tag>`, `Attribute`, `AttributeVector`, Defs, `Recipe`, `Beer`, `Profile`, `DomainEvent`, `Rng` | Foundation-only, `Sendable`, `Codable` |
| `BrewDomain` | All rules. See per-system notes below | `enum` namespaces of `static` pure functions |
| `BrewContent` | JSON resource bundle, `ContentLoader`, `ContentCatalog`, `ContentValidator`, `Tuning`, string/dialogue tables | `Bundle.module`, `JSONDecoder` |
| `BrewPersistence` | `SaveEnvelope`, `Migrations`, `ProfileStore` | `actor` + atomic file writes |
| `BrewFixtures` | Canonical test/preview catalogs, profiles, beers, patrons | Plain builders; used by tests, previews, harness |
| `brew-harness` | Headless balance/solvability runner | SwiftPM `executableTarget` |

### Recommended Project Structure

```
brewfighter/
├── App/
│   ├── Brewfighter.xcodeproj
│   └── Brewfighter/                      # app target: iPhone only, portrait, iOS 18 floor [decision]
│       ├── BrewfighterApp.swift          # @main, composition root, scenePhase save hook
│       ├── AppModel/                     # GameStore, BrewSession, EncounterSession, Router, Settings
│       ├── Presentation/                 # EncounterPresentation, BeatScript, PlaybackDirector (pure Swift, no SwiftUI import)
│       ├── Features/
│       │   ├── Hub/  Brew/  Taps/  Encounter/  TownMap/
│       │   ├── Collection/  RegularsBook/  RecipeTree/  Settings/  Onboarding/
│       ├── DesignSystem/                 # Theme, buttons, meters, AttributeBars, BeerGlassView, PatronPortrait
│       ├── Platform/                     # AudioClient, HapticsClient, EntitlementsClient (StoreKit seam)
│       └── Resources/                    # Assets.xcassets (art), Fonts, Sounds, Localizable.xcstrings, PrivacyInfo.xcprivacy
├── Packages/BrewKit/
│   ├── Package.swift
│   ├── Sources/
│   │   ├── BrewModel/
│   │   ├── BrewDomain/
│   │   │   ├── Brewing/   (Mash, Boil, Ferment, Condition, Finalize, Simulate)
│   │   │   ├── Styles/  Palate/  Statuses/  Encounter/  Clues/
│   │   │   ├── Lineage/  YeastBank/  Regulars/  Codex/  Progression/  World/  Bosses/
│   │   ├── BrewContent/
│   │   │   ├── Loader/ Validator/
│   │   │   └── Resources/Content/        # hops.json grains.json yeasts.json adjuncts.json styles.json
│   │   │                                 # statuses.json patrons/*.json bosses.json locations.json
│   │   │                                 # perks.json tuning.json strings/ manifest.json
│   │   ├── BrewPersistence/
│   │   ├── BrewFixtures/
│   │   └── brew-harness/
│   └── Tests/  BrewModelTests · BrewDomainTests · BrewContentTests · BrewPersistenceTests · BalanceTests
│               Fixtures/saves/v1.json v2.json ...   # frozen real saves, one per schema version
├── tools/                                # art generation/post-process, asset manifest check, content lint
└── scripts/test                          # `swift test` in package + xcodebuild test for app target
```

### Structure Rationale

- **One package, several targets, not several packages.** A solo developer wants a single `Package.swift` to maintain. Target boundaries still give compile-time dependency direction (`BrewDomain` cannot see `BrewPersistence` unless it declares it) and let tests build only what they need.
- **UI stays in the app target.** Splitting features into modules is a team-scale tool. The design system can be promoted to its own local package later if previews or build times demand it.
- **`Presentation/` is pure Swift inside the app target** so it can be unit-tested without a host app and promoted into a package target without edits.
- **`BrewKit` supports macOS** (`platforms: [.iOS(.v18), .macOS(.v15)]`, Foundation only). That is what makes `swift test` and `swift run brew-harness` run on the Mac in seconds, with no simulator boot. This is the headline productivity win of the whole structure.
- **Def *types* live in `BrewModel`, def *data* lives in `BrewContent`.** `BrewDomain` needs the types to compute but must not depend on how they are loaded. The domain receives a `ContentCatalog` as a parameter (never a global).

---

## Concurrency & Isolation Setup

- **App target:** Xcode 26+ new projects default to `MainActor` default isolation plus Approachable Concurrency. Keep the defaults. Stores and sessions are implicitly `@MainActor`.
- **`BrewKit` package:** leave the SwiftPM default (nonisolated). Do **not** add `.defaultIsolation(MainActor.self)`. Every domain type is a `Sendable` struct/enum; every domain function is synchronous and nonisolated, so it can be called inline from the main actor for live preview and from a `TaskGroup` in the harness. SwiftPM exposes `.defaultIsolation(_:)` from tools-version 6.2; new packages default to nonisolated and non-Approachable (Use Your Loaf; Donny Wals).
- **`swift-tools-version: 6.2` or later** gives Swift 6 language mode by default. Known rough edge: with MainActor default isolation in a *package*, `Bundle.module` and `CodingKey` conformances can warn. A further reason to keep the package nonisolated.
- **`ProfileStore` is the only `actor`.** Encoding and file IO happen off the main thread there.

```swift
// Packages/BrewKit/Package.swift  (illustrative)
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BrewKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "BrewModel", targets: ["BrewModel"]),
        .library(name: "BrewDomain", targets: ["BrewDomain"]),
        .library(name: "BrewContent", targets: ["BrewContent"]),
        .library(name: "BrewPersistence", targets: ["BrewPersistence"]),
        .library(name: "BrewFixtures", targets: ["BrewFixtures"]),
    ],
    targets: [
        .target(name: "BrewModel"),
        .target(name: "BrewDomain", dependencies: ["BrewModel"]),
        .target(name: "BrewContent", dependencies: ["BrewModel"],
                resources: [.copy("Resources/Content")]),   // .copy keeps folder structure; .process flattens
        .target(name: "BrewPersistence", dependencies: ["BrewModel"]),
        .target(name: "BrewFixtures", dependencies: ["BrewModel", "BrewContent"]),
        .executableTarget(name: "brew-harness",
                          dependencies: ["BrewDomain", "BrewContent", "BrewFixtures"]),
        .testTarget(name: "BrewDomainTests",
                    dependencies: ["BrewDomain", "BrewContent", "BrewFixtures"]),
        // ... BrewContentTests, BrewPersistenceTests, BalanceTests (Swift Testing)
    ]
)
```

**Deployment floor (decision for the roadmap):** every API this architecture needs is iOS 17.0+ (`@Observable`, `@Environment(Type.self)`, `PhaseAnimator`, `KeyframeAnimator`, `withAnimation(completion:)`, `sensoryFeedback`). The Xcode 27 `@State` lazy-init fix back-deploys to iOS 17 when built with Xcode 27. **Recommend iOS 18.0**: it adds `navigationTransition(.zoom)` and the modern `Tab` API at a small reach cost (iOS 26 was on 79% of iPhones by June 2026). iOS 17 is viable if reach matters more than polish. Do not use iOS 26-only APIs (e.g. `Observations`) in v1.

---

## Architectural Patterns

### Pattern 1: Pure domain reducers returning `(state, events)`

**What:** Every multi-step rule is `static func f(_ state: S, _ input: I, _ catalog: ContentCatalog) -> (S, [DomainEvent])`. No `async`, no clocks, no `Date()`, no global RNG, no SwiftUI. Randomness is an explicit `inout Rng`.
**When to use:** Encounter, brewing, yeast repitch, progression. All of L2.
**Trade-offs:** + trivially testable; + events feed animation, the "why" breakdown, the clue notebook and transcripts from one source; + the harness calls the same functions the UI does. - slightly more allocation than inline mutation (irrelevant at 3 pours).

```swift
public enum Encounter {
    public static func serve(
        _ state: EncounterState, tap: Int, catalog: ContentCatalog
    ) -> (EncounterState, [EncounterEvent]) {
        // 1. palate = Patron.palate(for: state.patron, context: state.context, catalog)
        // 2. components = Palate.score(beer.attrs, palate, state.statuses, state.lastServed)  // ledger
        // 3. statuses' = Statuses.advance(state.statuses, afterServing: beer)
        // 4. facts = Clues.select(components, patron, knowledge)          // >= 1 new fact until known
        // 5. return (state', [.scored(components), .statusApplied(..), .clue(fact), .satisfaction(from:to:), ...])
    }
}
```

### Pattern 2: "MV" adapters: observable store over a value-typed Profile

**What:** `GameStore` keeps the real `Profile` as an `@ObservationIgnored` value and publishes **narrow slices** (`taps`, `inventory`, `recipes`, `yeastBank`, `knowledge`, `regulars`, `codex`, `day`), each assigned only if changed.
**Why (this is the key SwiftUI trap for this project):** Observation tracks at the property level. If views read `store.profile.taps` and `profile` is one big observable struct property, *any* change to *any* field invalidates *every* view that read *any* part of it. With a 1000-recipe profile and 16-bar attribute views that becomes an invalidation storm. Slices plus manual `!=` guards keep invalidation proportional to what changed. (Apple's WWDC25 Instruments session names unnecessary updates and long body updates as the main hitch sources.)
**Trade-offs:** + fine-grained updates without extra frameworks; - a `publish` function to maintain (one line per slice, covered by a test that asserts every `Profile` field is mirrored).

```swift
@MainActor @Observable
final class GameStore {
    let catalog: ContentCatalog                       // immutable; also injected via @Entry
    @ObservationIgnored private var profile: Profile  // source of truth (value type)
    @ObservationIgnored private let saver: ProfileSaving
    private(set) var taps: [BeerID?]
    private(set) var inventory: Inventory
    private(set) var recipes: RecipeBook
    // ... one stored slice per Profile concern

    func commit(_ events: [DomainEvent]) {
        let next = Progression.apply(events, to: profile, catalog: catalog)
        publish(next)
        saver.scheduleSave(next)                      // debounced; flushed on scenePhase .background
    }
    private func publish(_ new: Profile) {
        if new.taps != taps { taps = new.taps }
        if new.inventory != inventory { inventory = new.inventory }
        // ...
        profile = new
    }
}
```

**Environment injection:** inject the store with `.environment(store)` and read with `@Environment(GameStore.self)`. Inject immutable and non-observable collaborators (`catalog`, `clock`, `audio`, `haptics`) through `@Entry` environment values so they never trigger invalidation. Rows take **ids**, not whole models, and re-read their own slice (stable identity: never `UUID()` in `body`; never use a mutable `Hashable` value as a list id).

**Root model ownership (Xcode 27 note):** `@State` became a macro in Xcode 27. The initial-value expression for an `@Observable` is now evaluated lazily and once, back-deployed to iOS 17 (builds with Xcode 27 only). Do not both give `@State` a default value *and* assign it in `init`; that no longer compiles. Because the store needs an async load (catalog + profile), use `@State private var store: GameStore?` and build it in `.task`, with a launch view until it exists. For models parameterized by a parent value, use `.task(id:)` rather than constructing in `init`.

### Pattern 3: Authoritative state vs presentation state (event-log playback)

**What:** `Encounter.serve` runs synchronously and advances *truth* immediately. The UI never renders truth. It renders `EncounterPresentation` (shown satisfaction, shown breakdown lines, shown statuses, patron mood, dialogue line, revealed clues). `BeatScript.make(events) -> [Beat]` groups events into timed beats. `PlaybackDirector` applies each beat's events to `EncounterPresentation` inside `withAnimation`, fires an effect cue, and sleeps for the beat's hold.
**Why:** (a) skip is exact: apply all remaining events with no animation and you are at the same presentation state; (b) tests inspect `[Beat]` and `EncounterPresentation` as data; (c) hidden information cannot leak early, because a clue is not in `shown` until its beat plays; (d) Reduce Motion just shortens holds and drops effects.

```swift
@MainActor @Observable
final class EncounterSession {
    enum Phase { case choosing, playing, finished }
    private(set) var phase: Phase = .choosing
    private(set) var shown = EncounterPresentation()   // what the player has been SHOWN
    private(set) var cues = EffectCues()               // counters; views use .keyframeAnimator(trigger:)
    @ObservationIgnored private var truth: EncounterState
    @ObservationIgnored private var playback: Task<Void, Never>?
    @ObservationIgnored private let sleep: @Sendable (Duration) async throws -> Void   // injected: tests pass { _ in }

    func serve(tap: Int) {
        guard phase == .choosing else { return }
        let (next, events) = Encounter.serve(truth, tap: tap, catalog: catalog)
        truth = next; phase = .playing
        let beats = BeatScript.make(events, reduceMotion: reduceMotion)
        playback = Task { await play(beats) }
    }
    func skip() { playback?.cancel() }                 // play() fast-forwards the remainder

    private func play(_ beats: [Beat]) async {
        var i = 0
        while i < beats.count, !Task.isCancelled {
            let beat = beats[i]
            withAnimation(beat.animation) { shown.apply(beat.events) }
            cues.fire(beat.cue)
            try? await sleep(beat.hold)
            i += 1
        }
        for beat in beats[i...] { shown.apply(beat.events) }   // skip path: no animation
        phase = truth.isOver ? .finished : .choosing
    }
}
```

### Pattern 4: Choosing the right animation tool (all verified iOS 17+)

| Need | Use | Notes |
|------|-----|-------|
| Variable, event-driven sequencing of a battle | `PlaybackDirector` (`Task` + injected sleep) | Owns timing. Do not chain game logic through animation completion callbacks. |
| State change with spring/ease (meter fill, badge in) | `withAnimation { shown.apply(...) }` | The default workhorse. |
| One-shot multi-property choreography with precise curves (score pop: scale+offset+opacity; patron recoil; meter overshoot) | `KeyframeAnimator(initialValue:trigger:content:keyframes:)` or `.keyframeAnimator` | Content closure runs every frame, so keep it cheap. Trigger with a counter from `cues`. |
| Small fixed set of discrete visual states (idle patron bob, glass tilt-pour-settle, button press) | `PhaseAnimator(_:trigger:content:animation:)` | Phases are a fixed array; it is not an event player. |
| Continuous particles (foam, bubbles, confetti, ambient dust) | `TimelineView(.animation(paused:))` + `Canvas` | Particle state is a small value sim stepped by the timeline date. Pause when off-screen. Canvas content is not accessible: pair with real views/labels. |
| Chaining a view-level step after a specific animation settles | `withAnimation(_:completionCriteria:_:completion:)` | Use sparingly. |
| Numbers that feel good (satisfaction, coins) | `.contentTransition(.numericText())` + animation | |
| Taps feel | `.sensoryFeedback(_:trigger:)` | Respect a Settings haptics toggle. |

SpriteKit (`SpriteView`) is a fallback **only** if Canvas particle counts cause measurable hitches on the oldest supported device `[VERIFY]` with the Instruments 26 SwiftUI template. Do not start there.

### Pattern 5: Attribute vector + contribution ledger

**What:** One `enum Attribute: CaseIterable` (the ~16 sensory attributes). `AttributeVector` is a fixed-size array indexed by it (deterministic order, fast, trivially `Codable` as a keyed object by raw name). Brewing stages *append* ledger entries rather than mutating a number; scoring does the same with components.

```swift
public struct Contribution: Codable, Sendable, Hashable {
    public var attr: Attribute
    public var delta: Double
    public var source: Source        // .ingredient(IngredientID) / .technique(..) / .yeast(..) / .status(..)
    public var stage: Stage          // .mash / .boil / .ferment / .condition / .finalize
    public var why: ReasonKey        // localizable reason key, e.g. "boil.bittering_60min"
}
// Brewing.simulate(recipe, yeast, catalog) -> BeerResult { attrs, ledger, derived(og/fg/abv/ibu/srm), traits }
```

Keep raw sim values (OG, IBU, attenuation) separate from 0-10 sensory attributes via curves in `Tuning`. Model ABV as a derived stat and expose *perceived alcohol* as a 0-10 attribute (decision needed in the brewing phase; both tolerance and Buzzed key off it).

### Pattern 6: Declarative rules, interpreted by one evaluator

**What:** Synergies, status triggers/effects, boss modifiers, perks and unlock conditions are Codable *data* (`Predicate`, `Effect`) interpreted by one `Rules` evaluator, so the UI can describe a rule from data (tooltips, Regulars Book).
**Swift specifics:** the DragonRuby version used a lambda escape hatch. JSON content cannot. Instead, bosses use a **closed enum of named built-in rule kinds, parameterized by data** (`styleConformance`, `commonnessPenalty`, `trendPalette`, `adjunctPenalty`), implemented in Swift. Write `init(from:)`/`encode(to:)` for these enums by hand with a `"type"` discriminator; the synthesized `Codable` shape for enums with associated values is verbose and awkward to author by hand, and a case rename would silently break content or saves.

### Pattern 7: Hidden-information boundary (`PatronView`)

**What:** `PatronDef` holds the true palate. `Knowledge.view(patron:, knowledge:) -> PatronView` returns only what the player has learned. Views and sessions receive `PatronView` only; `Palate.score` receives the truth and is called only from `Encounter` inside `BrewDomain`.
**Enforcement, strongest first:**
1. **Compile-time via Swift's `package` access level** `[VERIFY]`: declare `PatronDef.palate`, `PatronDef.hidden` and boss rule parameters `package`. Targets inside `BrewKit` (Domain, Content, Fixtures, harness) can read them. The Xcode app target is a different build "package" and cannot. A 30-minute spike in the scaffolding phase confirms this behaves as expected across an Xcode-project-plus-local-package boundary. This keeps the UI inside the app target (not a `BrewKit` target) for this reason.
2. **Fallback:** a lint test (`scripts/test`) that fails if `App/` references the palate fields or `catalog.patrons[...].palate`.
3. **Test:** a `PatronView` snapshot test proving a fresh player's view contains no values.
**Clue policy (anti-frustration, criterion #6):** each scored component maps to candidate facts; the policy reveals the most informative unrevealed fact and guarantees at least one new fact per pour until the patron is fully known. Style names are soft clues only (design constraint). Knowledge is committed to the Profile **after every pour**, so a force-quit mid-encounter never loses revealed clues (ENC-06).
**Dynamic palates:** `Patron.palate(for:context:)` is a function (Influencer trends, Buzzed). Build the hook now.

### Pattern 8: Navigation = custom tab bar, per-tab stacks, root modal enum

**What:**
- Root view = `switch` over `selectedTab` with a **custom chunky bottom bar** (Adventure Capitalist feel; thumb-zone, one-handed). Each tab owns an `@Observable Router` held in root `@State`, so its path survives tab switches even though the unselected view is torn down.
- Each tab: `NavigationStack(path: $router.path)` with `navigationDestination(for: Route.self)` declared once at the stack root. `Route` is a `Hashable & Codable` enum carrying **ids only** (`.beer(BeerID)`, `.recipeFamily(RecipeID)`, `.patronEntry(PatronID)`).
- Root `Modal` enum, presented with `.fullScreenCover(item:)` / `.sheet(item:)` at the root: `.encounter(EncounterSetup)`, `.brewResult(BeerID)`, `.onboarding(Step)`, `.settings`, pickers (ingredient, hop timing).
- **Encounters are a `fullScreenCover`, not pushed routes.** They are atmospheric (no nav bar), must not be swipe-dismissible (`.interactiveDismissDisabled()`), have their own internal phase machine (`choosing -> playing -> result`), and are Session-only, so nothing needs state restoration. Sheets may be nested inside the cover (beer detail, clue notebook).
- **Rewards and unlocks go through a `PresentationQueue`** on the hub rather than being presented in the same frame as a dismissal. This avoids the known SwiftUI sheet/cover dismiss-then-present race and guarantees unlock celebrations are never dropped.
- Polish: `matchedTransitionSource` + `navigationTransition(.zoom)` (iOS 18) for collection card to detail.
**Why a custom bar and not `TabView`:** since Xcode 27, the `UIDesignRequiresCompatibility` opt-out of Liquid Glass is ignored for apps built with the iOS 27 SDK (apps linked against the 26 SDK keep it; uploads must use the 27 SDK from April 2027). System tab bars and navigation bars will therefore be Liquid Glass, which clashes with a flat, chunky, cartoon skin. Hide the system nav bar on game screens and draw your own chrome; let system sheets, alerts and the keyboard look native. Add accessibility traits (`.isTabBar` and `.isSelected`) to the custom bar. `[VERIFY]` in a spike that the custom bar plus safe-area and home-indicator behavior is acceptable on small and large iPhones.

### Pattern 9: Generic collection browser (build the Pokédex once)

**What:** Ingredients, yeasts, recipes/beers, patrons, techniques are all "things you discover, own, and browse". One `CollectionBrowser<Item: CollectionItem>` (LazyVGrid/list, filter chips, sort, completion %, detail destination) where `CollectionItem` supplies `id`, `tile`, `detail`, `state` (`unseen/seen/owned/mastered`), `sortKeys`. Regulars Book and Yeast Bank are the same view with a custom detail. In `Profile`, one `codex[kind][id] = state` table.
**Why:** the design has about six collection UIs; bespoke screens are the largest UI cost in the project.

### Pattern 10: Domain-event queue (Progression)

**What:** domain operations return `DomainEvent`s (`beerBrewed`, `patronServed`, `encounterWon`, `ingredientAcquired`, `yeastMutated`). `GameStore.commit` passes them to `Progression.apply`, which updates codex, Regulars stage inputs, unlocks, tutorial triggers and rewards, and returns the new `Profile`. Brewing never knows winning unlocks a farmer's grain. Keep the vocabulary small (about 15 events).

### Pattern 11: Seedable, serializable RNG

Swift's `SystemRandomNumberGenerator` cannot be seeded or saved. Implement `struct Rng: RandomNumberGenerator, Codable, Sendable` (SplitMix64 or xoshiro) whose state lives in `Profile`, pass `inout Rng` to the few stochastic functions (yeast mutation, drops), and **record outcomes into results** (a mutated culture stores its `mutationSeed`). Encounters themselves are fully deterministic: it is a deduction game.

### Pattern 12: Derived, never stored

Regulars stage (`Seen -> Served -> Impressed -> Regular -> Friend`), beer style label (BREW-06), completion percentages and the lineage index are **derived** from stored facts plus thresholds in Content. Rebalancing thresholds can then never desync a save.

---

## Data Flow

### The Three Tiers

```
CONTENT (bundled, immutable)              PROFILE (persisted, Codable, ids only)       SESSION (transient)
────────────────────────────              ──────────────────────────────────────       ───────────────────
hop/grain/adjunct/yeast Defs              schemaVersion, simVersion, contentVersion    Router paths, Modal
style, status, trait, ability Defs        rng state, day, flags, unlocks               BrewSession (draft recipe, preview)
patron Defs (TRUE palate), boss Defs      inventory {IngredientID: qty}                EncounterSession (truth + shown)
location, perk, unlock-rule Defs          yeastBank {instances w/ generation, mutations} PresentationQueue
Attribute list + display metadata         recipes {id -> Recipe(parents:[id], choices)} cursor/scroll, toasts, animation cues
Tuning (scoring weights, curves)          beers {id -> {recipeID, snapshot, simVersion}}
String tables + dialogue tables           taps [BeerID? x 6], lineup presets
          ▲                               codex, knowledge {patronID -> facts}
          │ resolved by id at point       patronStats {served, best, wins}
          └──────────────────────         settings (separate file; not in a slot)
```

**Rules:**
1. **Ids in state; Defs resolved at point of use.** Never store a Def (or any class instance, especially an `@Observable`) in `Profile`. Saves survive content edits.
2. **A beer is a *result*:** `Beer = f(recipe, yeastInstance, catalog, tuning)`. Persist the `recipe` (truth) and a cached `snapshot` (attrs + ledger) stamped with `simVersion`. On load, if `simVersion` is stale, recompute: a balance patch intentionally reaches existing saves.
3. **The yeast *instance* (generation, trait deltas) is an input to brewing**, not just a `YeastID`.
4. **Save at safe points** (hub, after encounter result, after brew confirm, each pour's knowledge commit, scene-phase background). Encounter *state* is never persisted; its *outcome* and learned *knowledge* are.

### Intent -> Domain -> Commit -> Save

```
Tap in View
   │  store.serveBeer / session.serve / store.brew ...
   ▼
Session or Store (MainActor)
   │  calls pure domain:  (state', events) = Domain.fn(state, input, catalog[, &rng])
   ▼
events ──► Presentation (EncounterSession: beats → shown state → Views)
   │
   └────► GameStore.commit(events) ─► Progression.apply ─► new Profile
                                          │
                                          ├─► publish slices (diff-assign) ─► Views re-render
                                          └─► ProfileSaver.scheduleSave ─► ProfileStore (actor) ─► atomic file write
```

### Encounter flow (heart of the game; fully headless-testable)

```
EncounterSetup(patronID, tapBeerIDs)  ──►  Encounter.start(...)  ──► truth0 {satisfaction 0, poursLeft 3, statuses []}
loop (<= 3 pours):
  view: player taps tap #n
  session.serve(n) ─► Encounter.serve(truth, n) ─► (truth', events)
        events = [scored(components…), statusApplied…, clue(fact), patronLine(key), satisfaction(from,to), over?]
  BeatScript.make(events) ─► [Beat]  ─► PlaybackDirector ─► shown (animated)   (skip => same end state)
  store.commit(knowledge events)   // clues persist per pour
end: store.commit(encounterWon/Lost + rewards) ─► Progression ─► Profile ─► autosave ─► cover dismisses ─► PresentationQueue plays unlocks
```

### Content boot flow

```
App launch ─► ContentLoader.load(Bundle.module) ─► decode Defs (Codable) ─► ContentCatalog (immutable)
          └─► ContentValidator.validate(catalog)  ─► DEBUG: assertionFailure on issues; Release: preconditionFailure
                 (content is code-signed with the app: a load failure is a developer bug, not a user error)
          └─► ProfileStore.load() ─► migrate ─► Profile ─► GameStore(catalog, profile)
```

---

## Subsystem Notes

### Brewing engine
- Pipeline `mash -> boil -> ferment -> condition -> finalize`; each stage `(acc, choices, catalog) -> acc'` appending to the ledger. Mash temperature drives body/sweetness/fermentability; boil drives bitterness/aroma via utilization curves; fermentation drives attenuation/esters/phenols/funk via yeast Def x temperature (out-of-range temperature yields teachable off-flavor contributions); conditioning applies specialized traits.
- **Live preview** is a pure sync call executed once per `BrewSession.apply(_ edit:)` (microseconds). No debouncing or `Task` needed. Masking of undiscovered traits as "?" (BREW-03) uses a `Knowledge`-derived mask in the preview, the same boundary idea as `PatronView`.
- **Determinism rules (Swift-specific, verified):** Swift randomizes Dictionary/Set hash seeds per process, so iteration order varies between launches. Never iterate a `Dictionary` to score, build a ledger or emit events. Iterate `Attribute.allCases`, sorted keys, or arrays. Setting `SWIFT_DETERMINISTIC_HASHING=1` in CI hides the problem; do not rely on it. Use `Int` fixed-point for satisfaction scoring (exact repro, stable thresholds) and `Double` for brewing curves with explicit rounding at the boundary `[decision for scoring-math phase]`.
- Budget **style classification** (`Styles.classify(attrs, derived)`) and **rarity/commonness** metadata into `Beer` from the start. Boss rules (Beer Judge, Untappd Guy) need them.

### Recipe lineage
- Recipes are immutable versions: `Recipe { id, parents: [RecipeID], createdSeq, choices, diffTags, archived }`. **`parents` is an array** so crossbreeding stays a data change instead of a migration, although v1 only ever writes 0 or 1 parent. "Modify" = create a child; "delete" = `archived = true`, never destructive (COLL-04).
- `LineageIndex` (children map, roots, depth, ancestors/descendants) is a pure function built at load from `recipes`. At 100-1000 nodes, in-memory graph queries are trivial; **this is not a reason to adopt a database.**
- Persist `parents` from the **first** saved recipe. Ancestry cannot be reconstructed later. The tree UI can arrive late; the data cannot.
- Family-tree rendering: a custom SwiftUI `Layout` (or Canvas edges plus positioned views) over a precomputed tidy-tree layout from the index. Deep research item when that phase arrives.

### Collections
- **Yeast Bank:** instances `{cultureID, generation, traitDeltas, lineage}`; `YeastBank.repitch(instance, rng: inout Rng) -> (instance', events)`. Mutation forks, never overwrites (COLL-06).
- **Ingredients:** gameplay identity = trait bundles + synergy `Rule`s + drawbacks as data; inventory is `[IngredientID: Int]`.
- **Regulars:** stage derived; passive benefits are `effects: [Effect]` in the patron Def read through `Perks.query(profile, key)`; no per-patron special-case code.

### World
Location Def `{ id, kind, name, unlock: Predicate, patrons: [spawn rules], sources: [acquisition], art keys }`. Node-map travel with each location as an illustrated backdrop plus hotspots (patrons, shop counter, brew station) as plain SwiftUI buttons over an `Image`. No tile maps, collision or camera. Render the node map as a `ScrollView` of positioned node buttons with Canvas-drawn paths. A single integer `profile.day`; decide in design whether brewing consumes days (BREW-07 says yes).

### Bosses
Boss Def = patron Def + `rules: [RuleKind]` (named built-ins parameterized by data, see Pattern 6). Same `Encounter` engine, no special code path.

### Content pipeline
- **Format:** JSON per category, `Codable` into `Def` structs defined in `BrewModel`. Not Swift literals (large literal compile times; not AI/tool-authorable), not plists (worse diffs, same Codable). Bundled with `.copy("Resources/Content")` so folders (`patrons/*.json`) are preserved and filename collisions cannot flatten. Always access via `Bundle.module`.
- **Typed ids:** `struct ID<Tag>: RawRepresentable, Hashable, Codable, Sendable, ExpressibleByStringLiteral` with `typealias HopID = ID<HopTag>`. A `HopID` cannot be passed where a `YeastID` is expected; cross-references in JSON are plain strings validated at load.
- **Validation (`ContentValidator`)** returns `[Issue]`: duplicate id, unknown attribute name, unknown ingredient/trait/status/location/patron reference, patron preference outside the attribute set, missing localization key, **missing art asset** (checked against an asset manifest generated from `Assets.xcassets` by `tools/`), patron with no hidden-preference clue path, unreachable location. Runs in tests (CI gate) and at DEBUG launch.
- **Tuning:** `tuning.json` (scoring weights, status magnitudes, attribute curves) is part of `ContentCatalog`. The harness accepts `--tuning path.json` and `--content-dir path` overrides, so balance sweeps need no recompile. This replaces the DragonRuby "single-file tuning for hot reload" rule.
- **Localization-ready (PLAT-06):** content holds *keys* (`"nameKey": "patron.darryl.name"`); strings live in a String Catalog (`.xcstrings`). Domain events carry keys and structured `Fact`s, never prose. Dialogue (ENC-03) is a `DialogueTable` mapping `(patronID or archetype, factKind, polarity) -> lineKey` with archetype fallback, so a clue line is always tagged with its underlying fact.
- **Art:** convention `portrait.<patronID>.<mood>`, `ingredient.<id>`, `location.<id>`, resolved in the asset catalog. The validator flags missing art so content ships before art, and regenerated AI art drops in without code changes. Keep a provenance manifest (tool, prompt, seed) beside the source images.
- **Beer visuals are procedural and derived:** `BeerVisualSpec` (SRM color, head height/retention, carbonation, glass type) is a pure function of the `Beer` in the domain (testable). `BeerGlassView` renders it with SwiftUI shapes/Canvas. The shareable beer card (COLL-11) uses `ImageRenderer`.

### Persistence

**Decision: versioned Codable JSON envelope, in Application Support, written atomically by `actor ProfileStore`.**

| Option | Verdict | Reasoning |
|--------|---------|-----------|
| **Codable JSON file (recommended)** | Use | Domain is pure value types: persisting them directly needs no mapping layer. Fixtures are diffable text. Tests are headless. Profile is small (about 1 MB at 1000 recipes). Whole-file atomic write is simple and robust. |
| SwiftData | Reject for v1 | `@Model` classes are reference types bound to a framework; our pure-value domain would need a second mapping layer, so no boilerplate is saved. iOS 27 improved it (sectioning, observers, `.codable` attributes) but `ModelActor` still runs on the main thread unexpectedly and Codable attributes cannot participate in predicates, sorting or migrations. `@Query` brings nothing, since the store already holds in-memory slices. Reconsider only if CloudKit sync becomes a requirement. |
| GRDB (7.x, full Swift 6 support) | Documented escalation | Choose if the profile grows to many MB, or you want queryable history (every encounter log, analytics). Put it behind the same `ProfileStore` protocol so the swap is local. Adds a dependency and a SQL schema. |

- **Envelope:** `{ schemaVersion, simVersion, contentVersion, savedAt, playtimeSeconds, profile }`. Encode with `.sortedKeys`, ISO-8601 dates, ids as strings, and hand-written Codable for enums with associated values (explicit discriminators).
- **Additive evolution is free:** new fields decode with `decodeIfPresent` plus a default. Only structural changes need a migration.
- **Migrations:** small `v -> v+1` functions on the raw JSON tree (`[String: Any]`), then decode current `Profile`. No frozen copies of old types. **Every schema version ships a frozen real save in `Tests/Fixtures/saves/`, and a test loads each one through the full chain.** This is the highest-leverage persistence test.
- **Atomic write + backup:** encode in the actor, write to a temp file, decode-verify it, then `replaceItemAt` the live file, keeping the previous good file as `profile.bak.json`. On decode failure, fall back to the backup and surface a recovery message. Refuse to load a save with `schemaVersion` newer than the app.
- **When to save:** after domain commits (debounced about 1 s), after each pour's knowledge commit, and **immediately on `scenePhase == .background`** (iOS can kill a backgrounded app at any time). A force-quit mid-encounter restarts at the hub: no resumable encounter state, clues retained, and the loss cost (ENC-06) applies or not by explicit design `[decision]`.
- **Backup/sync:** Application Support is included in iCloud/device backup by default, which gives new-phone restore for free. CloudKit/Game Center sync is v2.
- **Settings** live in a separate small file (or `UserDefaults`), cross-save. If `UserDefaults` is used, declare the reason in `PrivacyInfo.xcprivacy` `[VERIFY]` current required-reason API list at submission time.

### Testing & balance harness
- **Runner:** Swift Testing in `BrewKit`; `swift test` on the Mac. Use parameterized tests (`@Test(arguments: catalog.patronIDs)`) for per-patron solvability.
- **Suites that earn their keep:** (1) golden brews (fixed recipe to attribute ranges); (2) "two IPAs differ": score variance across IPA-styled beers vs one patron (encodes the design's critical constraint); (3) solvability: every patron has a <= 3-pour sequence from at least one plausible lineup reaching 100, none wins on pour 1 with zero info (PLAT-07: >= 70% solvable, >= 4 best-in-class archetypes); (4) determinism: same inputs, same events, run in two processes without `SWIFT_DETERMINISTIC_HASHING`; (5) save fixtures through all migrations; (6) content validation; (7) `PatronView` hides truth; (8) `BeatScript`/`EncounterPresentation` skip equivalence (animated end state == skipped end state).
- **`brew-harness`:** `swift run -c release brew-harness --patrons all --lineups enumerate --tuning t.json` fans out with a `TaskGroup` (the domain is nonisolated and `Sendable`) and prints JSON/CSV plus a text transcript renderer for any encounter.
- **App-target tests:** UI logic that must be covered (`PlaybackDirector` with an injected instant sleep, `Router`, store slice-mirroring) uses Swift Testing in the app test target. Previews use `BrewFixtures`.

---

## Anti-Patterns

### Anti-Pattern 1: A ViewModel per screen that re-implements rules
**What people do:** reflexive MVVM: `BrewViewModel` computes attributes, `EncounterViewModel` scores pours.
**Why it's wrong:** no headless tests, no harness, rules fork between preview and encounter.
**Do this instead:** views and thin sessions call `BrewDomain`; sessions only hold UI-adjacent state.

### Anti-Pattern 2: Putting rules or `@Observable` on domain types
**What people do:** mark `Beer` or `EncounterState` `@Observable` "so the UI updates".
**Why it's wrong:** reference semantics leak into saves and tests, isolation and `Sendable` get tangled, and the harness can no longer fan out.
**Do this instead:** domain = values; observation lives only in L3.

### Anti-Pattern 3: One giant observable `profile` read by every view
**What people do:** `store.profile.recipes[...]` everywhere.
**Why it's wrong:** any profile change invalidates all readers (see Pattern 2).
**Do this instead:** diff-assigned slices, id-based rows.

### Anti-Pattern 4: Game logic driven by animation
**What people do:** apply score in `onAnimationCompleted`, or use `Task.sleep` as the game clock.
**Why it's wrong:** skip, Reduce Motion, backgrounding and tests all break.
**Do this instead:** truth advances synchronously; presentation catches up (Pattern 3).

### Anti-Pattern 5: UI reading hidden truth
**What people do:** pass `PatronDef` to the encounter screen for convenience.
**Why it's wrong:** one careless label leaks the answer.
**Do this instead:** `PatronView` only, `package`-access and lint enforced.

### Anti-Pattern 6: Dictionary iteration in scoring or event emission
**Why it's wrong:** order differs per launch (random hash seeds), producing flaky tests, differing ledgers and unreproducible bug reports.
**Do this instead:** enum-indexed vectors, `allCases`, sorted keys.

### Anti-Pattern 7: Synthesized Codable for saved associated-value enums and renamed cases
**Why it's wrong:** renaming a case or changing a payload silently breaks every existing save.
**Do this instead:** explicit string discriminators, a migration, and a frozen fixture.

### Anti-Pattern 8: SwiftData `@Model` as the domain model
**Why it's wrong:** couples rules to a framework and reference types and forces a mapping layer anyway.
**Do this instead:** Codable value `Profile` (Persistence section).

### Anti-Pattern 9: Fighting Liquid Glass with `UIDesignRequiresCompatibility`
**Why it's wrong:** ignored for apps built with the iOS 27 SDK, and the SDK is mandatory for uploads from April 2027.
**Do this instead:** own the chrome (custom tab bar, hidden nav bar on game screens); accept system sheets.

### Anti-Pattern 10: Constructing `@Observable` models in a view `init` from parent values
**Why it's wrong:** re-runs on parent recreation; the Xcode 27 `@State` macro rule changes make some forms uncompilable.
**Do this instead:** root-owned stores; `@State` + `.task(id:)`.

### Anti-Pattern 11: Premature frameworks
TCA (2.0 redesign is in beta, so migration churn is guaranteed), swift-dependencies, ECS, SpriteKit scene graphs, SwiftData, Combine. The pure-domain split already provides TCA's headline benefit (testable reducers) without a macro-heavy dependency. Revisit only if the app layer's state graph genuinely becomes hard to reason about (Point-Free's own advice: start vanilla, adopt later if needed).

### Anti-Pattern 12: `GeometryReader`-driven layout and unstable list identity
**Why it's wrong:** geometry fed through broad observable state and `UUID()`/mutable-hash ids are the top hitch causes called out by Apple's Instruments guidance.
**Do this instead:** `ViewThatFits`, `containerRelativeFrame`, `@ScaledMetric`, stable ids.

---

## Scaling Considerations

"Scale" is content volume and code size, not users.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Prototype (about 10 patrons, about 21 ingredients, about 20 beers) | Everything above, unoptimized. Fixtures drive previews. |
| v1 (40+ patrons, about 100 ingredients/yeasts, 100-1000 recipes) | Decode content once at launch (a few MB of JSON decodes in tens of ms; do it in `.task` behind a launch view). `LazyVGrid` for collections with id-only rows. Profile about 1-2 MB: encode in the `ProfileStore` actor. Split `patrons/*.json` per patron or small group for merge-friendliness. |
| Post-v1 (regions as content packs, trading, sync) | Add content directories and a `region` field; domain unchanged ("regions are content, not mechanics"). Escalate persistence to GRDB behind `ProfileStore` if history/queries appear; add CloudKit if sync is required. |

### Scaling Priorities

1. **First bottleneck: SwiftUI invalidation and list cost** in collection screens and 16-bar attribute views. Fix: slices, id-only rows, `Equatable` row views, caching derived display data. Profile with the Instruments 26 SwiftUI template (long view body updates, unnecessary updates).
2. **Second: Canvas particle cost** on the oldest supported device. Fix: cap particle counts, pause off-screen `TimelineView`s, pre-render static layers with `drawingGroup`/`ImageRenderer` caches keyed by `BeerVisualSpec`.
3. **Third: build and preview times** as BrewKit grows. Fix: keep BrewKit light (Foundation only, no third-party macros), prefer package tests over app tests, promote the design system to a local package only if previews slow down.

---

## Integration Points

### External Services / Platform

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| StoreKit 2 | `EntitlementsClient` protocol in `Platform/`; domain knows only abstract resources/entitlements | Monetization undecided (premium vs F2P+IAP). Keep the seam, build nothing else until the economy phase. |
| Haptics | `.sensoryFeedback` on cue counters, behind a Settings toggle | |
| Audio | `AudioClient` protocol (AVFoundation); cues come from beats | Respect silent switch and mixing. |
| Accessibility | VoiceOver labels on every custom control, Dynamic Type via `@ScaledMetric`/`ViewThatFits`, Reduce Motion via `BeatScript`, no color-only information | UX-03/04. Canvas drawing needs sibling accessibility elements. |
| TestFlight / App Store | Ship a TestFlight build in the first UI phase and keep shipping | External TestFlight needs beta app review `[VERIFY]` limits/expiry. App Store age rating questionnaire (new 13+/16+/18+ tiers) will be asked about alcohol references; keep the "no glorified intoxication" stance already in Out of Scope. `[VERIFY]` current guideline text at submission. |
| Privacy manifest | `PrivacyInfo.xcprivacy` declaring required-reason APIs actually used (UserDefaults, file timestamps) | Zero tracking, zero analytics SDKs in v1. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| View <-> Store/Session | Reads observable slices; calls intent methods | Views never call `BrewDomain` mutators directly; pure display math is allowed. |
| Store/Session <-> BrewDomain | Direct sync calls returning `(state, events)` | Always passes `catalog` explicitly. |
| BrewDomain <-> BrewDomain | Calls downward only (`Encounter -> Palate -> Statuses -> Rules`); sideways via events | Brewing never calls Encounter. |
| BrewDomain <-> BrewContent | None. Domain receives a `ContentCatalog` value | Content depends on Model only. |
| Store <-> BrewPersistence | `ProfileSaving` protocol: `scheduleSave(Profile)`, `load() -> Profile` | The only `actor` boundary. |
| Session <-> Presentation | `[DomainEvent]` in, `EncounterPresentation` + cue counters out | `Presentation/` has no SwiftUI import. |
| Tooling/Tests <-> Domain | `brew-harness` and `swift test` | Domain has zero UI deps: the contract. |
| Content <-> Assets | Def art keys resolved against the asset catalog; validator checks a generated manifest | |

---

## Suggested Build Order (dependencies, for roadmap)

Dependency logic: **scaffold + prove the toolchain -> typed data + content pipeline -> pure domain (headless, harness-gated) -> thin app skeleton -> vertical slice (brew -> serve -> learn) -> persistence of the loop -> collections -> world -> bosses -> commercial wrapper.** Prove the *matchup puzzle* before building the world around it (the design's own Phase-1 intent), but get a real device and TestFlight loop running early, because SwiftUI/Xcode 27 specifics are where the unknowns are.

| # | Build | Depends on | Why this position / exit gate |
|---|-------|-----------|-------------------------------|
| 0 | **Scaffold + spikes.** Xcode project (iPhone, portrait, iOS 18, Swift 6 mode), `BrewKit` package with empty targets, `scripts/test`, Swift Testing smoke test, `Bundle.module` JSON load smoke test, `package`-access hiding spike, TestFlight build of an empty app | none | Everything is cheaper once `swift test` on the Mac and a device build both work. Gate: package tests green; app launches; palate field hidden from app target (or lint fallback chosen). |
| 1 | **Model + content pipeline.** `ID<Tag>`, `Attribute`/`AttributeVector`, Defs, `Rng`, `Profile`/`Recipe` *types* (with `parents`), `ContentLoader`/`Validator`, `Tuning`, prototype content (5 grains, 8 hops, 5 yeasts, 3 adjuncts, 10 patrons), `SaveEnvelope` round-trip test | 0 | The ledger/attribute/id shapes and Codable discipline are the highest-regret early decisions. Land the envelope + first fixture here (cheap, since types are Codable). Gate: validator passes; envelope round-trips floats/unicode/names. |
| 2 | **Brewing engine (pure) + ledger + styles/rarity metadata.** Golden-brew tests | 1 | Beer attributes feed everything downstream. Gate: golden tests; determinism test. |
| 3 | **Palate + Statuses + Encounter + Clues/Knowledge/`PatronView` + `brew-harness`.** Event log, transcript renderer, solvability and "two IPAs differ" suites | 2 | The core design risk. It is iterated with **no UI at all**. Gate: harness shows >= 70% solvability, best-in-class diversity, no pour-1 wins. |
| 4 | **App skeleton + design system.** `BrewfighterApp`, `GameStore` (slices), `Router`, custom tab bar, Theme, chunky components, `BrewFixtures` previews, launch/load flow | 0-1 (can overlap 2-3) | Needs only Model types plus fixtures, so it can run in parallel with 2-3. Gate: hub navigates on device; one-handed reach checked. |
| 5 | **Vertical slice.** Brew screen (live preview, ledger sheet), tap lineup (6), encounter cover with `EncounterSession`/`PlaybackDirector`/`BeatScript`, result screen, `BeerGlassView`, placeholder art, haptics | 3, 4 | First playable "brew -> serve -> learn -> improve". Playtest here. Gate: skip equals full-playback end state; Reduce Motion path; 60 fps on the oldest supported device. |
| 6 | **Persistence of the loop.** `ProfileStore` actor, autosave policy (per pour, safe points, background), backup/recovery, migration chain v1 with fixtures, recipe journal + lineage index, rebrew | 1, 5 | Makes it a real game. Lineage data already exists from step 1; this adds the journal UI. Gate: kill-app tests; migration fixtures. |
| 7 | **Collections.** Codex + generic `CollectionBrowser`, ingredient inventory/acquisition, Yeast Bank + mutation (seeded RNG), Regulars Book + derived stages + Perks, recipe family-tree view, beer-card export | 6 | All instances of Pattern 9 on persisted Profile. Tree layout is a research item. |
| 8 | **World.** Location Defs, node map, location backdrops + hotspots, acquisition sources, unlock gating via Progression, day counter | 6-7 | World content is *sources of collectibles and patrons*; those must exist first. |
| 9 | **Bosses.** Rule-override built-ins, boss Defs, scene dressing | 3, 8 | Reuses the encounter engine; needs style/rarity metadata from step 2. |
| 10 | **Commercial wrapper.** Onboarding (Progression-event driven), Settings, accessibility pass (VoiceOver, Dynamic Type at AX sizes), audio pass, polish/juice, privacy manifest, age rating, monetization seam resolved, App Store packaging | all | Cross-cutting; onboarding needs the whole loop. TestFlight has been running since step 0. |

**Parallel tracks:** (a) *Art pipeline*: generate and normalize flat/cartoon assets from step 4 onward against placeholders, with the validator flagging gaps; (b) *Content authoring*: Defs grow continuously behind the validator and harness; (c) *Audio*: placeholder cues wired from step 5.

### Requirement implications of the platform pivot (for roadmap rewrite)

The existing `.planning/REQUIREMENTS.md` still describes a desktop build. Flag these for rewriting: **PLAT-01** (mouse/keyboard/controller intent model) becomes touch, accessibility and one-handed reach; **PLAT-02** is native; **PLAT-03** (JSON saves on 3 OSes, 3 slots) becomes the Codable envelope on iOS, likely a single profile with rolling backup; **PLAT-05** (Mac/Win/Linux packaging) becomes TestFlight/App Store pipeline; **PLAT-07** (headless harness) is satisfied by `swift test` + `brew-harness`; **ART-02/03/04** (pixel-art, locked palette) become flat/cartoon style consistency with a provenance manifest; **ART-05** (Sonic Pi audio) needs re-evaluation; **WORLD-03** (day counter) stays.

### Research flags for phases

| Phase | Flag |
|-------|------|
| 0 | **Spike:** `package` access across Xcode-project / local-package boundary; Xcode 27 + tools-version 6.2 package config; `Bundle.module` `.copy` resources reachable from app and from `swift test`/CLI. |
| 2-3 | **Deep game-design research:** scoring math (fixed-point vs Double), curve shapes, clue policy, status interactions. A design risk, not an engineering-pattern risk; budget harness iterations. |
| 4 | **Spike:** custom tab bar vs Liquid Glass chrome, safe areas, home indicator, one-handed reach on small and large iPhones. |
| 5 | **Spike:** playback feel (beat timing), Canvas particle budget on oldest supported device (Instruments 26 SwiftUI template), `KeyframeAnimator` per-frame cost, Reduce Motion path. |
| 6 | Standard patterns, but **fixture-driven migration testing** must be set up before the first schema change; decide the mid-encounter force-quit rule. |
| 7 | Recipe family-tree layout (custom `Layout`) needs focused research when reached. |
| 8 | **Design decision from user:** does brewing consume days; node-map + hotspots (recommended) vs anything richer. |
| 10 | **Verify at submission:** TestFlight/beta-review limits, age-rating questionnaire answers for alcohol, privacy manifest, monetization decision (premium vs F2P+IAP) before economy work. |

---

## Sources

**HIGH confidence (Apple documentation text, via a markdown mirror):**
- PhaseAnimator, iOS 17.0+: https://sosumi.ai/documentation/swiftui/phaseanimator
- KeyframeAnimator, iOS 17.0+ (content closure runs per frame): https://sosumi.ai/documentation/swiftui/keyframeanimator
- `withAnimation(_:completionCriteria:_:completion:)`, iOS 17.0+: https://sosumi.ai/documentation/swiftui/withanimation(_:completioncriteria:_:completion:)
- Migrating from ObservableObject to `@Observable` (`@State`, `@Environment`, `@Bindable`): https://sosumi.ai/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro
- `Observations` async sequence (SE-0475), iOS 26+: https://developer.apple.com/documentation/observation/observations
- Bundling resources with a Swift package (`process` vs `copy`, `Bundle.module`): https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
- WWDC25 session 306, Optimize SwiftUI performance with Instruments (new SwiftUI instrument; long body updates, unnecessary updates): https://developer.apple.com/videos/play/wwdc2025/306/

**MEDIUM confidence (cross-checked secondary sources):**
- Approachable Concurrency / `.defaultIsolation` in Swift packages (tools 6.2; packages default nonisolated; `Bundle.module` caveat): https://useyourloaf.com/blog/approachable-concurrency-in-swift-packages/ ; https://www.donnywals.com/should-you-opt-in-to-swift-6-2s-main-actor-isolation/
- Xcode 27 `@State` macro (lazy once-only init for `@Observable`, back-deployed to iOS 17, build with Xcode 27): https://nilcoalescing.com/blog/InitializingObservableClassesWithTheStateMacroInXcode27 ; https://www.pointfree.co/blog/posts/223-beta-preview-lazystate
- Xcode 27 release (Swift 6.4, Apple Silicon only, 2026-09-14): https://blakecrosley.com/fr/blog/xcode-27-release
- iOS 27 launch and Xcode 27 SDK requirement from April 2027: https://www.mactech.com/2026/09/10/app-store-submissions-now-open-for-the-latest-os-releases/
- `UIDesignRequiresCompatibility` ignored when built with iOS 27 SDK: https://developer.apple.com/forums/thread/832543
- SwiftData in OS 27 (what improved, what did not): https://mjtsai.com/blog/2026/06/23/swiftdata-in-appleos-27/
- GRDB vs SwiftData vs Core Data comparison: https://www.pistack.xyz/posts/2026-08-11-grdb-swiftdata-core-data-swift-persistence-comparison/ ; GRDB 7 Swift 6 support: https://forums.swift.org/t/grdb-7-is-out/77465
- TCA guidance (Observation-based; start vanilla, adopt later): https://www.pointfree.co/blog/posts/141-composable-architecture-frequently-asked-questions
- Swift dictionary hash-seed randomization (`SWIFT_DETERMINISTIC_HASHING`): https://forums.swift.org/t/psa-the-stdlib-now-uses-randomly-seeded-hash-values/10789
- SwiftUI data-flow/performance guidance (list identity, equality, environment): https://nilcoalescing.com/blog/TheSwiftUIWayUpdateJuly2026/
- Per-tab router, `Route`/`Modal` enum navigation patterns (community consensus): https://dev.to/sebastienlato/modern-navigation-in-swiftui-1c8g
- App Store age rating tiers (13+/16+/18+): https://www.macobserver.com/news/apple-adds-new-app-store-age-ratings-13-16-and-18/

**Carried forward (from the 2026-10-06 research, platform-independent ideas only):** Pokemon Showdown simulator/protocol separation (https://github.com/smogon/pokemon-showdown/blob/master/sim/SIMULATOR.md); Nystrom, *Game Programming Patterns* (State, Event Queue); the three-tier data model, ledger, `PatronView`, derived-not-stored and balance-harness ideas.

**Not verified / needs spike (all tagged `[VERIFY]` above):** `package`-access hiding across the Xcode project boundary; custom tab bar vs Liquid Glass on iOS 27; Canvas particle performance on the oldest supported device; TestFlight limits; privacy-manifest requirements at submission time; exact Swift 6.4 feature set (a WWDC26 writeup found was not reliable enough to cite).

---
*Architecture research for: collectible brewing RPG, native Swift/SwiftUI on iPhone*
*Researched: 2026-10-08*
