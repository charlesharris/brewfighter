---
phase: 01-brew-your-first-beer
plan: 03
subsystem: engine-content
tags: [swift, brewcore, content-json, tinseth, ibu, hops, conditioning, ledger, swift-testing]

requires:
  - phase: 01-01
    provides: "Brewer, additive ledger, RecipeRules, ContentCatalog, SeededRNG"
  - phase: 01-02
    provides: "Localizable.xcstrings and scripts/check-strings.swift"
provides:
  - "Full D-13 roster: 5 grains, 8 hops, 5 yeasts, 3 adjuncts, all with trait tags and neutral IDs"
  - "scripts/gen-brew-tables.swift and generated tinseth.json (Int utilization per slot per OG point)"
  - "Per-addition Tinseth IBU in tenths, bitterness rows, slot-weighted aroma rows, BeerStats.ibuTenths"
  - "Conditioning contributions (dry hop, fruit, lagering, bottle conditioning) as labelled ledger rows"
  - "Yeast effectsByDuration rows for the wild blend"
  - "RecipeGrid.structured (600) and RecipeGrid.sample (seeded) shared test support"
  - ".planning/names-cleared.md names log"
affects: [01-04, 01-05, 01-06, 01-07, 01-08, phase-02]

tech-stack:
  added: []
  patterns:
    - "All floating point lives in the offline generator; the engine reads committed Int tables"
    - "Grain-bill adjuncts fold into ContentCatalog.fermentables (kind .adjunct); fruit adjuncts stay separate"
    - "Conditioning rows use the chosen ingredient as source refID with the step kind as detail"
    - "Content tuning changes JSON values, never formulas"

key-files:
  created:
    - scripts/gen-brew-tables.swift
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/hops.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/tinseth.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/adjuncts.json
    - Packages/BrewCore/Tests/BrewCoreTests/HopContributionTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/ContentValidationTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/LedgerInvariantTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/Support/RecipeGrid.swift
    - .planning/names-cleared.md
  modified:
    - Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift
    - Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift
    - Packages/BrewCore/Sources/BrewCore/Engine/RecipeRules.swift
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/bands.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/grains.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/yeasts.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/conditioning.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/starter_recipes.json
    - App/BrewFighter/Localizable.xcstrings

key-decisions:
  - "House pale ale is dry-hopped (hop.h01: 3 qo bittering, 4 qo aroma, 4 qo dry hop); its day cost is 17, so the first brew ends on day 18"
  - "hop.h01 citrus/tropical effects tuned to 22/14 (hopAroma stays 25) so the house profile lands in the design-doc ranges; formulas untouched"
  - "Yeast effectsByTempBand must define all three bands (strict decode) instead of defaulting a missing band to empty"
  - "Wild-yeast duration rows use source kind .fermentDuration with refID = yeast ID and detail = duration band"

patterns-established:
  - "Grid tests loop over the whole recipe set inside one parameterized test per invariant (arguments: structured, sample) to keep output readable"
  - "Roster IDs are validated by regex in ContentValidationTests; display names live only in the catalog"

requirements-completed: [BREW-02, BREW-04, BREW-07, PLAT-06]

actuals:
  tokens: 17500
  tasks: 3
  commits: 5
plan_head_before: 5a3255ecda70f396e89f6f7a28f236902a339f1d
plan_head_after: 2a9214b1edb7bb838e0348cb5417ac2b6bf9b538

