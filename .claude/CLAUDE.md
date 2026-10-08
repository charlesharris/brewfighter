<!-- GSD:project-start source:PROJECT.md -->

## Project

**Brew Fighter**

Brew Fighter is a collectible brewing RPG for iPhone — Pokémon-style collection and matchup strategy, except the creatures are beers you personally design and evolve. The player collects ingredients, yeast cultures, recipes, and techniques; brews beers with real (but approachable) brewing decisions; and wins tactical encounters by serving the right beer to bar patrons whose palates they must deduce. Built natively in Swift/SwiftUI, portrait-orientation, with an Adventure Capitalist-style UI feel (bright, button-heavy, satisfying) wrapped around Pokémon-style "battles," targeting a commercial App Store release.

**Core Value:** Players create beers, develop them over time, learn which people they work against, and build a tap list that feels distinctly theirs. If everything else fails, the brew → serve → learn → improve loop must be genuinely fun and produce "my saison is great against adventurous patrons" moments.

### Constraints

- **Tech stack**: Native iOS — Swift + SwiftUI-first (encounters included; Canvas/animations for juice) — user's choice after pivoting from DragonRuby
- **Devices**: iPhone, portrait orientation, one-handed friendly; iPad runs scaled (no native iPad layouts in v1)
- **Art**: AI-generated AdCap-style flat/cartoon art — no artist budget assumed; pipeline must accommodate regeneration
- **Input**: Touch-first; standard iOS gestures and accessibility
- **Quality bar**: Commercial App Store release — store-page quality polish expected
- **Monetization**: Undecided (premium vs F2P+IAP) — must be decided before the economy phase; economy design keeps both doors open until then
- **Design fidelity**: `brewfighter-design-v1.md` is authoritative for mechanics and tone

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Headline Recommendation

## Platform and Toolchain (verified 2026-10-08)

| Item | Current value | Source | Confidence |
|------|---------------|--------|------------|
| Latest Xcode | **Xcode 27** (27A266a, 2026-09-14); 27.1 RC on 2026-10-05; Xcode 26.6 (2026-06-25) | developer.apple.com/news/releases | HIGH |
| Latest iOS | iOS 27.0.1 (2026-09-28); iOS 27.2 in beta | developer.apple.com/news/releases | HIGH |
| Latest Swift | **Swift 6.4** (released 2026-09-15; Swift Build now default in SwiftPM; Swift Testing/XCTest interop) | swift.org blog, swiftlang/swift-testing release tag | HIGH |
| App Store upload floor | Must build with **Xcode 26 / iOS 26 SDK or later** since 2026-04-28. Min deployment target must be iOS 13+ since 2026-09-09 | developer.apple.com/news/upcoming-requirements | HIGH |
| Xcode 27 host requirement | macOS Tahoe 26.6+, Apple silicon only | secondary blog sources | MEDIUM (confirm in Xcode 27 release notes) |
| Liquid Glass | `UIDesignRequiresCompatibility` opt-out is **ignored when building with the iOS 27 SDK**; new design applies on iOS 26+ regardless of deployment target | Apple dev forums + secondary sources | MEDIUM-HIGH |

### Minimum deployment target: **iOS 26.0**

| Reason | Detail |
|--------|--------|
| Adoption is already high | iOS 26 ran on 79% of all active devices and 86% of devices from the last four years as of 2026-06-07 (Apple). The game will not ship before 2027, so the share will be higher. |
| No hardware cut | iOS 27 supports the same devices as iOS 26 (iPhone 11 and newer). Targeting iOS 26 only excludes people who have not updated, plus iPhone XS/XR owners. |
| One visual regime | Under the iOS 27 SDK, Liquid Glass is unavoidable on 26+. Supporting iOS 17/18 as well means QA of two looks (system chrome, sheets, alerts, tab bars) for a solo dev. Most of this UI is custom chunky buttons, so the saving is mostly in sheets, alerts and nav chrome. |
| Newest APIs are free | `@Animatable` macro, current SwiftUI performance work, newest Instruments SwiftUI tooling. |

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift | 6.4 (language mode 6) | All code | Current release. Swift 6 mode gives compile-time data-race safety. |
| SwiftUI | iOS 26 SDK (build with iOS 27 SDK) | All UI, including encounter scenes | The game is panels, buttons, meters, lists and staged scenes. SwiftUI is the fastest route to an Adventure Capitalist-style UI and has enough animation power for Pokémon-style staging. |
| Observation (`@Observable`) | iOS 17+ | UI state | Per-property change tracking, so numeric counters and meters re-render only the views that read them. Replaces `ObservableObject`/Combine. |
| Swift Concurrency (approachable) | Swift 6.2+ model | Save I/O, audio loading | App target: Xcode 26+ defaults for new projects are *Approachable Concurrency* on and default actor isolation `MainActor`, which suits UI-heavy code. Keep `BrewCore` **nonisolated, `Sendable` value types** so it stays testable off the main actor and portable to Linux. |
| Xcode project | Single `.xcodeproj` plus local Swift packages | Project structure | Xcode 16+ folder-synchronized groups remove most merge-conflict and file-registration pain, which was the main reason to use XcodeGen/Tuist. Skip both. |

