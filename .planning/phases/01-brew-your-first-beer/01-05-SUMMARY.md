---
phase: 01-brew-your-first-beer
plan: 05
subsystem: persistence
tags: [swift, save-codec, validation, migration, share-sheet, file-importer, golden-fixture, swift-testing]

requires:
  - phase: 01-02
    provides: SaveRepository atomic save with one-deep backup and fallback load, GameStore single writer, UITestSupport helpers
  - phase: 01-04
    provides: BeerStats, GlassSpec and the 13-style roster that the frozen v1 save shape includes
provides:
  - SaveCodec.decode(_:content:) as the only decode path (size cap, header gate, migrator, envelope, validator)
  - SaveValidator bounds and referential checks with path-naming SaveError.invalid
  - SaveMigrator empty v1 chain with the one-step-per-schema-bump rule
  - GameStore export, preview and confirmed import with save.pre-import.json backup
  - Save file sheet in The Cellar (ShareLink export, fileImporter import, confirmation and error alerts)
  - Frozen save_v1.json golden fixture behind an FNV-1a 64 checksum
affects: [01-06, 01-07, 01-08, 01-09, phase-02 saves, any schema change]

actuals:
  tokens: 19600
  tasks: 3
  commits: 4

plan_head_before: 840c03c84527a06a9f037fc1fb6ae9c76cd2c1b5
plan_head_after: 9a106a6bfd13c9291fd0c90edadcfff2562cb0c6
commits: 4

tech-stack:
  added: []
  patterns:
    - "One validated decode path: no public decode skips SaveValidator"
    - "Preview-then-confirm destructive replace: backup first, write new save, then swap in-memory state"
    - "Frozen golden fixture plus checksum constant; generator test gated by BREWCORE_WRITE_GOLDEN=1"

key-files:
  created:
    - Packages/BrewCore/Sources/BrewCore/Save/SaveValidator.swift
    - Packages/BrewCore/Sources/BrewCore/Save/SaveMigrator.swift
    - Packages/BrewCore/Tests/BrewCoreTests/SaveCodecTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/GoldenSaveTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/Fixtures/save_v1.json
    - App/BrewFighter/Cellar/SaveTransferSheet.swift
    - App/BrewFighterTests/SaveTransferTests.swift
    - App/BrewFighterUITests/SaveTransferUITests.swift
  modified:
    - Packages/BrewCore/Package.swift
    - Packages/BrewCore/Sources/BrewCore/Save/SaveCodec.swift
    - Packages/BrewCore/Tests/BrewCoreTests/StatsTests.swift
    - Packages/BrewCore/Tests/BrewCoreTests/WalkingSkeletonTests.swift
    - App/BrewFighter/Persistence/SaveRepository.swift
    - App/BrewFighter/Shell/GameStore.swift
    - App/BrewFighter/Cellar/CellarView.swift
    - App/BrewFighter/Localizable.xcstrings
    - App/BrewFighterTests/SaveRepositoryTests.swift
    - App/BrewFighterUITests/ChromeUITests.swift

key-decisions:
  - "confirmImport writes the new save before swapping in-memory state, so a failed write leaves both state and save.json untouched"
  - "Ledger delta bound is a range check, not abs(), because abs(Int.min) traps on a hostile file"
  - "Validator bounds sit above engine maxima (IBU tenths 50,000, SRM tenths 1,500) so every brewable beer validates, proven by the extreme-recipe test"
  - "Save file button sits in its own header row under the title/day row so pseudo-localized labels cannot crowd the day counter"

patterns-established:
  - "Schema change rule: bump currentSchemaVersion, add exactly one SaveMigrator step, add a new frozen save_vN.json, keep older fixtures decoding"
  - "App tests build temp-directory SaveRepository + GameStore pairs to exercise import failure paths"

requirements-completed: [PLAT-03, PLAT-01, PLAT-06]

