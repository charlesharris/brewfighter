---
phase: 01-brew-your-first-beer
plan: 06
subsystem: ui
tags: [swiftui, wizard, recipe-draft, grain-bill, hops, custom-controls, xcuitest, localization]

requires:
  - phase: 01-03
    provides: RecipeRules (percent grain bill, hop slots, quarter-ounce steps), hop and grain content with trait keys
  - phase: 01-05
    provides: validated decode path and frozen save schema v1 (GameStore edits did not touch it)
provides:
  - Screen.wizard with GameStore.openWizard/closeWizard and the empty-cellar launch rule
  - RecipeDraft whose every edit delegates to RecipeRules, with can... queries that drive disabled controls
  - Stage wizard (Mash, Boil, Ferment, Condition, Review) with progress chips and a bottom-bar Back/Next/BREW
  - Mash stage (percent grain bill, batch strength dial, mash temperature dial) and Boil stage (slot dial, hop cards, quarter-ounce schedule)
  - UI kit controls Panel, IngredientCard, StepperButton, BandDial; GameButtonStyle size variants and dimmed disabled state
affects: [01-07, 01-08, 01-09, phase-02]

actuals:
  tokens: 21000
  tasks: 3
  commits: 3

plan_head_before: 22ceae20dc0af985dcc841f0d237910b6a608cff
plan_head_after: 33200c13a3bfef79fa7894acff2a537b62357463
commits: 3

tech-stack:
  added: []
  patterns:
    - "One wizard screen with a stage state machine, no system navigation container; Back, Next and BREW in a bottom safe-area bar"
    - "Controls are disabled by asking RecipeRules first (canStepFermentable, canMakeBase, canAddHop, canStepHop)"
    - "accessibilityRegion(id): contain + identifier, so a region id does not overwrite child identifiers"
    - "IngredientCard keeps its accessory outside the face Button so inner controls have their own hit frames"

key-files:
  created:
    - App/BrewFighter/Wizard/RecipeDraft.swift
    - App/BrewFighter/Wizard/RecipeWizardView.swift
    - App/BrewFighter/Wizard/ReviewStageView.swift
    - App/BrewFighter/Wizard/MashStageView.swift
    - App/BrewFighter/Wizard/BoilStageView.swift
    - App/BrewFighter/UIKit/Panel.swift
    - App/BrewFighter/UIKit/IngredientCard.swift
    - App/BrewFighter/UIKit/StepperButton.swift
    - App/BrewFighter/UIKit/BandDial.swift
    - App/BrewFighterUITests/WizardUITests.swift
  modified:
    - App/BrewFighter/Shell/GameShell.swift
    - App/BrewFighter/Shell/GameStore.swift
    - App/BrewFighter/Cellar/CellarView.swift
    - App/BrewFighter/UIKit/GameButtonStyle.swift
    - App/BrewFighter/Localizable.xcstrings
    - App/BrewFighterUITests/PersistenceUITests.swift
    - App/BrewFighterUITests/ChromeUITests.swift
    - App/BrewFighterUITests/SaveTransferUITests.swift
    - App/BrewFighterUITests/UITestSupport.swift
    - scripts/check-strings.swift

key-decisions:
  - "GameStore.wizardSession (a UUID renewed by openWizard) is the wizard view's identity, so a wizard reopened while the old one animates out still starts from a fresh pre-seeded draft"
  - "Make base is disabled when RecipeRules.settingBase refuses it (a 5% entry cannot become the base), instead of tapping to a silent no-op"
  - "Review panels are Buttons whose combined accessibility label carries the choices, so UI tests read them from one element and VoiceOver gets real button semantics"

patterns-established:
  - "UI test helpers: closeWizardToCellar, brewFromWizard, tapScrolling (reachability = inside the scroll body and above the bottom bar), dragWizardBody"
  - "assertTouchTargets reads each button's frame once and ignores wizard chrome versus scrolled content overlap"

requirements-completed: [BREW-01, PLAT-01, PLAT-06]

