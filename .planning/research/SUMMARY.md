# Project Research Summary

**Project:** Brew Fighter
**Domain:** Hybrid genre game — creature-collection (beers) + crafting-sim (brewing) + deduction-puzzle, built in DragonRuby GTK for commercial desktop release
**Researched:** 2026-10-06
**Confidence:** MEDIUM-HIGH

## Executive Summary

Brew Fighter is a hybrid genre game: creature-collection (beers) + crafting-sim (brewing) + deduction-puzzle (Wordle/Obra Dinn style). The recommended stack is DragonRuby GTK 7.x with a pure-simulation core, immediate-mode scene stack, and three-data-tier architecture (Defs / Profile / Session). The critical risk is proving the matchup puzzle is fun before building full scope — an explicit vertical-slice gate with outside playtesters is non-negotiable.

The stack is mature and well-documented. The architecture patterns are proven (including by the same-author sibling MechTech DragonRuby project). The main challenges are UI scale (6+ collection screens) and game-design iteration (scoring, clue budget, status effects require headless tuning before playtesting).

**Strategic recommendation:** Commit to full v1 scope (~30-40 patrons, 5-8 locations, 5-6 bosses), but sequence to prove the core loop in an ugly vertical slice (rectangles + text, 10 patrons, 6 taps) by Phase 3. No bulk art, world, or content scale until the gate passes. This delays visible progress but prevents rework.

## Key Findings

### Recommended Stack

DragonRuby GTK 7.x (7.10 latest observed): zero dependencies, hot reload, one-command Win/Mac/Linux packaging. mruby runtime — no gems, so community libraries (Draco, Zif — stale since 2021-2023) should be avoided in favor of small in-repo systems.

**Core technologies:**
- DragonRuby GTK 7.x: engine — fixed choice, user owns license; confirm tier (Standard $48 = manual Steam upload; Indie $96/yr = turnkey `dragonruby-publish` Steam + C extensions/achievements)
- In-repo scene stack (~100 lines) + intent-based input layer: no UI toolkit exists; focus model and glyph prompts must be built Phase 1
- Versioned JSON saves via hand-written encoder: engine's `serialize_state` writes Ruby text loaded with `eval` and warns above 20k chars — avoid; engine reads JSON natively via `DR.parse_json`
- Seeded, serializable PRNG stored in Profile
- Art pipeline: PixelLab (subscription) or Retro Diffusion (one-time) + locked ~32-color palette + post-process cleanup (proper-pixel-art/unfake) + Aseprite finishing; procedural beer rendering (tinted layered sprites), not per-recipe generation
- Rendering: 1280×720 logical, art at 4x scale (320×180), `scale_quality=3`
- Testing: built-in `--test` runner behind a wrapper script (runner only logs a summary)

### Expected Features

**Must have (table stakes):**
- 6-tap party management; collection log/Codex; recipe journal
- Live attribute preview while brewing — protects "understand why" success criterion
- 3-pour encounters with itemized score breakdowns and auto-recorded clue notebook (each reaction line tagged with the fact it reveals)
- Settings, versioned saves, full input abstraction (mouse/keyboard/gamepad), controller-friendly text entry, Steam Deck-readable text, colorblind-safe attribute display

**Should have (competitive):**
- Sensory-profile matchup against hidden palates (NOT style-matching)
- Status-effect serving-order tactics; recipe evolution with ancestry; yeast mutation
- Regulars progression with passive benefits; boss rule-modifiers; real-brewing learning via codex

**Defer (v2+) / anti-features:**
- Regional expansion, management systems, multiplayer (v2+)
- No real-time fermentation timers, no pure-RNG hidden traits, no grind gates, no losing beers on defeat, no mini-game brewing, cap status effects at 6-8, no procedurally generated patrons

### Architecture Approach

Layered, with a pure domain core: L0 shell (main, Input, Assets, Audio) → L1 data (Defs, Profile, Save) → L2 domain (pure functions, no `args`) → L3 flow (SceneStack, Game) → L4 presentation (Scenes, UI). Three data tiers kept apart: Defs (immutable content), Profile (saved plain-primitive state), Session (transient); Profile/Session reference Defs by id only.

