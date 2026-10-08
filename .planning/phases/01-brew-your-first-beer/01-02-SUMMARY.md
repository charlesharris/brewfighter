---
phase: 01-brew-your-first-beer
plan: 02
subsystem: app-shell
tags: [swiftui, xcodegen, observation, persistence, string-catalog, xcuitest, swift-testing, privacy-manifest]

requires:
  - phase: 01-01
    provides: "BrewCore package: Reducer, SaveCodec, ContentCatalog, GameState"
provides:
  - "XcodeGen-generated BrewFighter.xcodeproj (committed) with syncedFolder app and test targets and the local BrewCore package"
  - "GameStore (@MainActor @Observable) wiring Cellar BREW -> Reducer -> SaveCodec -> atomic file write, committed before return"
  - "SaveRepository: atomic write, previous-save backup copy, primary-then-backup load, DEBUG-only reset"
  - "Cellar root screen, GameShell/Screen, GameButtonStyle, Palette (custom chrome, no system nav)"
  - "scripts/check-strings.swift catalog coverage and hygiene checker; Localizable.xcstrings with 77 keys"
  - "UITestSupport harness: 44pt targets, raw-key detection, thumb zone, pseudo-localization, screenshots"
  - "scripts/test-app.sh dev-loop runner"
affects: [01-03, 01-04, 01-05, 01-06, 01-07, 01-08, 01-09, 01-10, phase-02]

tech-stack:
  added: [xcodegen-2.45.4, xcuitest, swift-testing-app-target]
  patterns:
    - "Synchronized-folder app target: new Swift files need no project edits"
    - "Single-writer persistence: only the @MainActor GameStore writes; commit state, then persist, before any reveal"
    - "Semantic dotted catalog keys with positional specifiers; check-strings enforces coverage"
    - "Prefer plain Swift Testing for app-side logic; scope simulator UI tests with -only-testing"

key-files:
  created:
    - project.yml
    - BrewFighter.xcodeproj/project.pbxproj
    - BrewFighter.xcodeproj/xcshareddata/xcschemes/BrewFighter.xcscheme
    - BrewFighter.xcodeproj/project.xcworkspace/contents.xcworkspacedata
    - App/BrewFighter/BrewFighterApp.swift
    - App/BrewFighter/Shell/GameShell.swift
    - App/BrewFighter/Shell/GameStore.swift
    - App/BrewFighter/Persistence/SaveRepository.swift
    - App/BrewFighter/Cellar/CellarView.swift
    - App/BrewFighter/UIKit/GameButtonStyle.swift
    - App/BrewFighter/UIKit/Palette.swift
    - App/BrewFighter/Localizable.xcstrings
    - App/BrewFighter/InfoPlist.xcstrings
    - App/BrewFighter/PrivacyInfo.xcprivacy
    - App/BrewFighterTests/SaveRepositoryTests.swift
    - App/BrewFighterUITests/UITestSupport.swift
    - App/BrewFighterUITests/PersistenceUITests.swift
    - App/BrewFighterUITests/ChromeUITests.swift
    - scripts/test-app.sh
    - scripts/check-strings.swift
  modified:
    - .planning/PROJECT.md

key-decisions:
  - "Custom chrome on all game screens; system chrome only for sheets, share sheet, file importer and alerts"
  - "Generated BrewFighter.xcodeproj is committed; project.yml is its source and regeneration yields no diff"
  - "Catalog keys are semantic dotted identifiers with positional specifiers; pseudo-localization checks cover plain strings only (see Issues)"
  - "A failed backup copy never blocks saving the new beer; atomic writes cannot damage the existing backup"

patterns-established:
  - "UI tests reuse launchApp(reset:pseudoLocalized:), assertTouchTargets, assertNoRawCatalogKeys, assertInThumbZone, assertDoubled, attachScreenshot"
  - "Every plan that adds UI strings runs swift scripts/check-strings.swift and adds keys to the catalog in sorted order"

requirements-completed: [PLAT-01, PLAT-03, PLAT-05, PLAT-06, BREW-07]

actuals:
  tokens: 14300
  tasks: 3
  commits: 4
plan_head_before: 0ee2a283d78471eb887cb5a2e07e0f509039090c
plan_head_after: 73d343401e310b59551515b455f4167281c1021d

