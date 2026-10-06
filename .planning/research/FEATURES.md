# Feature Research

**Domain:** Collectible brewing RPG (creature-collection loop where the "creatures" are player-designed beers) with tactical patron encounters, recipe evolution, and a commercial Steam/itch.io release
**Researched:** 2026-10-06
**Confidence:** MEDIUM (genre conventions and commercial table stakes are well established; the hybrid itself has no direct comparable, so differentiator value is a reasoned judgment, not observed data. Steamworks/DragonRuby specifics are flagged LOW where unverified.)

Scope note: Inputs are `PROJECT.md` and `brewfighter-design-v1.md`. Comparables surveyed: Pokémon-likes / Monster Sanctuary (collection + matchup), Potion Craft / Travellers Rest / Stardew (crafting and cozy sims), Dave the Diver (hybrid loop), VA-11 Hall-A / Coffee Talk (serving and patron dialogue), Return of the Obra Dinn / Golden Idol (deduction). Complexity ratings are relative to a solo or small team on DragonRuby GTK with AI/procedural art.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Missing any of these makes the product feel unfinished or unreviewable at Steam price points.

#### A. Collection-RPG table stakes (Pokémon-likes, Monster Sanctuary)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Active party / loadout management (6 taps) with swap, reorder, and saved loadout presets | Core of every party-based RPG; the "tap list" is the game's party screen | MEDIUM | Presets ("vs. hop-heads", "boss run") matter far more here than in Pokémon because the player re-tunes for each patron. Reordering is gameplay (serving order) not cosmetics. |
| Collection log / encyclopedia with completion tracking (Regulars Book, Ingredient Codex, Yeast Bank) | Pokédex-style completion drives the "gotta collect" loop; "seen vs. owned" silhouettes are expected | MEDIUM | Needs per-entry states (Unknown / Seen / Known / Mastered). Design doc's Seen → Served → Impressed → Regular → Friend ladder is this. Show completion %. |
| Rarity tiers on collectibles (yeast, ingredients) with distinct visual treatment | Rarity is the collector's hook; every collection game does this | LOW | Rare yeast hunts only work if rarity is legible at a glance (frame, icon, color plus shape for colorblind users). |
| Per-entity detail card: stats, traits, abilities, ancestry | Players inspect their "monsters" constantly; the card is where attachment forms | MEDIUM | Attribute display must be glanceable: bars or radar, not a spreadsheet (design doc art direction says "RPG not spreadsheet"). |
| Nicknaming / naming player creations | Ownership. Pokémon nicknames and Potion Craft recipe naming create attachment | LOW | Requires controller-friendly text entry (see Commercial section). Provide good auto-generated names so naming is optional. |
| Matchup legibility: the player can learn "what is good against what" | Pokémon type chart is the genre's backbone; without it matchup strategy is just guessing | HIGH | The central design risk. Here the "chart" is hidden per-patron palate, so legibility must come from clue reveals, a persistent notebook, and a post-pour breakdown. See Differentiators and Pitfalls. |
| Post-encounter summary with itemized score (+22 Hop Match, -12 Excess Bitterness) | Players need to understand why they won or lost; the design doc already specs this per pour | MEDIUM | Success criterion #2 ("understand why one beer succeeds and another fails") hinges on this. Show contributions per attribute. |
| Clear progression gating and difficulty ramp (easy patrons first, bosses as checkpoints) | RPG players expect signposted escalation. Monster Sanctuary was criticised for bosses that punish strategies the game never hints at | MEDIUM | Each boss rule-modifier must be telegraphed (a hint from a bartender regular, a Regulars Book entry, or a pre-fight scouting conversation). |
| Rewards loop after wins (new ingredient, yeast, recipe, patron unlock, Regulars progress) | "Win → loot → build" is the dopamine cycle | LOW | Reward table design is content work more than engineering. |
| Low-cost retry on failed encounters | Deduction games and RPG bosses both need quick retry; losing must not mean lost beers or lost progress | LOW | Retry should preserve revealed clues (see Differentiators: persistent clue journal). |
| Meaningful long-tail customization of the player's creatures | Monster Sanctuary is praised specifically for deep per-monster customization over fixed level-up abilities | MEDIUM | Brewing + evolution is this. Each beer must offer enough knobs that two players diverge (design pillar 1). |