**Major components:**
1. Brewing sim — pure functions producing attribute vectors with per-source contribution ledgers (powers "why did this succeed/fail")
2. Encounter engine — palate scoring, status effects (declarative rules), event-log output replayed by scenes as animation/dialogue; `PatronView` boundary enforces hidden information
3. Collection systems — immutable recipes with `parent_id` lineage from day one, Yeast Bank with forked mutation, Regulars Book derived from play, one generic collection browser
4. Cross-cutting — intent input layer with single focus rule, scene stack, versioned JSON save with slots + backup, domain-event progression queue

### Critical Pitfalls

1. **Full game before core proven** — gate Phase 3 vertical slice with 3+ outside playtesters against design criteria #2/#6/#7; pivot or stop if it fails
2. **Stat soup (16 attribute bars)** — present in families (Malt/Hop/Yeast/Mouthfeel), glyphs + radar, numbers on drill-down
3. **Deduction collapses into style-matching or frustration** — style labels computed from attributes (output, not input); info budget 1-2 facts per pour; coarse preference resolution; headless solvability test ≥70%; losing still records clues
4. **Dominant recipe / no balance tooling** — real brewing tradeoffs; balance harness generating archetype beers; require ≥4 distinct best-in-class
5. **Input abstraction retrofit** — build Phase 1; one focus rule everywhere; test gamepad-only and keyboard-only every phase
6. **Save/serialization debt** — versioned JSON, no `eval`, round-trip tests on production paths (dev saves go to game dir, production to OS sandbox); set `devtitle`/`gametitle` before first save ships
7. **AI art style drift** — style-lock spike (10-12 test assets), locked palette, post-process script, provenance manifest (Steam requires AI-content disclosure)

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Engine Foundation
**Rationale:** No UI toolkit exists in DragonRuby; input/focus/save decisions are costly to retrofit
**Delivers:** Engine setup + run/test wrappers, intent input layer, scene stack, UI kit (focus, List, Grid, Panel, dialogue), Defs + validation, save serializer spike, Tuning.rb, debug HUD, art style-lock spike, license-tier confirmation + hello-world Steam/itch upload check
**Avoids:** Input retrofit, save debt, art drift, Steam-tier surprises

### Phase 2: Simulation Core
**Rationale:** The game's fun lives in pure logic that can be tuned headlessly before any UI exists
**Delivers:** Brewing sim with contribution ledger, palate scoring, encounter state machine, declarative status effects, clue/info-reveal policy, ~10 patron Defs, immutable recipe + lineage model, seeded Rng, headless balance harness (solvability ≥70%, heatmap reports)
**Avoids:** Deduction collapse, dominant-recipe balance failure

### Phase 3: Core-Loop Vertical Slice + GATE
**Rationale:** Prove brew → serve → learn is fun before art, world, or content scale
**Delivers:** Brewing scene with live preview, tap lineup, 3-pour encounter scene, result screen, clue notebook, basic Regulars Book, inventory, Yeast Bank basics, settings, input parity, save/load v1, onboarding draft, 10 patrons, 3-4 locations, placeholder art, 3-OS smoke builds
**Gate:** 3+ outside playtesters pass design criteria #2/#6/#7; harness solvability ≥70%. If gate fails: pivot or stop.

### Phase 4: Collections & Progression
**Rationale:** Collection depth builds on proven core and save schema
**Delivers:** Codex (Unseen/Seen/Owned/Mastered), generic CollectionBrowser, acquisition-as-unlocks, yeast mutation (fork lineage, show diff), recipe archive with lineage view, Regulars progression (Seen→Friend), closed perk set (unlock/discount/+1 pour/hint), progression event queue, content scale toward ~30-40 patrons, 5-6 bosses, 25+ ingredients, 8+ yeasts

### Phase 5: World & Difficulty
**Rationale:** World is content + gating over existing systems; node-map avoids free-roam scope explosion
**Delivers:** 5-8 location Defs, node-map travel, location hotspot scenes, acquisition sources, unlock gating, 5-6 boss encounters with rule overrides, calendar/day abstraction, settings expansion, accessibility (colorblind-safe, text scale), 3-OS QA, partial Steam metadata, itch.io upload

### Phase 6: Art, Audio & Presentation
**Rationale:** Bulk art only after systems and content are stable; pipeline is scripted and manifest-tracked
**Delivers:** Bulk portraits (patrons × expressions, post-processed), ingredient icons, location backdrops, 9-slice UI frames, procedural beer visuals (cached render targets, texture count <1500 vs 2048 cap), pour animation, VFX, music + SFX with sliders/crossfade, animation polish, Steam Deck QA, asset provenance manifest

