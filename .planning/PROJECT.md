# Brew Fighter

## What This Is

Brew Fighter is a collectible brewing RPG for iPhone — Pokémon-style collection and matchup strategy, except the creatures are beers you personally design and evolve. The player collects ingredients, yeast cultures, recipes, and techniques; brews beers with real (but approachable) brewing decisions; and wins tactical encounters by serving the right beer to bar patrons whose palates they must deduce. Built natively in Swift/SwiftUI, portrait-orientation, with an Adventure Capitalist-style UI feel (bright, button-heavy, satisfying) wrapped around Pokémon-style "battles," targeting a commercial App Store release.

## Core Value

Players create beers, develop them over time, learn which people they work against, and build a tap list that feels distinctly theirs. If everything else fails, the brew → serve → learn → improve loop must be genuinely fun and produce "my saison is great against adventurous patrons" moments.

## Business Context

- **Customer**: Craft beer enthusiasts and mobile collection/idle-game players — overlap of Adventure Capitalist / Pokémon / cozy-sim audiences
- **Revenue model**: TBD — premium vs F2P+IAP decided before the economy phase (economy design depends on it)
- **Success metric**: Shippable commercial-quality v1 on the App Store; players describe their beers as if they were RPG characters (design doc success criterion #7)
- **Strategy notes**: Full design vision in `brewfighter-design-v1.md` (repo root)

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Brewing system: grain bill, hops + timing, yeast, fermentation temperature, conditioning choices produce beers with ~16 sensory attributes (malt, bitterness, hop aroma, citrus, body, funk, etc.)
- [ ] Patron encounter system: limited pours against a satisfaction meter, partial-information deduction, feedback and clue reveals per pour
- [ ] Status effects that make serving order matter (Palate Fatigue, Refreshed, Buzzed, Hop Burn, Wrecked Palate, etc.)
- [ ] Tap lineup management: 6 active beers as the player's "party"
- [ ] Recipe evolution with preserved lineage/ancestry (beer family trees)
- [ ] Yeast Bank: yeast as rare collectibles with traits, mutation across generations
- [ ] Ingredient collection with gameplay identities and synergies (hops, grains, adjuncts)
- [ ] Regulars Book: patron encyclopedia with Seen → Served → Impressed → Regular → Friend progression; regulars grant passive benefits
- [ ] One-city world: multiple locations (neighborhood bar, taproom, dive bar, festival, homebrew club, etc.) with explore → acquire → brew → serve loop
- [ ] Boss encounters (The Beer Judge, The Untappd Guy, The Dive Bar Regular, etc.) — 8 in v1
- [ ] AdCap-style flat/cartoon presentation: expressive patron portraits, procedurally rendered beer visuals, chunky satisfying mobile UI
- [ ] Touch-first iPhone portrait UI, one-handed friendly
- [ ] Commercial-release essentials: save system, onboarding, settings, App Store packaging

### Out of Scope

- Regional expansion (PNW, San Diego, Belgium, Germany, Czech, UK, Japan) — v2 content; one city validates everything
- Brewery construction / taproom management / staff — design doc explicitly defers management-game systems
- Multiplayer, recipe trading, rival breweries — long-term direction only
- Ingredient farming, hop breeding, barrel programs, aging cellars, competitions/festivals as systems — long-term direction only
- Desktop builds (Mac/Win/Linux) and Steam — superseded by the iOS-native pivot; revisit post-launch if ever
- Android port — iOS-first; native Swift makes Android a separate effort, v2+ at earliest
- Hand-drawn commissioned art — art is AI-generated/procedural; accept the aesthetic tradeoffs
- Real idle/incremental mechanics — Adventure Capitalist is a UI/feel reference only, not a gameplay model

## Context

- Complete design document exists at `brewfighter-design-v1.md` covering concept, core pillars, all systems, tone, art direction, prototype spec, and success criteria. It is the source of truth for design intent (mechanics and tone; its pixel-art direction is superseded by the AdCap-style pivot).
- **Tone target**: ~70% genuine beer culture and brewing knowledge, 30% absurd character comedy. Brewing accurate enough that players accidentally learn real brewing concepts; comedy comes from recognizable personalities (Kyle, Level 34 Finance Bro), not random jokes.
- **Critical design constraint**: never reduce encounters to "patron likes IPA → serve IPA." Style names are clues; the sensory attribute profile is the real matchup layer. Two IPAs should perform very differently.
- **Design success criteria** (from doc): players intentionally craft beers for specific patrons, understand why pours succeed/fail, iterate recipes, develop favorites, care about serving order, experience deduction not frustration, and talk about beers like RPG characters.
- **UI/feel reference**: Adventure Capitalist — bright, chunky, button-heavy, numbers that feel good to tap — mixed with Pokémon-style battle presentation for encounters.
- Prior research round (2026-10-06, committed under `.planning/research/`) targeted a DragonRuby desktop build; its game-design findings (deduction legibility, balance harness, clue notebook, gated vertical slice) remain valid, its stack/platform findings are superseded.
- Greenfield repo: no existing code.

## Constraints

- **Tech stack**: Native iOS — Swift + SwiftUI-first (encounters included; Canvas/animations for juice) — user's choice after pivoting from DragonRuby
- **Devices**: iPhone, portrait orientation, one-handed friendly; iPad runs scaled (no native iPad layouts in v1)
- **Art**: AI-generated AdCap-style flat/cartoon art — no artist budget assumed; pipeline must accommodate regeneration
- **Input**: Touch-first; standard iOS gestures and accessibility
- **Quality bar**: Commercial App Store release — store-page quality polish expected
- **Monetization**: Undecided (premium vs F2P+IAP) — must be decided before the economy phase; economy design keeps both doors open until then
- **Design fidelity**: `brewfighter-design-v1.md` is authoritative for mechanics and tone

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Full v1 game, not just Phase 1 prototype | User wants the complete core-loop game; prototype scope too small | — Pending |
| One city, all systems; regions deferred to v2 | One region validates every system; regions are content, not mechanics | — Pending |
| ~~DragonRuby GTK as engine~~ → superseded 2026-10-08 | Original pick; replaced by iOS-native pivot | ⚠️ Superseded |
| Native iOS: Swift + SwiftUI-first | Game is menu/panel-heavy with staged battles; phone is the real target; SwiftUI is fastest for AdCap-style UI | — Pending |
| iPhone portrait, touch-first, one-handed | AdCap-feel reference; one layout to design and QA | — Pending |
| AdCap-style flat/cartoon art (was: pixel art) | Matches the UI/feel reference; AI generation + SwiftUI rendering handle flat styles well | — Pending |
| AI-generated/procedural art | No artist; accept aesthetic tradeoffs for velocity | — Pending |
| Monetization decided later, before economy phase | Keep premium and F2P doors open; economy design is the dependency | — Pending |
| Commercial target (App Store) | Sets quality bar: saves, onboarding, settings, polish are requirements | — Pending |
| Custom chrome on all game screens; system chrome only for sheets, share sheet, file importer and alerts | One visual regime under the iOS 27 SDK, where Liquid Glass restyles standard controls on iOS 26+; AdCap buttons are custom ButtonStyles | — Pending |
| Generated BrewFighter.xcodeproj is committed; project.yml (XcodeGen, syncedFolder) is its source | Xcode Cloud and IDE edits need a checked-in project; regeneration must produce no diff; deliberate deviation from the generic scaffold reference | — Pending |
| Engine numbers are Int fixed-point (attributes in tenths 0-10.0); attribute families malt/hop/yeast/mouthfeel | Exact ledger sums and cross-platform determinism; Phase 2 encounter breakdowns inherit the families | — Pending |
| String Catalog keys are semantic dotted identifiers with positional format specifiers | Missing keys render visibly and are testable (check-strings, raw-key UI test); positional specifiers let translators reorder arguments. Note: -NSDoubleLocalizedStrings mangles the first copy of composite format strings, so pseudo-localization checks cover plain strings only | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-10-08 after platform pivot to native iOS*
