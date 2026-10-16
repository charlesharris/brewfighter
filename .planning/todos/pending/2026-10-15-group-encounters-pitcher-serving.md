---
created: 2026-10-15T19:36:31.380Z
title: Group encounters with pitcher serving
area: general
severity: major
files: []
---

## Problem

The encounter system (brewfighter-design-v1.md "Patron Encounter System") is strictly single-patron: one satisfaction meter, limited pours, deduction through pour feedback. Large parties are a natural bar situation the design doesn't cover, and they open a strategic layer the single-patron loop can't: choosing between serving a group individually (per-member targeted beers, high pour cost) or via a pitcher (one pour covering the table, with a multiplier).

The interesting tension: pitchers should win when the group's palates are homogeneous and lose when one member's tastes diverge — so there is a discoverable crossover point between strategies depending on group composition, pour budget, and the tap list available.

## Solution

Design notes from the 2026-10-15 discussion (direction, not final):

1. **Deduction target becomes group palate VARIANCE**, not just individual means — clues should reveal group cohesion ("how alike are they?") as well as member preferences.
2. **Min-gate the pitcher multiplier**: bonus triggers only if every member clears a satisfaction threshold, so one outlier spoils the toast — finding the outlier IS the puzzle.
3. **Pour budget smaller than group size** creates coverage pressure (e.g. 5 patrons, 3 pours). Reuses the limited-pours pillar; no timers/real-time pressure (fights the calm tactical-puzzle feel).
4. **Skill ceiling = mixed serve**: pitcher for the table + a targeted individual pour for the outlier. Should emerge from the rules, not be a designed-in mode.
5. **Pitchers apply shared status effects** to the whole table (everyone Refreshed/Buzzed) — sequencing combo hook, preserves "order matters" at group scale.
6. **Rating framing**: service efficiency / table satisfaction, never volume-as-reward (App Review Guideline 1.4.3; standing rule "more alcohol never means more reward").
7. **Validate with BalanceSim**: verify the crossover between strategies actually exists across group compositions × tap lists, rather than one strategy dominating.

Target: serve/encounter design, post-Phase-3 fun-gate (Phase 2 proves the single-patron loop first). Phase 5 hook: bosses could arrive with an entourage.

Open thread: what clue reveals look like for pitcher pours vs individual pours (discussion continuing 2026-10-15).