### Phase 7: Release Hardening
**Rationale:** Commercial requirements verified on real builds, not assumed
**Delivers:** Save migration + corrupted-save recovery QA, error logging, 3-OS production launch tests, Steam store page (capsule, trailer, AI + alcohol content disclosure), itch.io release, wishlist funnel ("coming soon" 2+ weeks pre-launch), achievements (if tier permits), cloud-save verification, credits, help/glossary, RC testing, post-launch plan

### Phase Ordering Rationale

- Foundations (input/save/UI kit) come first because DragonRuby provides none of them and all are expensive to retrofit
- Pure simulation precedes UI so balance and solvability are tuned headlessly with a harness
- The Phase 3 gate front-loads the project's biggest risk — whether deduction gameplay is fun — before content/art spend
- Collections → world → art is dependency order: content scale needs proven systems; bulk art needs stable content
- Release hardening is last but Steam-tier and packaging assumptions are spiked in Phase 1 to avoid late surprises

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** save serializer spike (JSON vs engine-native), controller API verification on real hardware, art style-lock spike, license tier decision, production save paths
- **Phase 2:** scoring formula design (expect 2-3 tuning passes), clue reveal policy, balance-harness design
- **Phase 3:** external playtest protocol for the gate
- **Phase 5:** calendar/day model decision, Steam Cloud path verification
- **Phase 7:** macOS signing/notarization (absent from DragonRuby docs), Steamworks achievements/cloud API confirmation

Phases with standard patterns (skip research-phase):
- **Phase 4:** collection browsers, progression queues are proven patterns
- **Phase 6:** art pipeline follows the Phase 1 spike's scripts; rendering patterns well-documented

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Engine facts from official DragonRuby docs, source, and changelog; licensing from official site (HD-mode tier detail has a docs/changelog discrepancy) |
| Features | MEDIUM-HIGH | Table stakes well-established from genre conventions; differentiators reasoned — no direct comparable exists |
| Architecture | MEDIUM-HIGH | Patterns verified in DR docs + working same-author sibling project (MechTech); genre adaptation is synthesis |
| Pitfalls | MEDIUM | Design risks synthesized from genre + design doc; DR-specific pitfalls from docs and sibling repo |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- License tier confirmation: gates Steam automation and achievements — resolve in Phase 1
- Economy model (recommend: ingredients as permanent unlocks, not consumables) — decide before Phase 4
- Time model (recommend: abstract days, no real-time timers) — decide before Phase 5
- Content budget: lock v1 patron/boss/location counts (recommend ~30 patrons, 6 bosses, 5-8 locations) — Phase 4/5 planning
- Attribute list: lock the 16 sensory attributes before Phase 2
- AI-art commercial terms: read generator EULAs before Phase 6 bulk work; Steam AI disclosure required
- mruby capability check (`Set`, `Struct`, pattern matching, JSON encoding) — Phase 1 spike
- Steamworks achievements/cloud and macOS notarization — verify Phase 7 (treat achievements as optional until confirmed)
- Audio sourcing plan — only an art plan exists; decide by Phase 6
- Trademark exposure (hop names like "Citra", "Untappd" references) — review before store page

## Sources

### Primary (HIGH confidence)
- Official DragonRuby GTK docs repo + changelog (v7.x) — engine features, serialization, texture cache, test runner, packaging
- Local DragonRuby engine install (`~/src/mechtech/dragonruby-macos`, build 0d709c3, v7.18) — shipped docs read first-hand
- Same-author MechTech repo learnings — hot-reload traps, mruby quirks, test runner behavior, require ordering
- DragonRuby pricing page — license tiers

### Secondary (MEDIUM confidence)
- Steam guides/devlogs — DragonRuby → Steam publishing paths, Auto-Cloud behavior
- Store reviews and community discussion (Potion Craft, Monster Sanctuary, Travellers Rest) — genre complaint patterns
- Web summaries of Valve AI-content disclosure policy

### Tertiary (LOW confidence)
- AI pixel-art tool comparison articles (PixelLab, Retro Diffusion) — pricing/terms need direct verification
- Steamworks achievements/cloud availability via DragonRuby — unconfirmed, needs spike

---
*Research completed: 2026-10-06*
*Ready for roadmap: yes*