### Project Structure

### State Management

| Technology | Purpose | Why |
|------------|---------|-----|
| Single `@MainActor @Observable final class GameStore` | Holds `GameState` (value type from `BrewCore`); exposes intent methods (`serve(beer:)`, `startBrew(...)`) | One source of truth, trivial to preview with fixtures, no framework to learn. |
| Engine as pure functions: `(GameState, Action, inout RNG) -> (GameState, [GameEvent])` | Brewing resolution, pour scoring, status effects, clue reveal | Deterministic and unit-testable. The returned **event list** (score deltas, clue revealed, status applied, meter crossed 100) is what the UI plays back as animations. Logic and presentation stay decoupled. |
| `NavigationStack` for menu depth; a root `GameShell` switching on a `Screen` enum for encounter and modal transitions | Navigation | The encounter should be a staged scene, not pushed system chrome. |

### Animation and "Game Juice" (SwiftUI only)

| API | Min iOS | Use for |
|-----|---------|---------|
| `.contentTransition(.numericText())` plus `withAnimation` | 17 | The Adventure Capitalist number-roll: satisfaction meter, coins, ABV counters |
| `.keyframeAnimator` / `PhaseAnimator` | 17 | Button squash-and-stretch, pour "thunk", patron reaction pops, reward reveal |
| Spring presets (`.bouncy`, `.snappy`, `.smooth`) | 17 | Default feel for all state changes |
| Custom `ButtonStyle` with press scale and shadow-drop | any | The chunky tactile button, the core of the AdCap feel |
| `Canvas` + `TimelineView(.animation)` | 15 | Beer bubbles, foam, confetti, sparkle bursts, particle layers. Draw many primitives in one view. |
| Metal shader modifiers (`.colorEffect`, `.layerEffect`, `.distortionEffect`, via `ShaderLibrary`) | 17 | Haze/turbidity on a hazy IPA, shimmer on rare cards, screen-wipe transitions. WWDC26 session 322 ("Compose advanced graphics effects with SwiftUI") shows `layerEffect` + `TimelineView` for animated shaders. |
| `MeshGradient` | 18 | Rich liquid colour gradients and encounter backdrops |
| `.matchedGeometryEffect`, `.navigationTransition(.zoom)` | 14 / 18 | Card to detail "collectible" zoom, tap handle to pour transitions |
| `.symbolEffect`, `.sensoryFeedback` | 17 | Icon bounces, simple haptics |
| `@Animatable` macro | 26 | Custom animatable shapes (glass fill levels) with less boilerplate |
| `.scrollTransition` | 17 | Parallax and scale on collection lists |
- Default: write a small stateless emitter (position computed from `age = now - birth`, about 150 lines) drawing in `Canvas`.
- Optional accelerator: **Vortex** (twostraws, v1.0.4, Canvas-based, iOS 15+, presets for confetti/sparkle/bubbles). A single-maintainer package, so vendor it into the repo rather than depending on it if used.
- **Performance rules (HIGH confidence, stable SwiftUI practice):** resolve symbols and images once outside the draw loop; use `.drawingGroup()` only on content that is not mutating the view tree; target 8 to 10 ms frame cost for 120 Hz ProMotion; cap live particles around a few hundred; honour `accessibilityReduceMotion` (replace big motion with fades, shorten shakes); test on an iPhone 11-class device.
- **Escape hatch, only if profiling proves Canvas cannot hold 60 fps for a specific effect:** a `SpriteView` containing an `SKEmitterNode`, scoped to that overlay. SpriteKit is not deprecated, but it is a second rendering model to maintain. Do not host scenes in it.

