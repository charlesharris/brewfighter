# Phase 1: Brew Your First Beer - Context

**Gathered:** 2026-10-08
**Status:** Ready for planning

<domain>
## Phase Boundary

A TestFlight-installable iPhone app (portrait, one-handed) where the player composes a recipe — grain bill, hops with timing, yeast, fermentation temperature/duration, conditioning — and brews it deterministically into a beer with 16 inspectable sensory attributes, a computed style label, a per-attribute contribution ledger, and a procedurally drawn glass. Beers persist across force-quit/relaunch in a versioned Codable JSON save with export/import via share sheet and a golden-save fixture. All strings in the String Catalog; 44pt minimum targets; App Store Connect record exists with privacy manifest and 18+ rating recorded.

NOT in this phase: encounters/patrons (Phase 2), live attribute preview while editing (BREW-03, later), rebrew-from-journal (BREW-05, Phase 3), beer naming/versioning (Phase 3), collection/rarity mechanics (Phase 4), onboarding/tutorial (Phase 6).

</domain>

<decisions>
## Implementation Decisions

### Recipe-building flow
- **D-01:** Stage wizard structure: Mash → Boil → Ferment → Condition as sequential full screens with a progress indicator. Mirrors real brewing order (serves the 70% genuine-brewing tone goal).
- **D-02:** Free back-navigation between stages; wizard ends on a **Recipe Review** screen summarizing all choices with a big BREW button. The review screen hosts the brew moment.
- **D-03:** Ingredient selection via chunky tappable card grids; tapping adds the ingredient, then big +/- steppers set amounts. AdCap feel, large targets.
- **D-04:** Numeric choices (mash temp, ferment temp, duration) use banded dials / segmented sliders with flavor-text bands (e.g., "Cold & clean" / "Balanced" / "Warm & fruity") plus the real °F shown small. Bands map to discrete deterministic engine inputs.
- **D-05:** Ingredient cards show short qualitative trait tags (Citra: "citrus, tropical"); exact numeric contributions only appear post-brew in the ledger. No live attribute preview in Phase 1 (BREW-03 later); tags set up the future "?" undiscovered-traits mechanic.
- **D-06:** First run opens the wizard pre-seeded with a simple house pale ale the player can accept or tweak; clear-all is one tap. No tutorial plumbing (onboarding is Phase 6).
- **D-07:** Validation floor: a brewable recipe needs ≥1 grain and a yeast; hops and conditioning optional. Hop-less/weird beers are legal and scored honestly — every valid input produces a beer.
- **D-08:** Phase 1 home screen is **The Cellar**: grid/list of brewed beers (procedural glass thumbnails) plus one big BREW button; day counter in the header. Phase 2+ screens attach alongside later. — **Reversibility:** costly — the app shell/navigation root that later phases hang off; changing it reworks every screen's entry point.

### The brew moment & reveal
- **D-09:** Tapping BREW plays a staged, skippable 3-5s reveal: brewing vignette → day counter visibly rolling forward (`.contentTransition(.numericText())`) → glass fills → style label stamps in. This is the phase's signature juice moment; no real-time waiting ever.
- **D-10:** Day cost is recipe-driven: days advanced = fermentation duration + conditioning time (e.g., lagering is expensive in days). Real calendar rules now, not cosmetic. — **Reversibility:** costly — later phases (world/economy) will build on day-cost semantics; changing the rule invalidates balance and save data meaning.
- **D-11:** Beer detail presents the 16 attributes as grouped family bars — malt / hop / yeast / mouthfeel families — with the exact number at each bar's end; zero/near-zero attributes may collapse. Matches the family grouping Phase 2's success criteria already require.
- **D-12:** Pre-naming identity: beers display as "Batch #N · {computed style}" plus brew day. Player naming arrives in Phase 3 and layers on top.

### Ingredient roster & granularity
- **D-13:** Roster at design-doc prototype size: ~5 grains, 8 hops, 5 yeast strains, 3 adjuncts. All available from the start; collection/rarity gating is Phase 4.
- **D-14:** Grain bill is expressed in **percentages** (user explicitly chose authenticity over the scoops abstraction). UI keeps it painless via auto-rebalance: steppers adjust specialty grains in 5% increments and the base (largest) malt absorbs the remainder so the bill always sums to 100.
- **D-15:** Hop timing uses named slots — Bittering (60 min) / Flavor (15 min) / Aroma (flameout) / Whirlpool — with real minutes as flavor text. Attribute math is slot × hop × amount. Dry hop lives in Conditioning.
- **D-16:** Conditioning ships as a small menu (user chose breadth over the single-option recommendation): **dry hop, fruit, lagering, bottle conditioning**. Each needs attribute data, balance tuning, and ledger copy; lagering showcases the day-cost rule.

