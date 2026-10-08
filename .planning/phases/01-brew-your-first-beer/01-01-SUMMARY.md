---
phase: 01-brew-your-first-beer
plan: 01
subsystem: engine
tags: [swift, swift-package, brewcore, swift-testing, deterministic-engine, codable-json, int-fixed-point]

requires: []
provides:
  - "BrewCore Swift package (tools 6.0, iOS 17 / macOS 14) buildable and testable headless with swift test"
  - "Int-tenths 16-attribute model with the four-family mapping (cross-phase contract D-11 / ENC-08)"
  - "Deterministic Brewer producing attributes, additive ledger with cap rows, stats shell and style"
  - "Reducer.apply(.brew) committing batch number and recipe-driven day advance (D-10)"
  - "StyleClassifier over an AttributeVector only (BREW-06) with fallbacks"
  - "RecipeRules: validation floor, grain-bill auto-rebalance, hop and conditioning edits, dayCost"
  - "SaveCodec v1 envelope with size cap and version gate"
  - "Content JSON catalog loaded through Bundle.module (bands, grains, yeast, conditioning, styles, house pale ale)"
affects: [01-02, 01-03, 01-04, 01-05, 01-06, 01-07, 01-08, 01-09, 01-10, phase-02]

tech-stack:
  added: [swift-tools-6.0, swift-testing]
  patterns:
    - "Int fixed-point only (attributes in tenths 0...100), no Double or Float in Model/Engine"
    - "Additive ledger: displayed value is the sum of rows; clamping emits an explicit cap row"
    - "package access for engine internals (Brewer, StyleClassifier, EffectMap); public result types only"
    - "Pure edit functions return a new value or nil when refused; one accepted() gate re-validates every candidate bill"
    - "Content as JSON decoded via Codable; effect maps decoded from [String: Int] (enum-keyed dictionaries encode as arrays)"

key-files:
  created:
    - Packages/BrewCore/Package.swift
    - Packages/BrewCore/Sources/BrewCore/Model/Attributes.swift
    - Packages/BrewCore/Sources/BrewCore/Model/Recipe.swift
    - Packages/BrewCore/Sources/BrewCore/Model/Beer.swift
    - Packages/BrewCore/Sources/BrewCore/Model/GameState.swift
    - Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift
    - Packages/BrewCore/Sources/BrewCore/Engine/Reducer.swift
    - Packages/BrewCore/Sources/BrewCore/Engine/RecipeRules.swift
    - Packages/BrewCore/Sources/BrewCore/Style/StyleClassifier.swift
    - Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift
    - Packages/BrewCore/Sources/BrewCore/Save/SaveCodec.swift
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/manifest.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/bands.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/grains.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/yeasts.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/conditioning.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/styles.json
    - Packages/BrewCore/Sources/BrewCore/Resources/Content/starter_recipes.json
    - Packages/BrewCore/Tests/BrewCoreTests/WalkingSkeletonTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/StyleClassifierTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/RecipeRulesTests.swift
  modified:
    - .gitignore

key-decisions:
  - "Attribute scale is Int tenths 0...100; families are malt{malt,sweetness,roast}, hop{bitterness,hopAroma,citrus,tropical,herbal}, yeast{fruit,spice,funk,sour}, mouthfeel{body,dryness,carbonation,abv}"
  - "Ledger rows emit in fixed brewing-stage order, never re-sorted, zero deltas skipped, cap rows last"
  - "Batch strength dial adopted (session/standard/strong/imperial, OG 1036/1050/1066/1085) per research Gap 1"
  - "Day cost = ferment days (7/14/21) + conditioning days (dryHop 3, fruit 7, bottleConditioning 14, lagering 28); lagering excludes bottle conditioning"
  - "settingBase reassigns the base role only; percents never move because the new base's share is already 100 minus the others"
  - "Hop adds to an existing hop+slot at 16 quarter-ounces are refused (nil) rather than silently no-op, so the UI can disable the control"
  - "Brewer is the single throwing entry point and validates through RecipeRules before any arithmetic (T-1-01)"

patterns-established:
  - "Tests use Swift Testing with @testable import; random-sequence tests draw from SeededRNG so failures reproduce"
  - "Invariants are stated independently in tests (violation helper) and cross-checked against RecipeRules.validate"
  - "Content keys: band.<group>.<id>.name|blurb, conditioning.<kind>.name|blurb, content.<id>.name, style.<id>.name; no English in JSON"

requirements-completed: [BREW-01, BREW-02, BREW-04, BREW-06, BREW-07, PLAT-03]

actuals:
  tokens: 24700
  tasks: 3
  commits: 5
plan_head_before: 2b6b486a3313e03f73a0c50c0a44f7cab81a6b82
plan_head_after: 2594852ef9ef4eec90db1354e9725e9f85f5a517