### Persistence (versioned saves with recipe lineage)

| Option | Verdict | Why |
|--------|---------|-----|
| **Codable `GameState` serialized to one JSON file** | **Use this** | Entire game state is small (hundreds of recipes, dozens of yeast, a few hundred progress flags) and lives in memory anyway. Gives a human-readable, diffable save, golden-file migration tests, atomic writes, trivial backup and a clean path to iCloud later. |
| SwiftData | Do not use | `@Model` classes couple game logic to persistence, so headless engine tests would need a `ModelContainer`. Migrations (`VersionedSchema` + `SchemaMigrationPlan`) are workable for simple changes but have a documented history of production regressions (CloudKit sync and migration issues across iOS 17 to 26 per Apple forum threads). Wrong tool for data you never query relationally. |
| GRDB 7.11.1 (2026-06-18) / SQLiteData 1.12.0 (2026-08-31) | Escape hatch only | Excellent migrator and observation if saves ever become relational or huge (for example full encounter history analytics). Not needed in v1; the Codable model can be migrated into it later. |
| Core Data / Realm | Do not use | Core Data predates the Swift-native model; Realm is effectively in wind-down. |

### Content Data Format

| Technology | Purpose | Why |
|------------|---------|-----|
| JSON files decoded with `Codable` (ingredients, yeast, patrons, bosses, locations, status effects, dialogue) | All authored content | Editable by hand or by an AI assistant, diffable, validated by tests. Swift array literals of hundreds of structs are slow to compile and un-diffable; avoid them. |
| Tests that load every content file | Validation | Referential integrity (every ID resolves), attribute ranges (the roughly 16 sensory attributes), "every patron is beatable with ingredients available by that location", no duplicate IDs. |
| String Catalog (`Localizable.xcstrings`) | UI chrome strings | Default in new Xcode projects; English-only in v1 but localization-ready. Xcode 27 adds a localization agent. Patron dialogue stays in JSON keyed by ID. |

### Audio

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| AVFoundation `AVAudioEngine` + preloaded `AVAudioPCMBuffer`s (SFX) | iOS 26 | Low-latency tap/pour/clink SFX with overlapping voices | A small `SFXPlayer` with about 8 `AVAudioPlayerNode` voices handles rapid tapping without the stutter of re-creating players. |
| `AVAudioPlayer` (music) | any | Looping music, `setVolume(_:fadeDuration:)` for crossfades | Simple and sufficient. |
| `AVAudioSession` category `.ambient` | any | Respect the silent switch and let the user's podcast keep playing | Right default for a casual game; offer a setting to take over audio. |
| Formats | | SFX as 16-bit PCM `.caf`/`.wav`; music as AAC `.m4a` (128 to 192 kbps) | Convert with `afconvert` (ships with macOS). |
- Sonic Pi **v5.0.0** (released 2026-08-07, macOS 13+, new "SuperSonic" audio engine) is the current version. Built-in samples are published under CC0, and sounds you synthesize are yours (per Sonic Pi community statements). Check the license files in the Sonic Pi repo before shipping any recording as final audio. **Confidence: MEDIUM.**
- The available MCP servers (for example `vinayak-mehta/mcp-sonic-pi`, Apache-2.0, last pushed 2025-03, 19 stars) send code/notes to a **running** Sonic Pi over OSC. They **do not render files**. Treat them as a convenience for having the AI write live-loop Ruby, then do a manual capture. **Confidence: MEDIUM.**
- Pipeline: AI writes `live_loop` code -> play in Sonic Pi -> record to WAV with its Record feature (bar-aligned, reverb tail trimmed for loops) -> normalize (ffmpeg `loudnorm` about -16 LUFS for music, peak-normalize SFX) -> `afconvert` to `.m4a`/`.caf` -> drop into the app.
- Make audio **replaceable**: code references logical IDs (`enum SFX { case pour, perfectPour, clue, ... }`) mapped to filenames in one table, so placeholder audio can be swapped for commissioned or licensed audio with no code change.
- Sonic Pi is strong for synth bleeps, jingles and ambient loops. It is weak for realistic liquid/glass SFX; expect to need real recordings or a licensed pack before launch.

