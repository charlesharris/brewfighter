# Requirements: Brew Fighter

**Defined:** 2026-10-06 (revised 2026-10-08 for iOS pivot)
**Core Value:** Players create beers, develop them over time, learn which people they work against, and build a tap list that feels distinctly theirs.

## v1 Requirements

Requirements for initial release (native iOS: Swift/SwiftUI, iPhone portrait, App Store). Each maps to roadmap phases.

### Brewing

- [ ] **BREW-01**: Player can compose a recipe from grain bill, hop choices with timing, yeast, fermentation temperature, and conditioning options
- [ ] **BREW-02**: Brewing choices deterministically produce a beer with the locked set of ~16 sensory attributes (malt, sweetness, dryness, body, bitterness, hop aroma, citrus, tropical, herbal, spice, roast, fruit, funk, sour, carbonation, ABV)
- [ ] **BREW-03**: Player sees a live attribute preview that updates as recipe choices change, with "?" shown for undiscovered ingredient traits
- [ ] **BREW-04**: Every attribute value carries a per-source contribution ledger the player can inspect (which ingredient/choice contributed what)
- [ ] **BREW-05**: Player can rebrew any saved recipe in one action from the recipe journal
- [ ] **BREW-06**: Beer style labels are computed from attributes (output), never chosen as input
- [ ] **BREW-07**: Brewing resolves via the day counter (no real-time waits or timers); fermentation duration is a recipe choice that affects attributes

### Encounters

- [ ] **ENC-01**: Player challenges a patron in a 3-pour encounter, selecting each pour from the 6 active taps to fill a satisfaction meter to 100
- [ ] **ENC-02**: Each pour scores deterministically against the patron's palate and shows an itemized breakdown (+/- per attribute match)
- [ ] **ENC-03**: Each pour reveals 1-2 structured clues about the patron's palate, delivered through character dialogue tagged with the underlying fact
- [ ] **ENC-04**: Patron palates include preferences, dislikes, bitterness/alcohol tolerances, and at least one hidden preference discoverable through play
- [ ] **ENC-05**: Status effects (6-8 at launch, framed as palate effects — Palate Fatigue, Refreshed, Hop Burn, etc.) make serving order change outcomes, each with a visible icon and tooltip; no effect rewards intoxication (more alcohol never means more reward)
- [ ] **ENC-06**: Losing an encounter costs a small resource and allows retry; revealed clues always persist
- [ ] **ENC-07**: Player can request an on-demand hint during an encounter (hint system, e.g., via bartender regular)
- [ ] **ENC-08**: Attribute displays group the 16 attributes into legible families (malt/hop/yeast/mouthfeel) with glyphs, with exact numbers on drill-down
- [ ] **ENC-09**: Boss encounters (8 in v1) apply telegraphed scoring-rule overrides (e.g., Beer Judge enforces style guidelines; original characters only — no real-world trademarks)

### Taps & Deduction Tools

- [ ] **TAP-01**: Player maintains an active lineup of 6 tapped beers, with swap and reorder before encounters
- [ ] **TAP-02**: Player can save and load named tap-lineup presets
- [ ] **TAP-03**: Every clue learned about a patron is auto-recorded in a per-patron clue notebook
- [ ] **TAP-04**: The clue notebook is visible during beer selection, showing known/suspected/unknown per palate dimension
- [ ] **TAP-05**: Player can review patron knowledge before an encounter to plan a counter-lineup (scouting/prep view)

### Collections

- [ ] **COLL-01**: Every brew is auto-saved to a recipe journal with search, filter, and favorites
- [ ] **COLL-02**: Recipes are immutable versions preserving ancestry (parent recipe) from the first brew onward
- [ ] **COLL-03**: Player can browse a recipe family tree UI showing a lineage's evolution
- [ ] **COLL-04**: Player can name beers (standard iOS text entry plus generated name suggestions) and archive — never destructively delete — lineage members
- [ ] **COLL-05**: Player collects yeast cultures into a Yeast Bank with rarity tiers and distinct traits
- [ ] **COLL-06**: Yeast cultures can mutate across repeated generations, forking (never overwriting) the culture with a visible trait diff
- [ ] **COLL-07**: Player collects ingredients (25+ incl. grains, hops, adjuncts) with gameplay identities shown via tooltips that teach real brewing concepts (fictional ingredient names where real ones are trademarked)
- [ ] **COLL-08**: Ingredient synergies exist, are hinted, and are confirmed/recorded on discovery
- [ ] **COLL-09**: Common ingredients unlock permanently once acquired; rare adjuncts/yeast are limited until cultivated (hybrid economy)
- [ ] **COLL-10**: Collection screens show completion states (Unseen/Seen/Owned/Mastered) and completion percentage
- [ ] **COLL-11**: Player can export/share a beer card image (name, glass, attributes, lineage) via the iOS share sheet