coverage:
  - id: D1
    description: "Deterministic brew: same recipe gives equal BrewResult, no RNG draw, 16 attributes within 0...100"
    requirement: "BREW-02"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/WalkingSkeletonTests.swift#brewIsDeterministic, brewingNeverTouchesTheRNG"
        status: pass
    human_judgment: false
  - id: D2
    description: "Additive contribution ledger: rows sum exactly to every attribute value, explicit cap rows, fixed stage order"
    requirement: "BREW-04"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/WalkingSkeletonTests.swift#ledgerRowsSumExactlyToEveryAttribute, capRowKeepsRowsEqualToValue, houseLedgerIsInBrewingStageOrder"
        status: pass
    human_judgment: false
  - id: D3
    description: "Style label computed from the attribute vector only; recipe JSON has no style key"
    requirement: "BREW-06"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/StyleClassifierTests.swift#fullAmericanPaleAleMatchWins, equalMatchPercentGoesToTheEarlierStyleInTheTable, recipeJSONNeverContainsAStyleKey"
        status: pass
    human_judgment: false
  - id: D4
    description: "Brew resolves instantly by advancing the day counter by fermentation plus conditioning days; no timers"
    requirement: "BREW-07"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/RecipeRulesTests.swift#reducerAdvancesTheDayByTheFullDayCost, dayCostSumsFermentationAndEveryConditioningStep"
        status: pass
      - kind: other
        ref: "grep -rnE 'Timer|asyncAfter|sleep|Date\\(\\)|DispatchQueue' Packages/BrewCore/Sources (no matches)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Recipe validation floor and edit rules keep grain bills, hops and conditioning valid under random edit sequences"
    requirement: "BREW-01"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/RecipeRulesTests.swift#randomGrainBillEditSequencesNeverBreakTheInvariants, validateReportsGrainBillProblems, brewerRefusesOutOfRangeAmountsBeforeAnyArithmetic"
        status: pass
    human_judgment: false
  - id: D6
    description: "GameState round-trips through SaveEnvelope v1 with byte-stable encoding, size cap and newer-version rejection"
    requirement: "PLAT-03"
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/WalkingSkeletonTests.swift#codecRoundTripsAndIsByteStable, newerSchemaIsRejectedBeforePayloadDecode, oversizedInputIsRejected, garbageBytesAreUnreadable"
        status: pass
    human_judgment: false

duration: 11 min
completed: 2026-10-08
status: complete
---

# Phase 1 Plan 01: BrewCore Engine Walking Skeleton Summary

**Headless BrewCore Swift package: house pale ale recipe to a deterministic Beer (16 Int-tenths attributes, additive ledger with cap rows, attribute-only style) through a batch-numbering, day-advancing reducer and a versioned byte-stable JSON save envelope, with the recipe edit rules that keep every wizard-built recipe valid.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-08T21:54:09Z
- **Completed:** 2026-10-08T22:05:00Z
- **Tasks:** 3 (1 tracer, 2 TDD)
- **Files modified:** 22 (21 created in `Packages/BrewCore`, plus `.gitignore`)

## Accomplishments

- Tracer path proven end to end on Swift 6.1.2 with no simulator: `swift test --package-path Packages/BrewCore` runs 58 tests (19 walking-skeleton, 10 style, 29 recipe-rules), all passing, zero warnings.
- Brewing is fully deterministic and RNG-free: two brews of the house pale ale are equal and the `SeededRNG` is bit-identical afterwards, including after a rejected brew.
- The ledger contract holds for every attribute: rows sum exactly to the stored value, values stay within 0...100, cap rows are appended last, and zero-delta rows are never emitted.
- `RecipeRules` is the single owner of edit semantics. One `accepted()` gate re-validates every candidate grain bill, and 1,000 random 30-op sequences (seed 42) over a six-fermentable catalog never violate an invariant, with the engine validator agreeing with an independently written checker.
- `SaveCodec` v1 is byte-stable (`.sortedKeys`), rejects oversize input before parsing, and rejects a newer `schemaVersion` from a header-only decode with no partial load.
- Brewer validates before any arithmetic, so hostile percents (`Int.max`, `Int.min`, negative) are rejected instead of trapping on overflow (T-1-01).

## Task Commits

1. **Task 1: Tracer, house pale ale to Brewer to Reducer to SaveCodec round trip** - `1e4efcc` (feat). Tracer gate: automated-only verify re-run green, "Tracer verified end-to-end, expanding".
2. **Task 2: Style label computed from attributes only** (TDD)
   - RED: `231bfa0` (test), evidence `RED_EVIDENCE_OK`
   - GREEN: `e6d7dfd` (feat)
3. **Task 3: Recipe rules, validation floor, grain-bill rebalance, hop and conditioning edits, day cost** (TDD)
   - RED: `c8d71ce` (test), evidence `RED_EVIDENCE_OK`
   - GREEN: `2594852` (feat)

