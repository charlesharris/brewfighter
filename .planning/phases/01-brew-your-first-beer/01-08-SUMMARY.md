---
phase: 01-brew-your-first-beer
plan: 08
subsystem: ui
tags: [swiftui, canvas, glass, ledger, reveal, numerictext, reduce-motion, xcuitest, localization]

requires:
  - phase: 01-04
    provides: GlassSpec.make(for:content:), BeerStats, SRM color stops, style classifier
  - phase: 01-07
    provides: complete recipe wizard, Review BREW button, UI test helpers
provides:
  - BeerDetailView with grouped attribute family bars, near-zero collapse, brewing numbers
  - LedgerSheet and LedgerSource.labelText (one catalog sentence per source kind) for every attribute
  - GlassView (hero with stateless bubble emitter, still thumbnail, animatable fillFraction)
  - Cellar as a two-column grid of glass cards
  - BrewRevealView, a staged skippable reveal sequenced by animation completions
  - Screen.detail/.reveal, GameStore.showDetail/showReveal/backToCellar
  - UI test helpers finishBrew(_:to:) and RevealExit; brewFromWizard now passes through the reveal
affects: [01-09, 01-10, phase-02, phase-03]

actuals:
  tokens: 20500
  tasks: 3
  commits: 3

plan_head_before: 58e11279a0b671c1f9b1e1b8da0007cee86330ac
plan_head_after: bffcbca96f192bea5aa2f75b056a46000f906c57
commits: 3

tech-stack:
  added: []
  patterns:
    - "Animatable View structs under Swift 6 main-actor inference: nonisolated animatableData over a nonisolated(unsafe) stored Double"
    - "Reveal phases chain through withAnimation(_:completionCriteria:_:completion:); the phase flips inside the same animation so implicit animations never shorten it"
    - "Stateless Canvas emitter: bubble positions are a pure function of time and a seeded SplitMix64 stream"
    - "Ledger labels are single catalog format strings per source kind, never concatenated fragments"

key-files:
  created:
    - App/BrewFighter/BeerDetail/BeerDetailView.swift
    - App/BrewFighter/BeerDetail/AttributeFamilyBars.swift
    - App/BrewFighter/BeerDetail/NerdStatsPanel.swift
    - App/BrewFighter/Ledger/LedgerSheet.swift
    - App/BrewFighter/Ledger/LedgerSource+Label.swift
    - App/BrewFighter/Glass/GlassView.swift
    - App/BrewFighter/Reveal/BrewRevealView.swift
    - App/BrewFighterUITests/BeerDetailUITests.swift
    - App/BrewFighterUITests/RevealUITests.swift
  modified:
    - App/BrewFighter/Shell/GameShell.swift
    - App/BrewFighter/Shell/GameStore.swift
    - App/BrewFighter/Cellar/CellarView.swift
    - App/BrewFighter/UIKit/Panel.swift
    - App/BrewFighter/Wizard/ReviewStageView.swift
    - App/BrewFighter/Localizable.xcstrings
    - App/BrewFighterUITests/UITestSupport.swift
    - App/BrewFighterUITests/WizardUITests.swift
    - App/BrewFighterUITests/ChromeUITests.swift

key-decisions:
  - "Ledger sheet rows are one combined accessibility element each (label plus signed delta), identified ledger.row.<i>, in stored order and never re-sorted"
  - "Haze fades with liquid darkness in the renderer, so an imperial stout stays opaque instead of turning gray"
  - "Thumbnail glasses are hidden from VoiceOver because the card text already names the style; the hero glass carries the label"
  - "The UI test harness exempts the system Sheet Grabber from the 44pt check (UIKit chrome with its own hit region)"

patterns-established:
  - "UI tests leave a brew through finishBrew(_:to:) so every flow passes the reveal and exits by Skip"
  - "Attributes below 0.5 tenths-of-ten (value < 5) are tucked behind a per-family Show N more button"

requirements-completed: [BREW-04, BREW-06, BREW-07, ART-01, PLAT-01, PLAT-03, PLAT-06]