coverage:
  - id: D1
    description: "Cellar BREW opens the pre-seeded wizard; Review hosts BREW; the beer lands in The Cellar and survives relaunch (first launch with an empty cellar opens the wizard)"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "App/BrewFighterUITests/PersistenceUITests.swift#testBrewedBeerSurvivesRelaunch; WizardUITests#testFirstRunOpensPreseededWizard, testCellarBrewOpensWizard"
        status: pass
    human_judgment: false
  - id: D2
    description: "Clear empties the draft and disables BREW; stages are freely navigable (Next, Back, chips)"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testClearDisablesBrew, testFreeNavigation"
        status: pass
    human_judgment: false
  - id: D3
    description: "Mash grain bill in 5% steps with base auto-rebalance, 20% cap, Make base and Remove, all routed through RecipeRules"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testComposeGrainBill, testBaseRebalanceAndMakeBase"
        status: pass
      - kind: unit
        ref: "swift test --package-path Packages/BrewCore (RecipeRules suites, 154 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Batch strength and mash temperature set with custom banded dials (flavor name plus small OG or degrees F)"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testComposeGrainBill (mash.strength.strong, mash.temp.low selected and shown on Review)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Boil stage: hop slot dial, hop cards that add or merge, quarter-ounce steps down to removal, hop-less beer brewable"
    requirement: BREW-01
    verification:
      - kind: automated_ui
        ref: "WizardUITests#testAddHopToAromaSlot, testHoplessBeerIsBrewable"
        status: pass
    human_judgment: false
  - id: D6
    description: "Touch targets 44pt or larger without overlapping hit frames, no raw catalog keys, Next in the thumb zone, pseudo-localized screenshots on Mash and Boil"
    requirement: PLAT-06
    verification:
      - kind: automated_ui
        ref: "ChromeUITests#testMashStageChrome, testBoilStageChrome, testMashStagePseudoLocalized, testBoilStagePseudoLocalized"
        status: pass
      - kind: other
        ref: "swift scripts/check-strings.swift (200 keys)"
        status: pass
    human_judgment: false
  - id: D7
    description: "One-thumb reachability of the whole compose flow and the chunky game feel of the dials (not system pickers)"
    requirement: PLAT-01
    verification: []
    human_judgment: true
    rationale: "Ergonomics and look-and-feel cannot be asserted by frame checks; plan Task 2 human-check has not been run by hand"

duration: ~60min active (wall clock far longer: the host Mac repeatedly slept mid-run)
completed: 2026-10-15
status: complete
---

# Phase 1 Plan 06: Recipe Wizard Summary

**A one-screen stage wizard (Mash, Boil, Ferment, Condition, Review) where the player composes a grain bill in percent, batch strength, mash temperature and a hop schedule with chunky custom controls, every edit validated by RecipeRules, and BREW on the Review stage drops the beer into The Cellar.**

## Performance
- **Duration:** about 60 minutes of active work; wall clock is much longer because the host Mac went to sleep during test runs (XCUITest steps showed 700 to 3,900 second gaps that vanish when the machine is awake)
- **Started:** 2026-10-14T19:19:29Z
- **Completed:** 2026-10-15T17:35Z
- **Tasks:** 3 (1 tracer, 2 auto)
- **Files:** 20 changed (10 created, 10 modified), 1,855 insertions

## Accomplishments
- First launch with an empty cellar opens the wizard pre-seeded with the house pale ale; every later BREW from The Cellar reopens it; Clear empties the draft in one tap; Review hosts the BREW button, disabled while `RecipeRules.validate` reports issues.
- Mash: two-column ingredient cards with trait tags, tap-to-add, 5% steppers (the base malt absorbs the remainder), Base badge, Make base, Remove, and a live "Total N%" line; strength (Session to Imperial, OG small) and mash temperature (Dry & crisp / Balanced / Full & sweet, degrees F small) on banded dials with a blurb for the selection.
- Boil: slot dial (Bittering 60 min / Flavor 15 min / Aroma flameout / Whirlpool), hop cards that add or merge into the chosen slot, and a schedule with quarter-ounce steppers that remove an addition at zero.
- No system Picker, Stepper, Toggle, TabView or NavigationStack anywhere in the app target.

## Task Commits
1. **Task 1: Tracer, Cellar BREW to pre-seeded wizard to Review to BREW to beer in the cellar** - `28da902` (feat)
2. **Task 2: Mash stage** - `9c2d765` (feat)
3. **Task 3: Boil stage** - `33200c1` (feat)

Tracer gate: after Task 1 the Wizard and Persistence UI tests and the full app suite passed, so the slice was verified end to end before expanding.

**Plan metadata:** recorded in the docs(01-06) commit that follows this file.

## Files Created/Modified
See `key-files` above. `Wizard/RecipeDraft.swift` is the engine seam (every edit through RecipeRules); `UIKit/BandDial.swift`, `IngredientCard.swift` and `StepperButton.swift` are the reusable chunky controls plan 01-07 builds on.

## Decisions Made
- `GameStore.wizardSession` keeps wizard identity per opening (see key-decisions).
- Launch rule refined: an empty cellar opens the wizard only when no save problem was detected. A damaged or restored save opens The Cellar so its banner explains what happened.
- Make base is disabled when the rules refuse it, and a "base needs at least 10%" reason shows on cards that cannot be added.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reopened wizard kept the previous wizard's stage**
- **Found during:** Task 1 (`testCellarBrewOpensWizard`)
- **Issue:** Tapping BREW then immediately tapping the Cellar's BREW re-inserted the wizard view while the old one was still animating out, so SwiftUI reused its state (landed on Review instead of Mash).
- **Fix:** `GameStore.wizardSession` UUID renewed in `openWizard()` and applied as `.id(...)` in `GameShell`.
- **Files modified:** `Shell/GameStore.swift`, `Shell/GameShell.swift`
- **Commit:** `28da902`

**2. [Rule 2 - Missing critical] Damaged-save banner would never show**
- **Found during:** Task 1 (launch rule)
- **Issue:** `state.beers.isEmpty` is also true after an unrecoverable save, so starting in the wizard hid the Cellar banner that tells the player their old file was kept.
- **Fix:** Launch screen is `.wizard` only when beers are empty and `persistenceError == nil`.
- **Files modified:** `Shell/GameStore.swift`
- **Commit:** `28da902`

