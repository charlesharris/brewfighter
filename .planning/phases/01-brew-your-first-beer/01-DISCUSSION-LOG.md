# Phase 1: Brew Your First Beer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-08
**Phase:** 1-Brew Your First Beer
**Areas discussed:** Recipe-building flow, The brew moment & reveal, Ingredient roster & granularity, Beer inspection & glass

---

## Recipe-building flow

**Q1 — Screen structure**

| Option | Description | Selected |
|--------|-------------|----------|
| Stage wizard (Recommended) | Mash → Boil → Ferment → Condition as sequential full screens with progress indicator | ✓ |
| Single brew sheet | One scrollable screen with collapsible sections | |
| Hub with stage cards | Brew-day dashboard with stage cards opening edit sheets | |

**Q2 — Picking ingredients within a stage**

| Option | Description | Selected |
|--------|-------------|----------|
| Card grid + steppers (Recommended) | Chunky tappable cards; +/- steppers for amounts | ✓ |
| List with detail sheets | Scrollable list, detail sheet per ingredient | |
| Slot machine style | Fixed recipe slots filled from a picker | |

**Q3 — Navigation and commitment**

| Option | Description | Selected |
|--------|-------------|----------|
| Free back-nav + review (Recommended) | Back to any stage; Recipe Review screen with big BREW button | ✓ |
| Strictly forward | Choices lock as you advance | |
| Back-nav, no review screen | BREW lives on the final stage | |

**Q4 — Guidance without live preview (BREW-03 not in Phase 1)**

| Option | Description | Selected |
|--------|-------------|----------|
| Trait tags on cards (Recommended) | Qualitative tags ("citrus, tropical"); numbers only post-brew | ✓ |
| Discover by brewing | Name and art only; learn from the ledger | |
| Numeric trait previews | Exact contributions on cards | |

**Q5 — Numeric inputs (temps, durations)**

| Option | Description | Selected |
|--------|-------------|----------|
| Banded dial w/ flavor text (Recommended) | Labeled bands + real °F shown small | ✓ |
| Exact numeric slider | Continuous precise values | |
| Discrete preset buttons | 3-4 big preset buttons per variable | |

**Q6 — First-run start**

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-seeded starter (Recommended) | Wizard pre-filled with a simple house pale ale; clear-all one tap | ✓ |
| Blank wizard | Build from nothing | |
| Guided first brew | Lightweight scripted first run | |

**Q7 — Validation guardrails**

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal floor (Recommended) | ≥1 grain + yeast required; hops/conditioning optional; weird beers legal | ✓ |
| Anything goes | Even yeast-less "beers" brew | |
| Guided completeness | Every stage required before BREW enables | |

**Q8 — Phase 1 home screen**

| Option | Description | Selected |
|--------|-------------|----------|
| Cellar home + BREW button (Recommended) | Beer collection grid + big BREW button; day counter in header | ✓ |
| Brewhouse hub | Stylized brewery scene with tappable stations | |
| Tab bar from day one | Brew / Beers system tabs | |

---

## The brew moment & reveal

**Q1 — What happens on BREW**

| Option | Description | Selected |
|--------|-------------|----------|
| Staged reveal (Recommended) | 3-5s skippable sequence: vignette → day counter ticks → glass fills → style stamps | ✓ |
| Instant result | Beer card appears immediately | |
| Two-step: brew now, reveal in cellar | New beer waits "ready to tap" in the Cellar | |

**Q2 — Day counter behavior**

| Option | Description | Selected |
|--------|-------------|----------|
| Recipe-driven days (Recommended) | Days = fermentation duration + conditioning time; rolls up during reveal | ✓ |
| Flat cost per brew | Fixed day amount per brew | |
| Cosmetic counter | Ticks forward, nothing references it | |

**Q3 — Attribute presentation**

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped family bars (Recommended) | Malt/hop/yeast/mouthfeel families, bars + exact numbers | ✓ |
| Flat 16-bar list | All 16 attributes in one list | |
| Radar/spider chart | 16-axis radar with drill-down | |

**Q4 — Beer identity before Phase 3 naming**