coverage:
  - id: D1
    description: "Every hop addition contributes Tinseth bitterness and slot-weighted aroma rows; BeerStats.ibuTenths is the sum of per-addition IBU; dry hop adds aroma and zero IBU"
    requirement: "BREW-02"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/HopContributionTests.swift (12 tests incl. oneOunceBitteringGivesRealisticIBUAndBitterness, ibuStatEqualsSumOfPerAdditionValues)"
        status: pass
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/LedgerInvariantTests.swift#dryHopAddsAromaRowsFromTheChosenHopAndNoIBU"
        status: pass
    human_judgment: false
  - id: D2
    description: "Full D-13 roster with neutral IDs, trait tags, bounded effects and referential integrity"
    requirement: "BREW-02"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/ContentValidationTests.swift (11 tests)"
        status: pass
      - kind: other
        ref: "grep -rniE 'citra|mosaic|simcoe|galaxy|amarillo' Packages/BrewCore/Sources/BrewCore/Resources/Content (no matches)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Four conditioning options add labelled ledger rows and their days to the brew's day cost"
    requirement: "BREW-07"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/LedgerInvariantTests.swift#fruitAddsPerPoundRowsFromTheFruitAdjunct, lageringAndBottleConditioningHaveFixedEffects, houseDryHopBrewAdvancesTheDayToEighteen"
        status: pass
    human_judgment: false
  - id: D4
    description: "Ledger exact-sum, range, cap-row, determinism and order-independence invariants hold over 600 structured and 500 seeded recipes"
    requirement: "BREW-04"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/LedgerInvariantTests.swift#rowsSumToValuesAndStayInRange, capRowsAreUniqueAndLastPerAttribute, brewingTwiceGivesEqualResults, reorderingHopsAndNonBaseGrainsLeavesTheBeerUnchanged"
        status: pass
    human_judgment: false
  - id: D5
    description: "House pale ale meets the design-doc profile and classifies as American Pale Ale"
    requirement: "BREW-02"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/LedgerInvariantTests.swift#housePaleAleMeetsTheDesignProfile"
        status: pass
    human_judgment: false
  - id: D6
    description: "Every new content key is in the String Catalog; the app still brews the hopped starter and persists it"
    requirement: "PLAT-06"
    verification:
      - kind: other
        ref: "swift scripts/check-strings.swift -> check-strings: OK (127 keys)"
        status: pass
      - kind: e2e
        ref: "scripts/test-app.sh -only-testing:BrewFighterUITests/PersistenceUITests"
        status: pass
    human_judgment: false
  - id: D7
    description: "Names are trademark-safe: fictional hop names, neutral IDs, log of every name and its check status"
    verification: []
    human_judgment: true
    rationale: "Only an informal by-eye comparison was done; a human USPTO/trademark search is still pending (logged in .planning/names-cleared.md)"

duration: 6 min
completed: 2026-10-08
status: complete
---

# Phase 1 Plan 03: Roster, Hop Slots, Tinseth IBU and Conditioning Summary

**Complete Phase 1 roster (5 grains, 8 fictional-name hops, 5 yeasts, 3 adjuncts) with hops flowing through generated Tinseth Int tables into bitterness, aroma and IBU rows, four conditioning options adding labelled ledger rows and days, and ledger invariants proven across 1,100 deterministic recipes.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-08T22:21:21Z
- **Completed:** 2026-10-08T22:28Z
- **Tasks:** 3 (1 tracer, 2 TDD)
- **Files modified:** 25 in the plan range (9 created source/test/log files, 9 modified, plus evidence and planning bookkeeping)

## Accomplishments

- Tracer proven end to end: a 1 oz bittering addition of hop.h01 at OG 1050 gives about 41.5 IBU (ibuTenths 405...425) and a bitterness row of 40...43. Tracer gate: automated-only verify re-run green, "Tracer verified end-to-end, expanding".
- `scripts/gen-brew-tables.swift` is the only place floating point appears. It writes `tinseth.json` (101 Ints per slot for OG 1020...1120); two runs give identical `shasum`. The engine clamps OG before indexing (T-1-09).
- Bittering utilization at OG 1050 is 23066 per 100k, and the ordering aroma < whirlpool < flavor < bittering holds.
- Conditioning is data-driven: dry hop reuses the chosen hop's effects at weight 130 with zero IBU, fruit scales per pound, lagering and bottle conditioning have fixed effects. The wild yeast's `effectsByDuration` makes extended fermentation funkier than quick.
- The recipe grid (600 structured, 500 seeded, built only through `RecipeRules`) satisfies exact-sum, 0...100 range, no zero rows, single trailing cap row, determinism, and order independence for hop and non-base grain reordering.
- Full BrewCore suite: 92 tests green. App `PersistenceUITests` green with the hopped, dry-hopped starter.

## Task Commits