coverage:
  - id: D1
    description: "Walking skeleton: BREW in The Cellar brews the house pale ale, appends a Batch row, advances the day, autosaves, and the beer and day survive terminate and relaunch"
    requirement: "BREW-07"
    verification:
      - kind: e2e
        ref: "App/BrewFighterUITests/PersistenceUITests.swift#testBrewedBeerSurvivesRelaunch"
        status: pass
    human_judgment: false
  - id: D2
    description: "Save interruption guarantees: atomic write, backup copy before replace, primary-then-backup load, load never writes, newer schema reported and untouched"
    requirement: "PLAT-03"
    verification:
      - kind: unit
        ref: "App/BrewFighterTests/SaveRepositoryTests.swift (9 tests incl. corruptPrimaryFallsBackToTheBackup, bothCorruptIsUnrecoverableAndLeavesBothFilesUntouched, newerSchemaIsReportedForThatFileAndNeverOverwrittenByLoad)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Built bundle carries PrivacyInfo.xcprivacy, portrait-only orientation and ITSAppUsesNonExemptEncryption false; no preferences or file-timestamp APIs in app code"
    requirement: "PLAT-05"
    verification:
      - kind: other
        ref: "plutil -p build/DerivedData/Build/Products/Debug-iphonesimulator/BrewFighter.app/Info.plist; test -f .../PrivacyInfo.xcprivacy; grep -rnE 'UserDefaults|AppStorage|SceneStorage|attributesOfItem|creationDate|modificationDate' App/BrewFighter (no matches)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Catalog coverage and hygiene: every app literal and content key present, key shape, no empty values, positional specifiers, no intoxication vocabulary"
    requirement: "PLAT-06"
    verification:
      - kind: other
        ref: "swift scripts/check-strings.swift -> check-strings: OK (77 keys); negative probe reported BADKEY, BANNED, EMPTY, NONPOSITIONAL, MISSING"
        status: pass
    human_judgment: false
  - id: D5
    description: "44pt touch targets, no overlap, thumb-zone BREW, no raw catalog keys, hit-region audit, doubled title and button under pseudo-localization"
    requirement: "PLAT-01"
    verification:
      - kind: automated_ui
        ref: "App/BrewFighterUITests/ChromeUITests.swift#testCellarEmptyChrome, testCellarWithBeerChrome, testCellarPseudoLocalized"
        status: pass
    human_judgment: false
  - id: D6
    description: "Visual feel of The Cellar chrome (chunky button, palette, layout)"
    verification: []
    human_judgment: true
    rationale: "Aesthetic quality of the placeholder chrome is a human call; only structure and touch targets are automated"

duration: 8 min
completed: 2026-10-08
status: complete
---

# Phase 1 Plan 02: App Walking Skeleton, Persistence Hardening and Catalog Harness Summary

**XcodeGen iOS app (synced folders, local BrewCore package) whose Cellar BREW button runs GameStore -> Reducer -> SaveCodec -> atomic write with a previous-save backup and fallback load, proven by a terminate/relaunch UI test, plus a String Catalog checker and a reusable 44pt / raw-key / pseudo-localization UI harness.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-08T22:10:00Z
- **Completed:** 2026-10-08T22:18:10Z
- **Tasks:** 3 (1 tracer, 1 TDD, 1 auto)
- **Files modified:** 21 (20 created, `.planning/PROJECT.md` edited)

## Accomplishments

- Tracer proven end to end on Xcode 16.4 / iOS 18.6 simulator: tap BREW, beer row `cellar.beer.1` appears, day advances, terminate, relaunch, row and day unchanged. Tracer gate: automated-only verify re-run green, "Tracer verified end-to-end, expanding".
- The app is the generated `.xcodeproj` target (5 `PBXFileSystemSynchronizedRootGroup` entries), not an SPM executable; `xcodegen generate` on the unchanged spec leaves no diff.
- Bundled BrewCore content loads inside the app process via `Bundle.module` (the app would `fatalError` otherwise, and the UI test brews the house pale ale).
- Persistence: atomic write, previous save copied to `save.backup.json` first, load tries primary then backup and never writes; the Cellar shows a non-blocking banner for recovered, write-failed and unrecoverable states.
- `check-strings.swift` is a one-command gate (77 keys). A scratch negative probe confirmed it reports BADKEY, BANNED, EMPTY, NONPOSITIONAL and MISSING.
- Full app suite green: 9 Swift Testing tests, 4 UI tests; `swift test --package-path Packages/BrewCore` still green (58 tests).

## Task Commits

1. **Task 1: Tracer, Cellar BREW through GameStore, Reducer and atomic save** - `a494c10` (feat)
2. **Task 2: Save backup copy, fallback load, visible failure** (TDD)
   - RED: `8810c83` (test), evidence `RED_EVIDENCE_OK`
   - GREEN: `9c1a1f0` (feat)
3. **Task 3: Catalog checker, UI harness, chrome decisions** - `73d3434` (feat)

No REFACTOR commit was needed.

## TDD Gate Compliance

### Task 2 RED

- **Target test:** `corruptPrimaryFallsBackToTheBackup()` in `App/BrewFighterTests/SaveRepositoryTests.swift`.
- **Evidence:** `.planning/phases/01-brew-your-first-beer/evidence/01-02-task2-red.json` (output in `01-02-task2-red.txt`), validated with `check tdd-red-evidence` as `RED_EVIDENCE_OK` (swift-testing format, 9 tests, 4 failed on assertions).
- **semanticAssessment:** the app and test bundle built and all 9 tests executed on the simulator. The target failed on the planned assertion because `load()` had no backup fallback and `write` made no backup copy. The 5 passing tests assert behavior Task 1 already provides. No compile, fixture or zero-test fault.

## Files Created/Modified

