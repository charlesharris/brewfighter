# Project Research Summary

**Project:** Brew Fighter (native iOS collectible brewing RPG)  
**Domain:** Collectible crafting + deduction + collection RPG, iPhone portrait, SwiftUI-first, commercial App Store release  
**Researched:** 2026-10-08 (replaces obsolete DragonRuby version)  
**Confidence:** MEDIUM-HIGH overall

---

## Executive Summary

Brew Fighter is a native iOS deduction-RPG where players brew beers and serve them to patrons to learn hidden taste preferences, then adapt their lineup based on deduced palates. This is a knowledge-driven loop (not a timing/energy loop), which demands premium monetization, instant resumability, and algorithmic balance validation. Research recommends **Swift 6.4 + SwiftUI on Xcode 27 (iOS 27 SDK required from April 2027), with a pure-domain package that runs headless tests and a balance simulator, persisting saves as versioned Codable JSON, not SwiftData.** The core insight is: architecture and persistence decisions made in Phase 1 directly enable or break the TestFlight fun-gate in Phase 3, so get the pure-domain layer testable and the encounter engine reproducible before UI work scales.

**Critical decision gates** are age rating (plan for **18+**, honestly), premium vs F2P (decide at Phase 3, before economy systems ship), and save durability (versioned JSON with migrations, not @Model). **Biggest risks** are Guideline 1.4.3 (mechanics that read as encouraging excessive drinking), Apple SDK deadline (April 2027 cutoff), Liquid Glass UI collision with cartoon art, and solo-dev release logistics piled into week 7. Research flags recommend deeper work during Phase 1 planning on: iOS 27 SDK build pipeline, art provenance pipeline, and TestFlight playtest protocol.

---

## Key Findings

### Recommended Stack

Swift 6.4 and SwiftUI are the mandated foundation. **Xcode 27 / iOS 27 SDK, building for iOS 26+ deployment** (79% adoption; iOS 27 SDK required for App Store uploads from April 2027). Do not use SwiftData for saves — instead, Codable structs serialized to a versioned JSON file in Application Support, with explicit migration functions and frozen fixtures per schema version.

**Core technologies:**
- **Swift 6.4 + SwiftUI (iOS 26+):** UI and app model; @Observable for fine-grained updates; @MainActor default isolation in app target, nonisolated domain package.
- **BrewKit/BrewCore (pure Swift package):** Brewing, encounter scoring, statuses, clues, lineage, progression. Runs swift test on Mac host (no simulator). No SwiftUI, UIKit, or Observation imports.
- **Codable JSON saves + ProfileStore actor:** Versioned envelope, atomic write with rollback, explicit v1→v2→v3 migrations on raw JSON before decode, frozen fixtures per version.
- **SwiftUI animation APIs:** contentTransition(.numericText()) for rolling numbers, keyframeAnimator / phaseAnimator for choreography, Canvas + TimelineView for particles, Metal shader modifiers (iOS 17+), no SpriteKit scene host.
- **AVFoundation + SFX pool:** AVAudioEngine with preloaded AVAudioPCMBuffers for low-latency tap/clink/pour; AVAudioPlayer for looping music; sensoryFeedback + Core Haptics for haptics.
- **Content as JSON:** Hops, grains, yeasts, patrons, bosses, locations, statuses, dialogue; bundled in package; validated at load and in CI; referenced by stable string ID.
- **No third-party SDKs:** Analytics, crash reporting, ads all handled by Xcode Organizer + MetricKit + TestFlight feedback, keeping privacy label clean ("Data Not Collected").

### Expected Features

**Table stakes** (users expect): tap lineup with swap/reorder/presets, collection codexes (Seen/Known/Mastered), rarity tiers with distinct visuals, detail cards, **matchup legibility** (itemized post-pour breakdown), persistent clue notebook, low-cost retry with clue banking, progression gating, live outcome preview while brewing, recipe journal with quick rebrew, memorable patrons with expressions, atmosphere (music/SFX/haptics).

**iPhone-specific table stakes:** instant resume after interruption/kill, short interruptible loops (3-5 min), fully offline play (no account/server), atomic versioned local save, cold start ~2 sec, **one-handed portrait** (bottom actions, 44x44 pt+ targets), **Dynamic Type throughout**, **VoiceOver labels**, Reduce Motion support, settings, onboarding, crash resilience.

