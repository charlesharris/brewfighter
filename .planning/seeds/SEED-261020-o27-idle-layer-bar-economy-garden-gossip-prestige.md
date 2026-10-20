---
id: SEED-261020-o27
status: dormant
planted: 2026-10-20
planted_during: "Phase 01 — Brew Your First Beer (v1 milestone)"
trigger_when: "when the Phase 3 fun-gate passes and economy-phase planning begins (monetization decision unlocks economy design, PLAT-08)"
scope: large
---

# SEED-261020-o27: Idle layer — bar economy + garden + gossip + prestige

## Why This Matters

The developer wants Brew Fighter to carry real idle/incremental mechanics (reference
games: Adventure Capitalist, Revolution Idle, Tower Wizard), not just AdCap *feel*.
A designed idle layer turns won patrons into durable assets, gives the economy its
sinks, and adds the long-horizon retention loop (prestige) — while the "idle = farm,
active = fights" rule keeps the tactical deduction game as the only path to new wins,
protecting the fun-gate's core loop.

## When to Surface

**Trigger:** when the Phase 3 fun-gate passes and economy-phase planning begins
(the premium-vs-F2P decision unlocks economy design, PLAT-08).

This seed will surface during `/gsd-new-milestone` when the milestone scope matches.

## Scope Estimate

**Large** — bar auto-serve economy, three-layer garden subsystem, three-mode gossip
system, exponential economy with prestige ("sell the bar", knowledge survives), plus
wall-clock accrual infrastructure. Likely a milestone-level addition, or several phases.

## Direction (settled in the 2026-10-20 exploration)

Full decision table: `.planning/notes/idle-mechanics-direction.md`. Summary:

- Idle payoffs: bar runs itself + patron gossip + garden growth; brewing stays
  game-time (no real-time fermentation)
- Idle = farm (auto-serves only won regulars); active play is the only way to win
  new patrons/bosses
- Money sinks: ingredients/cultures, brewery equipment, bar expansion, travel/locations
- Growth: exponential + prestige; payout scales with per-run accomplishments
- Prestige persistence: knowledge survives (recipes/lineage, patrons, cultures, seed
  log); business resets (cash, upgrades, taps, location progress)
- Garden: free staples + quality-by-tending + acquisition-gated exclusives
- Gossip: soft hints (unbeaten) + deep lore (beaten) + player-directed targeting

## Breadcrumbs

- `.planning/notes/idle-mechanics-direction.md` — full decision table, research with
  admitted/unresolved disposition, pre-Phase-3 engineering implications
- `.planning/research/questions.md` — "Idle/prestige economy" section (payout formula
  tuning, offline cap, clock-tamper stance, folklore claims to verify)
- `.planning/todos/pending/2026-10-20-reconcile-idle-direction-design-doc.md` —
  design-doc reconciliation task
- `brewfighter-design-v1.md` §"Patron Collection System" — "Regular patrons can
  provide passive benefits" (the existing hook this direction extends)
- `.planning/STATE.md` — decisions: monetization-neutral economy until Phase 3 gate

## Notes

Captured via /gsd-explore (2026-10-20). Pre-Phase-3 engineering guardrails (money type
headroom, save-state partitioning for prestige, rich encounter-win records, wall-clock
system) are listed in the note so Phase 2 work doesn't foreclose this direction.