#### B. Crafting-sim table stakes (Potion Craft, Stardew, Travellers Rest)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Live outcome preview while brewing (attribute bars or radar updating as ingredients, timing, and temperature change) | Crafting sims live or die on feedback tightness. Potion Craft's ingredient-map UI is its signature | HIGH | Biggest UX task in the game. Without it the brewing system becomes guesswork or spreadsheet math. Preview can show exact numbers for known ingredients and "?" for undiscovered traits. |
| Recipe journal: auto-save every brew, favorite/pin, search/filter, one-click "brew again" | Potion Craft and Stardew-likes get repetitive fast; players expect to repeat solved recipes cheaply | MEDIUM | Reviews flag repetitive late game and slow production (Potion Craft). Quick rebrew and batch collapse reduce tedium. |
| Ingredient inventory with tooltips, sorting, filtering | Standard for any crafting UI; hundreds of items need handling | MEDIUM | Tooltips teach brewing concepts (design tone: 70% real beer culture) and surface traits and synergies. |
| Discoverable ingredient properties (traits reveal through use or experiments) | The "discovery" feeling is the crafting-sim reward | MEDIUM | Pair with Regulars (microbiologist unlocks yeast info) so discovery is world-tied. |
| No wasted-time brewing: brewing is a decision screen, not a real-time wait | Potion Craft is criticised for extremely slow late-game production chains; cozy-sim fans tolerate short loops, not timers | LOW | Abstract fermentation as a day/step counter at most. Decide explicitly (open question below). |
| Pacing: a fast first hour | Travellers Rest's slow start is a recurring Steam complaint; first-impression reviews decide early sales | MEDIUM | First encounter reachable in minutes; first brew has 3-4 meaningful choices, not 16. Progressive disclosure of brewing variables. |
| Economy / resource sink-and-faucet loop (currency, ingredient costs or limits) | Crafting sims need something to constrain choices and create goals | MEDIUM | **Gap**: design doc has no economy. Needs an explicit decision (see Gaps). Keep light: ingredients as collectibles/unlocks rather than consumables is the simplest model. |

#### C. Serving-game / bar-game table stakes (VA-11 Hall-A, Coffee Talk, Dave the Diver)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Distinct, memorable patron characters with portraits and expressions | Characters are the product in VA-11 Hall-A and Coffee Talk; the brand promise here is "recognizable personalities" (Kyle, Patio Dad) | HIGH | Content-heavy. 10 prototype patrons is a floor; a one-city v1 likely needs 25-40 plus 5-6 bosses. Portrait expression states (neutral, pleased, sour, delighted) must feed encounter feedback. |
| Reaction feedback on every pour (dialogue line + visual reaction) that doubles as the clue delivery | Serving games communicate through reactions; here dialogue is the clue channel | MEDIUM | Writing carries the deduction. Lines must be diagnostic ("way too bitter for me") without being literal stat readouts. |
| Dialogue UX: text speed, skip, advance, history/backlog | Standard in dialogue-driven games; players abandon without skip | LOW | Backlog doubles as a clue reference. |
| Atmosphere: cozy music, ambience, UI sounds, juicy pour/serve animation | Cozy-genre buyers buy vibe; "no music" reads as unfinished | MEDIUM | **Gap**: audio sourcing is unspecified (only art is). Needs a plan for music and SFX. |
| Place variety with distinct feel (neighborhood bar, dive bar, festival) | World variety is why Dave the Diver sustains interest and prevents sameness | MEDIUM | Location = patron pool + ingredient shop + ambience. |