coverage:
  - id: D1
    description: "Every decode (disk or import) passes size cap, header gate, migrator, envelope decode, SaveValidator"
    requirement: PLAT-03
    verification:
      - kind: unit
        ref: "swift test --package-path Packages/BrewCore (SaveCodecTests, WalkingSkeletonTests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "SaveValidator rejects out-of-range or inconsistent data with a path-naming SaveError.invalid, and accepts every engine-brewable beer"
    requirement: PLAT-03
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/SaveCodecTests.swift (14 bound tests, extreme recipe, 120 random recipes)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Import replaces the cellar only after confirmation, after save.pre-import.json is written; failed, newer, oversized or cancelled imports change nothing"
    requirement: PLAT-03
    verification:
      - kind: unit
        ref: "App/BrewFighterTests/SaveTransferTests.swift via scripts/test-app.sh -only-testing:BrewFighterTests"
        status: pass
    human_judgment: false
  - id: D4
    description: "Frozen golden fixture save_v1.json decodes, validates, re-encodes to the same JSON tree, re-brews identically and matches its checksum"
    requirement: PLAT-03
    verification:
      - kind: unit
        ref: "Packages/BrewCore/Tests/BrewCoreTests/GoldenSaveTests.swift"
        status: pass
    human_judgment: false
  - id: D5
    description: "Save file sheet reachable from The Cellar, buttons 44pt or larger, no raw catalog keys, pseudo-localization screenshot"
    requirement: PLAT-06
    verification:
      - kind: automated_ui
        ref: "scripts/test-app.sh -only-testing:BrewFighterUITests/SaveTransferUITests -only-testing:BrewFighterUITests/ChromeUITests"
        status: pass
      - kind: other
        ref: "swift scripts/check-strings.swift"
        status: pass
    human_judgment: false
  - id: D6
    description: "The OS-owned share sheet offers BrewFighter-Save.json and the document picker re-imports it"
    requirement: PLAT-03
    verification: []
    human_judgment: true
    rationale: "Share sheet and document picker are OS-owned UI that XCUITest cannot drive reliably; research assumption A9 (ShareLink with a temp file URL) needs a real run"

duration: 7min
completed: 2026-10-14
status: complete
---

# Phase 1 Plan 05: Save Transfer and Frozen Schema v1 Summary

**One validated decode path for every save, export through the share sheet and confirmed, pre-backed-up import through the file picker, and schema v1 frozen behind a checksummed golden fixture.**

## Performance
- **Duration:** 7 min
- **Started:** 2026-10-14T19:09:06Z
- **Completed:** 2026-10-14T19:16:23Z
- **Tasks:** 3
- **Files modified:** 18 (8 created, 10 modified)

## Accomplishments
- `SaveCodec.decode(_:content:)` replaced the content-less decode: size cap, header-only version gate, `SaveMigrator`, envelope decode, then `SaveValidator`. Disk loads and imports share it, so there is no unvalidated entry point.
- `SaveValidator` checks day, beer count (10,000), unique IDs, strictly increasing batch numbers, `nextBatchNumber`, brew day, recipe via `RecipeRules.validate`, style ID, attribute range, ledger row bounds and per-attribute sums, and stat bounds. The most extreme legal recipe (8 maximal bittering additions, imperial, 15% roasted barley, 20% crystal) and 120 seeded random recipes brew and validate.
- `GameStore` exports to `Export-<UUID>/BrewFighter-Save.json`, reads imports through a bounded `FileHandle` (max `maxSaveBytes + 1`) inside security-scoped access, and `confirmImport` writes `save.pre-import.json` first, then the new save, then swaps state.
- `SaveTransferSheet` from a new Save file button in The Cellar: Export save, Share BrewFighter-Save.json, Import save, a Replace confirmation showing beer count and day, and plain-language error alerts.
- `save_v1.json` (3 beers covering all four hop slots, all four conditioning kinds, a grain-bill adjunct and a fruit adjunct) is frozen at FNV-1a 64 `0x1505d50a292b09fc`.

## Task Commits
1. **Task 1: Tracer, export to validated import to confirmed replace** - `39af495` (feat)
2. **Task 2: Save Transfer sheet** - `ee30b2d` (feat)
3. **Task 3: Freeze schema v1** - RED `13dbdf9` (test), GREEN `9a106a6` (feat); no refactor needed

