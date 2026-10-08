# Phase 1: Brew Your First Beer - Pattern Map

**Mapped:** 2026-10-08
**Files analyzed:** ~45 new files (grouped below)
**Analogs found:** 0 / ~45 (greenfield). Tracked files outside .planning are only `.claude/CLAUDE.md`, `.gitignore`, `README.md`.

No in-repo analogs exist. Do not invent any. The planner should use the spike-verified snippets in `01-RESEARCH.md` as the pattern source. They are referenced by section below, so the planner does not need to re-derive them.

## File Classification

| New File (group) | Role | Data Flow | Analog | Pattern Source (RESEARCH.md) |
|---|---|---|---|---|
| `project.yml` | config | batch | none | Pattern 1 (spike-built; full YAML) |
| `.gitignore` (modify) | config | n/a | existing `.gitignore` | Project Structure line: add DerivedData/ build/ *.xcarchive *.ipa xcuserdata/ .swiftpm/ .build/ *.p8 |
| `Packages/BrewCore/Package.swift` | config | n/a | none | Code Examples "Package.swift" (spike-verified) |
| `BrewCore/Model/*` (Recipe, Beer, GameState, AttributeID, LedgerRow, Stats) | model | transform | none | Pattern 4, 6, Pitfall 6 (explicit CodingKeys, string raw enums) |
| `BrewCore/Engine/Brewer.swift`, `Rounding.swift` | service | transform | none | Pattern 3, 4; Derived Stats table (Int fixed-point, table-driven) |
| `BrewCore/Engine/Reducer.swift`, `SeededRNG.swift` | service | event-driven | none | Pattern 6; ledger test example |
| `BrewCore/Content/ContentCatalog.swift` + `Resources/Content/*.json` | service/config | file-I/O | none | Pattern 3 (JSON shape), `Bundle.module` |
| `BrewCore/Style/StyleClassifier.swift` | service | transform | none | Pattern 5 |
| `BrewCore/Glass/GlassSpec.swift` | model | transform | none | Pattern 10 |
| `BrewCore/Save/SaveEnvelope, Migrator, Validator` | service | file-I/O (pure) | none | Pattern 7 (code sketch) |
| `Tests/BrewCoreTests/*` + `Fixtures/save_v1.json` | test | n/a | none | Code Examples (ledger invariant, determinism); Validation map |
| `App/BrewFighter/BrewFighterApp.swift`, `Shell/GameShell, Screen, GameStore` | store/provider | request-response | none | Pattern 2; CLAUDE.md State Management |
| `App/BrewFighter/UIKit/GameButtonStyle, StepperButton, BandDial, Panel, Palette` | component | n/a | none | Code Examples "GameButtonStyle" |
| `App/BrewFighter/Cellar, Wizard, Reveal, BeerDetail, Ledger` | component | CRUD / event replay | none | Pattern 2, 6; CLAUDE.md animation API table |
| `App/BrewFighter/Glass/GlassView.swift` | component | streaming (animation) | none | Pattern 10 |
| `App/BrewFighter/Persistence/SaveRepository.swift` | service | file-I/O | none | Pattern 7 (app side) |
| `App/BrewFighter/Localizable.xcstrings`, `PrivacyInfo.xcprivacy`, `Assets.xcassets` | config | n/a | none | Pattern 9; Privacy manifest example |
| `App/BrewFighterTests`, `App/BrewFighterUITests/ChromeTests, PersistenceTests` | test | n/a | none | Pseudo-loc + 44pt sketch |
| `config/ExportOptions.plist`, `scripts/archive-upload.sh`, `scripts/check-catalog.*` | config/script | batch | none | Pattern 8 |

## Shared Patterns (conventions to establish in the first plans, so later files copy from them)

These do not exist yet. The first file written in each category becomes the in-repo analog for the rest.

