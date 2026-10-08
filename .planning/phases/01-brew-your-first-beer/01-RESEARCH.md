# Phase 1: Brew Your First Beer - Research

**Researched:** 2026-10-08
**Domain:** Native iOS (Swift 6 / SwiftUI) game scaffold + pure-Swift deterministic brewing engine + versioned JSON persistence + TestFlight pipeline
**Confidence:** MEDIUM-HIGH (toolchain, scaffold and package-access findings are HIGH because they were spiked on this machine; brewing formulas, style thresholds and some Xcode 26+/27 build settings are MEDIUM/ASSUMED and flagged)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Recipe-building flow**
- **D-01:** Stage wizard structure: Mash → Boil → Ferment → Condition as sequential full screens with a progress indicator. Mirrors real brewing order (serves the 70% genuine-brewing tone goal).
- **D-02:** Free back-navigation between stages; wizard ends on a **Recipe Review** screen summarizing all choices with a big BREW button. The review screen hosts the brew moment.
- **D-03:** Ingredient selection via chunky tappable card grids; tapping adds the ingredient, then big +/- steppers set amounts. AdCap feel, large targets.
- **D-04:** Numeric choices (mash temp, ferment temp, duration) use banded dials / segmented sliders with flavor-text bands (e.g., "Cold & clean" / "Balanced" / "Warm & fruity") plus the real °F shown small. Bands map to discrete deterministic engine inputs.
- **D-05:** Ingredient cards show short qualitative trait tags (Citra: "citrus, tropical"); exact numeric contributions only appear post-brew in the ledger. No live attribute preview in Phase 1 (BREW-03 later); tags set up the future "?" undiscovered-traits mechanic.
- **D-06:** First run opens the wizard pre-seeded with a simple house pale ale the player can accept or tweak; clear-all is one tap. No tutorial plumbing (onboarding is Phase 6).
- **D-07:** Validation floor: a brewable recipe needs ≥1 grain and a yeast; hops and conditioning optional. Hop-less/weird beers are legal and scored honestly — every valid input produces a beer.
- **D-08:** Phase 1 home screen is **The Cellar**: grid/list of brewed beers (procedural glass thumbnails) plus one big BREW button; day counter in the header. Phase 2+ screens attach alongside later. — **Reversibility:** costly — the app shell/navigation root that later phases hang off; changing it reworks every screen's entry point.

**The brew moment & reveal**
- **D-09:** Tapping BREW plays a staged, skippable 3-5s reveal: brewing vignette → day counter visibly rolling forward (`.contentTransition(.numericText())`) → glass fills → style label stamps in. This is the phase's signature juice moment; no real-time waiting ever.
- **D-10:** Day cost is recipe-driven: days advanced = fermentation duration + conditioning time (e.g., lagering is expensive in days). Real calendar rules now, not cosmetic. — **Reversibility:** costly — later phases (world/economy) will build on day-cost semantics; changing the rule invalidates balance and save data meaning.
- **D-11:** Beer detail presents the 16 attributes as grouped family bars — malt / hop / yeast / mouthfeel families — with the exact number at each bar's end; zero/near-zero attributes may collapse. Matches the family grouping Phase 2's success criteria already require.
- **D-12:** Pre-naming identity: beers display as "Batch #N · {computed style}" plus brew day. Player naming arrives in Phase 3 and layers on top.

**Ingredient roster & granularity**
- **D-13:** Roster at design-doc prototype size: ~5 grains, 8 hops, 5 yeast strains, 3 adjuncts. All available from the start; collection/rarity gating is Phase 4.
- **D-14:** Grain bill is expressed in **percentages** (user explicitly chose authenticity over the scoops abstraction). UI keeps it painless via auto-rebalance: steppers adjust specialty grains in 5% increments and the base (largest) malt absorbs the remainder so the bill always sums to 100.
- **D-15:** Hop timing uses named slots — Bittering (60 min) / Flavor (15 min) / Aroma (flameout) / Whirlpool — with real minutes as flavor text. Attribute math is slot × hop × amount. Dry hop lives in Conditioning.
- **D-16:** Conditioning ships as a small menu (user chose breadth over the single-option recommendation): **dry hop, fruit, lagering, bottle conditioning**. Each needs attribute data, balance tuning, and ledger copy; lagering showcases the day-cost rule.

**Beer inspection & glass**
- **D-17:** Contribution ledger (BREW-04): tapping an attribute opens a sheet of itemized source rows with signed numbers summing to the total — e.g., "Citra (aroma slot) +3.2 · Warm ferment +0.8 · Lagering −0.5".
- **D-18:** Style labels (BREW-06): ~10-15 recognizable styles reachable from the Phase 1 roster (Pale Ale, West Coast IPA, Hazy IPA, Stout, Pilsner, Saison, Wheat, ...), plus honest fallback labels ("Amber Ale", "Experimental Ale") for in-between beers. Unmatched beers are legal — a vague label is itself feedback that the recipe is unfocused.
- **D-19:** Procedural glass (ART-01): animated hero glass on the beer detail view — Canvas + TimelineView rising bubbles driven by the carbonation attribute, settled foam head, liquid color derived from SRM. Static thumbnails in the Cellar grid. Honors Reduce Motion (fade instead of motion).
- **D-20:** Full nerd stats (user chose above the ABV-only recommendation): the beer detail shows real-world brewing numbers — **ABV %, IBU, SRM, OG/FG estimates** — derived from the recipe, alongside the abstract 0-10 game attributes. SRM is computed for the glass anyway; IBU/OG/FG need plausible (approachable, not lab-grade) formulas. — **Reversibility:** costly — these derived stats become part of the engine's public output contract and the save schema; removing them later breaks displayed data players have seen.