### Haptics

| Technology | Purpose | Why |
|------------|---------|-----|
| `.sensoryFeedback(...)` (iOS 17+) | About 90% of haptics: selection, success, impact on state changes | Declarative and trivial. |
| Core Haptics (`CHHapticEngine`, AHAP JSON patterns) | 3 to 5 signature moments: pour stream, perfect-pour crescendo, boss hit | Custom envelopes cannot be done with the basic generators. Gate on `CHHapticEngine.capabilitiesForHardware().supportsHaptics`; handle engine stop/reset; stop on background. |
| A single `Haptics` service wrapper with a settings toggle | Central control | Lets settings and Reduce Motion preferences disable haptics in one place. |

### Art Pipeline and Asset Management

| Asset | Source | Format |
|-------|--------|--------|
| Patron portraits (about 30 to 40 patrons plus 8 bosses, each with roughly 3 to 4 expressions) | AI-generated, curated | Transparent PNG, one canonical size (about 1024 px square is enough at 3x) |
| Ingredient/yeast/hop icons (collectible) | AI-generated | Transparent PNG |
| Location backdrops (about 8 to 10) | AI-generated | Opaque PNG/JPEG |
| Beer glass, foam, bubbles, meters, panels, buttons, rarity frames | **SwiftUI code (procedural)** | None; keeps UI crisp at every size and restyle-able in one place |
| Generic glyphs (gear, lock, star, chevron, speaker) | **SF Symbols** | Built-in; use for settings/system affordances only, not collectibles (they look generic next to cartoon art) |
| App icon | Icon Composer (ships with Xcode 26+) | Layered `.icon` for iOS 26 styling |
- Raw AI output with no meaningful human authorship is generally not copyrightable in the US (Copyright Office, 2025). Plan on modest human edits (composition, layering) for anything you want to defend as a brand asset, and use a **paid tier whose terms grant commercial rights**. **Confidence: MEDIUM** (not re-verified this session; confirm before launch).
- Apple's current App Review Guidelines text (fetched 2026-10-08) contains no rule specific to shipping pre-generated AI art. Some SEO articles claim disclosure rules; those concern apps that generate AI content at runtime. **Confidence: MEDIUM.**

### Testing

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Swift Testing** (`import Testing`, `@Test`, `#expect`, parameterized `arguments:`) | Bundled with Swift 6.4 / Xcode 27 | All engine and content tests | Modern default; parameterized tests suit "for each patron, for each starter beer" matrices. 6.4 adds XCTest interop and repetition. |
| XCTest / XCUITest | Bundled | One UI smoke test (launch, onboarding, first encounter) and `XCTMetric` performance tests | Swift Testing does not do UI automation or performance metrics. |
| `swift test` on macOS host and Linux | SwiftPM | Run `BrewCore` tests in seconds with no simulator | Only possible because the engine imports no UI frameworks. Enforce this. |
| `BalanceSim` executable target | | Run thousands of seeded encounters across patron x beer x ordering and print win-rate/solvability tables | Directly addresses the design doc's "deduction, not frustration" and "serving order matters" criteria. Run as `swift run BalanceSim --seed 42 --runs 10000`. |
| swift-snapshot-testing | 1.19.6 (2026-09-21) | Optional: about 5 key screens | Snapshots shift between simulator/OS versions, so use sparingly. MEDIUM value. |
| `#Preview` with fixture `GameState`s | Xcode | Primary UI iteration loop | Fast, and doubles as a visual catalog of encounter states. |

### Distribution, CI and Compliance