### Regulars

- [ ] **REG-01**: Patrons the player learns about are added to a Regulars Book with progression Seen → Served → Impressed → Regular → Friend, derived from play
- [ ] **REG-02**: Regulars grant passive benefits from a closed set (discounts, unlocks, hints, pour bonuses) that only reference systems that exist in v1
- [ ] **REG-03**: Completing patron knowledge (full palate known) grants rewards

### World & Progression

- [ ] **WORLD-01**: Player travels a node-based city map with 5-8 distinct locations (neighborhood bar, taproom, dive bar, festival, homebrew club, etc.)
- [ ] **WORLD-02**: Each location has its own patron pool, acquisition opportunities, and ambience
- [ ] **WORLD-03**: An abstract day counter advances on brewing/travel and gates some events and patron schedules
- [ ] **WORLD-04**: Progression gates (location/boss unlocks) are driven by encounter wins and knowledge, not grinding
- [ ] **WORLD-05**: Winning encounters rewards ingredients, yeast, recipes, or patron/location unlocks from authored reward tables
- [ ] **WORLD-06**: v1 ships 40+ hand-authored patrons with recognizable personalities, each with 3-5 preferences, 1-3 dislikes, tolerances, and 1+ hidden preference

### Onboarding & Accessibility

- [ ] **UX-01**: A mentor character guides the first session with progressive disclosure (first brew offers 3-4 choices, not 16; first encounter reachable in minutes)
- [ ] **UX-02**: Player can re-read help/codex entries (brewing concepts, palate effects, mechanics) from a help screen; codex entries unlock through play
- [ ] **UX-03**: No information is conveyed by color alone — attributes and rarity pair color with icon/shape/label; Canvas-drawn content has VoiceOver labels
- [ ] **UX-04**: UI supports Dynamic Type (layouts hold up at accessibility text sizes on attribute-heavy screens); dialogue has speed/skip/backlog controls; Reduce Motion is honored
- [ ] **UX-05**: Destructive actions (overwrite save, archive beer) require confirmation
- [ ] **UX-06**: Encounters and brewing fit mobile sessions: a full encounter completes in 2-5 minutes, playable one-handed in portrait

### Platform

- [ ] **PLAT-01**: All screens are touch-first, portrait, one-handed friendly, using standard iOS gestures with generous tap targets
- [ ] **PLAT-02**: The app resumes exactly where the player left off after backgrounding or termination — mid-encounter and mid-brew state is serialized and autosaved after every committed action
- [ ] **PLAT-03**: Game state saves to a versioned Codable JSON envelope with explicit migrations, atomic writes, a backup copy, and golden-save fixtures per released schema version; player can export/import a save
- [ ] **PLAT-04**: Settings persist independently of saves: audio sliders, haptics toggle, text speed; system settings (Dynamic Type, Reduce Motion) are respected
- [ ] **PLAT-05**: The app builds on the current Xcode/iOS SDK, distributes via TestFlight from Phase 1, and ships with privacy manifest, recorded age rating (plan for 18+), and App Store metadata whose screenshots/icon are 4+-appropriate
- [ ] **PLAT-06**: All player-facing strings are externalized in a String Catalog (localization-ready; English-only at launch)
- [ ] **PLAT-07**: Simulation logic (brewing, scoring, palate effects, clues) lives in a UI-free Swift package testable headlessly on macOS, with a balance harness verifying ≥70% encounter solvability and ≥4 distinct best-in-class archetype beers
- [ ] **PLAT-08**: The economy stays monetization-neutral until the model is decided (entitlement abstraction, single soft currency with a sources/sinks ledger, no randomized paid rewards, no timer/energy mechanics)

### Presentation

