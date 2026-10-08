# Roadmap: Brew Fighter

## Overview

Brew Fighter grows outward from its riskiest promise. Phase 1 puts a real TestFlight build on an iPhone in which a player brews a beer whose attributes come entirely from their recipe. Phase 2 lets them serve those beers to ~10 patrons in 3-pour deduction encounters, and sends the first external TestFlight build through Beta App Review as an early alcohol-content canary. Phase 3 closes the brew → serve → learn → improve loop and ends in a hard fun-gate: outside playtesters, using placeholder visuals, must show the loop works before any bulk art, city, or boss work begins. The premium-vs-F2P decision is also recorded at that gate. Phases 4-6 then build the collection layer, the one-city world with its 40+ patrons and 8 bosses, and the commercial wrapper (onboarding, sound, haptics, App Store launch).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Brew Your First Beer** - TestFlight build where a player composes a recipe and gets a deterministic, inspectable beer that persists
- [ ] **Phase 2: Serve & Deduce** - 6-tap lineup and 3-pour encounters against ~10 patrons, with clue notebook, palate effects, balance harness, and first external TestFlight
- [ ] **Phase 3: Iterate & Prove the Fun** - Live preview, recipe journal and versioning, scouting and hints, accessible slice; outside-playtester fun-gate and monetization decision
- [ ] **Phase 4: Collect & Evolve** - Encounter rewards, ingredients and synergies, Yeast Bank with mutation, family trees, Regulars Book, share cards
- [ ] **Phase 5: The City & Its Bosses** - Node map of 5-8 locations, 40+ illustrated patrons, 8 bosses, knowledge-driven progression
- [ ] **Phase 6: Onboarding, Feel & Launch** - Mentor onboarding, codex, music/SFX, haptics, settings, and App Store release

## Gates & Standing Rules

**Fun-gate (end of Phase 3) is a hard stop.** Phases 4-6 do not start until outside TestFlight playtesters pass the written protocol (Phase 3, criterion 5). If the gate fails, iterate within Phase 3 or insert decimal phases. Do not start bulk art, the city, or bosses before it passes.

**Decision checkpoints:**
- 18+ age rating: recorded in Phase 1, re-checked in Phase 5 once palate effects, bosses, and names are final, finalized at submission in Phase 6.
- Premium vs F2P: recorded at the Phase 3 gate, before Phase 4 economy work (COLL-09). If a model needing StoreKit (free-with-unlock or IAP) is chosen, add a monetization requirement before Phase 4 is planned.

**Standing rules** (each lands in its mapped phase, then binds every later phase):
- Touch-first portrait, one-handed, 44pt+ targets, primary actions in thumb reach (PLAT-01, Phase 1)
- Every player-facing string lives in the String Catalog (PLAT-06, Phase 1)
- Versioned save envelope: any schema change ships a migration plus a golden-save fixture (PLAT-03, Phase 1)
- Autosave after every committed action; every new flow resumes after termination (PLAT-02, Phase 2)
- Balance harness re-runs on every content change and keeps 70%+ solvability and 4+ archetypes (PLAT-07, Phase 2)
- Phase 1 UI kit uses semantic/relative text styles and min-height components; color never carries meaning alone; Canvas content has VoiceOver labels (UX-03/UX-04, verified in Phase 3)
- No timers, energy, or paid randomness; one soft currency with a sources/sinks ledger (PLAT-08, Phase 3)
- More alcohol never means more reward; statuses are palate effects; original characters only, and fictional ingredient names wherever real ones are trademarked (ENC-05, ENC-09, COLL-07)

## Phase Details

### Phase 1: Brew Your First Beer