### Beer inspection & glass
- **D-17:** Contribution ledger (BREW-04): tapping an attribute opens a sheet of itemized source rows with signed numbers summing to the total — e.g., "Citra (aroma slot) +3.2 · Warm ferment +0.8 · Lagering −0.5".
- **D-18:** Style labels (BREW-06): ~10-15 recognizable styles reachable from the Phase 1 roster (Pale Ale, West Coast IPA, Hazy IPA, Stout, Pilsner, Saison, Wheat, ...), plus honest fallback labels ("Amber Ale", "Experimental Ale") for in-between beers. Unmatched beers are legal — a vague label is itself feedback that the recipe is unfocused.
- **D-19:** Procedural glass (ART-01): animated hero glass on the beer detail view — Canvas + TimelineView rising bubbles driven by the carbonation attribute, settled foam head, liquid color derived from SRM. Static thumbnails in the Cellar grid. Honors Reduce Motion (fade instead of motion).
- **D-20:** Full nerd stats (user chose above the ABV-only recommendation): the beer detail shows real-world brewing numbers — **ABV %, IBU, SRM, OG/FG estimates** — derived from the recipe, alongside the abstract 0-10 game attributes. SRM is computed for the glass anyway; IBU/OG/FG need plausible (approachable, not lab-grade) formulas. — **Reversibility:** costly — these derived stats become part of the engine's public output contract and the save schema; removing them later breaks displayed data players have seen.

### Claude's Discretion
- Exact attribute scale internals (0-10 shown; engine representation), family-to-attribute mapping details, collapse threshold for near-zero bars.
- Save file format details, export file naming, share-sheet mechanics (within PLAT-03's envelope/migration/fixture requirements).
- Cellar sorting, empty states, pseudo-localization verification approach, exact starter-recipe contents.
- The specific ~12 style definitions and their classification thresholds (validated by tests).
- IBU/OG/FG estimation formulas — plausible simplified brewing math, tuned for consistency with the attribute engine rather than lab accuracy.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design intent (authoritative for mechanics and tone)
- `brewfighter-design-v1.md` — full design doc; see §Brewing System (stage choices and what they affect), §Phase 1 Prototype (roster sizes, 16 attributes list, brewing variables), §Important Design Constraint (style names are clues, attributes are the real layer), §Tone (70/30 genuine-brewing/comedy)

### Planning artifacts
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, research flags (Xcode 27 setup, `package`-access spike, custom chrome vs Liquid Glass, screenshot sizes / Declared Age Range, names-cleared log)
- `.planning/REQUIREMENTS.md` — BREW-01/02/04/06/07, PLAT-01/03/05/06, ART-01 definitions
- `.planning/PROJECT.md` — constraints, key decisions, out-of-scope list

### Tech stack (locked)
- `.claude/CLAUDE.md` — verified 2026-10-08 stack research: Swift 6.4, SwiftUI, iOS 26 floor, Codable JSON saves, pure `BrewCore` package, animation API table, testing stack, App Store compliance notes (18+ rating, Guideline 1.4.3 framing)

</canonical_refs>

<code_context>
## Existing Code Insights

Greenfield repository — no code exists yet (only `README.md` and `brewfighter-design-v1.md`). No codebase maps, no reusable assets.

### Established Patterns (from locked stack decisions, not code)
- Engine as pure functions in a UI-free `BrewCore` Swift package: `(GameState, Action, inout RNG) -> (GameState, [GameEvent])`; deterministic, testable on macOS without a simulator (PLAT-07 lands fully in Phase 2 but the package split starts now)
- Single `@MainActor @Observable GameStore` holding `GameState` value types; SwiftUI views + `#Preview` fixtures
- Authored content (ingredients, styles) as JSON decoded via Codable, validated by tests — not Swift literals
- Anti-pattern rule 28 applies: the iOS app target must be a real `.xcodeproj` (not an SPM executable target); `BrewCore` is a local package beside it

### Integration Points
- None yet — this phase creates the project skeleton everything else attaches to.

</code_context>

<specifics>
## Specific Ideas

- The reveal should have "Pokémon-egg-hatch energy" — anticipation, then payoff; skippable for repeat brews.
- Trait tags read like beer-nerd shorthand ("citrus, tropical", "roast, coffee") — they're flavor text AND strategy hints.
- "90% pale, 10% crystal" percentage talk is the authenticity register the user wants in the grain bill (chose percentages over a scoops abstraction deliberately).
- Nerd stats (IBU/SRM/OG/FG) are a differentiator for the craft-beer audience — approachable numbers, not a lab sim.
- An unfocused recipe earning "Experimental Ale" is intentional soft feedback, not an error state.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (Live attribute preview, rebrew, naming, collection gating, and onboarding were kept out by design; they're already mapped to later phases in ROADMAP.md.)

</deferred>

---

*Phase: 1-Brew Your First Beer*
*Context gathered: 2026-10-08*
