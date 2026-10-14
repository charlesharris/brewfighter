---
phase: 01-brew-your-first-beer
plan: 04
subsystem: engine-content
tags: [swift, brewcore, stats, abv, srm, morey, glass, style-classifier, content-json, swift-testing]

requires:
  - phase: 01-01
    provides: "Brewer, additive ledger, StyleClassifier, ContentCatalog, SaveCodec"
  - phase: 01-03
    provides: "Full roster, Tinseth IBU, conditioning rows, RecipeGrid, names-cleared log"
provides:
  - "Real OG/FG/ABV/SRM on every beer (IBU already real), computed with Int math"
  - "ABV attribute ledger rows that telescope exactly to the ABV stat, including an attenuationLimit clamp row"
  - "Generated morey.json (MCU tenths to SRM tenths) and a clamped MoreyTable"
  - "srm_colors.json (40 stops) and SRMColorTable with per-channel Int interpolation"
  - "Pure GlassSpec (shape, liquid, head, bubbles, haze, seed) with a pairwise distance test across six archetypes"
  - "styles.json with 13 styles plus amber_ale and experimental_ale, each carrying a glass shape"
  - "Archetypes test support: one recipe per style, built only through RecipeRules"
  - "15 style display names in the String Catalog and names-cleared log"
affects: [01-05, 01-06, 01-07, 01-08, phase-02]

actuals:
  tokens: 13757
  tasks: 3
  commits: 5
plan_head_before: 8a539b687be90446aa82dfe4eba971e02b7f5faa
plan_head_after: 64bbaadac681da2fb291e9976f4c4531d6f98dfa

tech-stack:
  added: []
  patterns:
    - "Attenuation chain as a private value type; each step returns its ABV delta so rows telescope with no remainder rule"
    - "Floating point stays in the offline generator; engine reads committed Int tables (now tinseth.json and morey.json)"
    - "GlassSpec is a pure BrewCore function; the app only paints it"
    - "Style conditions use attribute tenths only; required conditions guard against vague recipes claiming a style"

key-files:
  created:
    - Packages/BrewCore/Sources/BrewCore/Glass/GlassSpec.swift
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/morey.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/srm_colors.json
    - Packages/BrewCore/Tests/BrewCoreTests/StatsTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/GlassSpecTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/Support/Archetypes.swift
    - .planning/phases/01-brew-your-first-beer/evidence/01-04-task2-red.json
    - .planning/phases/01-brew-your-first-beer/evidence/01-04-task3-red.json
  modified:
    - scripts/gen-brew-tables.swift
    - Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift
    - Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift
    - Packages/BrewCore/Sources/BrewCore/Style/StyleClassifier.swift
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/styles.json
    - Packages/BrewCore/Tests/BrewCoreTests/StyleClassifierTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/Support/RecipeGrid.swift
    - App/BrewFighter/Localizable.xcstrings
    - .planning/names-cleared.md

key-decisions:
  - "ABV ledger rows are emitted at each stage with the stage's own source (fermentable sugar rows, strength, mash, yeast, ferment temp, duration); the yeast attenuation row uses detail 'attenuation' and the clamp row uses 'attenuationLimit'"
  - "The clamp row is emitted next to the yeast row (yeast-attributed) rather than at the end of the chain; the telescoping sum is order-independent"
  - "Porter roast window is 25...55 and brown ale is defined by low roast plus malt and sweetness, because roasted barley at 5% steps gives roast 35 or 70 and the plan's 40...65 porter window is unreachable"
  - "Signature bitterness or body conditions are required for pilsner, helles, blonde, brown ale and wheat so an unhopped recipe falls back instead of claiming a style"
  - "StyleDefinition.glass is required in styles.json (strict decode); the Swift memberwise init defaults it to shaker so earlier tests compile unchanged"

patterns-established:
  - "RED stubs: types and data plumbing are real, only the behavior under test is a constant stub, so the target test fails on its assertion"
  - "Archetype recipes are test fixtures tuned to classify to their own style and to keep glasses at least 60 apart without relying on shape alone"

requirements-completed: [BREW-02, BREW-04, BREW-06, ART-01, PLAT-06]