#### D. Commercial-release table stakes (Steam / itch.io)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Autosave plus manual save, multiple slots, atomic writes, versioned save format | Players lose trust instantly on lost progress; recipe lineage and yeast mutation make state complex and long-lived | MEDIUM | Version the schema from day one; later content patches will otherwise break saves. Write to temp then rename. Cloud-sync needs files in a predictable location. |
| Settings menu: volume sliders (master/music/SFX), fullscreen/windowed/resolution, vsync, input remap, UI/text scale | Reviewers and refund triggers; many Steam review complaints are about missing basics | MEDIUM | Needs a persisted settings store separate from save slots. |
| Full input abstraction: mouse + keyboard + gamepad, hot-swap, glyph switching (Xbox/PlayStation/Deck) | Already a project constraint. Steam Deck Verified requires the default controller config to reach all content with no in-game setup, glyphs matching Deck/Xbox, no mouse/keyboard glyphs shown when using the controller | HIGH | Every screen needs a focus/navigation model. Retrofit cost is huge, so build the focus system first. Source: Steamworks Deck compatibility docs (MEDIUM). |
| Controller-friendly text entry (beer naming, save naming) | Steam Deck Verified requires either a Steamworks on-screen keyboard call or a built-in controller-only text entry | MEDIUM | Prefer a built-in simple name-builder plus preset name generator so it works on itch.io builds also. |
| Legible text at 12 inches on a 7-inch screen (Deck) | Deck Verified criterion. Pixel-art UI with tiny fonts fails it | MEDIUM | Choose the base resolution and font size with Deck in mind from the start. UI scale option. |
| Tutorial/onboarding: first-encounter guided flow, contextual tooltips, re-readable help/codex | A 16-attribute system with deduction is dense; onboarding is the main retention risk. Dave the Diver teaches complex systems through characters, not manuals | HIGH | Use a mentor character (the bartender-regular archetype in the design doc) and progressive unlock of attributes and variables. Add a "how to play / tips" screen reachable from pause. |
| Pause, quit-to-title, confirm-before-destructive actions (delete beer, overwrite save) | Basic UX hygiene | LOW | Include an "archive instead of delete" for beers to protect lineage. |
| Accessibility baseline: remappable controls, scalable text, no color-only information, readable contrast, adjustable text speed, reduced motion/flash toggle | Game Accessibility Guidelines "basic" tier: remap, subtitles/text legibility, colorblind-safe information, difficulty options. Also reduces review-bomb risk | MEDIUM | The 16 attributes are likely color-coded: pair every color with an icon or shape/label. A hint system or assist mode serves as the "difficulty option". |
| Crash resilience and logging; builds for macOS, Windows, Linux | Already in project constraints. Three-OS builds multiply test cost | MEDIUM | Packaging and notarization (macOS) is real work. Keep a platform smoke-test checklist. |
| Steam integration basics: achievements, cloud saves, store assets/capsules, Steam Input default config | Players of Steam games expect achievements and cloud saves; Steam Input config is required for a clean Deck experience | MEDIUM | **LOW confidence**: could not confirm DragonRuby's Steamworks API surface for achievements and cloud. DragonRuby documents turnkey Steam distribution (Indie/Pro license). Spike early. Cloud saves may be achievable purely via Steamworks Auto-Cloud pointing at the save directory. |
| Playable demo / Steam page readiness (trailer, screenshots, wishlists) | For indie Steam releases, the demo and wishlist funnel are the primary marketing levers | MEDIUM | Not a code feature but constrains scope: a demo needs a clean vertical slice and save-compat decision. Keep an itch.io demo in parallel. |
| Localization-ready string handling (English only at launch) | Cheap now, expensive later; makes later translation possible | LOW | Externalize all strings, avoid baked-in text in art. |
| Platform content flags and age-rating readiness (alcohol references) | Alcohol is the game's subject; storefront content surveys and regional ratings need accurate answers | LOW | Knowledge-based, not verified. Keep tone satirical and about craft/taste, avoid glamorizing intoxication (note "Buzzed" and "Wrecked Palate" statuses). |

---

### Differentiators (Competitive Advantage)