1. **Task 1: Tracer, hop additions through Tinseth IBU into ledger rows and IBU stat** - `0e3034c` (feat)
2. **Task 2: Complete roster and content validation** (TDD)
   - RED: `b98f21c` (test), evidence `RED_EVIDENCE_OK`
   - GREEN: `c75592f` (feat)
3. **Task 3: Conditioning contributions, recipe grid, ledger invariants** (TDD)
   - RED: `f09da40` (test), evidence `RED_EVIDENCE_OK`
   - GREEN: `2a9214b` (feat)

No REFACTOR commits were needed.

## TDD Gate Compliance

### Task 2 RED

- **Target test:** `rosterCountsMatchD13()` in `ContentValidationTests.swift`.
- **Evidence:** `.planning/phases/01-brew-your-first-beer/evidence/01-03-task2-red.json`, validated as `RED_EVIDENCE_OK` (swift-testing, 11 tests, 6 failed on assertions).
- **semanticAssessment:** the suite compiled and executed. `AdjunctInfo` and an empty `adjuncts` accessor were added as compile-only stubs so the tests could reference them; the target failed on the planned counts (grains 2 vs 5, yeasts 1 vs 5, adjuncts 0 vs 3). The 5 passing tests assert behavior that already held (key shapes, hop bounds, starter validation). No compile, fixture or zero-test fault.

### Task 3 RED

- **Target test:** `dryHopAddsAromaRowsFromTheChosenHopAndNoIBU()` in `LedgerInvariantTests.swift`.
- **Evidence:** `.planning/phases/01-brew-your-first-beer/evidence/01-03-task3-red.json`, validated as `RED_EVIDENCE_OK` (11 tests, 5 failed on assertions).
- **semanticAssessment:** the dry hop row count was 0 because conditioning effects were empty and the Brewer emitted nothing for dry hop. The house profile, day-18 and conditioning-effect tests failed for the intended reasons. The six grid invariant tests passed already: the Task 1-2 ledger was sound and `RecipeGrid` itself built all 1,100 recipes without a rules refusal, which is the evidence the grid is valid.

## Files Created/Modified

- `scripts/gen-brew-tables.swift` - offline Tinseth table generator (plan 01-04 extends it with SRM)
- `Resources/Content/{hops,tinseth,adjuncts}.json` - new; `{bands,grains,yeasts,conditioning,starter_recipes}.json` - extended
- `Content/ContentCatalog.swift` - `HopInfo`, `HopSlotInfo`, `AdjunctInfo`, `AdjunctUsage`, `TinsethTable`, `adjuncts`/`fruits`/`hops`/`hopSlots`, yeast `effectsByDuration`
- `Engine/Brewer.swift` - hop stage, yeast duration rows, conditioning stage, IBU stat
- `Engine/RecipeRules.swift` - fruit ingredient resolution against `fruits`
- `Tests/BrewCoreTests/{HopContributionTests,ContentValidationTests,LedgerInvariantTests}.swift`, `Support/RecipeGrid.swift`
- `App/BrewFighter/Localizable.xcstrings` - 50 new keys (127 total)
- `.planning/names-cleared.md` - names log

## Decisions Made

- The starter's profile is reached by tuning content (hop.h01 citrus 30 to 22, tropical 20 to 14), keeping hopAroma 25 so every plan-stated number (aroma row 25, dry hop 33, bittering 3) still holds.
- Missing yeast temperature-band effects are now a decode error rather than silently empty, so a content typo cannot ship a flavorless yeast.
- Fruit and dry hop ingredient references are validated at brew time; the Brewer also throws if a conditioning step's ingredient is missing, rather than skipping it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Existing expectations written against the hop-less starter**
- **Found during:** Task 3 GREEN
- **Issue:** The starter now has a dry hop (3 days) and hops. Four existing assertions encoded the old facts: reducer day 15/29 (`WalkingSkeletonTests`), house day cost 14 (`RecipeRulesTests`), and house style `amber_ale` (`StyleClassifierTests`, whose own comment said it would move once hops existed).
- **Fix:** Updated to day 18 / 32, day cost 17, and `american_pale_ale`. The plan anticipated only the WalkingSkeletonTests day change; the other two are the same cause.
- **Files modified:** `WalkingSkeletonTests.swift`, `RecipeRulesTests.swift`, `StyleClassifierTests.swift`
- **Verification:** `swift test --package-path Packages/BrewCore` passes (92 tests).
- **Commit:** `2a9214b`