coverage:
  - id: D1
    description: "OG/FG/ABV/SRM stats on every brewed beer; house pale ale OG 1050, FG 1008...1014, ABV 4.8...5.6, SRM 7.0...13.0"
    requirement: "BREW-02"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/StatsTests.swift#housePaleAleStatsAreInTheExpectedRanges, imperialFarmhouseIsStrongerThanTheSameRecipeAtSessionStrength, roastedBarleyStoutIsDark, candiSugarRaisesAbvAndLowersFinalGravity, moreyTableMatchesTheKnownAnchor"
        status: pass
    human_judgment: false
  - id: D2
    description: "ABV attribute rows telescope to exactly min(abvTenths, 100) over the 600 structured and 500 seeded recipes; attenuation clamps at 550...950 as its own yeast row"
    requirement: "BREW-04"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/StatsTests.swift#abvRowsTelescopeToTheAbvStatOverBothGrids, attenuationIsClampedAndTheClampIsItsOwnYeastRow, abvRowsAreInGlobalStageOrder"
        status: pass
    human_judgment: false
  - id: D3
    description: "Stats survive the save round trip unchanged"
    requirement: "PLAT-06"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/StatsTests.swift#statsSurviveTheSaveRoundTrip"
        status: pass
    human_judgment: false
  - id: D4
    description: "GlassSpec is deterministic and bounded, snifter at 8.0% ABV and up, shape from the style's glass field, and the six glass archetypes are at least 60 apart"
    requirement: "ART-01"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/GlassSpecTests.swift (14 tests incl. glassArchetypesArePairwiseAtLeastSixtyApart, derivedValuesStayInRangeOverTheRecipeGrids)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Thirteen styles plus two fallbacks are each reachable from an archetype recipe, the house pale ale is American Pale Ale, the two IPAs differ, fallback share over the structured grid is 15.5%, and the classifier never returns an unknown ID"
    requirement: "BREW-06"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/StyleClassifierTests.swift (19 tests incl. everyStyleIsReachableFromItsArchetypeRecipe, fallbackShareOverTheStructuredGridIsAtMostHalf, everySampleRecipeClassifiesToAKnownStyle, emptyAndMinimalRecipesFallBackInsteadOfClaimingAStyle)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Style persisted only as a stable ID; display names live only in the String Catalog and the catalog check passes"
    requirement: "PLAT-06"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/StyleClassifierTests.swift#aBrewedBeerPersistsTheStyleIDAndNeverTheDisplayName"
        status: pass
      - kind: other
        ref: "swift scripts/check-strings.swift -> check-strings: OK (139 keys)"
        status: pass
      - kind: e2e
        ref: "scripts/test-app.sh -only-testing:BrewFighterUITests/PersistenceUITests -> TEST SUCCEEDED"
        status: pass
    human_judgment: false
  - id: D7
    description: "No UI or recipe field lets the player choose a style; ABV and IBU are shown only as brewing stats with no reward semantics (App Review 1.4.3)"
    requirement: "BREW-06"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/StyleClassifierTests.swift#recipeJSONNeverContainsAStyleKey"
        status: pass
    human_judgment: true
    rationale: "The prohibition on ranking, badges or celebratory ABV copy applies to UI built in later plans; this plan only verifies that Recipe has no style field and that catalog strings carry no banned vocabulary"
  - id: D8
    description: "SRM color stops match a published chart"
    requirement: "ART-01"
    verification: []
    human_judgment: true
    rationale: "Fifteen stops were cross-checked against swatch hex values on brewersfriend.com and brewgr.com; the rest come from the plan's list and need a visual check (WINDOWS entry 3, plan 01-08)"

duration: 11min
completed: 2026-10-14
status: complete
---

# Phase 1 Plan 04: Stats, Glass and Style Roster Summary

**OG/FG/ABV/SRM stats with a telescoping ABV ledger, a pure Int-only GlassSpec driven by cited SRM color stops, and a 13-style attribute-only classifier with bounded fallbacks (15.5% of the structured grid).**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-14T18:54:05Z
- **Completed:** 2026-10-14T19:05Z
- **Tasks:** 3 (1 tracer, 2 TDD)
- **Files modified:** 19 in the plan range

## Accomplishments

- Tracer proven end to end: the house pale ale has OG 1050, FG in 1008...1014, ABV 4.8...5.6, SRM 7.0...13.0. The ABV attribute rows (strength, grain-bill sugar, mash, yeast, ferment temp, duration, plus an `attenuationLimit` clamp row when the chain leaves 550...950) sum exactly to `min(abvTenths, 100)` across 1,100 recipes. Tracer gate: automated-only verify re-run green, "Tracer verified end-to-end, expanding".
- `scripts/gen-brew-tables.swift` now also writes `morey.json` (4,001 Ints); two runs give an identical `shasum`. `MoreyTable` and `SRMColorTable` clamp their indices (T-1-11).
- `GlassSpec.make(for:content:)` is a pure function of the beer: liquid from SRM stop interpolation, head tinted by roast, bubbles and head height from carbonation, haze from body, tropical and fruit, a snifter at 8.0% ABV and up, and a SplitMix64 seed from the batch number. No `Double` or `Float` in `Glass/`.
- The six glass archetypes are at least 60 apart under both the interim style set (Task 2) and the full roster (Task 3).
- `styles.json` holds 13 styles and 2 fallbacks, all attribute-only. Every style is reproduced by an archetype recipe, the two IPAs classify differently, and unhopped or empty recipes fall back.
- Full suite: 127 BrewCore tests pass (92 at the start of the plan). `swift scripts/check-strings.swift` prints `check-strings: OK (139 keys)`. App `PersistenceUITests` pass.