No REFACTOR commits were needed.

## TDD Gate Compliance

### Task 2 RED

- **Target test:** `fullAmericanPaleAleMatchWins()` in `StyleClassifierTests.swift`.
- **Evidence:** `.planning/phases/01-brew-your-first-beer/evidence/01-01-task2-red.json`, validated with `check tdd-red-evidence` as `RED_EVIDENCE_OK` (swift-testing format, 10 tests, 5 failed on assertions).
- **Why it failed:** the classifier was a deliberate stub returning `experimental_ale`, so the planned `american_pale_ale` expectation failed.
- **semanticAssessment:** the package built, the target executed and failed on the planned assertion for the intended reason. The 5 passing tests are trivially satisfied by the stub or by data already in place. No compile, fixture or zero-test fault.

### Task 3 RED

- **Target test:** `validateEmptyRecipeReportsNoGrainAndNoYeast()` in `RecipeRulesTests.swift`.
- **Evidence:** `.planning/phases/01-brew-your-first-beer/evidence/01-01-task3-red.json`, validated as `RED_EVIDENCE_OK` (29 tests, 24 failed on assertions).
- **Why it failed:** `RecipeRules` was a RED stub (validate `[]`, edits `nil`, dayCost `0`).
- **semanticAssessment:** all 29 tests were discovered and executed. A first RED attempt crashed the process on an `Int` overflow (percent `Int.max / 2` through the pre-validation Brewer), producing no summary line. That attempt was discarded and the test was changed to a non-overflowing out-of-range value (1,000) for a complete, valid report. The extreme-value cases (`Int.max / 2`, `Int.max`, `Int.min`, `-1`) were added as a parameterized test in the GREEN commit alongside the fix.

## Files Created/Modified

- `Packages/BrewCore/Package.swift` - tools 6.0, iOS 17 / macOS 14, `.copy("Resources/Content")`
- `Model/Attributes.swift` - `AttributeID`, `AttributeFamily`, `AttributeScale`, `AttributeVector` (16-key JSON object, strict decode)
- `Model/Recipe.swift` - recipe, bands, hop and conditioning types, `RecipeIssue` (no style field)
- `Model/Beer.swift` - `Beer`, `BrewResult`, `BeerStats`, `LedgerRow`, `LedgerSource`, `SourceKind`
- `Model/GameState.swift` - `GameState`, `Action`, `GameEvent`
- `Engine/Brewer.swift` - deterministic brew, `divRound`, `finalize` (cap rows)
- `Engine/Reducer.swift` - `SeededRNG` (SplitMix64) and `Reducer.apply`
- `Engine/RecipeRules.swift` - validation floor, grain/hop/conditioning edits, `dayCost`
- `Style/StyleClassifier.swift` - weighted-range classifier, `StyleTable`
- `Content/ContentCatalog.swift` - JSON loading, descriptor structs, lookups
- `Save/SaveCodec.swift` - envelope v1, `SaveError`
- `Resources/Content/*.json` - manifest, bands, grains, yeasts, conditioning, styles, starter recipes
- `Tests/BrewCoreTests/*.swift` - 58 tests
- `.gitignore` - Xcode / SwiftPM block appended (existing lines kept)

## Decisions Made

- Adopted the batch-strength dial (research Gap 1): four bands with OG 1036/1050/1066/1085 and malt/body effects scaling with strength.
- Conditioning days 3/7/28/14 summed per step; lagering and bottle conditioning exclude each other; ferment durations 7/14/21 (research Gaps 3 and 4).
- `settingBase` only reassigns the role. The spec's "new base becomes 100 minus the others" is an identity when the bill already sums to 100, so refusal reduces to the new base being under 10% or out of range.
- `addingHop` at 16 quarter-ounces returns `nil` (refused) so the UI can disable the control, and merging clamps at 16 on the way up.
- `conditioning.json` uses a `{ "conditioning": [...] }` wrapper object, consistent with the other content files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `package set` is not valid accessor syntax**
- **Found during:** Task 1 (first build)
- **Issue:** `AttributeVector`'s subscript used `package set { ... }`, which does not parse; the build failed.
- **Fix:** Declared the subscript as `public package(set) subscript(...)` so reads are public and writes are package-only.
- **Files modified:** `Packages/BrewCore/Sources/BrewCore/Model/Attributes.swift`
- **Verification:** `swift test --filter WalkingSkeletonTests` built and passed (19 tests).
- **Commit:** `1e4efcc` (fixed before the commit)