**Goal**: A player installs Brew Fighter from TestFlight on their iPhone and brews a beer whose 16 sensory attributes, glass, and style label come entirely from their own recipe choices, and the beer is still there the next time they open the app.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: BREW-01, BREW-02, BREW-04, BREW-06, BREW-07, PLAT-01, PLAT-03, PLAT-05, PLAT-06, ART-01
**Success Criteria** (what must be TRUE):
  1. A build made with the current Xcode/iOS SDK installs on a real iPhone through TestFlight. The App Store Connect app record exists (name reserved), the build carries a privacy manifest, and the 18+ age rating is recorded both in App Store Connect and in PROJECT.md Key Decisions.
  2. Holding the phone one-handed in portrait, the player composes a recipe (grain bill, hops with timing, yeast, fermentation temperature and duration, conditioning). Brewing it advances an abstract day counter and never starts a real-time wait.
  3. Brewing the same recipe twice yields an identical beer: 16 sensory attributes, a style label computed from those attributes (never chosen by the player), and a procedurally drawn glass (color, head, carbonation) that looks visibly different from other beers. Tapping any attribute shows its contribution ledger, meaning which ingredient or choice added or removed how much.
  4. Brewed beers survive force-quit and relaunch. The player can export the save through the share sheet and import it back, and a frozen golden-save fixture for the first schema version round-trips in tests.
  5. A pseudo-localized run shows every on-screen string coming from the String Catalog, and every interactive control meets the 44pt minimum.

**Research flags**: Xcode 27 / iOS 27 SDK project setup and deployment target; `package`-access spike to hide domain internals (true palates) from the app target; custom chrome vs Liquid Glass decision for game screens; confirm required screenshot sizes and Declared Age Range scope when creating the app record; start a names-cleared log. An optional art style-lock spike can settle name/icon direction early (the pipeline requirement itself lands in Phase 4).
**Plans**: 1/10 plans executed

Plans:
**Wave 1**
- [x] 01-01-PLAN.md — Walking skeleton, engine half: BrewCore package, deterministic brew + ledger, reducer/day counter, v1 save envelope, style classifier, recipe rules

**Wave 2** *(blocked on Wave 1 completion)*
- [ ] 01-02-PLAN.md — Walking skeleton, app half: XcodeGen app, Cellar BREW → autosave → relaunch, backup/fallback saves, String Catalog checker, 44pt/pseudo-loc UI harness

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 01-03-PLAN.md — Full roster (5 grains, 8 hops, 5 yeasts, 3 adjuncts), Tinseth IBU, conditioning rows + day cost, ledger invariants, names-cleared log

**Wave 4** *(blocked on Wave 3 completion)*
- [ ] 01-04-PLAN.md — Nerd stats (OG/FG/ABV/SRM), telescoping ABV ledger, GlassSpec, 13-style classifier with fallbacks

**Wave 5** *(blocked on Wave 4 completion)*
- [ ] 01-05-PLAN.md — Save schema v1: validator, share-sheet export / file-picker import with confirmed backup, frozen golden fixture

**Wave 6** *(blocked on Wave 5 completion)*
- [ ] 01-06-PLAN.md — Recipe wizard shell + Review (pre-seeded pale ale, Clear), Mash and Boil stages, UI kit controls

**Wave 7** *(blocked on Wave 6 completion)*
- [ ] 01-07-PLAN.md — Ferment and Condition stages, day-cost display, Review validation with Fix jumps

**Wave 8** *(blocked on Wave 7 completion)*
- [ ] 01-08-PLAN.md — Beer detail family bars, contribution ledger sheet, procedural glass, nerd stats, skippable brew reveal

**Wave 9** *(blocked on Wave 8 completion)*
- [ ] 01-09-PLAN.md — Human toolchain upgrade gate, iOS 26.0 floor, full suite on iOS 26+ SDK, app icon, pseudo-loc sweep

**Wave 10** *(blocked on Wave 9 completion)*
- [ ] 01-10-PLAN.md — Bundle ID decision, App Store Connect record + 18+ rating, archive/upload script, TestFlight install

**UI hint**: yes

### Phase 2: Serve & Deduce

**Goal**: The player taps six of their own beers and wins 3-pour encounters against ~10 hand-authored patrons by reading each pour's breakdown and clues. Success comes from deducing hidden palates, not from matching style names.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: ENC-01, ENC-02, ENC-03, ENC-04, ENC-05, ENC-06, ENC-08, TAP-01, TAP-03, TAP-04, PLAT-02, PLAT-07
**Success Criteria** (what must be TRUE):
  1. The player sets a 6-beer tap lineup (swap and reorder), challenges a patron, and serves 3 pours toward a 100-point satisfaction meter. Every pour shows an itemized +/- breakdown, with the 16 attributes grouped into malt/hop/yeast/mouthfeel families with glyphs and exact numbers on drill-down.
  2. Each pour reveals 1-2 clues through patron dialogue. Every clue is auto-recorded in that patron's notebook, which stays visible while the player picks the next pour and shows known/suspected/unknown for each palate dimension, including a hidden preference that play can uncover.
  3. Serving the same three beers in a different order changes the result because of 6-8 visible palate effects (each with an icon and tooltip), and no effect or strategy ever rewards serving more alcohol.
  4. Losing costs a small resource and offers an immediate retry with every learned clue kept. Force-quitting mid-encounter or mid-brew relaunches to the exact same pour or step.
  5. Running `swift test` and the headless balance harness on a Mac (no simulator) shows at least 70% of encounters solvable and at least 4 distinct best-in-class archetype beers (two IPAs perform differently). An external TestFlight build of this slice clears Beta App Review as the alcohol-content canary.