## Task Commits

1. **Task 1: Tracer, stats and the telescoping ABV ledger** - `7428379` (feat)
2. **Task 2: GlassSpec** (TDD)
   - RED: `5b938ae` (test), evidence `RED_EVIDENCE_OK`
   - GREEN: `b2731ae` (feat)
3. **Task 3: Full style roster** (TDD)
   - RED: `8ddc926` (test), evidence `RED_EVIDENCE_OK`
   - GREEN: `64bbaad` (feat)

No REFACTOR commits were needed.

## TDD Gate Compliance

### Task 2 RED

- **Target test:** `glassArchetypesArePairwiseAtLeastSixtyApart()` in `GlassSpecTests.swift`.
- **Evidence:** `.planning/phases/01-brew-your-first-beer/evidence/01-04-task2-red.json`, validated as `RED_EVIDENCE_OK` (swift-testing, 14 tests, 9 failed).
- **semanticAssessment:** the suite compiled and ran. `RGB`, `GlassShape`, the `glass` style field and `distance(to:)` are real; `GlassSpec.make` and the SRM color table were compile-only stubs returning constants, so all 15 archetype pairs had distance 0 and the target failed on its planned assertion. The 5 passing tests assert behavior independent of the stubs (determinism of a constant, grid ranges, unknown style fallback). No compile, fixture or zero-test fault.

### Task 3 RED

- **Target test:** `stylesFileDefinesThirteenStylesAndTwoFallbacksInOrder()` in `StyleClassifierTests.swift`.
- **Evidence:** `.planning/phases/01-brew-your-first-beer/evidence/01-04-task3-red.json`, validated as `RED_EVIDENCE_OK` (19 tests, 15 issues across 4 failing tests).
- **semanticAssessment:** styles.json had only `american_pale_ale`, so the order test failed on the expected 13 IDs, 12 archetypes classified to a fallback and the structured-grid fallback share was 100%. The remaining tests (ASCII IDs, sample-grid known-style check, zero and minimal fallback, ID-not-name persistence) passed because they assert invariants that already held. No compile or fixture fault.

## Files Created/Modified

- `scripts/gen-brew-tables.swift` - also generates `morey.json`
- `Resources/Content/{morey,srm_colors}.json` - new; `styles.json` - 13 styles, 2 fallbacks, `glass` field
- `Content/ContentCatalog.swift` - `MoreyTable`, `SRMColorTable`, `glassShape(forStyle:)`
- `Engine/Brewer.swift` - attenuation chain, FG/ABV/SRM stats, ABV attribute rows
- `Glass/GlassSpec.swift` - `RGB`, `GlassShape`, `GlassSpec`
- `Style/StyleClassifier.swift` - `StyleDefinition.glass`
- `Tests/BrewCoreTests/{StatsTests,GlassSpecTests}.swift`, `Support/Archetypes.swift`, `StyleClassifierTests.swift`, `Support/RecipeGrid.swift` (helpers made internal)
- `App/BrewFighter/Localizable.xcstrings` - 12 new style names (139 keys); `.planning/names-cleared.md` - 15 style rows

## Decisions Made

- See `key-decisions` in the frontmatter. In short: stage-attributed ABV rows with a yeast-attributed clamp row, content-side tuning of style thresholds rather than ingredient effects, and strict decoding of the `glass` field.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's porter window is unreachable**
- **Found during:** Task 3 GREEN
- **Issue:** Roasted barley (the only roast source) moves in 5% steps and gives roast 35 at 5% and 70 at 10%. The plan's porter window of 40...65 and brown ale roast 15...40 (required) cannot both be hit by a recipe.
- **Fix:** Porter roast 25...55 (required), stout roast 60...100 (required), brown ale defined as malty, sweet-leaning, low roast (0...24) with bitterness 10...35 required. Ingredient effects were left untouched.
- **Files modified:** `styles.json`
- **Verification:** `everyStyleIsReachableFromItsArchetypeRecipe` for all 13 styles.
- **Commit:** `64bbaad`

**2. [Rule 1 - Bug] Unhopped recipes could claim a style**
- **Found during:** Task 3 GREEN
- **Issue:** With the plan's starting conditions, `unqualifiedMaltySweetBeerFallsBackToAmberAle` (an earlier test) failed because brown ale matched an unhopped malty beer, and the minimal recipe would have matched helles.
- **Fix:** Signature conditions made required: bitterness for brown ale, pilsner, helles and blonde; body for wheat.
- **Files modified:** `styles.json`
- **Verification:** all 19 `StyleClassifierTests` pass, test bounds unchanged.
- **Commit:** `64bbaad`