| Option | Description | Selected |
|--------|-------------|----------|
| Batch # + style (Recommended) | "Batch #4 · West Coast IPA" + brew day | ✓ |
| Simple name editor now | Text field at reveal | |
| Generated fun names | Auto-generated names | |

---

## Ingredient roster & granularity

**Q1 — Roster size**

| Option | Description | Selected |
|--------|-------------|----------|
| Design-doc prototype size (Recommended) | ~5 grains, 8 hops, 5 yeasts, 3 adjuncts; all available from start | ✓ |
| Leaner starter set | ~3 grains, 5 hops, 3 yeasts, no adjuncts | |
| Bigger pantry | ~8 grains, 12 hops, 8 yeasts | |

**Q2 — Grain bill expression**

| Option | Description | Selected |
|--------|-------------|----------|
| Parts/scoops (Recommended) | 1-5 scoops per grain; engine normalizes | |
| Percentages | Player sets % per grain summing to 100 | ✓ |
| Base + accents | One base malt + small/medium/large accents | |

**User's choice:** Percentages — user overrode the recommendation, preferring real-brewing authenticity ("90% pale, 10% crystal").

**Q3 — Keeping percentages painless one-handed**

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-rebalance base malt (Recommended) | Specialty grains step in 5% increments; base malt absorbs remainder | ✓ |
| Free sliders + normalize | Relative-weight sliders with live normalized % | |
| Lock-and-distribute | Lockable %s with distribution across unlocked grains | |

**Q4 — Hop timing expression**

| Option | Description | Selected |
|--------|-------------|----------|
| Named timing slots (Recommended) | Bittering / Flavor / Aroma / Whirlpool, real minutes as flavor text | ✓ |
| Minute dial per addition | 0-60 min dial per hop addition | |
| Role tags only | "For bitterness" / "for aroma" tags, no timing | |

**Q5 — Conditioning options in Phase 1**

| Option | Description | Selected |
|--------|-------------|----------|
| Dry hop only (Recommended) | Single highest-leverage option per design-doc prototype spec | |
| Dry hop + lagering | Two options; lagering showcases day cost | |
| Small menu (3-4 options) | Dry hop, fruit, lagering, bottle conditioning | ✓ |

**User's choice:** Small menu — user chose breadth over the single-option recommendation.

---

## Beer inspection & glass

**Q1 — Contribution ledger format**

| Option | Description | Selected |
|--------|-------------|----------|
| Itemized source rows (Recommended) | Signed numbers per source, summing to total | ✓ |
| Narrative explanation | A sentence per attribute | |
| Rows + one-line summary | Itemized rows + auto-assembled headline sentence | |

**Q2 — Computed style label behavior**

| Option | Description | Selected |
|--------|-------------|----------|
| ~12 styles + fallbacks (Recommended) | 10-15 recognizable styles + honest fallbacks ("Experimental Ale") | ✓ |
| Broad buckets only | 5-6 coarse labels | |
| Deep style tree | BJCP-flavored hierarchy, 30+ styles | |

**Q3 — Procedural glass liveliness**

| Option | Description | Selected |
|--------|-------------|----------|
| Animated hero glass (Recommended) | Canvas+TimelineView bubbles on detail view; static Cellar thumbnails | ✓ |
| Static everywhere | Still glass in all contexts | |
| Animated everywhere | Live bubbles in the Cellar grid too | |

**Q4 — Real-world brewing numbers**

| Option | Description | Selected |
|--------|-------------|----------|
| ABV real, rest abstract (Recommended) | ABV as real %; everything else 0-10 | |
| Full nerd stats | ABV, IBU, SRM, OG/FG estimates alongside game attributes | ✓ |
| Everything abstract | ABV as a 0-10 "Strength" stat | |

**User's choice:** Full nerd stats — user chose above the recommendation; craft-beer-audience differentiator.

---

## Claude's Discretion

- Attribute scale internals and family-to-attribute mapping; collapse threshold for near-zero bars
- Save format details, export file naming, share-sheet mechanics (within PLAT-03)
- Cellar sorting, empty states, pseudo-localization verification, starter-recipe contents
- The specific ~12 style definitions and classification thresholds
- IBU/OG/FG estimation formulas (plausible simplified brewing math)

## Deferred Ideas

None — discussion stayed within phase scope.