**App Store table stakes:** honest age rating (18+ for alcohol references), privacy policy URL, App Privacy label (zero SDKs = "Data Not Collected"), PrivacyInfo.xcprivacy with required-reason APIs, iOS 26 SDK build, screenshots (6.1" required), app preview, reviewer notes explaining theme, metadata complete, Declared Age Range handling (regional, [VERIFY]).

**Differentiators:** sensory-profile matchup layer (16 attributes vs hidden palate, not style-matching), 3-pour deduction encounter with clue reveals, serving-order status effects (6-8 at launch), recipe evolution with preserved ancestry, yeast bank with rarity and mutation, ingredient synergies, Regulars Book with passive benefits, boss encounters (8 in v1), **procedurally rendered beer glass** (SRM color, head, carbonation; resolves AI-art consistency), AdCap-feel juice, ritual reveal moments (deterministic, no loot box), real-brewing codex, share-sheet beer card (local, no trading), colorblind-safe + VoiceOver deduction UI.

### Architecture Approach

**Layered separation:** pure domain (no UI frameworks) → observable app model (GameStore + sessions) → SwiftUI views. Domain logic as synchronous (state, input) -> (state, [DomainEvent]) functions, entirely Sendable value types, testable off main actor and in a headless CLI balance harness.

**Key patterns:**
1. GameStore is single @MainActor @Observable, holds Profile as @ObservationIgnored value, publishes narrow diff-assigned slices (taps, recipes, codex, etc.) so changes invalidate only affected views.
2. Pure domain reducers return event logs; Encounter.serve runs synchronously, truth advances immediately, presentation (EncounterPresentation) lags behind and catches up beat-by-beat via PlaybackDirector.
3. PatronView hidden-information boundary: compile-time package access, lint fallback, prevents UI reading true palates before clue reveals.
4. Custom chunky UI end-to-end (custom tab bar, NavigationStack per tab, fullScreenCover for encounters, no system chrome on game screens); Liquid Glass is unavoidable with iOS 27 SDK, clashes with cartoon art.
5. Typed IDs (ID<Tag>) and content refs by stable string; recipes are immutable (edit = create child); lineage is parentID forest reconstructed at load.
6. Deterministic seeded RNG (SplitMix64) stored in Profile; outcomes recorded; encounters reproducible for testing and balance harness.

### Critical Pitfalls (Top 5)

1. **Age rating treated as paperwork, but it shapes design, reach, rejection risk.** Alcohol is on every screen → frequent = **18+** per Apple. Plan for 18+ in P1 (craft-beer audience, adult-only). **Prevention:** Fill questionnaire in App Store Connect in P1, rename "Buzzed"/"Wrecked" to "Mellow"/"Loosened Up", add "Drink responsibly" note in Settings, write specific review notes on tasting gameplay. **Detection:** Nobody states the planned rating; store copy contradicts design.

2. **Mechanics and copy reading as encouraging excessive drinking (Guideline 1.4.3).** Real rejections cite drinking-game mechanics. Brew Fighter is not that, but "Buzzed" as a reward, "Wrecked" language trigger skims. **Prevention:** Define rule (player is brewer/server, more alcohol never = more reward), no chug mechanics, **use external TestFlight as an App Review canary** (Beta App Review surfaces alcohol concerns months before launch). **Detection:** Testers describe "Buzzed" as "get them drunk to win"; harness shows high-ABV chaining best strategy.

3. **Marketing metadata, names, trademarks collide with 4+ rules and ad policy.** Guideline 2.3.8: screenshots/icons must be 4+ suitable even at 18+. Design doc names "Untappd," "Citra" hop. **Prevention:** Create app record in P1 to reserve name, rename "Untappd Guy" to generic parody, rename "Citra" to invented, review screenshots against "4+ safe?", add negative prompts to art pipeline. **Detection:** App record doesn't exist; keywords include real brands; portrait shows a logo.

4. **Premium vs F2P deferred until economy built, so economy encodes wrong assumptions.** Timers, energy, "rare drops," soft/hard currency fight instant-retry loop. **Prevention:** **Decide at P3 gate**, after fun-gate. Recommended: **premium** (paid upfront or free-with-one-time-unlock), no energy, no timers, no paid randomness. **Detection:** "timer", "energy", or "premium currency" in plans before decision exists.

5. **Save data that can't survive reinstall, schema change, backgrounding, TestFlight build expiry.** SwiftData is a trap (CloudKit requires relationships optional with inverse, migrations fail with "unknown model version"). **Prevention:** Codable value types in versioned JSON envelope, written atomically by ProfileStore actor, validated by decode before replace, rolling .bak backup. Write migrations from day one with frozen fixtures from every shipped build and round-trip tests. Autosave at every pour and brew. **Detection:** @Model in domain code; no saveVersion; first TestFlight update shows testers empty game.

---

## Implications for Roadmap

### Suggested Phase Structure

**Phase 1: Foundations & Scaffolding**  
Xcode 27 project, pure Swift domain package (BrewKit) running swift test, versioned JSON save envelope + migrations, app record in App Store Connect, TestFlight hello-world, UI kit tokens. **Research flags:** iOS 27 SDK constraints, art tool selection spike, Required-reason API list recheck, Declared Age Range API scope. **Avoids:** Pitfalls 5, 7, 8, 9, 10, 12, 15.

**Phase 2: Deduction Core & Balance**  
Headless scoring engine with ledger, palate model, 3-pour encounter, seeded RNG, balance harness (swift run brew-harness), ~10 patrons, ~20 ingredients, validation tests. **Avoids:** Pitfalls 14, 16, 17, 18, 19, 20.

**Phase 3: Slice, Live Preview & TestFlight Fun-Gate**  
Encounter UI with playback director, brew wizard with live preview, clue notebook, recipe journal, tap lineup, instant save/resume, external TestFlight build, **written playtest protocol** (5-8 craft-beer + 2 non-beer testers, no coaching). **Fun-gate:** 2+ of 3 testers explain a failed pour without help. If pass, unblock Phase 4.

**Phase 4: Collections & Lineage**  
Recipe lineage (immutable, parentID), family tree UI, yeast bank with forking mutation, collection codexes, Regulars Book, beer detail + card, ~40 patrons, ~100 ingredients. **Decision:** Premium vs F2P. **Avoids:** Pitfalls 4, 11, 21.

**Phase 5: City, Bosses, Progression & Economy**  
World node map (8-10 locations), progression/unlock system, 8 boss patrons with named rule modifiers, economy finalized (currency ledger), balance matrix re-run, full accessibility audit, age-rating re-check.

**Phase 6: Art, Audio, Haptics & Onboarding**  
Bulk AI art (30-40 patrons × 4 expressions, provenance manifest), SFX (Sonic Pi → capture → normalize), procedural glass, haptics end-to-end, onboarding curriculum, accessibility final pass, screenshots (4+-safe), metadata draft, perf testing.

**Phase 7: Release**  
Privacy/legal finalization, metadata complete, age-assurance API integration [if mandated], TestFlight → review → phased release.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | **HIGH** | Xcode/iOS/Swift from Apple (2026-10-08). SwiftUI APIs verified. Codable JSON fits data shape. Audio/haptics standard frameworks. Sonic Pi tool-version verified, workflow (MED, needs spike). |
| **Features** | **MEDIUM-HIGH** | App Review Guidelines read directly. Age-rating definitions verified. Feature prioritization is synthesis; retention benchmarks from secondary sources (LOW-MEDIUM, generalization risk). |
| **Architecture** | **MEDIUM-HIGH** | SwiftUI/SwiftPM mechanics HIGH. Pure domain + Observable store is reasoned fit, not benchmarked. Persistence/playback are synthesis (MEDIUM, strong but unproven). |
| **Pitfalls** | **MEDIUM-HIGH** | Age rating, 1.4.3, App Review facts HIGH. TestFlight, SDK deadline HIGH. SwiftUI perf from WWDC25 session 306. Balance/determinism (MEDIUM, game-design best practices). |

**Overall:** MEDIUM-HIGH — sufficient for Phase 1 planning.

### Gaps to Address

1. **Sonic Pi + MCP workflow end-to-end:** Tools verified, recording/normalize/integrate unproven. **Action:** 1-day spike in P1 or early P6.
2. **Art tool consistency at scale:** Style-lock (P1) tests one tool. Scaling to 120+ portraits risks drift. **Action:** Provenance manifest + post-process script (P1); validate first 5 per category (P6).
3. **Declared Age Range API scope:** Texas SB 2420 enforcement unclear as of 2026-10-08. **Action:** Confirm with Apple docs or counsel in P1; integrate in P7 if required (1-day spike).
4. **Required-reason API list at submission:** Stable since May 2024 (HIGH) but may expand. **Action:** Re-check Apple docs at P7.
5. **iPad compatibility and screenshot sizes:** App Store Connect lists 6.1" required, secondary sources cite 6.9". **Action:** Verify in App Store Connect when creating app record (P1).
6. **Monetization ledger pre-decision:** Sketch economy sources/sinks in P2 to unblock P4; finalize decision at P3. **Action:** Ensure P2 sketches don't assume F2P.
7. **Name and IP clearance:** Design doc names "Untappd," "Citra," parody references. **Action:** Create names-cleared.md log in P1; counsel review if budget allows; final review in P5.

---

## Sources

**PRIMARY (HIGH confidence)**
- Apple Upcoming Requirements (2026-09-09)
- Apple Releases (verified 2026-10-08): https://developer.apple.com/news/releases/
- Apple App Review Guidelines (fetched 2026-10-08): https://developer.apple.com/app-store/review/guidelines/
- Apple Age Ratings: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/
- Swift 6.4 Release (swift.org, 2026-09-15): https://www.swift.org/blog/swift-6.4-released/
- WWDC26 Sessions 258, 322, 306

**SECONDARY (MEDIUM confidence)**
- GitHub API (verified 2026-10-08): Xcode 27 release, Vortex 1.0.4, Sonic Pi 5.0.0, GRDB, SwiftData versions
- SwiftUI Canvas/TimelineView: swiftcrafted.dev
- iOS 26 Adoption (Apple, June 2026): 79% active devices
- 18+ gating Australia/Brazil/Singapore (9to5mac, 2026-02-24)
- GameAnalytics mobile session length (2025): 2-5 min typical

---

*Research completed: 2026-10-08*  
*Ready for roadmap: Yes*