**3. [Rule 3 - Blocking] Glass distance floor at Task 2 time**
- **Found during:** Task 2 GREEN
- **Issue:** Before Task 3 only three styles exist, so pilsner, saison and wheat all fell back to the same glass shape and two pairs were under 60 (46 and 28).
- **Fix:** Tuned the archetype recipes (the plan's stated remedy, no threshold change): saison gets 5% crystal, wheat is 50% wheat malt, 40% pale, 10% oats with bottle conditioning, stout uses 2 quarter-ounces of bittering hops (8 capped bitterness at 100). The floor now holds on color, head, bubbles and haze alone, and shape only adds margin once Task 3 lands.
- **Files modified:** `Tests/BrewCoreTests/Support/Archetypes.swift`
- **Verification:** `GlassSpecTests` pass at both commits.
- **Commit:** `b2731ae`, `64bbaad`

**4. [Rule 2 - Missing critical] SRM chart only partly verified**
- **Found during:** Task 2
- **Issue:** The plan asks to confirm every stop against a published chart. I could fetch swatch values from brewersfriend.com and brewgr.com and matched 15 stops (SRM 2-9, 12, 17, 19, 20, 24, 28, 34). The chart page itself serves images, so the other stops are unconfirmed.
- **Fix:** `source` cites the Brewer's Friend chart URL and a `note` field states the partial verification. Logged as WINDOWS entry 3 so plan 01-08 or the ship gate re-checks them visually.
- **Files modified:** `srm_colors.json`, `.planning/WINDOWS.md`
- **Commit:** `b2731ae`

**Total deviations:** 4 (2 Rule 1, 1 Rule 2, 1 Rule 3). **Impact:** thresholds and archetype recipes differ from the plan's starting guidance as the plan allows ("tune content, never the test bounds"); no test bound, formula or interface changed.

## Issues Encountered

- A 15 permille attenuation clamp does not always change the rounded ABV at OG 1050, so the clamp test uses imperial strength (OG 1085). The clamp row itself is correct; the zero-delta rule simply omits it when it rounds away.
- The structured grid has no 5% roasted-barley recipe, so porter appears only in the seeded sample grid. Reachability is proven by its archetype.
- The `wheat_beer` and `wild_ale` styles each claim about 16-19% of the structured grid because their signature conditions (body, funk) are broad. Fallback share is the only bounded quantity in the plan, and it is 15.5%.

## Known Stubs

None. WINDOWS entry 2 (the FG/ABV/SRM zero stub) is closed.

## Threat Flags

None. T-1-11 is mitigated: attenuation is clamped to 550...950, `MoreyTable` and `SRMColorTable` clamp their indices, and all divisors are constants. T-1-12 is mitigated: ABV is a neutral attribute row with no reward semantics and `check-strings` (BANNED list) passes over every catalog value.

## User Setup Required

None - no external service configuration required. A human trademark search for the style-name terms is not needed (generic terms); the earlier pending search for "Brew Fighter" and the hop names remains open in `.planning/names-cleared.md`.

## Next Phase Readiness

- Plan 01-05 can freeze the save schema: `BeerStats` is fully populated and the style is stored as an ID.
- Plans 01-06 to 01-08 can render stats, the ABV ledger rows (detail values `attenuation`, `attenuationLimit` and band IDs), `GlassSpec` and style names via `style.<id>.name`.
- Plan 01-08 should visually tune the SRM stops flagged in WINDOWS entry 3.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-14*

## Self-Check: PASSED

- All created key-files exist on disk (`[ -f ]`): `GlassSpec.swift`, `morey.json`, `srm_colors.json`, `StatsTests.swift`, `GlassSpecTests.swift`, `Archetypes.swift`, both RED evidence files.
- Five task commits (`7428379`, `5b938ae`, `b2731ae`, `8ddc926`, `64bbaad`) are ancestors of HEAD; `check evaluation-scope --plan 01-04 --commits-only` returns the same 5, and `commits: 5` was measured with `git rev-list --count` from the plan ledger.
- Acceptance criteria re-run and passing: `StatsTests` (12), `GlassSpecTests` (14), `StyleClassifierTests` (19), full BrewCore suite (127); `morey.json` contains `srmTenths` and `mcuTenthsMax` and is byte-identical across two generator runs; `Brewer.swift` contains `13125`; `GlassSpec.swift` contains `public struct GlassSpec` and `static func make(for beer: Beer`; `srm_colors.json` has an `https://` source and `36080A`; no `Double` or `Float` under `Glass/`; `styles.json` names all five required IDs; catalog has `style.west_coast_ipa.name`; names-cleared has `West Coast IPA`; `swift scripts/check-strings.swift` exits 0.
- Plan verification: `scripts/test-app.sh -only-testing:BrewFighterUITests/PersistenceUITests` exits 0 (TEST SUCCEEDED).
