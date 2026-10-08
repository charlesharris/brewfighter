# Walking Skeleton — Brew Fighter

**Phase:** 1
**Generated:** 2026-10-08

## Capability Proven End-to-End

A player taps BREW in The Cellar on an iPhone simulator, the pure `BrewCore` engine turns the bundled house pale ale recipe into a beer with 16 attributes, a contribution ledger and a computed style, the app autosaves it to a versioned JSON envelope on disk, and the beer is still listed after the app is terminated and relaunched.

Plan 01-01 proves the engine half headlessly with `swift test` (recipe in, beer out, envelope bytes, the same state back). Plan 01-02 proves the full stack: XcodeGen app, local package link, bundled content loading inside the app, `@Observable` store, atomic file write, and a relaunch UI test.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Native iOS, Swift 6 language mode, SwiftUI + Observation (`@MainActor @Observable final class GameStore`) | Locked in CLAUDE.md. One store holds a `GameState` value type and exposes intent methods. |
| Engine boundary | Local Swift package `Packages/BrewCore` (tools-version 6.0, platforms iOS 17 / macOS 14) that imports Foundation only. Value types are `Sendable` and nonisolated. Engine formulas and raw content tables use `package` access; the app sees only `public` result types and entry points (`Reducer`, `RecipeRules`, `ContentCatalog`, `SaveCodec`, `GlassSpec`). | Headless `swift test` on macOS/Linux with no simulator. `package` access was spiked: visible to BrewCoreTests, a compile error in the app target. Never set `-package-name` on the app target. |
| Engine shape | `Reducer.apply(_ action: Action, to: GameState, content: ContentCatalog, rng: inout SeededRNG) -> (GameState, [GameEvent])`. Brewing is deterministic and never touches the RNG. Events are replayed by the UI as animation. | CLAUDE.md pattern. Determinism makes ledgers, golden saves and balance tests possible. |
| Numeric model | Int fixed-point only. Attributes are Int **tenths** on 0...100 (shown as 0.0-10.0). OG/FG are gravity points (1050 = 1.050), ABV/IBU/SRM are Int tenths. Transcendental math (Tinseth, Morey) is precomputed offline into committed JSON tables by `scripts/gen-brew-tables.swift`. | Ledger rows shown at one decimal sum exactly to the displayed total, and results are bit-identical across platforms. |
| Ledger | Additive `LedgerRow { attribute, source, delta }`. Displayed value = sum of rows. Clamping emits an explicit `cap` row. Rows come out in fixed brewing-stage order, and zero-delta rows are never emitted. | D-17: signed rows sum to the total. |
| Attribute families (cross-phase contract, D-11 / ENC-08) | malt = malt, sweetness, roast; hop = bitterness, hopAroma, citrus, tropical, herbal; yeast = fruit, spice, funk, sour; mouthfeel = body, dryness, carbonation, abv (3+5+4+4 = 16) | Phase 2 encounter breakdowns inherit this grouping. |
| Content | JSON under `Packages/BrewCore/Sources/BrewCore/Resources/Content/`, loaded via `Bundle.module` (`.copy("Resources/Content")`), validated by tests. IDs are neutral and stable (`grain.g01`, `hop.h01`, `yeast.y01`, `adjunct.a01`). Display text is always a catalog key (`content.hop.h01.name`, `trait.citrus`, `style.american_pale_ale.name`). | Data-driven and diffable. Trademark-safe IDs never freeze into saves. |
| Data layer | One Codable JSON save: `SaveEnvelope { schemaVersion, contentVersion, payload: GameState }`, encoded with `.sortedKeys`. Decode path: size cap (5 MB), header version gate, migrator chain, decode, validate. App-side `SaveRepository` writes `Application Support/BrewFighter/save.json` atomically, copies the prior file to `save.backup.json`, and loads primary then backup. Beers persist recipe + result snapshot + `contentVersion`. | PLAT-03. Snapshots mean later balance tuning cannot rewrite beers the player has seen. |
| Auth | None. Single-player, offline, no accounts, no network. | Keeps the privacy manifest empty and the label at "Data Not Collected". |
| Navigation / chrome | `GameShell` switches on a `Screen` enum held by `GameStore`. No system nav bar, tab bar, stepper, toggle or picker on game screens. All controls use `GameButtonStyle` (min 44pt wide, 56pt high, press-scale). System chrome is limited to `.sheet` (solid `presentationBackground`), `ShareLink`, `.fileImporter` and alerts. | Research decision on custom chrome vs Liquid Glass: one visual regime on iOS 26+. |
| Strings | One `App/BrewFighter/Localizable.xcstrings`. Every key is a semantic dotted identifier (`cellar.brewButton`), optionally followed by SwiftUI interpolation specifiers. Every value with a format specifier uses positional specifiers (`%1$lld`). `scripts/check-strings.swift` enforces catalog coverage of app literals and content keys. | PLAT-06. A missing key renders as a visible dotted key, which UI tests detect. Positional specifiers survive pseudo-localization doubling. |
| Project generation | `project.yml` + XcodeGen 2.45.4 with `type: syncedFolder` sources, a local package dependency and a shared scheme. The generated `BrewFighter.xcodeproj` **is committed** (a deliberate deviation from ios-scaffold.md so Xcode Cloud and IDE edits work); `xcodegen generate` on an unchanged spec must produce no diff. The app is never an SPM executable target. | Spike-verified on Xcode 16.4. |
| Deployment target | `IPHONEOS_DEPLOYMENT_TARGET` is 18.0 while the Mac runs Xcode 16.4 (the newest target that toolchain can build). Plan 01-09 raises it to the locked 26.0 floor after the human toolchain upgrade. Until then, no iOS 26-only API is used (`@Animatable`, generated string symbols, glass-effect APIs). | Environment constraint, not a scope change: the iOS 26 floor in CLAUDE.md is delivered in 01-09. |
| Deployment target (distribution) | Internal TestFlight via `scripts/archive-upload.sh` (`xcodebuild archive` + `-exportArchive`, `method=app-store-connect`, `destination=upload`, automatic signing, `manageAppVersionAndBuildNumber`). | PLAT-05. Xcode Cloud is optional later. |
| Dev loop | `swift test --package-path Packages/BrewCore` (seconds, no simulator); `xcodegen generate`; `scripts/test-app.sh [-only-testing:...]` resolves an available iPhone simulator UDID and runs `xcodebuild test`. | Grounded commands every plan reuses. |
| Directory layout | `Packages/BrewCore/{Sources/BrewCore/{Model,Engine,Content,Style,Glass,Save,Resources/Content},Tests/BrewCoreTests/{Support,Fixtures}}`, `App/BrewFighter/{Shell,Cellar,Wizard,Reveal,BeerDetail,Ledger,Glass,UIKit,Persistence}`, `App/BrewFighterTests`, `App/BrewFighterUITests`, `scripts/`, `config/` | Feature folders on the app side; role folders in the engine. |