**2. [Rule 2 - Missing critical] Strict yeast band decoding and Brewer guards for missing conditioning ingredients**
- **Found during:** Task 2 and Task 3
- **Issue:** A yeast missing a temperature band would silently decode as empty effects; a conditioning step with no ingredient would otherwise be skipped by the Brewer instead of failing.
- **Fix:** `YeastInfo` throws `keyNotFound` for a missing band; the Brewer throws `.invalidRecipe` for dry hop or fruit steps without a resolvable ingredient or amount.
- **Files modified:** `ContentCatalog.swift`, `Brewer.swift`
- **Commit:** `c75592f`, `2a9214b`

**Total deviations:** 2 (1 Rule 1, 1 Rule 2). **Impact:** none on scope.

## Issues Encountered

- The "base grain with g01" structured-grid option was ambiguous in the plan. It is implemented as grain.g03 (base) at 50% plus grain.g01 at 50%, which still gives 3 x 5 x 5 x 4 x 2 = 600 recipes as specified.
- The 600-recipe structured grid is deterministic but not exhaustive of conditioning; conditioning coverage comes from the 500 seeded recipes (0-3 steps each).

## Known Stubs

| Stub | File | Reason / resolved by |
|------|------|----------------------|
| `BeerStats.fgPoints/abvTenths/srmTenths` fixed at 0 | `Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift` | Plan 01-04 computes FG, ABV and SRM. `ibuTenths` is real as of this plan. Tracked in `.planning/WINDOWS.md` (entry 2 stays open). |

The `containsHop` stub (WINDOWS entry 1) is closed: it now resolves against `hops`. `lovibondTenths` and `attenuationPermillePerPercent` content fields are loaded but unused until plan 01-04.

## Threat Flags

None. New surface matches the threat model: T-1-09 is mitigated (bounded effects, alpha, percent and temperature fields, referential integrity and unique IDs under test, OG clamped before table indexing); T-1-10 is mitigated (neutral IDs, fictional hop names, brand-name grep clean, names log written).

## User Setup Required

None - no external service configuration required. A human trademark search for "Brew Fighter" and the hop names remains open (see `.planning/names-cleared.md`).

## Next Phase Readiness

- Plan 01-04 can add FG/ABV/SRM to the same Brewer using `lovibondTenths`, `attenuationPermille`, `attenuationDeltaPermille` and `attenuationPermillePerPercent`, and extend `scripts/gen-brew-tables.swift` with the SRM table.
- Plans 01-06 and 01-07 (wizard) can rely on `ContentCatalog.hops`, `hopSlots`, `fruits`, `adjuncts` and the trait keys for ingredient cards.
- `RecipeGrid` is ready for the style and save tests in plans 01-04 and 01-05.

## Self-Check: PASSED

- All created key-files exist on disk (checked with `[ -f ]`: generator, three content JSONs, four test files, names log).
- Five task commits (`0e3034c`, `b98f21c`, `c75592f`, `f09da40`, `2a9214b`) are ancestors of HEAD; `git log --grep='(01-03)'` returns 5 and `commits: 5` was measured from the plan ledger.
- Acceptance criteria re-run and passing: `swift test --package-path Packages/BrewCore` (92 tests); `HopContributionTests` (12), `ContentValidationTests` (11), `LedgerInvariantTests` (11) each exit 0; `tinseth.json` contains `bittering`, `whirlpool`, `ogMin` and its `shasum` is identical across two generator runs; brand-name grep prints nothing; `swift scripts/check-strings.swift` prints `check-strings: OK (127 keys)`; adjuncts/yeasts/grains/names-cleared/conditioning/starter/RecipeGrid content greps match.
- Plan verification: `scripts/test-app.sh -only-testing:BrewFighterUITests/PersistenceUITests` exits 0.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-08*
