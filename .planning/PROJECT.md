# Brew Fighter

## What This Is

Brew Fighter is a collectible brewing RPG — Pokémon-style collection and matchup strategy, except the creatures are beers you personally design and evolve. The player collects ingredients, yeast cultures, recipes, and techniques; brews beers with real (but approachable) brewing decisions; and wins tactical encounters by serving the right beer to bar patrons whose palates they must deduce. Built in DragonRuby GTK with a cozy pixel-art JRPG aesthetic, targeting a commercial v1 release on Steam and itch.io.

## Core Value

Players create beers, develop them over time, learn which people they work against, and build a tap list that feels distinctly theirs. If everything else fails, the brew → serve → learn → improve loop must be genuinely fun and produce "my saison is great against adventurous patrons" moments.

## Business Context

- **Customer**: Craft beer enthusiasts and cozy/JRPG game players — overlap of Dave the Diver / Stardew / Pokémon audiences
- **Revenue model**: Paid game on Steam and itch.io
- **Success metric**: Shippable commercial-quality v1; players describe their beers as if they were RPG characters (design doc success criterion #7)
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
- [ ] Boss encounters (The Beer Judge, The Untappd Guy, The Dive Bar Regular, etc.)
- [ ] Pixel-art presentation from day one: patron portraits, beer visuals (color/head/glassware), JRPG-style menus
- [ ] Full input abstraction: mouse + keyboard + controller from day one
- [ ] Commercial-release essentials: save system, onboarding, menus, settings, Mac/Windows/Linux builds

### Out of Scope

- Regional expansion (PNW, San Diego, Belgium, Germany, Czech, UK, Japan) — v2 content; one city validates everything
- Brewery construction / taproom management / staff — design doc explicitly defers management-game systems
- Multiplayer, recipe trading, rival breweries — long-term direction only
- Ingredient farming, hop breeding, barrel programs, aging cellars, competitions/festivals as systems — long-term direction only
- Hand-drawn commissioned art — art is AI-generated/procedural; accept the aesthetic tradeoffs
- Mobile/web ports — desktop (Mac/Win/Linux) first; DragonRuby makes ports possible later

## Context

- Complete design document exists at `brewfighter-design-v1.md` covering concept, core pillars, all systems, tone, art direction, prototype spec, and success criteria. It is the source of truth for design intent.
- **Tone target**: ~70% genuine beer culture and brewing knowledge, 30% absurd character comedy. Brewing accurate enough that players accidentally learn real brewing concepts; comedy comes from recognizable personalities (Kyle, Level 34 Finance Bro), not random jokes.
- **Critical design constraint**: never reduce encounters to "patron likes IPA → serve IPA." Style names are clues; the sensory attribute profile is the real matchup layer. Two IPAs should perform very differently.
- **Design success criteria** (from doc): players intentionally craft beers for specific patrons, understand why pours succeed/fail, iterate recipes, develop favorites, care about serving order, experience deduction not frustration, and talk about beers like RPG characters.
- Engine: DragonRuby GTK (Ruby). User owns a license but it is not yet set up in this repo — engine setup is a real first task.
- Greenfield repo: no existing code.

## Constraints

- **Tech stack**: DragonRuby GTK (Ruby) — user's choice; owns license, not yet installed in repo
- **Art**: AI-generated/procedural pixel art — no artist budget assumed; asset pipeline must accommodate regeneration
- **Input**: Mouse + keyboard + controller supported from day one — requires input abstraction layer early
- **Platforms**: Mac/Windows/Linux desktop builds for commercial release
- **Quality bar**: Commercial (Steam/itch.io paid release) — store-page quality polish expected
- **Design fidelity**: `brewfighter-design-v1.md` is authoritative for mechanics and tone

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Full v1 game, not just Phase 1 prototype | User wants the complete core-loop game; prototype scope too small | — Pending |
| One city, all systems; regions deferred to v2 | One region validates every system; regions are content, not mechanics | — Pending |
| DragonRuby GTK as engine | User preference; Ruby, 2D-focused, cross-platform exports, license owned | — Pending |
| Pixel art from day one | The cozy JRPG look is part of what's being tested | — Pending |
| AI-generated/procedural art | No artist; accept aesthetic tradeoffs for velocity | — Pending |
| Mouse + KB + controller from day one | Commercial reach; cheaper to abstract input early than retrofit | — Pending |
| Commercial target (Steam/itch) | Sets quality bar: saves, onboarding, settings, polish are requirements | — Pending |

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
*Last updated: 2026-10-06 after initialization*