coverage:
  - id: D1
    description: "Beer detail: Batch #N and style, brew day, 16 attributes in four family panels with exact numbers, near-zero collapse"
    requirement: BREW-04
    verification:
      - kind: automated_ui
        ref: "BeerDetailUITests#testFamiliesPresent, testEmptyLedger"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ledger sheet: signed rows in stored order summing to the total, Solstice row named, empty-state sentence for an attribute with no source"
    requirement: BREW-04
    verification:
      - kind: automated_ui
        ref: "BeerDetailUITests#testLedgerRowsSumToTotal, testEmptyLedger"
        status: pass
    human_judgment: false
  - id: D3
    description: "Neutral Brewing numbers panel (ABV, IBU, SRM, OG, FG) with no reward framing"
    requirement: BREW-06
    verification:
      - kind: automated_ui
        ref: "BeerDetailUITests#testGlassAndStatsVisible"
        status: pass
      - kind: other
        ref: "swift scripts/check-strings.swift (267 keys, BANNED list clean)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Procedural glass: six silhouettes, SRM liquid, foam head, haze, carbonation-driven bubbles; static thumbnails; Reduce Motion pauses the timeline"
    requirement: ART-01
    verification:
      - kind: automated_ui
        ref: "BeerDetailUITests#testGlassAndStatsVisible (label names the style)"
        status: pass
    human_judgment: true
    rationale: "Distinct-at-a-glance glasses and bubble feel are visual judgments; reviewed from screenshots of a synthetic gallery and the live detail and Cellar screens, but the four-beer and Reduce Motion simulator pass was not done by hand (WINDOWS entry 7)"
  - id: D5
    description: "Reveal sequencing: kettle, day roll, fill, stamp advance by animation completion; Skip lands on the final card; plays to completion unaided in under 9 s"
    requirement: BREW-07
    verification:
      - kind: automated_ui
        ref: "RevealUITests#testSkipJumpsToFinalState, testRevealPlaysToCompletionWithoutSkip"
        status: pass
      - kind: other
        ref: "grep -rnE 'Timer|asyncAfter|Task\\.sleep|usleep' App/BrewFighter Packages/BrewCore/Sources prints nothing"
        status: pass
    human_judgment: true
    rationale: "Anticipation-then-payoff timing and the five-second glance are subjective (WINDOWS entry 8)"
  - id: D6
    description: "Force quit mid-reveal keeps the beer exactly once with the day advanced once (Day 18)"
    requirement: PLAT-03
    verification:
      - kind: automated_ui
        ref: "RevealUITests#testForceQuitMidRevealKeepsBeerOnce"
        status: pass
    human_judgment: false
  - id: D7
    description: "Detail, ledger sheet and reveal meet 44pt, non-overlap, thumb-zone and raw-key checks; pseudo-localized screenshots attached"
    requirement: PLAT-06
    verification:
      - kind: automated_ui
        ref: "ChromeUITests#testDetailAndLedgerChrome, testDetailAndLedgerPseudoLocalized, testRevealChrome, testRevealPseudoLocalized"
        status: pass
    human_judgment: false
  - id: D8
    description: "SRM color stops match the published palette"
    requirement: ART-01
    verification: []
    human_judgment: true
    rationale: "All 40 stops rendered as swatches and checked by eye (smooth monotone darkening, no corrections needed); no machine-readable published chart could be fetched, so this is the plan's by-eye verification (WINDOWS entry 3 closed)"

duration: 41min
completed: 2026-10-15
status: complete
---

# Phase 1 Plan 08: Beer Detail, Ledger, Glass and Brew Reveal Summary

**Every beer can now be opened and explained: grouped attribute bars, a tap-through ledger whose signed rows sum to each number, a procedurally drawn glass (animated hero, still Cellar thumbnails), neutral brewing numbers, and a skippable kettle-to-stamp brew reveal that only plays after the beer is already saved.**

## Performance
- **Duration:** 41 minutes
- **Started:** 2026-10-15T18:10:25Z
- **Completed:** 2026-10-15T18:51Z
- **Tasks:** 3 (1 tracer, 2 auto)
- **Files:** 18 changed (9 created, 9 modified), 1825 insertions, 30 deletions

## Accomplishments
- Tracer proved end to end first: Cellar card, detail, citrus tap, ledger sheet whose rows (including a Solstice row) sum to the total. Gate log: "Tracer verified end-to-end, expanding".
- Detail: four family panels (malt, hop, yeast, mouthfeel) with the exact number at each bar's end; attributes below 0.5 collapse behind "Show N more"; Funk on the house pale ale shows 0.0 and its ledger says "Nothing in this recipe added Funk."
- GlassView draws shaker, nonic, tulip, pilsner, weizen and snifter silhouettes in one Canvas with SRM liquid, scalloped head, haze and seeded bubbles; hero runs one TimelineView paused under Reduce Motion, thumbnails run none.
- Reveal: kettle with steam, "Day 1 to Day 18" rolling with numericText, glass filling, style stamping in (scale and rotation), then See the details / To the Cellar. Sequenced purely by animation completions; Skip jumps to the end.
- Force quit during the reveal relaunches into The Cellar with Batch 1 once and Day 18.
- Verification: full app suite green (37 UI tests, 0 failures), BrewCore 154 tests, check-strings OK (267 keys), BREW-07 grep prints nothing.

## Task Commits
1. **Task 1: Tracer, detail, family bars, ledger sheet** - `1cf6640` (feat)
2. **Task 2: Glass, nerd stats, Cellar grid** - `3765ac6` (feat)
3. **Task 3: Staged skippable reveal** - `bffcbca` (feat)

**Plan metadata:** recorded in the docs(01-08) commit that follows this file.

## Files Created/Modified
See `key-files` above.

## Decisions Made
See `key-decisions` above. Style label uses the plan's `reveal.style` key (identity format `%1$@`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Animatable View rejected by main-actor isolation**
- **Found during:** Task 2 (first build)
- **Issue:** `animatableData` on a `View` struct is inferred main-actor isolated and cannot satisfy the nonisolated `Animatable` requirement.
- **Fix:** `nonisolated var animatableData` over a `nonisolated(unsafe)` stored Double (only SwiftUI writes it during animation). Same pattern in the kettle view.
- **Files modified:** `Glass/GlassView.swift`, `Reveal/BrewRevealView.swift`
- **Commit:** `3765ac6`, `bffcbca`