| Technology | Purpose | Why |
|------------|---------|-----|
| Apple Developer Program ($99/yr) | Signing, TestFlight, App Store | Required. |
| **TestFlight** | Internal testers (up to 100) immediately; external (up to 10,000) after first-build Beta App Review | Standard beta path. |
| **Xcode Cloud** | Run tests on push; archive and deliver to TestFlight on tag | Zero signing-certificate wrangling for a solo dev. Included allowance is 25 compute hours/month with the Program; paid tiers start at $49.99/mo for 100 hours. Xcode 27 streamlines onboarding. |
| GitHub Actions (optional) | `ubuntu-latest` job running `swift test` on `BrewCore`; `macos-26` runners for app builds | Cheap Linux-side engine regression. `macos-26` images carry Xcode 26.x GA and Xcode 27 as preview at time of research; verify before relying on it for submissions. |
| fastlane 2.240.1 | Only if screenshots/metadata automation is wanted later | Not needed while Xcode Cloud handles upload. |
| `PrivacyInfo.xcprivacy` | Declare required-reason APIs (UserDefaults, file timestamps) | Mandatory since 2024; omission blocks upload. |
| No third-party analytics/crash SDKs | App Privacy label can say "Data Not Collected" | Use Xcode Organizer and MetricKit; Xcode 27 adds animation-hitch and storage metrics. |
| StoreKit 2 (`StoreView`, `ProductView`, StoreKit config file for local testing) | Only if F2P+IAP is chosen | Premium needs no StoreKit code. Put purchases behind an `Entitlements` protocol so the economy phase can choose later. |
- Apple's age tiers are now 4+, 9+, 13+, 16+, 18+. Per Apple's definitions, **infrequent** alcohol references map to 13+ and **frequent** alcohol references to 18+. A game whose whole premise is beer will likely have to answer "frequent" and land at **18+**. That restricts audience, ads and discovery, and it affects the premium vs F2P decision. **Confidence: HIGH** on the rating table (Apple page), **MEDIUM** on how the questionnaire will resolve for this game.
- Guideline 1.4.3 forbids apps that "encourage ... excessive amounts of alcohol" and any that encourage minors to consume. The design doc's "Buzzed" and "Wrecked Palate" status effects should be framed as palate/sensory mechanics, not intoxication glorification. Flag for UI-copy review.
- Guideline 3.1.1: if collectible randomness is ever sold (for example paid random yeast), odds must be disclosed before purchase. Avoid paid gacha.

## What NOT to Use

| Do not use | Why |
|------------|-----|
| **SpriteKit as the scene host** (beyond a possible `SpriteView` particle overlay) | A second state/render model beside SwiftUI; the game is not physics- or sprite-driven. |
| **SceneKit / RealityKit / Metal engine** | No 3D; SwiftUI shaders cover custom effects. |
| **Unity / Godot / Unreal** | Engine decision is fixed to native Swift. They would add a bridge for every native feature (haptics, StoreKit, accessibility, Dynamic Type). |
| **SwiftData / Core Data** | See Persistence. |
| **The Composable Architecture (1.26.2)** | Strong but heavy: macro-driven, large API, long compile times, steep learning cost. A hand-written pure engine + one `@Observable` store gives the same testability here. |
| **Combine, `ObservableObject`, UIKit wrappers** | Superseded by Observation and SwiftUI. |
| **XcodeGen / Tuist** | Folder-synchronized groups removed the problem they solve. |
| **Lottie / Rive** | Need After Effects/Rive authoring that the AI-art workflow does not produce. Skip unless a specific animated asset demands it. |
| **GameplayKit** | Stale; the seeded RNG is 20 lines. |
| **Foundation Models (on-device LLM) for patron dialogue in v1** | Requires Apple Intelligence-capable hardware (excludes much of the iPhone 11 to 14 base), is non-deterministic, and conflicts with authored comedy and testable clue text. Revisit post-launch. |
| **Third-party ad/analytics SDKs** | Privacy-label cost and 18+ rating friction; unnecessary at launch. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Persistence | Codable JSON | SwiftData | Class-based models couple logic to persistence; migration/CloudKit regression history. |
| Persistence | Codable JSON | GRDB/SQLiteData | Good, but a relational engine for in-memory state is overhead in v1; keep as upgrade path. |
| Architecture | `@Observable` + pure engine | TCA | Complexity and compile cost for a solo project. |
| Particles | Own `Canvas` emitter (optionally vendored Vortex) | SpriteKit `SKEmitterNode` | Extra render model; only if profiling forces it. |
| Min iOS | 26.0 | 18.0 | Reach vs. QA of two design regimes; revisit at release. |
| CI | Xcode Cloud + optional Linux `swift test` | GitHub Actions macOS only | Signing and upload friction, and macOS minutes cost more. |
| Haptics | `.sensoryFeedback` + Core Haptics for signature moments | Core Haptics everywhere | Needless boilerplate. |
| Content format | JSON | Swift literals / SQLite | Compile time, diffability, tooling. |