**Research flags**: Deep game-design work on scoring math (fixed-point vs Double), the clue information budget (bucketed vs raw breakdowns so patrons aren't trivially solved), and status interactions; size the palate-effect roster with a best-vs-worst order-delta test; write reviewer notes for the first external build.
**Plans**: TBD
**UI hint**: yes

### Phase 3: Iterate & Prove the Fun

**Goal**: The player closes the brew → serve → learn → improve loop by previewing, versioning, naming, and rebrewing beers aimed at specific patrons. Outside TestFlight playtesters then prove the loop is fun before any bulk art, city, or boss work begins.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: BREW-03, BREW-05, COLL-01, COLL-02, COLL-04, TAP-05, ENC-07, PLAT-08, UX-03, UX-04, UX-05, UX-06
**Success Criteria** (what must be TRUE):
  1. While composing, the player watches a live attribute preview update on every choice, with "?" shown for ingredient traits not yet discovered. Every brew lands in a searchable, filterable recipe journal with favorites, and any recipe rebrews in one tap.
  2. Tweaking a saved recipe creates a new version linked to its parent while the original stays untouched. The player names beers (typed or from generated suggestions) and archives lineage members (never deletes them), and must confirm before archiving a beer or overwriting the save.
  3. Before an encounter the player can scout everything known about a patron to plan a counter-lineup. Mid-encounter they can ask for a hint, and a full encounter finishes one-handed in 2-5 minutes.
  4. The slice holds up for accessibility. Attribute, status, and clue states pair color with an icon, shape, or label; Canvas-drawn glasses have VoiceOver labels; attribute-heavy screens stay usable at accessibility text sizes; Reduce Motion is honored; and dialogue has speed, skip, and backlog controls.
  5. The fun-gate passes under a written playtest protocol. Uncoached outside TestFlight testers (craft-beer fans plus at least 2 non-beer players) brew for specific patrons, explain a failed pour without help, and make serving-order choices on purpose. The gate result and the premium-vs-F2P decision are recorded in PROJECT.md Key Decisions. The economy testers played uses one soft currency with a sources/sinks ledger behind an entitlement seam, with no timers, energy, or paid randomness.

**Research flags**: Write the playtest protocol and recruit testers early (5-8 craft-beer players plus 2 non-beer players, no coaching); live-preview performance (memoize and compute off the main actor, never in `body`); five-second glance test on a real phone; accessibility audit at default, XXL, and AX3 text sizes.
**Plans**: TBD
**UI hint**: yes

### Phase 4: Collect & Evolve

**Goal**: Winning encounters grows a collection of ingredients, yeast cultures, recipe lineages, and regulars that makes the player's tap list distinctly theirs.
**Mode:** mvp
**Depends on**: Phase 3 (fun-gate passed and monetization decision recorded)
**Requirements**: COLL-03, COLL-05, COLL-06, COLL-07, COLL-08, COLL-09, COLL-10, COLL-11, REG-01, REG-02, REG-03, WORLD-05, ART-03
**Success Criteria** (what must be TRUE):
  1. Winning an encounter pays out from an authored reward table (ingredients, yeast, recipes). Common ingredients unlock permanently while rare adjuncts and yeasts stay limited until cultivated. Each of the 25+ ingredients has a tooltip identity that teaches a real brewing concept, and synergies are hinted, then confirmed and recorded once discovered.
  2. The Yeast Bank lists cultures by rarity tier with distinct traits. Brewing with a culture across generations can mutate it into a new forked culture with a visible trait diff, while the parent culture stays intact.
  3. The player can browse a recipe family tree for any lineage, sees Unseen/Seen/Owned/Mastered states and a completion percentage on every collection screen, and can share a beer card image (name, glass, attributes, lineage) through the iOS share sheet.
  4. Patrons fill a Regulars Book that advances Seen → Served → Impressed → Regular → Friend from play. Fully learning a patron's palate grants a reward, and regulars grant passive benefits (discounts, unlocks, hints, pour bonuses) that only touch systems already in the game.
  5. Every AI-generated asset in the build passes through the locked style guide and post-process pipeline, and has a provenance manifest entry (tool, prompt, seed) that can regenerate it.

**Research flags**: Recipe family-tree layout (custom SwiftUI `Layout`) needs focused research; validate the first ~5 assets per art category for style drift before generating more; long-list performance in collection browsers; re-run the balance harness after every content addition.
**Plans**: TBD
**UI hint**: yes

### Phase 5: The City & Its Bosses

**Goal**: The player explores a one-city world of 5-8 locations, gets to know 40+ distinct patrons, and progresses by beating 8 bosses. Progress is gated by wins and knowledge, never by grinding.
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: WORLD-01, WORLD-02, WORLD-03, WORLD-04, WORLD-06, ENC-09, TAP-02, ART-02, ART-04
**Success Criteria** (what must be TRUE):
  1. The player travels a node-based city map between 5-8 locations (neighborhood bar, taproom, dive bar, festival, homebrew club, and more). Each location has its own backdrop, ambience, patron pool, and acquisition opportunities. Travel and brewing advance the day counter, which gates some events and patron schedules.
  2. 40+ hand-authored patrons, each with a recognizable personality, 3-5 preferences, 1-3 dislikes, tolerances, and at least one hidden preference, appear as flat/cartoon portraits whose expression (neutral/pleased/sour/delighted) reacts to every pour.
  3. Each of the 8 original bosses telegraphs its scoring-rule override before the first pour (for example, the Beer Judge enforcing style guidelines). No boss or patron name uses a real-world trademark.
  4. New locations and bosses unlock through encounter wins and patron knowledge rather than repetition. The player saves and loads named tap-lineup presets to counter specific locations and bosses.
  5. All game screens share one consistent chunky custom UI treatment (system chrome avoided where it clashes), and the balance harness still passes on the full patron and boss roster.

**Research flags**: Design decision on whether brewing consumes days and how patron schedules interact with the day counter; boss rule-override design; final patron/boss name clearance; re-check the 18+ questionnaire now that palate effects, bosses, and names are final; portrait consistency at scale (40+ patrons x 4 expressions plus bosses).
**Plans**: TBD
**UI hint**: yes

### Phase 6: Onboarding, Feel & Launch

**Goal**: A brand-new player downloads Brew Fighter from the App Store, is guided into the loop by a mentor, and plays a game that sounds and feels finished.
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: UX-01, UX-02, ART-05, ART-06, PLAT-04
**Success Criteria** (what must be TRUE):
  1. A mentor character guides a first-time player with progressive disclosure. The first brew offers 3-4 choices rather than every dimension, and the first encounter is reachable within minutes of first launch.
  2. The player can reopen help and codex entries (brewing concepts, palate effects, mechanics) from a help screen, and entries unlock through play.
  3. Scene-appropriate music and SFX play across brewing, encounters, and the map, and signature moments (pour, perfect pour, mutation, boss win) fire tuned haptics. Audio sourcing has been re-evaluated for release and the choice recorded.
  4. Audio sliders, the haptics toggle, and text speed persist independently of the save (surviving a save import or reset), and system Dynamic Type and Reduce Motion settings are respected.
  5. The release build is approved and released on the App Store with 4+-appropriate screenshots and icon, metadata and reviewer notes that explain the tasting gameplay, the final 18+ rating, and a "Data Not Collected" privacy label.

**Research flags**: Sonic Pi + MCP audio pipeline spike (unproven end to end); re-check required-reason APIs, the SDK deadline, screenshot sizes, and Declared Age Range obligations at submission; budget 2-3 App Review cycles and use a phased or manual release.
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → (fun-gate) → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Brew Your First Beer | 1/10 | In Progress | - |
| 2. Serve & Deduce | 0/TBD | Not started | - |
| 3. Iterate & Prove the Fun | 0/TBD | Not started | - |
| 4. Collect & Evolve | 0/TBD | Not started | - |
| 5. The City & Its Bosses | 0/TBD | Not started | - |
| 6. Onboarding, Feel & Launch | 0/TBD | Not started | - |