**3. [Rule 1 - Bug] Make base tap could be a silent no-op**
- **Found during:** Task 2 (`testBaseRebalanceAndMakeBase`)
- **Issue:** `RecipeRules.settingBase` refuses a base below 10%, so Make base on a 5% entry did nothing while looking enabled.
- **Fix:** Added `RecipeDraft.canMakeBase` and disabled the button when refused.
- **Files modified:** `Wizard/RecipeDraft.swift`, `Wizard/MashStageView.swift`
- **Commit:** `9c2d765`

**4. [Rule 3 - Blocking] Existing UI tests assumed a reset launch lands on The Cellar**
- **Found during:** Task 1
- **Issue:** First run now opens the wizard, so Chrome, Persistence and SaveTransfer UI tests that tapped `cellar.brew` immediately broke.
- **Fix:** Added `closeWizardToCellar` and `brewFromWizard` helpers and updated those tests.
- **Files modified:** `UITestSupport.swift`, `ChromeUITests.swift`, `PersistenceUITests.swift`, `SaveTransferUITests.swift`
- **Commit:** `28da902`

**5. [Rule 3 - Blocking] Test harness limits**
- **Found during:** Tasks 2 and 3
- **Issue:** `isHittable` is true for buttons partly below the screen or under the bottom bar; the pairwise overlap check re-read every frame (minutes on busy screens) and flagged cards scrolled under the chips or bottom bar; `swipeUp()` stalled.
- **Fix:** `tapScrolling` now requires the element inside the scroll body above the bar; `assertTouchTargets` reads each frame once and ignores wizard-chrome-versus-content pairs; Chrome tests use a short press-and-drag.
- **Files modified:** `UITestSupport.swift`, `ChromeUITests.swift`
- **Commit:** `9c2d765`

**6. [Rule 2 - Missing critical] check-strings did not see `Panel("...")` keys**
- **Found during:** Task 2
- **Issue:** Panel titles are new LocalizedStringKey call sites the checker's regex ignored, so a missing key would pass.
- **Fix:** Added `Panel` to the scanned call names.
- **Files modified:** `scripts/check-strings.swift`
- **Commit:** `9c2d765`

**Also (minor, not rule-tracked):** `GameButtonStyle` gained `size` (regular, compact, square) and a dimmed disabled look; the BREW button lives in the wizard's bottom bar via `ReviewBrewButton` defined in `ReviewStageView.swift`; extra catalog keys beyond the plan list: `mash.noRoom`, `boil.maxAmount`, `review.noHops`, `review.strengthLine`, `review.mashTempLine`, `review.fermentTempLine`, `review.fermentDurationLine`.

**Total deviations:** 6 auto-fixed (2 bugs, 2 missing critical, 2 blocking). **Impact:** none on scope; all strengthen D-07 and PLAT-06.

## Issues Encountered
- Test runs were extremely slow and flaky ("Timed out while synthesizing event", 700 to 3,900 second gaps) because the host Mac slept during runs. `caffeinate` did not fully prevent it. Tests that failed only with that timeout passed when re-run in isolation, and the final full suite (`scripts/test-app.sh`: 25 app unit tests, 18 UI tests) passed in a clean 210-second run.
- A first-scroll hang seen in Chrome tests was host sleep, not an app defect (sampling and timelines showed gaps with no CPU use).

## User Setup Required
None - no external service configuration required.

## Known Stubs
None. Ferment and Condition stages show the read-only summary panel only; their editing controls are plan 01-07 by design, and BREW stays gated by `RecipeRules.validate`.

## Threat Flags
None. T-1-17 is mitigated: every draft mutation calls RecipeRules (returns nil when refused), controls disable via the matching `can...` queries, and BREW is disabled while validation reports issues.

## Next Phase Readiness
- 01-07 can add Ferment and Condition editing to `RecipeDraft` and replace the summary panels in `RecipeWizardView.stageBody`; `Panel`, `IngredientCard`, `StepperButton`, `BandDial` and the UI test helpers are ready to reuse.
- 01-08 replaces `store.closeWizard()` in `ReviewBrewButton` with the reveal.
- Open item (WINDOWS ledger, `unrun-verify`): the one-thumb walk through Mash and Boil on a simulator or device has not been done by hand.

## Self-Check: PASSED
- Created files exist on disk; `git merge-base --is-ancestor` holds for `28da902`, `9c2d765`, `33200c1`.
- `swift test --package-path Packages/BrewCore`: 154 tests passed.
- `scripts/test-app.sh` full suite: succeeded (25 unit, 18 UI tests).
- `swift scripts/check-strings.swift`: OK (200 keys).
- Acceptance greps re-run: no `TabView|NavigationStack|Picker(|Stepper(|Toggle(` in `App/BrewFighter`; `draft.addFermentable`, `canStepFermentable`, `draft.addHop`, `canStepHop`, `boil.empty`, `boil.maxAdditions` present.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-15*