### Claude's Discretion
- Exact attribute scale internals (0-10 shown; engine representation), family-to-attribute mapping details, collapse threshold for near-zero bars.
- Save file format details, export file naming, share-sheet mechanics (within PLAT-03's envelope/migration/fixture requirements).
- Cellar sorting, empty states, pseudo-localization verification approach, exact starter-recipe contents.
- The specific ~12 style definitions and their classification thresholds (validated by tests).
- IBU/OG/FG estimation formulas — plausible simplified brewing math, tuned for consistency with the attribute engine rather than lab accuracy.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. (Live attribute preview, rebrew, naming, collection gating, and onboarding were kept out by design; they're already mapped to later phases in ROADMAP.md.)

NOT in this phase (CONTEXT.md domain): encounters/patrons (Phase 2), live attribute preview while editing (BREW-03, later), rebrew-from-journal (BREW-05, Phase 3), beer naming/versioning (Phase 3), collection/rarity mechanics (Phase 4), onboarding/tutorial (Phase 6).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BREW-01 | Compose a recipe from grain bill, hops with timing, yeast, fermentation temperature, conditioning | Recipe model + band enums + wizard state machine (Architecture Patterns 1-2); auto-rebalance rules (Pitfall 7) |
| BREW-02 | Deterministic beer with the ~16 sensory attributes | Pure `Brewer.brew(recipe, content)` with Int fixed-point, no RNG; content tables as JSON (Pattern 3, Code Examples) |
| BREW-04 | Per-source contribution ledger per attribute | Additive ledger rows + marginal-attribution rule + sum-exactness invariant test (Pattern 4, Pitfall 2-3) |
| BREW-06 | Style label computed from attributes, never chosen | Attribute-only rule classifier + reachability test over a recipe grid (Pattern 5) |
| BREW-07 | Brewing resolves via day counter, no real-time waits | Day cost = fermentation days + conditioning days committed in the reducer before the reveal plays (Pattern 6, Pitfall 8) |
| PLAT-01 | Touch-first, portrait, one-handed, generous targets | `GameButtonStyle` min 44pt + bottom-anchored primary actions + `performAccessibilityAudit(.hitRegion)` UI test (Validation Architecture) |
| PLAT-03 | Versioned Codable JSON envelope, migrations, atomic writes, backup copy, golden fixture, export/import | Envelope + migrator + `.atomic` write + backup + `ShareLink`/`fileImporter` + frozen V1 fixture (Pattern 7, Code Examples) |
| PLAT-05 | Builds on current SDK, TestFlight from Phase 1, privacy manifest, recorded 18+ rating | Toolchain upgrade gate, XcodeGen scaffold, CLI archive/upload, privacy manifest, human ASC checklist (Environment Availability, Pattern 8) |
| PLAT-06 | All strings in a String Catalog | Catalog + generated symbols (Xcode 26+) + dynamic-key test + `-NSDoubleLocalizedStrings` UI test (Pattern 9, Pitfall 1) |
| ART-01 | Procedural glass from attributes, visually distinct per beer | Pure `GlassSpec` in BrewCore + Canvas/TimelineView renderer + distinctness test (Pattern 10) |
</phase_requirements>

## Summary

This phase builds a greenfield skeleton that every later phase attaches to, so the highest-leverage research is about *structure and gates*, not game content. Three findings dominate planning. **First, the toolchain gate:** the only Mac available has Xcode 16.4, macOS 15.3.2 and only an iOS 18.6 simulator runtime. That cannot build the locked iOS 26 deployment target and cannot upload to App Store Connect (Apple requires Xcode 26+ / iOS 26 SDK since 2026-04-28). A human macOS + Xcode upgrade is a hard prerequisite for every app-target plan and the TestFlight criterion. The engine package (`BrewCore`) can be built and tested today with the installed Swift 6.1.2, so plans should be ordered engine-first. **Second, the scaffold question is resolved with a spike:** XcodeGen 2.45.4 (already installed) generates an Xcode 16+ *synchronized-folder* project (`type: syncedFolder`) with a local-package dependency, a compiled String Catalog, a copied `PrivacyInfo.xcprivacy`, and a generated Info.plist; it built successfully. This reconciles `ios-scaffold.md` (use XcodeGen, never SPM executables) with CLAUDE.md (folder-synchronized groups): XcodeGen is the scriptable generator, the output *uses* synchronized folders so adding files never requires regeneration. **Third, `package` access works as the hiding mechanism:** a `package` symbol in `BrewCore` was visible to `BrewCore`'s own tests and invisible to the app target (compile error `cannot find 'secretScore' in scope`).

The engine design that makes the other requirements fall out cheaply: all game math is **Int fixed-point** (attribute centi-points, OG as gravity points, IBU/SRM in tenths) with every transcendental function (Tinseth's `exp`/`pow`, Morey's `pow`) precomputed offline into JSON lookup tables, so results are bit-identical across macOS/iOS/Linux and the ledger *sums exactly* by construction (total = Σ rows, including an explicit "capped" row when clamping). Beers persist as recipe + computed result snapshot + `contentVersion`, so later balance tuning cannot silently rewrite beers the player has already seen (D-20 makes the stats part of the schema contract).

**Primary recommendation:** Plan engine-first on the installed Swift 6.1.2 (`BrewCore`, tools-version 6.0, Swift Testing, Int fixed-point, additive ledger, frozen V1 golden save); put the macOS/Xcode upgrade as an early human checkpoint; scaffold the app with `project.yml` → XcodeGen (synchronized folders, committed `.xcodeproj`); build game screens with fully custom chrome (system chrome only for sheets/share/file picker); verify PLAT-06/PLAT-01 with a `-NSDoubleLocalizedStrings YES` XCUITest and `performAccessibilityAudit(for: .hitRegion)`.

## Architectural Responsibility Map

Adapted for a single-process native app (no browser/API/CDN tiers): the tiers here are the layers the stack decision imposes.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Recipe → attributes/ledger/stats/style (brew resolution) | `BrewCore` engine (pure, nonisolated, `Sendable`) | — | Must be headless-testable on macOS/Linux (CLAUDE.md); no UI imports |
| Content tables (ingredients, bands, styles, SRM colors, Tinseth tables) | `BrewCore` resources (JSON via `Bundle.module`) | App String Catalog (display strings) | Data-driven, validated by tests; display strings stay in the app catalog keyed by ID |
| Day counter, batch numbering, beer list | `BrewCore` reducer `(GameState, Action, inout RNG) -> (GameState, [GameEvent])` | `GameStore` (`@MainActor @Observable`) | Reducer owns rules; store only holds state and calls reducer |
| Save envelope, migration, validation | `BrewCore` (encode/decode/migrate/validate, no file I/O) | App `SaveRepository` (file I/O, atomic write, backup) | Codable + migrations are pure and fixture-testable; I/O stays in the app |
| Export/import UX | iOS system UI (`ShareLink`, `fileImporter`) | App `SaveRepository` | Don't build file pickers or share UI |
| Wizard, Cellar, Reveal, Beer detail, ledger sheet | SwiftUI views (app target) | `GameStore` intents | All UI custom chrome except system sheets |
| Glass description (colors, head, bubble params, shape) | `BrewCore` `GlassSpec` (pure) | Canvas renderer (app) | Distinctness is testable headlessly; renderer is a dumb painter |
| Pseudo-localization, 44pt audit, relaunch persistence | XCUITest (app) | `BrewCore` tests for catalog-key integrity | Only UI automation can see rendered text/hit regions |
| Build/sign/upload | `xcodebuild` + ASC (human for app record) | Xcode Cloud (optional, later) | App record creation is a web-UI step |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | Language mode 6; installed 6.1.2 (`swift --version`), target 6.4 with Xcode 27 [VERIFIED: local `swift package --version` → 6.1.0 / driver 6.1.2; CLAUDE.md for 6.4] | All code | Locked in CLAUDE.md. `BrewCore` can use `// swift-tools-version: 6.0` so it builds today and under 6.4 |
| SwiftUI + Observation | iOS 26 floor, build with Xcode 27 / iOS 27 SDK [CITED: CLAUDE.md] | UI, `@Observable GameStore` | Locked |
| Swift Testing | Bundled (ran: `Testing Library Version: 124.4`) [VERIFIED: spike `swift test`] | `BrewCore` tests, parameterized matrices | Works with installed toolchain headlessly |
| XCTest / XCUITest | Bundled with Xcode | UI tests (pseudo-loc, hit regions, relaunch) | Swift Testing cannot drive UI |
| XcodeGen | 2.45.4 (installed at `/opt/homebrew/bin/xcodegen`) [VERIFIED: `xcodegen --version`] | Generate `.xcodeproj` from `project.yml` | Sanctioned by `ios-scaffold.md`; supports `syncedFolder` [CITED: XcodeGen Docs/ProjectSpec.md] and was spiked |
| Foundation `JSONEncoder/Decoder` (`.sortedKeys`) | system | Save envelope, content | No dependency; deterministic key order for golden files |
| `ShareLink`, `.fileImporter` | iOS 16+/17+ system | Export/import via share sheet | Required by criterion 4; do not hand-roll |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `xcodebuild archive` / `-exportArchive` | Xcode-bundled | Scripted TestFlight upload | `destination=upload`, `method=app-store-connect` [VERIFIED: `xcodebuild -help` exportOptions keys] |
| `xcrun simctl` | Xcode-bundled | Launch with flags/screenshot for spikes | Pseudo-loc smoke checks |
| Canvas + `TimelineView(.animation)` | iOS 15+ | Glass bubbles/foam | D-19; own ~100-line emitter, no Vortex needed in Phase 1 |
| swift-snapshot-testing | 1.19.6 [CITED: CLAUDE.md] | Optional glass snapshots | Skip in Phase 1 (simulator-version drift); prefer `GlassSpec` distinctness unit test |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| XcodeGen + syncedFolder | Hand-authored `.pbxproj` / Xcode GUI new-project | GUI step cannot be scripted by the executor; hand-written pbxproj is brittle. XcodeGen wins |
| XcodeGen | Tuist | Not installed; CLAUDE.md says skip. No |
| Own Int tables | Double + `exp`/`pow` at runtime | Transcendentals are not guaranteed bit-identical across platforms; rounding boundary flips would break golden tests on Linux CI. Use offline-generated tables |
| `ShareLink(item: fileURL)` | `Transferable` + `FileRepresentation` | Known forum issues with `FileRepresentation` in `ShareLink` [CITED: developer.apple.com/forums/thread/734741]; start with a temp file URL, switch only if device test shows trouble |

**Installation / scaffold:**
```bash
# XcodeGen already installed (brew install xcodegen if missing)
xcodegen generate            # from repo root, reads project.yml
cd Packages/BrewCore && swift test   # runs today on Swift 6.1.2
```

**Version verification:** No third-party SwiftPM or npm packages are introduced in Phase 1. Tool versions verified locally: XcodeGen 2.45.4, Swift 6.1.2, Xcode 16.4 (to be replaced), Swift Testing 124.4.

## Package Legitimacy Audit

No external packages are installed in Phase 1 (no SwiftPM remote dependencies, no npm/pip/cargo). `gsd-tools query package-legitimacy check` supports npm/pypi/crates only and has nothing to check. XcodeGen is a Homebrew-installed dev tool already present on the machine and named in `~/.claude/gsd-core/references/ios-scaffold.md`.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
If the planner later adds Vortex or swift-snapshot-testing, vendor Vortex per CLAUDE.md and gate each new remote dependency behind a `checkpoint:human-verify` task (both are `[ASSUMED]` here: named in CLAUDE.md, not verified this session).

## Architecture Patterns

### System Architecture Diagram

```
 Player taps ──► SwiftUI views (GameShell: Cellar | Wizard | Reveal | BeerDetail | LedgerSheet)
                      │  intents (startBrew(draft), importSave(url), exportSave())
                      ▼
               GameStore  (@MainActor @Observable; holds GameState)
                      │ apply(Action)                          ▲ events replayed as animation
                      ▼                                        │
        ┌────────────────────────────────────────────┐        │
        │ BrewCore (pure, nonisolated, Sendable)      │────────┘  [GameEvent]
        │  Reducer: (GameState, Action, inout RNG)    │
        │     └─► Brewer.brew(Recipe, Content)        │
        │            ├─ validate Recipe (≥1 grain+yeast, bill = 100)
        │            ├─ gather ledger rows (grain, hop×slot, yeast×tempBand,
        │            │     mash band, ferment days, conditioning)   ← Content JSON tables
        │            ├─ clamp → explicit "cap" rows; total = Σ rows
        │            ├─ derive Stats (OG/FG/ABV/IBU/SRM) via Int tables
        │            ├─ StyleClassifier(attributes) → label | fallback
        │            └─ GlassSpec(attributes, style)
        │  SaveCodec: envelope encode/decode ─► Migrator ─► Validator
        └────────────────────────────────────────────┘
                      │ Data (envelope)                       ▲ Data
                      ▼                                       │
               SaveRepository (app): atomic write → save.json, copy prior → save.backup.json
                      │                                       │
               ShareLink (export file) ───────────  .fileImporter (security-scoped URL)
```

### Recommended Project Structure
```
project.yml                         # XcodeGen spec (commit); .xcodeproj is committed too (see Open Question 3)
.gitignore                          # ADD: DerivedData/ build/ *.xcarchive *.ipa xcuserdata/ .swiftpm/ .build/ *.p8
App/
├── BrewFighter/                    # syncedFolder: Swift sources, Localizable.xcstrings, PrivacyInfo.xcprivacy, Assets.xcassets
│   ├── BrewFighterApp.swift
│   ├── Shell/ (GameShell, Screen enum, GameStore)
│   ├── Cellar/ Wizard/ Reveal/ BeerDetail/ Ledger/
│   ├── UIKit/ (GameButtonStyle, StepperButton, BandDial, Panel, Palette)  # the "UI kit" Phase 2+ reuse
│   ├── Glass/ (GlassView Canvas renderer)
│   └── Persistence/ (SaveRepository: file I/O only)
├── BrewFighterTests/               # app-level tests (Swift Testing ok)
└── BrewFighterUITests/             # XCTest: pseudo-loc, hit-region, relaunch
Packages/BrewCore/
├── Package.swift                   # tools 6.0, platforms iOS 17 / macOS 14
├── Sources/BrewCore/
│   ├── Model/ (Recipe, Beer, GameState, AttributeID, LedgerRow, Stats)
│   ├── Engine/ (Brewer, Reducer, SeededRNG, Rounding)      # package/internal by default
│   ├── Content/ (ContentCatalog loader)                     # public descriptors only
│   ├── Style/ (StyleClassifier)
│   ├── Glass/ (GlassSpec)
│   ├── Save/ (SaveEnvelope, Migrator, Validator)
│   └── Resources/Content/*.json    # grains, hops, yeasts, adjuncts, bands, conditioning, styles, srm_colors, tinseth_tables
├── Tests/BrewCoreTests/ (+ Fixtures/save_v1.json — frozen)
config/ExportOptions.plist, scripts/archive-upload.sh, scripts/check-catalog.*
```

### Pattern 1: XcodeGen spec with synchronized folder + local package (VERIFIED by spike)
**What:** `project.yml` generates a project whose app target uses a `PBXFileSystemSynchronizedRootGroup` (4 occurrences in the generated pbxproj; `objectVersion = 77`), a local package dependency, a generated Info.plist, and ships `PrivacyInfo.xcprivacy` and the compiled catalog.
**When to use:** The one scaffold for this repo. Regenerate only when `project.yml` changes (new targets/settings), never for new source files.
**Example:** (the spike's spec, with the Xcode 26+ settings added as *to-verify* lines)
```yaml
# Source: spike built OK with Xcode 16.4 (deployment 18.0 only because 16.4 cannot target 26.0)
name: BrewFighter
options:
  bundleIdPrefix: com.example          # replace with real reverse-DNS before ASC record creation
  developmentLanguage: en
  deploymentTarget: { iOS: "26.0" }    # spike used "18.0"; 26.0 requires Xcode 26+
  createIntermediateGroups: true
packages:
  BrewCore: { path: Packages/BrewCore }
settings:
  base:
    SWIFT_VERSION: "6.0"               # language mode 6
    SWIFT_STRICT_CONCURRENCY: complete
    GENERATE_INFOPLIST_FILE: YES
targets:
  BrewFighter:
    type: application
    platform: iOS
    sources: [ { path: App/BrewFighter, type: syncedFolder } ]
    dependencies: [ { package: BrewCore } ]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.example.brewfighter
        TARGETED_DEVICE_FAMILY: "1"                       # iPhone only; iPad runs scaled
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
        INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO   # verified present as 0 in built Info.plist
        INFOPLIST_KEY_CFBundleDisplayName: "Brew Fighter"
        SWIFT_EMIT_LOC_STRINGS: YES
        STRING_CATALOG_GENERATE_SYMBOLS: YES              # Xcode 26+ only; ignored/failed on 16.4 (see Pitfall 1)
        # SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor        # [ASSUMED] Xcode 26 name; verify after upgrade
        # SWIFT_APPROACHABLE_CONCURRENCY: YES             # [ASSUMED] verify after upgrade
  BrewFighterTests:
    type: bundle.unit-test
    platform: iOS
    sources: [ { path: App/BrewFighterTests, type: syncedFolder } ]
    dependencies: [ { target: BrewFighter } ]
  BrewFighterUITests:
    type: bundle.ui-testing
    platform: iOS
    sources: [ { path: App/BrewFighterUITests, type: syncedFolder } ]
    dependencies: [ { target: BrewFighter } ]
```
Spike observations [VERIFIED: spike build, Xcode 16.4]: built `.app` contains `PrivacyInfo.xcprivacy`, `en.lproj/Localizable.strings` (compiled from the `.xcstrings`), `Info.plist` with `ITSAppUsesNonExemptEncryption = 0`, `MinimumOSVersion`, `UIDeviceFamily`, `UISupportedInterfaceOrientations`, `CFBundleDisplayName = "Brew Fighter"`. The `BrewFighterUITests` target was NOT spiked; generate it in the first scaffold plan and build it before relying on it.

### Pattern 2: Wizard as one screen with a stage state machine (not NavigationStack pushes)
**What:** `RecipeWizardView` switches on a `WizardStage` enum (`mash, boil, ferment, condition, review`) over an `@Observable RecipeDraft`. Back/Next are custom buttons anchored in `.safeAreaInset(edge: .bottom)`. System nav bar hidden.
**Why:** D-01/D-02 (free back-nav + review hosts the brew), keeps custom chrome (no Liquid Glass nav bar), thumb-reach primary actions (PLAT-01). `GameShell` owns a `Screen` enum (`cellar, wizard, reveal(beerID), detail(beerID)`) per CLAUDE.md; ledger is a system `.sheet`.

### Pattern 3: Data-driven additive effects (no code per ingredient)
**What:** Content JSON declares, per ingredient, integer centi-point effects per attribute. Interactions are expressed as *lookup tables*, not math: e.g. `yeast.effectsByTempBand[band][attribute]`, `hop.effects[attribute]` scaled by `slotWeight[slot]` and an integer amount step.
**Why:** every row in the ledger is one table lookup × an integer scale, so rows are explainable (D-17) and golden-testable.
```json
{ "id": "hop.example", "traitKeys": ["trait.citrus", "trait.tropical"],
  "alphaAcidTenths": 120,
  "effects": { "citrus": 300, "tropical": 200, "hopAroma": 200, "bitterness": 0 } }
```
(Illustrative shape only; ingredient names/values are the planner's content task.)

### Pattern 4: Ledger = source of truth; total = Σ rows; clamp is a row
- `LedgerRow { attribute, source: {kind, id, slot?}, delta: Int }`; the displayed attribute value is `clamp(Σ delta)` and any clamp is emitted as a final `cap` row so the visible rows always sum to the total (D-17 says "signed numbers summing to the total").
- For multiplicative quantities (ABV from OG × attenuation, bitterness balance), use **marginal attribution in fixed order**: compute the total, then attribute step-by-step (each source's row = total-with-source minus total-without, in a fixed source order); put the integer remainder on the largest source. Test: for every attribute of every brewed beer, `rows.reduce(0,+.delta) == value` exactly.
- Persist `source` as `kind`+`id`(+`slot`) only; labels are composed in the UI from catalog keys (never store English in the save).

### Pattern 5: Style classification from attributes only
- `StyleClassifier.classify(attributes) -> StyleID`. Each style in `styles.json` has weighted range conditions over the 16 attributes (not IBU/SRM, to keep "computed from attributes" literal and to match what Phase 2 patrons see). Highest score ≥ threshold wins; ties break by fixed file order; below threshold → fallback rules (`amber_ale` when malt/sweetness mid and roast low, else `experimental_ale`).
- Candidate styles (D-18 asks ~10-15): American Pale Ale, West Coast IPA, Hazy IPA, Pilsner, Helles/Lager, Saison, Wheat Beer, Stout, Porter, Brown Ale, English Bitter, Blonde Ale + fallbacks Amber Ale, Experimental Ale. Starting ABV/IBU/SRM envelopes (BJCP-like, **[ASSUMED]**, tune with tests): Pale Ale 4.5-6.2% / 30-50 / 5-10; WC IPA 6-7.5% / 50-75 / 6-14; Hazy IPA 6-7.5% / 25-60 / 3-7; Pilsner 4.4-5.2% / 25-45 / 2-5; Saison 5-7% / 20-35 / 5-14; Wheat 4.3-5.6% / 8-15 / 2-6; Stout 4-5% / 30-45 / 25-40.
- Required tests: (a) every non-fallback style is produced by ≥1 recipe from a deterministic enumerated recipe grid; (b) fallback share over the grid is bounded (e.g., <35%) so "Experimental Ale" is feedback, not the default; (c) no recipe crashes the classifier.

### Pattern 6: Brew commit before reveal
Reducer action `.brew(recipe, newBeerID)` appends the `Beer`, advances `day += fermentDays + conditioningDays`, increments `nextBatchNumber`, returns events `[.dayAdvanced(from,to), .beerBrewed(id), .styleAssigned(...)]`, **and the store autosaves immediately**. The reveal animation replays events and is purely presentational; Skip just jumps the view to its final state. Beer ID is generated outside the engine (injected) so the engine stays deterministic.

### Pattern 7: Save envelope + migrator + validator
```swift
// Source: design for this phase; Codable/JSONEncoder behavior is standard Foundation
public struct SaveEnvelope: Codable, Sendable {
    public var schemaVersion: Int          // 1 for Phase 1
    public var contentVersion: Int
    public var payload: GameState
}
// Decode only the header first:
struct SaveHeader: Decodable { var schemaVersion: Int }
public enum SaveError: Error { case unreadable, newerThanApp(Int), invalid(String) }

public func decodeSave(_ data: Data) throws -> GameState {
    guard data.count < 5_000_000 else { throw SaveError.invalid("too large") }
    let header = try JSONDecoder().decode(SaveHeader.self, from: data)
    guard header.schemaVersion <= SaveMigrator.current else { throw SaveError.newerThanApp(header.schemaVersion) }
    let migrated = try SaveMigrator.migrate(data, from: header.schemaVersion)   // chain of frozen steps
    let env = try JSONDecoder().decode(SaveEnvelope.self, from: migrated)
    try SaveValidator.validate(env.payload)                                      // ranges, bill=100, ids non-crashing
    return env.payload
}
// Encode: .sortedKeys (+ .prettyPrinted for the golden fixture only) for stable bytes
```
- App side: `data.write(to: url, options: .atomic)`; before overwrite, move the current file to `save.backup.json`; load tries primary then backup. Location `Application Support/BrewFighter/`. Avoid file-timestamp APIs and UserDefaults/`@AppStorage` in Phase 1 so the privacy manifest can stay empty (Pitfall 11).
- Keep explicit `CodingKeys` with stable string names and string-raw-value enums; never rely on synthesized shapes for enums with associated values or enum-keyed dictionaries (Pitfall 6). Golden fixture locks the on-disk shape.
- Import = decode via the same path; on any failure the current save is untouched; before replacing, write `save.pre-import.json` and show a confirmation alert (destructive replace; UX-05 formalizes in Phase 3).
- Export: write envelope bytes to a temp file named e.g. `BrewFighter-Save.json` and present `ShareLink(item: url)`; import with `.fileImporter(allowedContentTypes: [.json])`, calling `startAccessingSecurityScopedResource()` / `defer stop…` [CITED: useyourloaf.com/blog/accessing-security-scoped-files; safe to call for in-container files]. Defer a custom UTType (needs Info.plist `UTExportedTypeDeclarations`).

### Pattern 8: Scripted archive → TestFlight (human prerequisites first)
```bash
# scripts/archive-upload.sh (sketch)
xcodebuild archive -project BrewFighter.xcodeproj -scheme BrewFighter \
  -destination 'generic/platform=iOS' -archivePath build/BrewFighter.xcarchive \
  DEVELOPMENT_TEAM="$TEAM_ID" -allowProvisioningUpdates
xcodebuild -exportArchive -archivePath build/BrewFighter.xcarchive \
  -exportOptionsPlist config/ExportOptions.plist -allowProvisioningUpdates
# ExportOptions.plist: method=app-store-connect, destination=upload, teamID=<TEAM_ID>, signingStyle=automatic
```
`-allowProvisioningUpdates` works with the Xcode-signed-in account (this Mac has Xcode accounts with a non-free team: `isFreeProvisioningTeam = 0`) or with `-authenticationKeyPath/-KeyID/-KeyIssuerID` [VERIFIED: `xcodebuild -help`]. `manageAppVersionAndBuildNumber` defaults to YES, so Xcode bumps build numbers on upload [VERIFIED: `xcodebuild -help`]. Never commit the `.p8` key.

### Pattern 9: String Catalog discipline
- Static UI text: `Text("literal")` / `Text(.symbolKey)` (symbols require Xcode 26+).
- Content-driven text (ingredient names, trait tags, style names, ledger source labels): store a **key** in content JSON and render `Text(LocalizedStringKey(key))`; **add the keys to `Localizable.xcstrings` explicitly** (see Pitfall 1: command-line builds do not extract them and a missing key silently renders the raw key).
- `BrewCoreTests` includes a test that parses `Localizable.xcstrings` (JSON) and asserts every key referenced by content JSON exists with a non-empty `en` value.
- Interpolations use catalog format strings (`"%lld days"`), with plural variations where needed.

### Pattern 10: Glass = pure `GlassSpec` + dumb Canvas painter
- `GlassSpec(attributes, style, beerSeed) -> { shape: GlassShape(enum by style family), liquidRGB (SRM stop interpolation, Int), headFraction (carbonation, body), bubbleCount/speed (carbonation), seed }` lives in `BrewCore`, so "visibly different" is a unit test (pairwise spec distance for the starter-style beers above an epsilon).
- Renderer: `Canvas` for the glass + `TimelineView(.animation(paused: reduceMotion))` for bubbles; bubble y = `fract(phase + t * speed)` computed from `age = now - birth`, params from a seeded SplitMix64 (stable per beer). Cellar thumbnails use a static `Canvas` (no `TimelineView`) so a grid does not run N timelines. Add `.accessibilityElement(children: .ignore)` + a localized label (UX-03 is verified in Phase 3, but cheap now). `accessibilityReduceMotion` → static bubbles + fade.
- SRM→color: use a stop table in content JSON. First eight stops [CITED: BJCP/brewfather-style SRM chart via search, brewing community sources]: 1 `#FFE699`, 2 `#FFD878`, 3 `#FFCA5A`, 4 `#FFBF42`, 5 `#FBB123`, 6 `#F8A600`, 7 `#F39C00`, 8 `#EA8F00`. Stops above 8 up to ~40 (deep amber → near black) are `[ASSUMED]`; take them from a cited chart during implementation and tune visually.

### Anti-Patterns to Avoid
- **Computing the displayed total separately from the rows** — guarantees the ledger drifts after any tweak. Total is derived from rows.
- **`Double` attribute math** — rounding makes displayed rows not sum to the total and risks cross-platform drift.
- **Putting English strings or localized labels in the save or in `BrewCore` outputs.**
- **Using `NavigationStack` pushes + system nav bar for the wizard** — pulls in Liquid Glass chrome and breaks the chunky look.
- **A "largest malt is base" dynamic rule** (D-14 wording) — it flips when a specialty grain exceeds the base mid-edit; make the base an explicit field (Pitfall 7).
- **Writing the beer only after the reveal finishes** — force-quit mid-reveal would lose it or re-brew it.
- **`@AppStorage`/`UserDefaults`/file-timestamp APIs in Phase 1** — each adds a required-reason declaration for no benefit (settings are Phase 6).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Share/export UI | Custom share modal | `ShareLink` | System sheet, Files/AirDrop for free |
| Import picker | Custom file browser | `.fileImporter` | Security-scoped URL handling is the only subtle part |
| Atomic persistence | Temp-file/rename dance | `Data.write(to:options: .atomic)` + one backup copy | Standard Foundation semantics |
| Pseudo-localization | Fake-translation generator | `-NSDoubleLocalizedStrings YES` launch arg (and Xcode scheme pseudolanguages) | Verified on simulator: catalog strings doubled ("Hello Hello"), `Text(verbatim:)` and raw `String` stayed single |
| Hit-region audit | Custom view-tree walker | `app.performAccessibilityAudit(for: .hitRegion)` (iOS 17+) plus a frame assertion over `app.buttons` | Built-in audit types: contrast, elementDetection, hitRegion, sufficientElementDescription, dynamicType, textClipped, trait [CITED: search result summaries; confirm in Xcode 26 docs] |
| Number-roll animation | Timer-driven digit flipping | `.contentTransition(.numericText())` + `withAnimation` | D-09; Reduce Motion aware |
| IBU/SRM/ABV/color math at runtime | `exp`/`pow` per brew | Offline-generated Int lookup tables checked into content | Cross-platform determinism, simpler tests |
| Project file | Hand-edited `.pbxproj` | XcodeGen `project.yml` | Reproducible, reviewable diffs |
| Haptics/audio/particles libs | Anything | Nothing in Phase 1 (haptics/audio are Phase 6; particles are the glass's own bubbles) | Scope |

**Key insight:** every "magic number" in this phase should live in reviewable data (content JSON, tables, fixtures) and every invariant should be a test; the code is a small, pure interpreter of that data.

## Runtime State Inventory

Not a rename/refactor/migration phase (greenfield; the only state to create is the new save format). Omitted per instructions.

## Common Pitfalls

### Pitfall 1: Dynamic content strings are not in the String Catalog
**What goes wrong:** `Text(LocalizedStringKey("ingredient.hop.x.name"))` renders the raw key in the app when the key is missing from the catalog; PLAT-06 "every on-screen string from the catalog" silently fails for content-driven text.
**Why:** Xcode extracts only literals visible at compile time; the key built from JSON is invisible. Also, `xcodebuild` on the command line did **not** write new literal keys into the `.xcodeproj`'s `.xcstrings` (spike: added `Text("brand_new_literal")`, build succeeded, catalog file unchanged) — extraction into the source catalog is an IDE behavior, so a scripted executor must add keys itself.
**How to avoid:** Add every key to the catalog by script/hand; add the content-key integrity test (Pattern 9); prefer generated symbols for static text on Xcode 26+ (compile-time errors for removed keys) [CITED: tessl.io ios-localization summary of Xcode 26 behavior]. `STRING_CATALOG_GENERATE_SYMBOLS` failed on the local Xcode 16.4 (`reference to member 'ledgerTitle' cannot be resolved`) [VERIFIED: spike], so confirm after the upgrade and keep literals as the fallback.
**Warning signs:** UI shows `snake.case.keys`; pseudo-loc screenshot shows single-length text.

### Pitfall 2: Ledger rows do not sum to the displayed total
**What goes wrong:** rounding/clamping makes the sheet show +3.2 +0.8 −0.5 = 3.4 while the bar says 3.5.
**How to avoid:** Int centi-points; total = Σ rows; explicit `cap` row; remainder rule in marginal attribution; invariant test over the whole recipe grid (all 16 attributes).

### Pitfall 3: Clamping hides the cause
**What goes wrong:** an attribute pinned at 10.0 makes later ledger rows meaningless to the player.
**How to avoid:** the `cap` row is shown ("Capped at maximum −x.x"); design tuning aims for typical beers well inside 0-10 (assert via tests that starter-style beers have ≤2 capped attributes).

### Pitfall 4: Content tuning silently rewrites saved beers
**What goes wrong:** if the app re-derives results from recipes on load, any balance edit changes beers players have already seen (D-20 makes stats part of the contract).
**How to avoid:** save recipe + result snapshot + `contentVersion`. Add a "re-brew drift" test: brewing each fixture recipe under current content equals its stored snapshot; a deliberate content change must either bump `contentVersion` and update snapshots or be rejected. (Phase 3 immutable-recipe versioning, COLL-02, builds on this.)

### Pitfall 5: Ingredient IDs leak into permanent saves
**What goes wrong:** IDs like `hop.citra` freeze a possibly trademarked name into saves.
**How to avoid:** stable, neutral IDs (`hop.h01` or descriptive fictional names), display names only via the catalog. `Citra`, `Mosaic` are registered marks of Hop Breeding Company; Simcoe is a marketed brand name [CITED: trademark.justia.com/owners/hop-breeding-company-l-l-c-1563237 via search]; COLL-07 and the Out-of-Scope table already require fictional names where trademarked. D-05's "Citra: citrus, tropical" is an example, not a roster mandate. Start the names-cleared log (roadmap research flag) with the app name, every hop/yeast name used, and the style names.

### Pitfall 6: Codable shape surprises
**What goes wrong:** enum-keyed `Dictionary` or enums with associated values encode in non-obvious shapes; renaming a Swift property changes the JSON key.
**How to avoid:** `[String: Int]` keyed by raw strings or arrays of `{id,value}` in a fixed order; explicit `CodingKeys`; golden fixture frozen. `[ASSUMED]` exact Swift behavior per version; the fixture test is the guard regardless.

### Pitfall 7: Grain-bill auto-rebalance edge cases (D-14)
**What goes wrong:** "largest malt absorbs the remainder" flips identity when a specialty exceeds the base; base can go negative; adjuncts (flaked oats, sugar) have caps.
**How to avoid:** store `baseGrainID` explicitly (first-added or chosen by tap); specialty steppers move in 5% steps; disable "+" when the base would drop below a minimum (e.g., 10%) or the grain's `maxPercent` is hit; invariant `Σ percents == 100` enforced in `GrainBill` init and `SaveValidator`; unit tests for random stepper sequences.

### Pitfall 8: Double-advancing the day / losing the beer on force-quit
**How to avoid:** Pattern 6; test: reducer `.brew` once advances `day` exactly `fermentDays + conditioningDays`; relaunch UI test asserts the beer is present and the day is unchanged after force-quit during reveal.

### Pitfall 9: Hop "Aroma (flameout)" vs "Whirlpool" are different slots in D-15
**What goes wrong:** treating both as the same minutes collapses a decision.
**How to avoid:** define distinct IBU-utilization factors and aroma weights per slot in content (e.g., effective minutes: bittering 60, flavor 15, aroma 5, whirlpool 20 at reduced utilization; `[ASSUMED]` values for tuning). Dry hop (conditioning) adds aroma with zero IBU.

### Pitfall 10: Liquid Glass leaks into "custom" screens
**What goes wrong:** on iOS 26+, standard nav bars, toolbars, sheets, `Stepper`/`Toggle`/alerts adopt the system material when built with the iOS 26 SDK [CITED: tessl.io swiftui-liquid-glass summary]; CLAUDE.md notes `UIDesignRequiresCompatibility` is ignored with the iOS 27 SDK (MEDIUM). Mixed looks reduce store-page polish.
**How to avoid:** decision below; all game controls are custom `ButtonStyle`s; the ledger sheet and share/import UI are the only system chrome; give the sheet `.presentationBackground` a solid panel color.

### Pitfall 11: Privacy manifest drift
**What goes wrong:** using `UserDefaults`/`@AppStorage`/`@SceneStorage` or file-timestamp APIs (`attributesOfItem`, `creationDate`, `contentModificationDate`) without a declared reason blocks upload [CITED: developer.apple.com required-reason API page via fetch].
**How to avoid:** Phase 1 uses neither; ship the minimal manifest (`NSPrivacyTracking` false, empty arrays — spike-verified bundled). If a later plan adds UserDefaults, add `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` (key names `[ASSUMED]` from training; verify against Apple's page when needed).

### Pitfall 12: Overflow traps from imported saves
**What goes wrong:** Swift traps on Int overflow; a hostile or corrupted import with huge amounts crashes the app.
**How to avoid:** `SaveValidator` bounds every numeric field (percent 0-100, amounts 0-N, days ≥0 and ≤ sane cap, ledger delta magnitude) before anything multiplies them; use `&+`/clamped helpers in the engine; size cap on import data.

### Pitfall 13: ASC prerequisites block the first upload
**What goes wrong:** upload fails if the bundle ID is not registered or no app record exists, or the name is taken.
**How to avoid:** human checkpoint ahead of the upload task (Environment Availability + Open Questions); name "Brew Fighter" was not found as an existing App Store title in one web search [LOW confidence]; availability is only confirmed when reserving in ASC; keep a fallback name.

## Code Examples

### Ledger invariant test (Swift Testing)
```swift
// Source: design for this phase; Swift Testing API is standard (spike ran @Test/#expect OK)
import Testing
@testable import BrewCore

@Test(arguments: RecipeGrid.sample(seed: 42, count: 500))
func ledgerSumsExactlyToValue(recipe: Recipe) throws {
    let beer = try Brewer.brew(recipe, content: .starter)
    for attr in AttributeID.allCases {
        let rows = beer.ledger.rows(for: attr)
        #expect(rows.reduce(0) { $0 + $1.delta } == beer.attributes[attr])
    }
}
@Test func brewIsDeterministic() throws {
    let r = StarterRecipes.housePaleAle
    #expect(try Brewer.brew(r, content: .starter) == Brewer.brew(r, content: .starter))
}
@Test func brewDoesNotTouchRNG() throws {
    var rng = SeededRNG(seed: 7); let before = rng
    _ = Reducer.apply(.brew(StarterRecipes.housePaleAle, id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!), to: .new, rng: &rng)
    #expect(rng == before)
}
```

### Package.swift for BrewCore (spike-verified shape; `swift test` passed)
```swift
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "BrewCore",
    platforms: [.iOS(.v17), .macOS(.v14)],     // spike used .v18; lower floor keeps engine buildable broadly
    products: [.library(name: "BrewCore", targets: ["BrewCore"])],
    targets: [
        .target(name: "BrewCore", resources: [.process("Resources")]),
        .testTarget(name: "BrewCoreTests", dependencies: ["BrewCore"],
                    resources: [.copy("Fixtures")]),
    ]
)
```
(`resources:` lines are not spiked; `Bundle.module` for resources is standard SwiftPM.)

### `package` access: hide internals from the app (VERIFIED)
```swift
// BrewCore/Sources/BrewCore/Domain.swift
public struct Beer: Sendable, Codable, Equatable { public let name: String; public init(name: String) { self.name = name } }
package struct TruePalate: Sendable { package let secret = 42; package init() {} }
package func secretScore() -> Int { TruePalate().secret }
public func publicBrew() -> Beer { Beer(name: "x\(secretScore())") }
// BrewCoreTests: `#expect(secretScore() == 42)` PASSED under `swift test`
// App target: `func leak() -> Int { secretScore() }` → error: cannot find 'secretScore' in scope
```
Rule for Phase 1: engine formulas, raw content tables, and (from Phase 2) true patron palates are `package`; the app sees only `public` result types (`Beer`, `LedgerRow`, `GlassSpec`, `ContentCatalog` descriptors) and the `Reducer`/`Brewer` entry points. The app unit-test target cannot see `package` symbols either, so test internals in `BrewCoreTests`. Caveat: this works because the Xcode target has no matching package name; do not set `-package-name` on the app target.

### Pseudo-localization + 44pt UI test sketch (XCTest)
```swift
// Source: design; flag behavior [VERIFIED: simulator spike — catalog "Hello" rendered "Hello Hello" with the flag]
final class ChromeTests: XCTestCase {
    func testEveryControlIs44ptAndTextIsCatalogBacked() {
        let app = XCUIApplication()
        app.launchArguments += ["-NSDoubleLocalizedStrings", "YES", "-UITestResetSave", "YES"]
        app.launch()
        for screen in GameScreens.allForUITest(app) {             // navigate each major screen
            for b in app.buttons.allElementsBoundByIndex where b.isHittable {
                XCTAssertGreaterThanOrEqual(b.frame.width, 44, b.debugDescription)
                XCTAssertGreaterThanOrEqual(b.frame.height, 44, b.debugDescription)
            }
            for t in app.staticTexts.allElementsBoundByIndex where !t.label.isNumericOrSymbolic {
                XCTAssertTrue(t.label.isDoubled, "Not from catalog: \(t.label)")  // "X X" pattern
            }
            try? app.performAccessibilityAudit(for: .hitRegion)
        }
    }
}
```
Caveats: content strings with interpolated numbers/names need an allowlist rule; system-owned elements (share sheet) are excluded by scoping to the app's own windows.

### GameButtonStyle (44pt floor, AdCap press feel)
```swift
// Source: design; ButtonStyle/contentShape/scale are standard SwiftUI
struct GameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 56)            // 44pt floor, 56 default chunky height
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy, value: configuration.isPressed)
    }
}
```

### Privacy manifest (bundled in spike build)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>NSPrivacyTracking</key><false/>
<key>NSPrivacyTrackingDomains</key><array/>
<key>NSPrivacyCollectedDataTypes</key><array/>
<key>NSPrivacyAccessedAPITypes</key><array/>
</dict></plist>
```

### Engine inputs quoted from locked sources
- 16 attributes, verbatim from REQUIREMENTS.md line 14: "(malt, sweetness, dryness, body, bitterness, hop aroma, citrus, tropical, herbal, spice, roast, fruit, funk, sour, carbonation, ABV)".
- Hop slots, verbatim from CONTEXT.md D-15 (line 37): "Bittering (60 min) / Flavor (15 min) / Aroma (flameout) / Whirlpool".
- Conditioning options, verbatim from D-16 (line 38): "**dry hop, fruit, lagering, bottle conditioning**".
- Proposed family mapping for D-11/ENC-08 (discretion; **proposal**): malt = malt, sweetness, roast; hop = bitterness, hop aroma, citrus, tropical, herbal; yeast = fruit, spice, funk, sour; mouthfeel = body, dryness, carbonation, ABV (3+5+4+4 = 16). Phase 2 inherits this, so the planner should confirm it in the plan.

## Derived Stats: Recommended Formulas (D-20, discretion)

| Stat | Approach | Provenance |
|------|----------|------------|
| Batch | Fixed 5 gal / 19 L batch (not a player input) | [ASSUMED] design choice |
| OG | Gravity points = strength-band points × weighted fermentable extract factors (JSON); store as Int points (e.g. 1052) | [ASSUMED] |
| FG | OG points × (1 − attenuation); attenuation = yeast base ± mash-temp band ± ferment band, in Int per-mille | [ASSUMED] |
| ABV | (OG − FG) × 131.25 in gravity points, Int tenths | [ASSUMED] standard homebrew approximation |
| IBU | Tinseth: bigness = 1.65 × 0.000125^(OG−1); time factor = (1 − e^(−0.04·t)) / 4.15 [CITED: brewersfriend / Grainfather help pages via search]. Because hop timing is 4 named slots, **pre-compute `slotTimeFactor` and a gravity-factor table by OG point offline**; runtime is Int multiply/divide | CITED formula, ASSUMED table generation |
| SRM | Morey: SRM = 1.4922 × MCU^0.6859 [CITED: search result], or simply a linear MCU→SRM table in content | CITED formula; table is design |

Cross-platform determinism rationale: IEEE-754 requires correctly rounded `+ − × ÷` but not `exp`/`pow` [ASSUMED, standard knowledge]; do the transcendental work once in a generator script whose output table is committed.

## Phase 1 Open Design Gaps Found (planner must resolve)

1. **No total-grain / gravity input exists in the locked decisions.** D-14 gives percentages only; OG/ABV/body need a strength. Without one, nearly every beer lands at the same OG and ABV, which makes the ABV attribute and nerd stats flat, and the design doc's "Lower Gravity Variant → Session Pale Ale" lineage impossible. **Recommendation:** add a "Batch strength" banded dial to the Mash stage (Session / Standard / Strong / Imperial → fixed grain weights), consistent with D-04. This is a small addition inside Claude's discretion ("exact starter-recipe contents", band definitions) but should be surfaced to the user in the plan (see Open Questions).
2. **Hop amount units.** D-15 says "slot × hop × amount" without units. Recommend integer quarter-ounce steps (1-16) per slot entry, displayed in oz.
3. **Conditioning combination rule.** Recommend multi-select with day costs summed (dry hop 3, fruit 7, bottle conditioning 14, lagering 28 are starting values, `[ASSUMED]`); lagering excludes bottle conditioning.
4. **Ferment duration bands.** Recommend Quick 7 / Standard 14 / Extended 21 days (`[ASSUMED]`) so D-10's day cost spans ~7-65 days.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-edited/GUI `.xcodeproj` with per-file registration | Xcode 16+ synchronized folders (via XcodeGen `syncedFolder`) | Xcode 16 (2024) | New files need no project edits |
| `ObservableObject`/Combine | `@Observable` | iOS 17 | Per-property tracking for counters |
| Localizable.strings | String Catalogs; typed symbols | Xcode 15; symbols Xcode 26 | Compile-time key safety (26+) |
| Xcode 16 for App Store uploads | Xcode 26+ / iOS 26 SDK required | 2026-04-28 [CITED: developer.apple.com/news/upcoming-requirements] | This Mac must be upgraded |
| Old age rating tiers | 4+/9+/13+/16+/18+; infrequent alcohol → 13+, frequent → 18+ | Responses due 2026-01-31 [CITED: Apple pages] | Record 18+ in ASC |

**Deprecated/outdated:** `NavigationView`, `ObservableObject` for new code (CLAUDE.md "What NOT to Use"); `app-store` export method string (deprecated; use `app-store-connect`) [VERIFIED: `xcodebuild -help`].

## Decision: Custom Chrome vs Liquid Glass (research flag)

**Recommendation: custom chrome for every game screen; system chrome only where the OS owns the surface.** Reasons: (1) the AdCap-style chunky buttons are `ButtonStyle`s that Liquid Glass does not restyle; (2) under the iOS 27 SDK Liquid Glass applies on iOS 26+ regardless of the compatibility opt-out (CLAUDE.md, MEDIUM-HIGH), so the only control is *which controls you use*; (3) one visual regime is a stated reason for the iOS 26 floor. Concretely: hide the nav bar, no `TabView`, no system `Stepper`/`Toggle`/`Picker` on game screens, ledger as a `.sheet` with a solid `presentationBackground`, system `ShareLink`/`fileImporter`/alerts accepted as system chrome. Record this as a Key Decision in PROJECT.md. Re-check at Phase 5 (ART-04 formalizes the one-treatment rule).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `STRING_CATALOG_GENERATE_SYMBOLS` and `Text(.symbol)` work as described on Xcode 26+ (fails on local 16.4; behavior from secondary sources) | Pattern 9, Pitfall 1 | Plan uses literals; low cost |
| A2 | `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` / `SWIFT_APPROACHABLE_CONCURRENCY=YES` are the right Xcode 26 setting names | Pattern 1 | Concurrency warnings/errors until fixed |
| A3 | SRM stops above #8 and BJCP-like style envelopes are approximate | Pattern 5, 10 | Visual/threshold tuning; covered by tests |
| A4 | ASC app records cannot be created via API; creation is a web-UI human step | Environment, Pattern 8 | If API exists, more automation possible |
| A5 | Automatic signing with `-allowProvisioningUpdates` will create a cloud-managed distribution certificate for upload (only an Apple Development cert exists locally) | Pattern 8 | Extra manual cert step |
| A6 | `performAccessibilityAudit(for: .hitRegion)` flags <44pt hit regions (secondary sources) | Validation | Frame-assertion loop is the real guard |
| A7 | IEEE-754 doesn't guarantee `exp`/`pow` bit-identity across platforms | Derived Stats | Table approach is still harmless |
| A8 | Privacy-manifest category key names (`NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`) | Pitfall 11 | Only matters if UserDefaults is added |
| A9 | `ShareLink(item: tempFileURL)` shares the file correctly on device; `FileRepresentation` has known issues | Pattern 7 | Needs a real-device test; fallback to UIActivityViewController wrapper |
| A10 | Swift Codable enum-keyed dictionaries/associated-value enums encode non-obviously | Pitfall 6 | Fixture guards it |
| A11 | iPhone-only (`TARGETED_DEVICE_FAMILY=1`) apps run scaled on iPad | Pattern 1 | Matches CLAUDE.md intent; confirm on iPad simulator |
| A12 | Mac14,6 (M2 Max) supports macOS Tahoe 26.6 for Xcode 27 | Environment | Would force Xcode 26.x path |
| A13 | Hop/yeast/grain names listed as non-trademarked; hop ID/name clearance | Pitfall 5 | Names-cleared log is the mitigation; no legal advice |
| A14 | "Brew Fighter" is available as an App Store name (single web search found none) | Pitfall 13 | Pick fallback name at ASC |
| A15 | Starter day costs and band values (ferment 7/14/21; conditioning 3/7/14/28; whirlpool 20-min equivalent) | Gaps | Tuning only |

## Open Questions

1. **Batch strength / total gravity input (Gap 1).**
   - What we know: D-14 specifies percentages only; OG/FG/ABV (D-20) and the ABV attribute need a gravity driver.
   - What's unclear: whether the user wants a strength dial in the Mash stage or a fixed 5-gal standard strength.
   - Recommendation: add a 4-band "Batch strength" dial; confirm with user at plan time (cheap to reverse before Phase 2 consumes ABV).
2. **Toolchain path: Xcode 26.x on Sequoia 15.6+ vs Xcode 27 on Tahoe 26.6.**
   - Known: Xcode 26.0-26.3 need macOS Sequoia 15.6+; 26.4-26.6 need Tahoe 26.2+; Xcode 27 needs Tahoe 26.6+ [CITED: developer.apple.com/xcode/system-requirements]. CLAUDE.md locks Xcode 27 / Swift 6.4.
   - Recommendation: upgrade directly to Tahoe 26.6+ and Xcode 27 (stack-locked, covers the SDK floor); fall back to Xcode 26.x only if Tahoe is unavailable. Also download the iOS 26/27 simulator runtime.
3. **Commit the generated `.xcodeproj`?** `ios-scaffold.md` says gitignore it; Xcode Cloud (planned for Phase 2+) and any Xcode edits are simpler with it committed. Recommendation: commit it and add a CI/pre-commit "regenerate produces no diff" check; this is a deliberate deviation to document.
4. **Real bundle ID, display name, and signing team.** A paid (non-free) team is configured in this Mac's Xcode; confirm it is the intended publisher, pick the reverse-DNS bundle ID, and reserve the name in ASC before the upload task.
5. **Declared Age Range scope.** Apple's Texas SB 2420 tooling exists on iOS 26+, enforcement status is volatile (injunction Dec 2025, appeal stay, later reporting of a 2026-06-04 effective date). Phase 1 has no accounts and is 18+, so recommend *no integration in Phase 1*, record the finding, and re-verify at Phase 6.
6. **Screenshots.** Apple's current page lists one required iPhone set: "iPhone with Dynamic Island (medium display)" at 1179 × 2556 (alternative 1206 × 2622), scaled down to smaller sizes [CITED: developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications]. No screenshots are needed for internal TestFlight; only record this for Phase 6.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| macOS (Apple silicon) | Everything | ✓ but too old | 15.3.2 on Mac14,6 / M2 Max [VERIFIED: `sw_vers`, `sysctl`] | Upgrade to ≥15.6 (Xcode 26.0-26.3) or Tahoe 26.6+ (Xcode 27) |
| Xcode | App target, TestFlight | ✓ but too old | 16.4 (16F6) [VERIFIED: `xcodebuild -version`] | Install Xcode 26.x/27 (human, large download) |
| Swift toolchain | `BrewCore`, tests | ✓ | 6.1.2 (SwiftPM 6.1.0) [VERIFIED] | Engine work proceeds now with tools-version 6.0 |
| iOS Simulator runtime | UI tests, previews | ✓ but only 18.6 [VERIFIED: `simctl list runtimes`] | iOS 18.6 | Download iOS 26/27 runtime after Xcode upgrade (`xcodebuild -downloadPlatform iOS`) [ASSUMED command] |
| XcodeGen | Scaffold | ✓ | 2.45.4 [VERIFIED] | — |
| Disk space | Xcode + runtime | ✓ | 170 GiB free [VERIFIED: `df`] | — |
| Signing | Device/TestFlight | Partial | 1 Apple Development identity; Xcode has a non-free team [VERIFIED: `security find-identity`, `defaults read com.apple.dt.Xcode`] | Cloud-managed distribution cert via `-allowProvisioningUpdates` (A5) |
| Physical iPhone (iOS 26+) | Criterion 1 install via TestFlight | Unknown | — | TestFlight needs a real device; human confirms |
| ASC app record, bundle ID, API key | Upload | ✗ (not created) | — | Human checklist below; STATE.md already lists this blocker |
| tuist | — | ✗ | — | Not needed |

**Missing dependencies with no fallback (block the TestFlight criterion and all app-target compile):**
- macOS/Xcode upgrade to a toolchain with the iOS 26+ SDK (human).
- App Store Connect: bundle ID registration, app record with name reserved, age-rating questionnaire answered (alcohol "frequent" → 18+), internal TestFlight tester added (human, web UI).

**Missing dependencies with fallback:**
- iOS 26 simulator runtime: engine tests run without it; UI tests wait for it.

**Human checklist (planner: encode as `checkpoint:human-action` tasks):** (1) upgrade macOS + install Xcode, accept license (`sudo xcodebuild -license`) and download platform runtime; (2) confirm Apple Developer team and bundle ID; (3) create the ASC app record (name reserved, primary language, bundle ID, SKU); (4) set Age Rating in App Information, answering the alcohol question as frequent so the result is 18+ [CITED: Apple age ratings definitions page]; then record the 18+ decision in PROJECT.md Key Decisions; (5) add yourself as an internal tester; (6) optionally create an ASC API key (Admin/App Manager) for headless uploads and store the `.p8` outside the repo.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, ran as v124.4 locally) for `BrewCore`; XCTest/XCUITest for UI |
| Config file | none yet — Wave 0 creates `Packages/BrewCore/Package.swift`, `project.yml` |
| Quick run command | `cd Packages/BrewCore && swift test` (works on installed Swift 6.1.2, no simulator) |
| Full suite command | `swift test` in `Packages/BrewCore` + `xcodebuild test -project BrewFighter.xcodeproj -scheme BrewFighter -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` (needs the new Xcode + iOS 26 runtime) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BREW-01 | Recipe validity floor (≥1 grain + yeast; bill sums 100; hops/conditioning optional) | unit | `swift test --filter RecipeValidationTests` | ❌ Wave 0 |
| BREW-01 | Stepper auto-rebalance invariants over random sequences | unit | `swift test --filter GrainBillTests` | ❌ Wave 0 |
| BREW-02 | Same recipe → identical beer; RNG untouched; all 16 attrs present and in range | unit | `swift test --filter BrewDeterminismTests` | ❌ Wave 0 |
| BREW-02 | Content integrity (IDs resolve, ranges, no dup IDs, catalog keys exist) | unit | `swift test --filter ContentValidationTests` | ❌ Wave 0 |
| BREW-04 | Ledger rows sum exactly to every attribute value over recipe grid | unit (parameterized) | `swift test --filter LedgerInvariantTests` | ❌ Wave 0 |
| BREW-06 | Each style reachable; fallback share bounded; classifier input is attributes only | unit | `swift test --filter StyleClassifierTests` | ❌ Wave 0 |
| BREW-07 | Day advances by fermentation + conditioning days exactly once; no timers in code | unit + grep | `swift test --filter DayCounterTests`; `grep -rn "Timer\|asyncAfter\|sleep" App/ Packages/ ` reviewed (reveal animation allowance) | ❌ Wave 0 |
| PLAT-03 | Golden V1 save decodes, validates, re-encodes byte-stable; future version rejected; corrupt → backup; export→import round trip | unit | `swift test --filter SaveCodecTests` | ❌ Wave 0 |
| PLAT-03 | Beers survive force-quit/relaunch | UI | `xcodebuild test … -only-testing:BrewFighterUITests/PersistenceTests` | ❌ Wave 0 |
| PLAT-06 | Catalog keys integrity (unit) + doubled-string UI check | unit + UI | `swift test --filter CatalogKeyTests`; `-only-testing:BrewFighterUITests/ChromeTests` | ❌ Wave 0 |
| PLAT-01 | 44pt hit regions on every screen | UI | `-only-testing:BrewFighterUITests/ChromeTests` | ❌ Wave 0 |
| ART-01 | `GlassSpec` pairwise distinct across starter styles; deterministic per beer | unit | `swift test --filter GlassSpecTests` | ❌ Wave 0 |
| PLAT-05 | Build carries privacy manifest, ITSAppUsesNonExemptEncryption, portrait; archive validates | script | `xcodebuild archive …` then `plutil -p` on built Info.plist; `xcrun altool`/export `destination=upload` is the human-verified step | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `swift test` in `Packages/BrewCore` (seconds).
- **Per wave merge:** full suite incl. UI tests once the new Xcode lands.
- **Phase gate:** full suite green, one real-device TestFlight install, manual five-second glance at the reveal on device, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `Packages/BrewCore` skeleton + `Tests/BrewCoreTests/Fixtures/save_v1.json` (generate once with a script, then freeze; add a checksum test so accidental edits fail)
- [ ] `RecipeGrid` deterministic enumerator (shared by ledger/style/save tests)
- [ ] `project.yml`, app + test + UI-test targets, `.gitignore` additions
- [ ] Catalog + content-key parser test helper
- [ ] Framework install: none for tests (bundled); macOS/Xcode upgrade is the gating item for app-target tests

Manual-only items (justified): real-device TestFlight install; subjective "glass looks different/good" and reveal feel (cannot be asserted; use GlassSpec distance as the automated proxy); share-sheet export/import on device (system UI); ASC age-rating entry.

## Security Domain

`security_enforcement` is enabled in `.planning/config.json` (ASVS level 1, block on high).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No accounts, no network |
| V3 Session Management | no | — |
| V4 Access Control | no | Single-user local app |
| V5 Input Validation | yes | `SaveValidator` on every decoded save/import: version gate, size cap, numeric bounds, referential tolerance (unknown IDs must not crash UI) |
| V6 Cryptography | no | No crypto; `ITSAppUsesNonExemptEncryption = NO` |
| V8 Data Protection | partial | Save in Application Support (included in device backup); no PII, no analytics SDKs; privacy label "Data Not Collected" |
| V12 Files/Resources | yes | Imports via system picker; security-scoped access with `defer stop…`; never execute or follow paths from file content; temp export files in the temp dir |
| V14 Configuration | yes | No secrets in repo (ASC `.p8`, team IDs in untracked env/config); `.gitignore` additions |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hostile/corrupt imported save (huge arrays, overflow values) | DoS / Tampering | Size cap, bounded numerics, `SaveValidator`, current save untouched on failure, pre-import backup |
| Int overflow trap in engine from unvalidated amounts | DoS | Validate inputs; clamped arithmetic helpers |
| Newer-schema save opened by older app | Tampering | `newerThanApp` error, no partial load |
| Leaking true palates to UI (Phase 2) | Information disclosure (design-level) | `package` access (spike-verified) |
| Committing signing keys | Information disclosure | `.gitignore` `*.p8`, `*.mobileprovision`, `*.p12`; store outside repo |
| Alcohol-promotion review risk (Guideline 1.4.3) | Compliance | Copy frames ABV/IBU as brewing stats and tasting, no intoxication language; no "buzzed/drunk" strings in Phase 1 [CITED: CLAUDE.md] |

## Sources

### Primary (HIGH confidence)
- Local spike builds/tests on this Mac (scratchpad project; Xcode 16.4, Swift 6.1.2, XcodeGen 2.45.4): scaffold shape, `package` access, privacy manifest/Info.plist/catalog bundling, `-NSDoubleLocalizedStrings`, catalog extraction behavior, generated-symbol failure on 16.4.
- `xcodebuild -help` (local) — export options (`destination`, `method`, `manageAppVersionAndBuildNumber`), signing/auth flags.
- https://developer.apple.com/xcode/system-requirements — Xcode/macOS matrix (fetched 2026-10-08).
- https://developer.apple.com/news/upcoming-requirements/ — Xcode 26 / iOS 26 SDK floor since 2026-04-28, min target iOS 13 since 2026-09-09, new age rating system.
- https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/ — infrequent alcohol → 13+, frequent → 18+.
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/ — required iPhone screenshot size and scaling.
- https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api — required-reason categories.
- https://raw.githubusercontent.com/yonaskolb/XcodeGen/master/Docs/ProjectSpec.md — `syncedFolder`, local packages, `info`.
- `.planning/phases/01-brew-your-first-beer/01-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.claude/CLAUDE.md`, `brewfighter-design-v1.md`, `~/.claude/gsd-core/references/ios-scaffold.md`.

### Secondary (MEDIUM confidence)
- https://www.macrumors.com/2026/06/03/apple-app-store-texas-sb-2420 and 9to5mac/ppc.land coverage — Texas SB 2420 / Declared Age Range status.
- https://tessl.io/registry/dpearson2699/swift-ios-skills/… (ios-localization, swiftui-liquid-glass summaries) — Xcode 26 generated string symbols; Liquid Glass adoption by standard components.
- https://developer.apple.com/forums/thread/734741 — ShareLink + FileRepresentation issue; https://useyourloaf.com/blog/accessing-security-scoped-files/ — security-scoped URLs.
- Tinseth/Morey formula references: brewersfriend.com, help.grainfather.com, arxiv.org/pdf/2204.02752 (via search).
- https://trademark.justia.com/owners/hop-breeding-company-l-l-c-1563237 — hop trademarks (via search).
- SRM hex stops 1-8 from beer-color charts (BJCP color reference and npm `beer-color`, via search).

### Tertiary (LOW confidence)
- Web search for an existing "Brew Fighter" app (none found) — not authoritative for ASC name availability.
- XCUIAccessibilityAudit `hitRegion` semantics from tessl/apiumhub summaries — confirm in Xcode docs.

## Metadata

**Confidence breakdown:**
- Standard stack / scaffold: HIGH — spiked and built locally; remaining risk is Xcode 26/27-only settings (A1, A2) and the untested UI-test target.
- Toolchain gate and ASC steps: HIGH on the version matrix (Apple page), MEDIUM on exact automation limits (A4, A5).
- Architecture (engine/ledger/save): MEDIUM-HIGH — standard techniques, not yet implemented; invariants are test-backed.
- Brewing formulas/style thresholds/day costs: MEDIUM-LOW — intentionally approximate, tuned by tests (Claude's-discretion area).
- Pitfalls: HIGH for items spiked (1, package access, catalog behavior), MEDIUM for the rest.

**Research date:** 2026-10-08
**Valid until:** 2026-10-22 for Xcode/macOS/App Store requirement facts (fast-moving: Xcode 27.2 beta in flight, Texas law status volatile); 30 days for the architectural recommendations.