### Pure engine boundary
BrewCore imports Foundation only (no SwiftUI/UIKit), is `Sendable` value types, and is tested with `swift test` on the installed Swift 6.1.2 (tools-version 6.0). Engine formulas and raw content tables use `package` access. The app sees only `public` result types. Spike result: a `package` symbol was visible to BrewCoreTests and gave `cannot find 'secretScore' in scope` in the app target. Do not set `-package-name` on the app target.

### Int fixed-point + additive ledger
No `Double` in attribute math. Total = sum of rows. Clamping emits an explicit `cap` row. Transcendentals (Tinseth, Morey) are precomputed offline into JSON tables. See Pattern 4 and the Ledger invariant test.

### Save codec
Excerpt source: RESEARCH Pattern 7. Decode the header first, then check version, size cap, migrate, decode the envelope, validate. Encode with `.sortedKeys`, with explicit `CodingKeys` and string raw enums. The app side writes `.atomic`, copies the prior save to `save.backup.json`, and stays out of UserDefaults and file-timestamp APIs (privacy manifest stays empty).

### Custom chrome
Hide the nav bar, no TabView or system Stepper/Toggle/Picker on game screens, all controls use `GameButtonStyle` (min 44 wide, 56 high, `.snappy` press scale 0.96). The ledger is a `.sheet` with a solid `presentationBackground`. Only ShareLink, fileImporter and alerts are system chrome.

### Strings
Static UI text uses a literal `Text("...")`. Content-driven text uses `Text(LocalizedStringKey(key))`, with the keys added to `Localizable.xcstrings` by script. A BrewCore test asserts every key in the content JSON exists in the catalog. Never store English in the save or in engine output.

### Observable store
A single `@MainActor @Observable final class GameStore` holds `GameState`. It calls the reducer, autosaves on `.brew` before the reveal plays, and the reveal replays `[GameEvent]` presentationally.

## Spike Code Carried Forward (verbatim sources in 01-RESEARCH.md)

- `project.yml` XcodeGen spec with `syncedFolder`, local package `BrewCore`, and three targets: RESEARCH lines 207-250. Spiked on Xcode 16.4 with deployment 18.0. The UITests target was NOT spiked. The Xcode 26 settings (`SWIFT_DEFAULT_ACTOR_ISOLATION`, `SWIFT_APPROACHABLE_CONCURRENCY`, `STRING_CATALOG_GENERATE_SYMBOLS`) are unverified (A1, A2).
- `Package.swift` shape: RESEARCH lines 444-455. `swift test` passed; the `resources:` lines are unspiked.
- `package` access example: RESEARCH lines 460-467.
- Privacy manifest XML: RESEARCH lines 510-518. Bundled in the spike build.
- Archive/upload script and ExportOptions keys (`method=app-store-connect`, `destination=upload`): RESEARCH lines 310-317.
- `-NSDoubleLocalizedStrings YES` verified on the simulator: catalog strings doubled, `Text(verbatim:)` stayed single.

## Proposed Cross-Phase Contract (planner must confirm in a plan)

Attribute families (inherited by Phase 2 ENC-08): malt = malt, sweetness, roast; hop = bitterness, hop aroma, citrus, tropical, herbal; yeast = fruit, spice, funk, sour; mouthfeel = body, dryness, carbonation, ABV (3+5+4+4 = 16).

## Open Gaps the Planner Must Resolve (RESEARCH "Open Design Gaps")

1. Batch strength dial (no gravity input in D-14).
2. Hop amount units (quarter-ounce steps).
3. Conditioning combination rule and day costs.
4. Ferment duration bands (7/14/21).

Also: a human gate for the macOS/Xcode upgrade (Xcode 16.4 and macOS 15.3.2 cannot build iOS 26 or upload). Order the plans engine-first.

## No Analog Found

All files above. The repo has no source code, so each file's pattern comes from the RESEARCH.md sections cited.

## Metadata

**Analog search scope:** `git ls-files` (repo root, outside `.planning`)
**Files scanned:** 3 tracked non-planning files (.claude/CLAUDE.md, .gitignore, README.md)
**Pattern extraction date:** 2026-10-08