- [ ] **ART-01**: Beers render procedurally (glass shape, liquid color/SRM, head, carbonation) from their attributes, visually distinct per beer
- [ ] **ART-02**: Patrons have AdCap-style flat/cartoon portraits with expression states (neutral/pleased/sour/delighted) that react to pours
- [ ] **ART-03**: All AI-generated art passes through a locked style guide + post-process pipeline with a provenance manifest (tool, prompt, seed per asset)
- [ ] **ART-04**: Locations have distinct backdrops; the app uses a consistent chunky custom UI treatment on game screens (system chrome avoided where it clashes)
- [ ] **ART-05**: Placeholder music and SFX are AI-generated via the Sonic Pi + MCP pipeline, with volume sliders and scene-appropriate playback (re-evaluate sourcing before release)
- [ ] **ART-06**: Signature moments (pour, perfect pour, mutation, boss win) have tuned haptic feedback, with a settings toggle

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Platform Expansion

- **PLATX-01**: iCloud save sync across devices
- **PLATX-02**: Game Center (achievements, leaderboards)
- **PLATX-03**: Native iPad layouts
- **PLATX-04**: Android port
- **PLATX-05**: Localization beyond English
- **PLATX-06**: Widgets / notifications (only if a non-nagging design emerges)

### Content Expansion

- **CONTX-01**: Regional expansion (Pacific Northwest, San Diego, Colorado, New England, Belgium, Germany, Czech Republic, UK, Japan)
- **CONTX-02**: Seasonal content, additional patron packs and bosses
- **CONTX-03**: Expanded palate-effect roster and synergy graph (only if playtests show base set is exhausted)
- **CONTX-04**: Assist mode beyond hints (extra pours, scoring tolerance)

### Systems Expansion

- **SYSX-01**: Brewery construction, taproom management, staff
- **SYSX-02**: Food pairing, barrel programs, aging cellars, hop breeding, ingredient farming
- **SYSX-03**: Competitions, beer festivals as systems, rival breweries, patron quests
- **SYSX-04**: Recipe trading / multiplayer / leaderboards
- **SYSX-05**: Mod/content expandability (content formats kept data-driven in v1 to preserve this option)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Desktop builds (Mac/Win/Linux) and Steam | Superseded by iOS-native pivot; revisit post-launch if ever |
| Real-time brewing/fermentation timers or energy mechanics | Punishes players, collides with monetization-neutral economy; duration is a recipe choice instead |
| Full brewing simulation (water chemistry, real IBU/SRM math) | Breaks approachability; real concepts appear as names, directions, and tooltips, not arithmetic |
| Style-lookup matching ("likes IPA → serve IPA") | Explicitly forbidden by design doc; sensory profile decides score, style names are soft clues |
| Hidden preferences with no discoverable clue | Violates "deduction not frustration"; every hidden trait must be inferable from at least one clue channel |
| Pure-RNG brew outcomes or encounter rolls | Destroys attribution and the authored-beer fantasy; bounded randomness only in mutation/loot |
| Randomized paid rewards (loot boxes) | Triggers odds-disclosure rules and regional rating escalations; closes no doors we want open |
| Grind-to-progress gates | Knowledge-driven loop; progress gates on recipe quality and deduction, not repetition |
| Losing beers/recipes on defeat | Conflicts with attachment to player-designed beers |
| 15+ palate effects at launch | Legibility collapse; capped at 6-8 |
| Procedurally generated patrons | Loses the recognizable-personality comedy that is the tone promise |
| Real-world trademarks (Untappd, real hop names pending clearance) | App Review/legal risk; use original parody characters and fictional ingredient names where needed |
| Mini-game brewing (QTE/timing bars) | Accessibility burden; hurts deliberate recipe-design identity |
| Voice acting / cutscene production | Budget-prohibitive; expressive portraits + writing instead |
| Glorifying intoxication as a goal | Guideline 1.4.3 rejection risk and tone risk; satisfaction through taste is the frame, statuses are palate effects |
| Third-party analytics/ads SDKs | Keeps privacy label clean and ATT prompt unnecessary |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| (populated during roadmap creation) | | |

**Coverage:**
- v1 requirements: 60 total
- Mapped to phases: 0
- Unmapped: 60 ⚠️

---
*Requirements defined: 2026-10-06*
*Last updated: 2026-10-08 after iOS platform pivot*