## Installation / Setup

# Toolchain (user's Mac must be on macOS Tahoe 26.6+ for Xcode 27)

# Engine package (create inside the repo)

# Asset/audio tooling (art pipeline, one-time)

# afconvert ships with macOS; rembg optional: pipx install "rembg[cli]"

## Confidence Summary

| Area | Confidence | Basis |
|------|------------|-------|
| Xcode/iOS/Swift versions, App Store SDK floor, iOS 26 adoption | HIGH | Apple release/requirements/support pages, swift.org, GitHub API (2026-10-08) |
| iOS 26.0 as deployment floor | MEDIUM | Adoption data is solid; the reach vs. QA tradeoff is a product call |
| SwiftUI-only animation/juice approach | HIGH (APIs), MEDIUM (particle limits) | Stable Apple APIs; WWDC26 shader session; practitioner guidance for limits |
| Codable JSON saves over SwiftData | HIGH on fit, MEDIUM on SwiftData reliability evidence | Data shape analysis; forum/blog reports |
| Audio/haptics stack | HIGH | Standard Apple frameworks |
| Sonic Pi + MCP workflow | MEDIUM | Versions verified; end-to-end recording flow not yet exercised; MCP servers are small and stale |
| AI art tooling | LOW-MEDIUM | Fast-moving; practitioner blogs only; needs a spike |
| Copyright/AI policy notes | MEDIUM | Not re-verified this session |
| Age rating (18+) implication | HIGH on table, MEDIUM on outcome | Apple age-rating definitions; the questionnaire outcome depends on answers |

## Sources

- Apple, Upcoming Requirements: https://developer.apple.com/news/upcoming-requirements/ (HIGH)
- Apple, Releases: https://developer.apple.com/news/releases/ (HIGH)
- Apple, App Store support / OS adoption: https://developer.apple.com/support/app-store/ (HIGH)
- Apple, Age ratings values and definitions: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/ (HIGH)
- Apple, App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/ (HIGH)
- Swift 6.4 release: https://www.swift.org/blog/swift-6.4-released/ (HIGH)
- WWDC26, What's new in Xcode 27: https://developer.apple.com/videos/play/wwdc2026/258/ (HIGH)
- WWDC26, Compose advanced graphics effects with SwiftUI: https://developer.apple.com/videos/play/wwdc2026/322/ (HIGH)
- Apple dev forums, Liquid Glass / iOS 27: https://developer.apple.com/forums/thread/839061 (MEDIUM)
- Xcode 27 requirements write-up: https://blakecrosley.com/blog/xcode-27-release (MEDIUM)
- Canvas/TimelineView practice: https://swiftcrafted.dev/article/swiftui-canvas-timelineview-custom-drawings-animated-graphics-ios-26 (MEDIUM)
- GitHub API release data (2026-10-08): groue/GRDB.swift 7.11.1, pointfreeco/sqlite-data 1.12.0, pointfreeco/swift-snapshot-testing 1.19.6, pointfreeco/swift-composable-architecture 1.26.2, twostraws/Vortex 1.0.4, fastlane 2.240.1, sonic-pi-net/sonic-pi v5.0.0 (HIGH)
- GitHub Actions macOS 26 runners: https://github.blog/changelog/2026-02-26-macos-26-is-now-generally-available-for-github-hosted-runners/ (MEDIUM-HIGH)
- Xcode Cloud pricing (search summaries): https://developer.apple.com/xcode-cloud/get-started (MEDIUM)
- Sonic Pi MCP servers: https://github.com/vinayak-mehta/mcp-sonic-pi (MEDIUM)
- SwiftData issue reports: https://developer.apple.com/forums/thread/775060 and related (MEDIUM)
- AI art tooling roundups (LOW-MEDIUM): https://ludo.ai/compare/best-ai-image-generators-for-game-art, https://toonystory.com/blog/best-ai-for-character-consistency-2026

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-fast` for a trivial task inline, with no subagents and no PLAN.md
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