- `project.yml`, `BrewFighter.xcodeproj/*` - XcodeGen spec and committed generated project (shared scheme with both test targets)
- `App/BrewFighter/Shell/{GameStore,GameShell}.swift`, `BrewFighterApp.swift` - store, screen switch, app entry
- `App/BrewFighter/Persistence/SaveRepository.swift` - atomic write, backup, fallback load
- `App/BrewFighter/Cellar/CellarView.swift`, `UIKit/{GameButtonStyle,Palette}.swift` - root screen and chunky chrome
- `App/BrewFighter/{Localizable,InfoPlist}.xcstrings`, `PrivacyInfo.xcprivacy` - catalog (77 keys), display name, empty privacy manifest
- `App/BrewFighterTests/SaveRepositoryTests.swift`, `App/BrewFighterUITests/{UITestSupport,PersistenceUITests,ChromeUITests}.swift`
- `scripts/test-app.sh`, `scripts/check-strings.swift`
- `.planning/PROJECT.md` - four Key Decisions rows

## Decisions Made

- Custom chrome on game screens; the committed generated project; Int fixed-point engine numbers and the four attribute families; semantic catalog keys with positional specifiers. All four recorded in PROJECT.md.
- Backup-copy failure is deliberately non-fatal in `SaveRepository.write` (the old backup cannot be damaged by a failed atomic write, and the new beer must still be saved).
- Band display names follow D-04 flavor text (for example "Dry & crisp", "Cold & clean"); strength and duration bands use plain names (Session, Quick) with the quoted text as blurbs.

## Deviations from Plan

None - plan executed exactly as written. (One factual premise in the plan proved wrong; see Issues Encountered. It changed no deliverable.)

## Issues Encountered

- **Pseudo-localization does not keep composite strings well-formed.** The plan states positional specifiers keep `-NSDoubleLocalizedStrings` output well-formed. Observed on iOS 18.6: "Day %1$lld" renders as "Day 1$lld Day 15", and the batch label as "Batch #1$lld · 2$@ Batch #1 · Amber Ale Amber Ale". The first copy loses its leading `%`. Non-positional specifiers behave the same way ("Day lld Day 15"), so this is OS behavior, not a catalog defect. Positional specifiers remain the right practice for translators and are enforced by check-strings. The pseudo test therefore asserts doubling only on plain strings (title and BREW button), as the plan specified. Phase 6 or a later localization effort should not rely on `-NSDoubleLocalizedStrings` to validate composite labels. PROJECT.md records this next to the decision.
- Xcode 16.4 only: `STRING_CATALOG_GENERATE_SYMBOLS` is not used (literals instead, per research); plan 01-09 revisits after the toolchain upgrade.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None added by this plan. Pre-existing BrewCore stubs from plan 01-01 are unchanged and tracked in `.planning/WINDOWS.md`.

## Threat Flags

None. New surface matches the plan's threat model: T-1-05 (atomic write, backup, fallback, load never writes: unit tested), T-1-06 (`-UITestResetSave` honored only inside `#if DEBUG`), T-1-07 (empty manifest bundled, API grep clean), T-1-08 (no signing material created).

## Next Phase Readiness

- Plans 01-03 onward can add screens as `Screen` cases and views under `App/BrewFighter/<Feature>/` with no project edits; run `swift scripts/check-strings.swift` and reuse the UITestSupport helpers.
- Plan 01-05 inserts the migrator and validator into `SaveCodec.decode`; `SaveRepository` already treats any decode error as a fallback trigger.
- Plan 01-09 raises the deployment target from 18.0 to 26.0 and re-evaluates Xcode 26-only settings.
- Note for 01-06 and later: composite labels must come from one catalog format string; do not assert pseudo-localization doubling on them.

## Self-Check: PASSED

- All 20 key-files.created exist on disk (checked with `[ -f ]`).
- 4 task commits (`a494c10`, `8810c83`, `9c1a1f0`, `73d3434`) are ancestors of HEAD; `git log --grep='(01-02)'` returns 4; `commits: 4` measured from the plan ledger.
- Acceptance criteria re-run and passing: `project.yml` has `syncedFolder`, `Packages/BrewCore`, `deploymentTarget`; `PBXFileSystemSynchronizedRootGroup` count 5; built bundle has `PrivacyInfo.xcprivacy`, portrait-only orientation, `ITSAppUsesNonExemptEncryption` 0; no `executableTarget`; no excluded frameworks or preferences/timestamp APIs; `GameStore.swift` has `@MainActor`, `@Observable`, `Reducer.apply`; `SaveRepository.swift` has `.atomic` and `save.backup.json`; catalog has the three `cellar.save.*` keys, `attribute.hopAroma.name`, `band.fermentTemp.cold.name`; PROJECT.md has `Custom chrome on all game screens`; UITestSupport has all three required helpers.
- Plan verification re-run: `scripts/test-app.sh` full suite exits 0, `swift scripts/check-strings.swift` prints `check-strings: OK (77 keys)`, `swift test --package-path Packages/BrewCore` passes (58 tests).

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-08*