These are why someone buys this instead of Potion Craft or Pokémon. They line up with the Core Value in `PROJECT.md`.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Sensory-profile matchup layer (16 attributes vs. hidden patron palate), explicitly not style-matching | The defining mechanic. "Two IPAs perform very differently" makes beers feel like individual creatures and rewards flavor thinking | HIGH | Needs a scoring model that is deterministic, explainable, and tunable. Build it as a pure, headless-testable module early and simulate thousands of beer-vs-patron pairs to balance. |
| Deduction-with-clues encounter (3 pours, partial info, reveals per pour) | Wordle/Obra Dinn-style satisfaction inside an RPG shell; short tactical puzzles suit the cozy audience | HIGH | Lessons from Obra Dinn: guard against brute force (3 pours is itself the limiter) and make verification feedback informative without giving the answer away. Multiple-choice style answers are easily exploitable. |
| Persistent clue notebook per patron (auto-recorded, shown during beer selection) | Directly serves "deduction not frustration" (success criterion #6). Players shouldn't have to remember clues across sessions | MEDIUM | Auto-record, with optional player pins/annotations. Show in the tap-selection screen as "known / suspected / unknown" per attribute. Cheap but high value. |
| Serving-order mechanics via status effects (Palate Fatigue, Refreshed, Hop Burn, Wrecked Palate...) | Turns a pick-the-best-beer problem into a sequencing puzzle; the second-biggest tactical hook | MEDIUM | Cap at about 6-8 statuses at launch, with a visible status icon and a tooltip. Too many statuses wrecks legibility. |
| Recipe evolution with preserved ancestry (family tree view) | Attachment engine: "my saison's grandchild". Creature-breeding-style lineage with player authorship | MEDIUM-HIGH | Data model is a DAG of recipe versions; tree UI is the cost. Define what counts as a new lineage branch vs. an edit to the same beer. Support "archive" so ancestry never breaks. |
| Yeast Bank with mutation across generations | Yeast as rare collectible with emergent traits is unique to this setting and gives long-term collection hooks | MEDIUM-HIGH | Keep mutation deterministic-seeded or bounded so results are explainable. Mutation visibility (notify, show diff) matters. |
| Ingredient synergies and drawbacks (Saaz + lager yeast; roasted barley penalty vs roast-haters) | Gives ingredients identities beyond +N numbers; encourages experimentation | MEDIUM | Present synergies as discoverable (hinted, then confirmed). Keep the graph small enough to explain. |
| Regulars Book with passive benefits (plumber, farmer, chef, microbiologist, bartender) | Collection of people with world-linked rewards; rewards knowledge work rather than grinding | MEDIUM | Benefit types must plug into real systems (discounts, unlocks, hints). Don't promise benefits for systems that are cut (e.g., food pairing is "long-term direction"). |
| Boss encounters as rule-modifiers (Beer Judge, Untappd Guy, Dive Bar Regular...) | Exaggerates the core mechanic, gives marketable set pieces and clear progression gates | MEDIUM | Each boss = a scoring-rule override plus a telegraphed hint. Highly shareable/streamable. |
| Real-brewing learning (tooltips and a codex that teach real concepts: attenuation, flocculation, dry hopping) | Brand promise: "players accidentally learn real brewing". Appeals to the craft-beer audience Potion Craft doesn't touch | MEDIUM | Writing and accuracy review work. Codex entries unlock through use. Concept tooltips on every brewing control. |
| Procedurally rendered beer visuals (color/SRM, head, glassware, carbonation) derived from attributes | Makes each beer visually distinct and "collectible" even with AI/procedural art; reinforces ownership | MEDIUM | Strong fit with the procedural-art constraint: render glass layers from attribute values rather than hand-drawing every beer. High payoff per effort. |
| Scouting/prep layer: use the Regulars Book and clues to pre-select a counter tap list before the encounter | The "team build" fantasy; players say "my saison is great against adventurous patrons" | MEDIUM | Mostly UI on top of existing data; pairs with loadout presets. |
| Shareable beer card (exported image: name, glass, attributes, lineage) | Free social marketing for a beer-culture audience; satisfies "my beer as a character" talk | LOW-MEDIUM | Local image export only. Not the same as out-of-scope recipe trading. Candidate for v1.x. |
| Beer-culture comedy writing grounded in real archetypes (Untappd guy, Finance Bro, Patio Dad) | The 70/30 tone is a marketing differentiator against both Pokémon-likes and generic cozy sims | HIGH (content) | Writing quality is the deciding factor. Budget revision passes. |

---

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-time brewing timers / waiting for fermentation | "Authentic" brewing feel; cozy-sim idle loop | Potion Craft and Travellers Rest reviews cite slow, tedious late-game production; time-gating punishes players and complicates saves | Fermentation as a choice (duration is a variable that affects attributes), resolved instantly or via a single "advance day" step |
| Full brewing simulation (water chemistry, real IBU/SRM formulas, mash efficiency) | Brewer-audience authenticity | Breaks "approachable" goal, makes balance and onboarding intractable, and the 16 attributes already carry the gameplay | Real concepts as flavor and tooltips, mapped to attribute deltas; accuracy in naming and direction, not arithmetic |
| "Patron likes IPA → serve IPA" style-lookup matching | Easy to implement and teach | Explicitly forbidden by the design doc; collapses the deduction layer and makes recipes interchangeable | Style names as soft clues and biases; sensory profile decides score |
| Hidden preferences with no discoverable evidence | Cheap difficulty | Monster Sanctuary's bosses that punish never-hinted strategies draw complaints; violates "deduction not frustration" | Every hidden trait must be inferable from at least one clue channel (dialogue, Regulars Book, bartender hint, prior pour reaction) |
| Pure-RNG brew outcomes or encounter rolls | Variety and surprise | Destroys attribution ("why did this fail?") and the authored-beer fantasy | Deterministic scoring; bounded randomness only in yeast mutation and loot, and displayed clearly |
| Grind-to-progress (XP/level grinding, resource farming gates) | Playtime padding; Monster Sanctuary's post-game is criticised as grind-dependent | Conflicts with a knowledge-driven loop; reads as filler in reviews | Gate progress on knowledge and recipe quality, not repetition; reward discoveries |
| Management-game systems (brewery construction, staff, taproom ops) | Natural expansion; Travellers Rest comparison | Design doc and PROJECT.md explicitly defer; Travellers Rest is also criticised for bloat | Brewery as a hub UI screen (shelves, tap board) with no simulation |
| Mini-game brewing (QTE stirring, timing bars) | Tactile feel, Dave the Diver-style variety | Adds input-accessibility burden, controller tuning, and hurts the deliberate recipe-design identity | Optional light animation/juice only |
| Large status-effect zoo (15+ statuses) | Depth on paper | Players can't track them; legibility collapse and balance explosion | 6-8 statuses at launch, each with clear icon and duration, expand post-launch |
| Procedurally generated patrons | Infinite content | Loses recognizable-personality comedy (the tone promise) and makes clue design unreliable | Hand-authored patrons from templates with authored dialogue; remixed variants as a later add |
| Permadeath / loss of beers on failed encounters | Stakes | Conflicts with attachment to personally-designed beers; punishes experimentation | Failure costs a retry and maybe a minor resource, never recipe loss |
| Multiplayer, recipe trading, leaderboards, online services | Community appeal | Out of scope per PROJECT.md; adds netcode, moderation, and platform obligations | Local shareable beer card export (v1.x); revisit in v2 |
| Mod support / scripting API at launch | Ruby/DragonRuby makes it tempting | Stabilizing a content/data format and security surface before content is settled adds support load | Keep content in data files (JSON/Ruby hashes) so modding stays possible later |
| Voice acting / large cutscene production | Polish | Budget-prohibitive; localization multiplier | Expressive portraits, text blips, strong writing |
| Achievements that require grinding or repetition | Easy to add | Reinforces grind perception | Discovery/mastery achievements (first Perfect Pour, defeat boss, 5-generation lineage) |
| Glorifying intoxication ("get patrons drunk" as the goal) | Comedy | Store content-rating and review risk; undermines the tasting-focused identity | Frame "Buzzed" as a mild palate modifier; goal is satisfaction through taste |

---

## Feature Dependencies

```
Input abstraction + focus/navigation model
    └──requires──> (all UI screens: menus, brewing, encounters, books)

Save system (versioned schema)
    └──requires──> Data model for beers/recipes/yeast/regulars/ingredients
                       └──enables──> Cloud saves, multiple slots

Ingredient + attribute data model (16 attributes)
    └──requires──> Brewing computation (recipe -> attribute profile)
                       └──requires──> Brewing UI with live preview
                       └──enables──> Procedural beer visuals
                       └──enables──> Recipe journal / rebrew

Patron palate model (preferences, dislikes, tolerances, hidden prefs)
    └──requires──> Scoring engine (beer profile x palate)
                       └──requires──> Pour feedback + clue reveal
                                          └──requires──> Dialogue/reaction content
                                          └──enables──> Clue notebook / Regulars Book progress
                       └──requires──> Status effects (serving order)
                                          └──enables──> Boss rule-modifiers

Tap lineup (6 beers) ──requires──> Beer collection ──requires──> Brewing
Loadout presets ──enhances──> Tap lineup + Scouting layer

Recipe evolution/ancestry ──requires──> Recipe data model + save versioning
    └──enables──> Family tree UI, shareable beer card

Yeast Bank ──requires──> Yeast data model + brewing integration
    └──enables──> Mutation (requires generation tracking + save)

Regulars Book ──requires──> Patron data + encounter outcomes
    └──enables──> Passive benefits (requires: shops/discounts, unlock gates, hint system)

Onboarding/tutorial ──requires──> Encounter flow + brewing UI (needs stable UI to teach)
    └──requires──> Progressive disclosure design (staged unlock of variables/attributes)

Economy ──requires──> Decision (consumable vs. unlock ingredients) ──enables──> Shops, rewards, passive benefits

Steam features (achievements, cloud) ──requires──> Save system + stable file layout
Steam Deck readiness ──requires──> Input abstraction + text scale + controller text entry

Style-lookup matching ──conflicts──> Sensory-profile matchup layer
Real-time brewing timers ──conflicts──> Fast-loop pacing / low-friction retry
Large status zoo ──conflicts──> Encounter legibility
```

### Dependency Notes

- **Everything UI requires the input/focus model:** retrofitting controller navigation into finished screens is the costliest mistake available; build it with the first menu.
- **Scoring engine requires both data models first:** attributes (beer side) and palate (patron side) must be defined together, because balance is the relationship between them. Build and simulate headless before any art.
- **Clue notebook requires structured clues, not just free-text dialogue:** each reaction line must be tagged with the underlying fact it reveals, so the notebook and Regulars Book can record it automatically.
- **Passive benefits require the systems they affect:** don't ship a chef benefit without food pairing; limit benefits to discounts, unlocks, hints, and starting-state bonuses that exist in v1.
- **Mutation requires save versioning and a lineage model:** yeast generations and recipe ancestry share the same "descendant" bookkeeping, so design them as one concept.
- **Onboarding depends on stable UI:** schedule tutorial work after the brewing and encounter screens settle, but design progressive disclosure (which variables unlock when) at the start because it shapes the data model.
- **Economy is a missing dependency:** shops, rewards, and Regulars benefits all assume currency or unlock rules; decide before roadmap phases are fixed.

---

## MVP Definition

### Launch With (v1)

The full v1 per PROJECT.md is the goal, but within it these form the **vertical slice that must exist first** (core-loop validity before content scale):

- [ ] Attribute data model + brewing computation (grain, hops, timing, yeast, ferment temp, one conditioning option) — validates "brewing decisions create interesting beers"
- [ ] Patron palate model + scoring engine + 3-pour encounter with clue reveals and itemized breakdown — validates "beers create patron-selection puzzles"
- [ ] Tap lineup (6) with serving order and 3-4 status effects — validates sequencing
- [ ] Brewing UI with live attribute preview, recipe journal, quick rebrew
- [ ] Input abstraction (mouse/KB/controller) + focus navigation + settings + versioned save/autosave
- [ ] Clue notebook per patron and post-pour explanation — protects "deduction not frustration"
- [ ] Recipe ancestry (data model first, tree view second) and Regulars Book basics
- [ ] 10 prototype patrons, then content scale to a one-city v1 (about 25-40 patrons, 5-6 bosses, locations)
- [ ] Yeast Bank with collectible yeast; mutation after the lineage model is proven
- [ ] Onboarding (mentor-led first hour with progressive disclosure)
- [ ] Commercial essentials: accessibility baseline, Deck-readable text, glyph switching, controller text entry, achievements, cloud-save readiness, three-OS builds, demo build

### Add After Validation (v1.x)

- [ ] Shareable beer card export — once beer visuals are stable
- [ ] Additional bosses/patron packs and seasonal content — based on which encounters players talk about
- [ ] Expanded status effects and ingredient synergy graph — only if playtests show the base set is learned and exhausted
- [ ] Assist options beyond the baseline (clue hints on demand, extra pours toggle) — if playtest frustration data shows need
- [ ] Localization — once strings are stable and sales justify

### Future Consideration (v2+)

- [ ] Regional expansion (PNW, Belgium, Germany, Czech, UK, Japan) — regions are content, not mechanics
- [ ] Brewery construction, taproom management, staff — explicitly deferred
- [ ] Food pairing, barrel programs, aging cellars, hop breeding, farming — long-term direction
- [ ] Recipe trading, multiplayer, rival breweries — long-term direction
- [ ] Mod support — after content format stabilizes

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Scoring engine (sensory x palate) with itemized breakdown | HIGH | HIGH | P1 |
| Brewing UI with live preview | HIGH | HIGH | P1 |
| 3-pour deduction encounter with clue reveals | HIGH | HIGH | P1 |
| Clue notebook (auto-recorded) | HIGH | MEDIUM | P1 |
| Input abstraction + focus navigation | HIGH | HIGH | P1 |
| Save system (versioned, autosave) | HIGH | MEDIUM | P1 |
| Tap lineup + loadout presets | HIGH | MEDIUM | P1 |
| Status effects (serving order) | HIGH | MEDIUM | P1 |
| Onboarding / progressive disclosure | HIGH | HIGH | P1 |
| Settings + accessibility baseline | HIGH | MEDIUM | P1 |
| Patron roster + portraits + writing | HIGH | HIGH | P1 |
| Recipe journal + quick rebrew | HIGH | MEDIUM | P1 |
| Recipe ancestry (data) | HIGH | MEDIUM | P1 |
| Regulars Book | MEDIUM-HIGH | MEDIUM | P1 |
| Yeast Bank (collect) | MEDIUM-HIGH | MEDIUM | P1 |
| Boss encounters | MEDIUM-HIGH | MEDIUM | P1 |
| Procedural beer visuals | MEDIUM-HIGH | MEDIUM | P2 |
| Family tree UI | MEDIUM | MEDIUM | P2 |
| Yeast mutation | MEDIUM | MEDIUM-HIGH | P2 |
| Passive benefits from regulars | MEDIUM | MEDIUM | P2 |
| Ingredient synergies | MEDIUM | MEDIUM | P2 |
| Steam achievements / cloud | MEDIUM | MEDIUM (LOW confidence on API) | P2 (before launch) |
| Brewing codex / real-concept tooltips | MEDIUM | MEDIUM | P2 |
| Shareable beer card | LOW-MEDIUM | LOW-MEDIUM | P3 |
| Localization | LOW (at launch) | MEDIUM | P3 (prep strings in P1) |

**Priority key:** P1 = needed for core-loop validation or launch; P2 = needed for launch quality but can follow the slice; P3 = post-launch.

---

## Competitor Feature Analysis

| Feature | Pokémon-likes / Monster Sanctuary | Potion Craft / Travellers Rest | VA-11 Hall-A / Coffee Talk | Dave the Diver | Our Approach |
|---------|-----------------------------------|-------------------------------|---------------------------|----------------|--------------|
| Collection | Creature dex, rarity, party | Recipe book, ingredient list | Drink recipes unlocked by story | Fish/ingredient logs | Four codexes: beers (lineage), yeast bank, ingredients, regulars |
| Crafting | Skill trees, gear | Core loop (map-based brewing UI) | Recipe-based mixing; accuracy tied to dialogue | Cooking/menu design | Attribute-driven brewing with live preview and discoverable traits |
| Matchup | Type chart, visible | Customer demand is explicit | Order stated; choices shape story | Customer preferences visible | Hidden palate, learned by deduction; sensory not style-based |
| Progression | Level + gating bosses | Reputation/unlocks, long production chains | Narrative chapters | Chapters adding new systems | Locations + boss gates + Regulars ladder; knowledge not grind |
| Onboarding | NPC-delivered tutorials | Gradual unlock | Light | Character-driven tutorials | Mentor character with staged disclosure |
| Pain points reviewers cite | Grind, unsignalled boss rules | Repetitive/slow late game; slow start (Travellers Rest) | Linear/limited agency | Can overwhelm with mini-game variety | Avoid timers, grind, unhinted rules; keep loop fast |
| Platform polish | Controller-first | Mixed | Mixed | Controller + Deck friendly | Controller + Deck from day one |

---

## Gaps and Decisions Needed Before Requirements

Design doc and PROJECT.md leave these unspecified; each affects features above.

1. **Economy model:** currency and costs vs. ingredients-as-unlocks. Recommend the latter (collectibles unlock permanently; no consumable grind).
2. **Time model:** does brewing or travel advance a day/calendar? Recommend no real-time timers; at most an abstract step.
3. **Failure model:** what a lost encounter costs. Recommend retry-only, clue persistence on.
4. **Beer count and capacity:** how many recipes the player can own, and whether archived beers are limited. Recommend generous or unlimited with an archive.
5. **Audio plan:** music and SFX sourcing (art plan exists, audio does not).
6. **Difficulty/assist:** whether an assist mode (extra pours, on-demand hints) ships in v1. Recommend a hint system at minimum.
7. **Patron count and boss list for v1:** content budget determines schedule more than any engineering feature.
8. **Steamworks via DragonRuby:** confirm how achievements, cloud saves, and Steam Input are exposed (LOW confidence here); run an early spike before committing roadmap phases.

---

## Sources

- Steamworks Steam Deck compatibility documentation (controller default config, glyph rules, text input, 12-inch legibility): https://partner.steamgames.com/doc/steamdeck/compat — MEDIUM (read via search summary)
- Game Accessibility Guidelines (basic tier: remapping, subtitles/legibility, colorblind-safe info, difficulty options): https://gameaccessibilityguidelines.com — MEDIUM
- Potion Craft review aggregate (repetitive mid/late game, slow production chains, strong reception): https://vaporlens.app/app/1210320/potion_craft_alchemist_simulator — LOW-MEDIUM
- Monster Sanctuary reviews (customization praised; grind and unhinted boss strategies criticised): https://opencritic.com/game/10647/-/reviews , https://godisageek.com/reviews/monster-sanctuary-review/ — MEDIUM
- Travellers Rest Steam review summaries (slow start, repetitive gathering, bloat): https://vaporlens.app/app/1139980/travellers_rest — LOW-MEDIUM
- Dave the Diver GDC24 session recap (character-driven tutorials, hybrid loop variety): https://www.invenglobal.com/articles/18786/gdc24-blending-humor-and-gameplay-insights-from-dave-the-divers-session — MEDIUM
- Return of the Obra Dinn / Case of the Golden Idol design discussion (batch-of-three verification, brute-force resistance, multiple-choice exploitability): https://filmstories.co.uk/?p=83249 , https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn — MEDIUM
- DragonRuby Steam distribution notes (turnkey Steam packaging for Indie/Pro; no confirmation of achievements/cloud API): https://dragonruby.itch.io/dragonruby-gtk/devlog/542709/mid-year-update-quacks-steam-distribution-sound-synthesis-and-pixel-arrays — LOW for Steamworks feature coverage
- VA-11 Hall-A, Coffee Talk, Stardew Valley, Pokémon conventions: training-knowledge synthesis, not freshly verified — MEDIUM
- Project inputs: `/Users/charris/src/brewfighter/.planning/PROJECT.md`, `/Users/charris/src/brewfighter/brewfighter-design-v1.md`

---
*Feature research for: collectible brewing RPG (Brew Fighter)*
*Researched: 2026-10-06*
