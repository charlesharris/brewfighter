---
phase: 01-brew-your-first-beer
plan: 07
subsystem: ui
tags: [swiftui, wizard, ferment, conditioning, validation, custom-controls, xcuitest, localization]

requires:
  - phase: 01-06
    provides: RecipeDraft, wizard shell and stage switch, Panel, IngredientCard, StepperButton, BandDial, UI test helpers
  - phase: 01-03
    provides: RecipeRules conditioning functions and dayCost, yeast, hop and fruit content
provides:
  - Ferment stage (yeast cards, temperature band with the selected yeast's real degrees F, duration band in days)
  - Condition stage (dry hop, fruit, lagering, bottle conditioning with exclusivity reason and a live day-cost line)
  - Review validation (issue messages, Fix buttons that jump to the owning stage, Ready in N days, BREW gating hint)
  - RecipeDraft.setYeast, setFermentTemp, setFermentDuration, dayCost, toggleConditioning, canToggleConditioning, setConditioningAmount, setConditioningIngredient
  - RecipeIssue.messageKey, .stage, .slug
affects: [01-08, 01-09, phase-02]

actuals:
  tokens: 56000
  tasks: 3
  commits: 3

plan_head_before: 988f513a8dd93e6339cdd49f517d8423a515359e
plan_head_after: 3963989b0f8b54eb12cb67300b36558a1651917
commits: 3

tech-stack:
  added: []
  patterns:
    - "Small choosers inside scrolling stages use a non-lazy Grid so every choice stays in the accessibility tree when scrolled away"
    - "IngredientCard takes an optional blurb and badge, so non-ingredient option cards (conditioning) reuse it"
    - "Validation issues are presented through RecipeIssue.messageKey / stage / slug; several engine issues collapse into one message per area"

key-files:
  created:
    - App/BrewFighter/Wizard/FermentStageView.swift
    - App/BrewFighter/Wizard/ConditionStageView.swift
    - App/BrewFighter/Wizard/RecipeIssue+Presentation.swift
  modified:
    - App/BrewFighter/Wizard/RecipeDraft.swift
    - App/BrewFighter/Wizard/RecipeWizardView.swift
    - App/BrewFighter/Wizard/ReviewStageView.swift
    - App/BrewFighter/UIKit/IngredientCard.swift
    - App/BrewFighter/Localizable.xcstrings
    - App/BrewFighterUITests/WizardUITests.swift
    - App/BrewFighterUITests/ChromeUITests.swift
    - App/BrewFighterUITests/UITestSupport.swift

key-decisions:
  - "The day-cost line sits at the top of the Condition and Review stages, so lagering's 28 days is visible the moment it is toggled"
  - "Review lists dry hop and fruit with ingredient and amount (Name · Ingredient · amount), not just the option name, so the player can verify what they set"
  - "Ferment temperature shows 'Pick a yeast' per dial segment when no yeast is chosen, since each yeast has its own real degrees F"

patterns-established:
  - "assertTouchTargets tolerates 0.01pt of layout rounding (a 44pt button can measure 43.99999999999997)"
  - "Dynamic identifiers use RecipeIssue.slug (noGrain, noYeast, grainBill, hops, conditioning, unknownIngredient)"

requirements-completed: [BREW-01, BREW-07, PLAT-01, PLAT-06]

coverage:
  - id: D1
    description: "Ferment: pick one of 5 yeast cards, temperature band with the yeast's real degrees F, duration band with days"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testFermentChoicesAdvanceDays"
        status: pass
    human_judgment: false
  - id: D2
    description: "Brewing never starts a wait: BREW advances the day counter by exactly the day cost and the beer is in The Cellar immediately (Day 25 = 1 + 21 + 3)"
    requirement: BREW-07
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testFermentChoicesAdvanceDays"
        status: pass
    human_judgment: false
  - id: D3
    description: "Condition: dry hop, fruit, lagering and bottle conditioning toggle; lagering and bottle conditioning exclude each other and the blocked card says why; day cost is visible (17, 45, 31 days)"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testConditioningExclusivityAndDayCost, testFruitAndDryHopAmounts"
        status: pass
    human_judgment: false
  - id: D4
    description: "Review lists issues as catalog messages with Fix buttons that jump to the owning stage; BREW disabled while issues exist; a one-grain plus yeast recipe with no hops or conditioning brews"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testMinimalRecipeFlow"
        status: pass
    human_judgment: false
  - id: D5
    description: "Ferment, Condition and Review (with and without issues) meet 44pt, non-overlap, thumb-zone and raw-key checks; pseudo-localized screenshots attached"
    requirement: PLAT-06
    verification:
      - kind: automated_ui
        ref: "ChromeUITests#testFermentAndConditionChrome, testReviewChrome, testFermentAndConditionPseudoLocalized, testReviewPseudoLocalized"
        status: pass
      - kind: other
        ref: "swift scripts/check-strings.swift (224 keys)"
        status: pass
    human_judgment: false
  - id: D6
    description: "One-handed, one-thumb composition of a full recipe across all five stages (ergonomics, flow, feel of the chunky controls)"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "Plan Task 3 human-check (compose a full recipe one-handed and brew) has not been run by hand; frame assertions cover sizes and reach, not comfort. Recorded in .planning/WINDOWS.md as entry 6."

duration: 28min
completed: 2026-10-15
status: complete
---

# Phase 1 Plan 07: Ferment, Condition and Review Validation Summary

**Recipe composition is now complete in the wizard: a yeast, fermentation temperature (with the yeast's real degrees F) and duration on Ferment; dry hop, fruit, lagering and bottle conditioning with an exclusivity explanation on Condition; and a Review that lists exactly what blocks BREW with Fix buttons that jump to the right stage, while the day counter advances by precisely the recipe's own day cost.**

## Performance
- **Duration:** 28 minutes
- **Started:** 2026-10-15T17:38:41Z
- **Completed:** 2026-10-15T18:07Z
- **Tasks:** 3 (1 tracer, 2 auto)
- **Files:** 11 changed (3 created, 8 modified), 950 insertions, 14 deletions

## Accomplishments
- Ferment: five yeast cards with trait tags and a selected state; a temperature dial where each segment shows the selected yeast's own degrees F small ("Pick a yeast" before one is chosen); a duration dial showing 7, 14, 21 days.
- Condition: four option cards in catalog order with a "+N days" badge, a hop chooser and quarter-ounce stepper for dry hop, a fruit chooser and pound stepper for fruit, "This brew takes N days" always at the top, and the blocked lagering or bottle-conditioning card explaining "Choose lagering or bottle conditioning, not both".
- Review: "Before you brew" panel with one row per distinct message and a Fix button to the owning stage; "Ready in N days"; BREW disabled with a spoken hint while issues exist. Dry hop and fruit now appear in the Review summary with ingredient and amount.
- Tracer proved end to end first: Ferment choices, BREW, and the Cellar reads "Day 25" with no waiting step.
- Full verification green: BrewCore 154 tests, full app suite (unit plus 24 UI tests in the two selected suites, full run 26 UI tests), check-strings OK at 224 keys.

## Task Commits
1. **Task 1: Tracer, Ferment choices to BREW to day counter** - `35f0ab3` (feat)
2. **Task 2: Condition stage** - `3988509` (feat)
3. **Task 3: Review validation** - `3963989` (feat)

Tracer gate: after Task 1 the WizardUITests suite (9 tests) passed, so the slice was verified end to end before expanding.

**Plan metadata:** recorded in the docs(01-07) commit that follows this file.

## Files Created/Modified
See `key-files` above. `RecipeDraft` stays the single seam to `RecipeRules`; `IngredientCard` gained optional `blurbKey` and `badge` so Condition reuses it.

## Decisions Made
- Day-cost line at the top of Condition and Review (always visible when toggling options).
- Review summary shows conditioning ingredient and amount, in the same dotted style as hop lines.
- Dry hop's default hop is the first hop already in the boil schedule, else the first catalog hop; fruit defaults to the first catalog fruit. Ingredient edits accept only catalog hops for dry hop and catalog fruit for fruit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Touch-target harness rejected a 44pt button measured at 43.99999999999997**
- **Found during:** Task 2 (`testFermentAndConditionChrome`)
- **Issue:** A compact hop button at a fractional y offset reported a height one part in 10^15 under 44, failing an assertion that exists to catch genuinely small targets.
- **Fix:** `assertTouchTargets` floors at 44 minus 0.01pt (layout rounding), real undersized targets still fail.
- **Files modified:** `App/BrewFighterUITests/UITestSupport.swift`
- **Commit:** `3988509`

**2. [Rule 1 - Bug] Hop chooser buttons absent from the accessibility tree when scrolled away**
- **Found during:** Task 2 (`testFruitAndDryHopAmounts`)
- **Issue:** The first chooser used `LazyVGrid`, so rows scrolled out of view were not instantiated; `tapScrolling` waits for existence before scrolling and reported the button missing (VoiceOver would equally not see them).
- **Fix:** Replaced with a non-lazy `Grid` of rows (`choiceGrid`).
- **Files modified:** `App/BrewFighter/Wizard/ConditionStageView.swift`
- **Commit:** `3988509`

**3. [Rule 2 - Missing critical] Review hid what the conditioning choices were**
- **Found during:** Task 2 (plan says "Review lists both")
- **Issue:** The existing summary printed only the option name for conditioning, so a dry hop of a chosen hop and amount, or fruit pounds, never showed on Review.
- **Fix:** `StageSummaryPanel` prints "Dry hop · Island Haze · 2.00 oz" and "Fruit · Raspberry Puree · 3 lb" via a new `review.conditionLine` key.
- **Files modified:** `App/BrewFighter/Wizard/ReviewStageView.swift`, `App/BrewFighter/Localizable.xcstrings`
- **Commit:** `3988509`

**Also (minor, not rule-tracked):** extra catalog keys beyond the plan: `condition.menu.title`, `condition.none`, `condition.dryHop.choose`, `condition.fruit.choose`, `review.conditionLine %@ %@ %@`. `RecipeIssue.slug` and `Array<RecipeIssue>.distinctByMessage` were added to the presentation file for identifiers and one-row-per-message. Review also gained an accessibility region id `review`.

**Total deviations:** 3 auto-fixed (1 bug, 1 missing critical, 1 blocking). **Impact:** none on scope; all strengthen BREW-01, D-07 and PLAT-06.

## Issues Encountered
- `xcodebuild` prints "Result bundle saving failed ... mkstemp" at the end of runs; tests themselves report `** TEST SUCCEEDED **`, so this is host temp-directory noise, not a failure.
- The host did not sleep during these runs, so none of the "Timed out while synthesizing event" flakiness from wave 6 reappeared.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None. All three stages are fully wired to `RecipeRules`; no placeholder data flows to UI.

## Threat Flags
None. T-1-18 is mitigated: BREW is disabled while `RecipeRules.validate` reports issues (`ReviewBrewButton`), and the Reducer independently rejects invalid recipes (01-01). Conditioning and yeast edits go through RecipeRules or are restricted to catalog ids in the draft.

## Next Phase Readiness
- Every brewing variable in ROADMAP criterion 2 is composable one-handed in portrait; 01-08 can replace `store.closeWizard()` in `ReviewBrewButton` with the reveal.
- Open item (WINDOWS ledger entry 6, `unrun-verify`): the one-thumb full-recipe walk (Task 3 human-check) has not been done by hand.

## Self-Check: PASSED
- Created files exist: `FermentStageView.swift`, `ConditionStageView.swift`, `RecipeIssue+Presentation.swift`.
- Commits `35f0ab3`, `3988509`, `3963989` are ancestors of HEAD; `git rev-list --count` from the ledger base is 3.
- Acceptance greps re-run: `draft.setYeast` and `tempF` in FermentStageView; `toggleConditioning` and `dayCost` in ConditionStageView; `var messageKey` and `var stage` in RecipeIssue+Presentation; catalog keys `ferment.pickYeastFirst`, `condition.exclusive`, `condition.dayCost %lld`, `issue.noGrain`, `issue.noYeast`, `review.dayCost %lld` present; no `TabView|NavigationStack|Picker(|Stepper(|Toggle(` in `App/BrewFighter`.
- `swift scripts/check-strings.swift`: OK (224 keys). `swift test --package-path Packages/BrewCore`: 154 tests passed. `scripts/test-app.sh` full suite: succeeded.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-15*