**Plan metadata:** recorded in the docs(01-05) commit that follows this file.

Tracer gate: after Task 1, `swift test` (130 tests) and `scripts/test-app.sh -only-testing:BrewFighterTests` (25 tests) both passed, so the tracer was verified end to end before expansion.

## Files Created/Modified
See `key-files` above. Notable: `Save/SaveValidator.swift` (bounds), `Save/SaveMigrator.swift` (empty v1 chain plus the schema-change rule), `Cellar/SaveTransferSheet.swift` (ShareLink and fileImporter UI), `Fixtures/save_v1.json` (frozen).

## Decisions Made
- `confirmImport` writes the new save before changing in-memory state. The plan allowed either order; this one makes a failed write a failed import, in line with the PLAT-03 prohibition.
- Ledger delta bound uses a range check instead of `abs()` since `abs(Int.min)` traps.
- Added two catalog keys beyond the plan's list: `saveTransfer.error.title` and `saveTransfer.error.writeFailed` (alerts need a title, and a write failure needs its own message).
- Save file button gets its own header row so doubled pseudo-localized strings cannot collide with the day counter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] abs() on a hostile ledger delta would trap**
- **Found during:** Task 1 (writing SaveValidator)
- **Issue:** `abs(row.delta) <= 1000` crashes for `Int.min`, which a hostile file can supply.
- **Fix:** `(-1000...1000).contains(row.delta)`; test `anOversizedLedgerRowIsInvalidAndDoesNotTrap` added.
- **Files modified:** `Packages/BrewCore/Sources/BrewCore/Save/SaveValidator.swift`, `SaveCodecTests.swift`
- **Commit:** `39af495`, test in `13dbdf9`

**2. [Rule 2 - Missing critical] Write failure after import must not strand state**
- **Found during:** Task 1 (`confirmImport`)
- **Issue:** Setting state first and persisting after (as the plan words it) would leave the cellar replaced in memory but not on disk if the write failed.
- **Fix:** write new save first, then swap state; test `aFailedPreImportBackupAbortsTheReplacement` covers the backup-failure path.
- **Commit:** `39af495`

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical). **Impact:** none on scope; both strengthen the PLAT-03 safety prohibition.

### TDD note
Task 3's validator bound tests already passed at RED because the validator shipped with the tracer in Task 1 (unexpected-GREEN is expected there). The RED gate was valid for the migrator and golden tests: `gsd check tdd-red-evidence` returned `RED_EVIDENCE_OK` for `migratingFromANewerVersionIsRefused` (9 tests failing on planned assertions, against a stub migrator that always threw `.unreadable` and a placeholder fixture). Semantic assessment: the target executed and failed on the planned `#expect(throws: newerThanApp)` assertion for the intended reason.

## Issues Encountered
None. A pre-existing iOS 18.6 pseudo-localization quirk ("Day 1$lld Day 1" in the day counter) is the known OS behavior documented in STATE.md, not a regression.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None.

## Threat Flags
None. New surface (file picker input, exported temp file) is covered by T-1-13 to T-1-16 in the plan's threat model.

## Next Phase Readiness
- Plan 01-06 onward can rely on the schema-change rule: any new field means a version bump, one `SaveMigrator` step and a new golden fixture.
- Open item (ledger #4, `unrun-verify`): the manual share-sheet and Files round trip (brew two beers, Export, Share to Files, brew a different beer, Import, Replace; Cancel leaves the cellar alone) has not been run. The human-check in the plan's Task 2 still applies.

## Self-Check: PASSED
- Created files exist; `git merge-base --is-ancestor` confirmed for `39af495`, `ee30b2d`, `13dbdf9`, `9a106a6`.
- `swift test --package-path Packages/BrewCore`: 154 tests passed; fixture byte-identical before and after.
- `scripts/test-app.sh` full suite: succeeded (25 app unit tests, 6 UI tests).
- `swift scripts/check-strings.swift`: OK (155 keys).
- Acceptance criteria for all three tasks re-run and passing.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-14*