**2. [Rule 3 - Blocking] Touch-target harness flagged the system Sheet Grabber**
- **Found during:** Task 2 (`testDetailAndLedgerChrome`)
- **Issue:** The ledger sheet has two detents, so UIKit shows a drag grabber (76x25pt hit region) that failed the 44pt check.
- **Fix:** `assertTouchTargets` skips the system "Sheet Grabber"; every game button is still checked.
- **Files modified:** `App/BrewFighterUITests/UITestSupport.swift`
- **Commit:** `3765ac6`

**3. [Rule 1 - Bug] Haze turned dark beers muddy gray**
- **Found during:** Task 2 (visual review of an imperial stout)
- **Issue:** A cream haze veil at up to 40% opacity over a near-black liquid rendered mauve-gray.
- **Fix:** Renderer scales haze opacity by liquid lightness (floor 0.2). GlassSpec is unchanged.
- **Files modified:** `Glass/GlassView.swift`
- **Commit:** `3765ac6`

**4. [Rule 1 - Bug] Implicit phase animation would have overridden the reveal's explicit durations**
- **Found during:** Task 3 (design review before first run)
- **Issue:** A `.animation(value: phase)` modifier would replace the 1.0 s fill and day-roll animations when the phase flips in the same update.
- **Fix:** The phase flips inside each phase's own `withAnimation`, so cross-fades use that animation.
- **Files modified:** `Reveal/BrewRevealView.swift`
- **Commit:** `bffcbca`

### Plan adjustments (not rule-tracked)
- `LedgerSource.labelText` gained a defaulted `delta:` parameter, needed to word cap rows (max versus floor) that the specified signature could not distinguish.
- `Panel` gained an optional `systemImage` for the family glyphs; `GlassView` takes a required `styleNameKey` for its VoiceOver label.
- Plan text names helper `brewFromVizard`; the real helper is `brewFromWizard`, now routed through `finishBrew` (so Chrome, SaveTransfer and Persistence tests pass through the reveal without edits). Wizard tests that tapped BREW inline were switched to `finishBrew`.
- Added ledger source `fermentDuration` for yeast-specific duration rows (`ledger.source.yeastDuration`) as the plan describes, plus `ContentCatalog.ingredientNameKey` so sugar adjuncts in a grain bill resolve their names.

**Total deviations:** 4 auto-fixed (2 Rule 1, 2 Rule 3). **Impact:** none on scope; all support D-09, D-19 and PLAT-06.

## Issues Encountered
- The detail chrome test is slow (about 2 minutes) because every element read is a simulator round trip; it checks three scroll positions.
- "Result bundle saving failed" noise appears at the end of runs; tests report TEST SUCCEEDED.
- The synthetic pilsner recipe in my review gallery classified as Experimental Ale; a content matter, not a rendering one.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None. All views read real beer data; no placeholder data flows to the UI.

## Threat Flags
None. T-1-19 mitigated: `GameStore.brew` commits and saves before `showReveal`, `.reveal` is never restored on launch, and `testForceQuitMidRevealKeepsBeerOnce` asserts one beer and one day advance. T-1-20 mitigated: bubbles capped at 60 (12 on thumbnails), no TimelineView on thumbnails, colors resolved once per view value, Reduce Motion pauses the timeline.

## Next Phase Readiness
- Plan 01-09 can raise the deployment target and run the human checkpoint; the Cellar, detail and reveal are in place for the TestFlight build in 01-10.
- Open items recorded in `.planning/WINDOWS.md`: entry 7 (hand check of four brewed glasses and Reduce Motion) and entry 8 (reveal timing and feel). Entry 3 (SRM stops) is closed by the by-eye swatch review.

## Self-Check: PASSED
- Created files exist: BeerDetailView, AttributeFamilyBars, NerdStatsPanel, LedgerSheet, LedgerSource+Label, GlassView, BrewRevealView, BeerDetailUITests, RevealUITests.
- Commits `1cf6640`, `3765ac6`, `bffcbca` are ancestors of HEAD; `git rev-list --count` from the plan ledger is 3.
- Acceptance greps: LedgerSheet has `rows(for:` and `ledger.empty`; AttributeFamilyBars has `AttributeFamily` and `detail.showMore`; GlassView has `Canvas`, `TimelineView`, `accessibilityReduceMotion`, `GlassSpec`; NerdStatsPanel has `abvTenths`, `ibuTenths`, `srmTenths`, `ogPoints`, `fgPoints`; CellarView has `LazyVGrid` and `.thumbnail`; BrewRevealView has `numericText`, `reveal.skip`, `accessibilityReduceMotion`, `lastEvents`; ReviewStageView has `showReveal`.
- `scripts/test-app.sh` full suite succeeded (37 UI tests); `swift test --package-path Packages/BrewCore` 154 passed; `swift scripts/check-strings.swift` OK (267 keys); the BREW-07 grep prints nothing.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-15*