**2. [Rule 2 - Missing critical] Overflow-safe percent sum in validation**
- **Found during:** Task 3
- **Issue:** A naive `reduce(0, +)` over untrusted percents can trap on overflow, which is exactly the T-1-01 hazard the validator exists to prevent.
- **Fix:** `billIssues` sums percents clamped to 0...100, and base percents are range-checked against `0...min(maxPercent, 100)`.
- **Files modified:** `Packages/BrewCore/Sources/BrewCore/Engine/RecipeRules.swift`
- **Verification:** `brewerRefusesOutOfRangeAmountsBeforeAnyArithmetic` parameterized over `1000, Int.max/2, Int.max, Int.min, -1` passes.
- **Commit:** `2594852`

**3. [Rule 3 - Blocking] Protected-branch commit guard**
- **Found during:** startup, before Task 1
- **Issue:** The working tree was on `main`, which `git.base-branch --is-protected` reports as protected, so the mandatory pre-commit HEAD assertion would have failed every commit. `git.allow_default_branch_commits` is not set, and changing `.planning/config.json` was not mine to do.
- **Fix:** Re-homed onto a new branch `gsd/phase-01-brew-your-first-beer` (matches the configured `phase_branch_template`) before the first edit; all commits are on that branch. No history was rewritten and `main` is untouched at `2b6b486`.
- **Impact:** The orchestrator and any later plan in this phase will find HEAD on `gsd/phase-01-brew-your-first-beer`, not `main`. Either keep executing on that branch or merge it back; if direct commits to `main` are intended for this project, set `git.allow_default_branch_commits: true`.

**4. [Process] First Task 3 RED run crashed**
- **Found during:** Task 3 RED
- **Issue:** See "TDD Gate Compliance". Not a code bug in the shipped result; it demonstrated the pre-validation overflow that Task 3 fixes.
- **Fix:** Moved the extreme-value cases into the GREEN commit.

**Total deviations:** 4 (1 Rule 2, 2 Rule 3, 1 process). **Impact:** none on scope; deviation 3 changes which branch holds the work.

## Issues Encountered

- `ContentCatalog.appendingFermentables(_:)` (package) was added so tests can build richer grain bills; the plan did not list it. It is test support only.
- The plan's `RecipeRules.addingHop` signature includes a `content` parameter that is unused until plan 01-03 adds a hop catalog. It is kept so the public signature does not change later.
- Informational for plan 01-03: with no hops, the house pale ale classifies as `amber_ale`, not `american_pale_ale` (bitterness is 0 and `american_pale_ale` requires 25...55). It will move once the starter's hop additions exist.

## Known Stubs

| Stub | File | Reason / resolved by |
|------|------|----------------------|
| `ContentCatalog.containsHop` always returns `false` | `Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift` | No hop content yet; plan 01-03 adds hops. Until then any hop ID validates as `.unknownIngredient`, as the plan specifies. |
| `BeerStats.fgPoints/abvTenths/ibuTenths/srmTenths` fixed at 0 | `Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift` | Plan 01-03 computes IBU; plan 01-04 computes FG, ABV and SRM, as the plan specifies. |
| Conditioning `effects` are `{}` for all four kinds | `Packages/BrewCore/Sources/BrewCore/Resources/Content/conditioning.json` | Plan 01-03 fills attribute effects. The Brewer conditioning stage already emits rows from them. |

The first two are also recorded in `.planning/WINDOWS.md`.

## Threat Flags

None. The files introduced match the plan's threat model (`SaveCodec` input handling, Brewer arithmetic); mitigations T-1-01 through T-1-04 are implemented and tested.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 01-02 onward can depend on the public names in the plan's `<interfaces>` block; none were renamed.
- Plan 01-02 can link `Packages/BrewCore` from the XcodeGen app target; content loads through `Bundle.module`.
- Plans 01-03 and 01-04 extend `Brewer` through the existing row pipeline (hop stage between mash and yeast, stats computation) with no architectural change.
- Plan 01-05 inserts the migrator chain and `SaveValidator` between steps (c) and (d) of `SaveCodec.decode`, and adds the frozen golden fixture and `Fixtures` test resource.

## Self-Check: PASSED

- All 21 `Packages/BrewCore` files listed in key-files exist on disk.
- All 5 task commits (`1e4efcc`, `231bfa0`, `e6d7dfd`, `c8d71ce`, `2594852`) are ancestors of HEAD; `git log --grep='(01-01)'` returns 5.
- `swift test --package-path Packages/BrewCore` exits 0 (58 tests passed, no warnings).
- Task 1, 2 and 3 acceptance criteria re-run and passing: Foundation-only imports, no `Double`/`Float` in Model or Engine, `package enum Brewer`, tools-version and `.copy` present, `.gitignore` entries present, style and conditioning content greps, `RecipeRules.dayCost` in the Reducer.
- Prohibitions checked: no timers, dates, dispatch or sleep anywhere in `Sources`; no RNG use in Brewer or the style classifier.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-08*
