---
title: Idle mechanics design direction
date: 2026-10-20
context: /gsd-explore session — idle/incremental systems for Brew Fighter, captured ahead of the Phase 3 fun-gate so pre-Phase-3 design and engineering can account for them
status: direction, not committed scope — economy stays monetization-neutral until the Phase 3 gate (PLAT-08)
---

# Idle Mechanics Design Direction

Decisions from the 2026-10-20 exploration session. These are **direction**, not scheduled
scope. The seed in `.planning/seeds/` triggers the actual design/planning work when the
Phase 3 fun-gate passes.

## Decisions

| Decision | Choice |
|---|---|
| Idle payoffs | Bar runs itself (cash/reputation) + patron gossip (intel) + garden growth (ingredients). Explicitly NOT real-time brewing — the in-game day counter stays game-time; brewing remains an active, instant decision. |
| Idle ↔ active relationship | **Idle = farm, active = fights.** The bar auto-serves only patrons already won over (regulars). New patrons and bosses always require active tactical play. Idle never wins encounters. |
| Money sinks | All four: ingredients & cultures (shop), brewery equipment (capability unlocks), bar expansion (AdCap reinvest loop → more regulars served/hour), travel & location gating. |
| Growth curve | **Full exponential + prestige** ("sell the bar"). Not bounded-linear. Reference games the developer likes: Adventure Capitalist, Revolution Idle, Tower Wizard and similar Steam idles. |
| Prestige payout | Should scale with per-run accomplishments (encounters won, beers perfected), not elapsed time — see admitted research below. |
| Prestige persistence | **Knowledge survives; the business resets.** Persist: recipe book + full lineage, patron collection/relationships, yeast cultures, garden seed log. Reset: cash, bar upgrades, taps, location progress. Thesis: "you rebuild the business, never the knowledge." |
| Garden | Three layers in one system: free staple trickle, quality-by-tending over real time (plot levels), and acquisition-gated exclusives (seeds/cultures/knowledge found in the world — a collection surface tied to the Explore loop). |
| Gossip | Three modes: soft hints about unbeaten patrons (narrowing, never solving — deduction stays the player's), deep lore/bonus objectives for beaten patrons, and player-directed targeting ("buy a round" aims idle time at a chosen patron or the community before you leave). |

## Core-identity constraint

The game's thesis is attachment ("my saison", recipe lineages, patron relationships).
Any prestige design that wipes recipes, lineage, patrons, or cultures violates the
core value in PROJECT.md. "Knowledge survives" is the binding resolution.

## Engineering implications BEFORE Phase 3

Captured so Phase 2 work doesn't foreclose this direction:

- **Money representation**: exponential economy means currency will exceed Int32 quickly
  and may exceed Int64 display conventions (scientific notation). Avoid baking "small int
  cash" into Phase 2 save schema or UI. Prefer a dedicated money type with headroom.
- **Save schema**: prestige implies partitioning state into "persists across reset"
  (recipes/lineage, patrons, cultures, seed log) vs "run state" (cash, upgrades, taps,
  location progress). The existing versioned-save + migration discipline (SaveMigrator,
  golden saves) covers evolution, but new Phase 2 state should be tagged mentally with
  which bucket it belongs to.
- **Patron model**: "regular = won patron = passive asset" means encounter wins need a
  durable record (who, where, how convincingly) — Phase 2's encounter results should be
  persisted richly enough to later drive auto-serve rates and gossip.
- **Real-time clock**: garden growth and idle accrual need a wall-clock-aware system
  (and anti-clock-tamper stance TBD). Nothing in v1 uses wall time yet.
- **Economy neutrality (PLAT-08)**: all of this stays compatible with either premium or
  F2P; no sink/source here presumes IAP. Paid gacha remains off the table (Guideline 3.1.1).

## Research (disposition preserved — do not flatten)

DATA_k7q2xw9f_START
Admitted (with sources):
- The prestige currency formula is the active-play lever. Lifetime-earnings formulas
  (Cookie Clicker, AdCap) give diminishing returns for resetting at the same point;
  earnings-since-reset formulas (Egg, Inc.) reward equal runs equally and, with a short
  offline cap, pull players toward active play. Source:
  https://www.gamedeveloper.com/design/the-math-of-idle-games-part-iii
- Layered prestige is a current pattern: Revolution Idle's store page describes tiers
  where a higher layer "resets everything" below it while Stars "boost every run".
  Source: https://store.steampowered.com/app/2763740/Revolution_Idle/

Unresolved (NOT verified — genre folklore until checked against primary sources):
- Cookie Clicker ascension persists collection records (achievements, seed log) while
  live state resets — fan wiki, non-authoritative.
- AdCap keeps unspent angels, cosmetics, premium purchases across resets — Steam forum
  posts only; official page silent.
- No designer postmortems found on hybrid idle/active balance; Tower Wizard, Melvor,
  Idleon, NGU, Leaf Blower reset details were player reports or outdated wikis.
DATA_k7q2xw9f_END