## Stack Touched in Phase 1

- [x] Project scaffold (framework, build, lint, test runner): XcodeGen project with app, unit-test and UI-test targets; BrewCore package with Swift Testing (plans 01-01, 01-02)
- [x] Routing (at least one real route): `GameShell` + `Screen.cellar` (01-02), extended with `.wizard`, `.reveal`, `.detail` (01-06, 01-08)
- [x] Database (at least one real read AND one real write): `SaveRepository` atomic write + load of the `SaveCodec` envelope (01-02)
- [x] UI (at least one interactive element wired to the engine): Cellar BREW button → `GameStore.brew` → `Reducer.apply(.brew)` (01-02)
- [x] Deployment (dev environment OR documented local full-stack run command): `scripts/test-app.sh` on the iOS simulator (01-02); TestFlight internal build (01-10)

## Out of Scope (Deferred to Later Slices)

- Encounters, patrons, palate effects, clue notebook, tap lineup, balance harness (Phase 2)
- Live attribute preview while composing, recipe journal, rebrew-from-journal, beer naming, recipe versioning and lineage, destructive-action confirmations beyond import (Phase 3)
- Collection gating, rarity, yeast mutation, synergies, reward tables, share cards, AI art pipeline (Phase 4)
- City map, locations, bosses, illustrated patrons (Phase 5)
- Onboarding/mentor, codex, music/SFX, haptics, settings screen and settings persistence (Phase 6)
- iCloud sync, Game Center, iPad layouts, localization beyond English (v2)
- Autosave of mid-wizard draft state and exact-screen resume (PLAT-02, Phase 2). Phase 1 persists brewed beers only.

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- Phase 2: Serve 3-pour encounters from a 6-tap lineup against ~10 patrons (new `Reducer` actions, encounter screens under `GameShell`, palate data behind `package` access, headless balance harness)
- Phase 3: Iterate recipes: live preview, journal, versioned recipes with parent links (save schema v2 with a migration + golden fixture), scouting, hints, accessibility pass, fun-gate
- Phase 4: Collect and evolve: reward tables, Yeast Bank, family trees, Regulars Book, AI art pipeline
- Phase 5: The city: node map, 40+ patrons, 8 bosses, knowledge-driven gates
- Phase 6: Onboarding, feel and launch: mentor, codex, audio, haptics, settings, App Store release
