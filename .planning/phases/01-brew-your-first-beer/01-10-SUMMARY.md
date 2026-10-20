---
phase: 01-brew-your-first-beer
plan: 10
subsystem: distribution
tags: [testflight, app-store-connect, xcodebuild, archive, export, bundle-id, age-rating]

requires:
  - phase: 01-09
    provides: iOS 26.0 floor on Xcode 27.1, app icon, concurrency settings, green full suite
provides:
  - Permanent bundle ID com.chuckco.brewfighter in project.yml and the regenerated Xcode project
  - config/ExportOptions.plist (app-store-connect, upload, automatic signing)
  - scripts/archive-upload.sh: test gate, unsigned archive, privacy-manifest check, signed export and upload
  - Builds 0.1.0 uploaded to App Store Connect and processing for TestFlight
  - 18+ age rating, identity, no-Declared-Age-Range and screenshot-spec decisions recorded in PROJECT.md
  - names-cleared.md app-name row resolved as accepted risk
affects: [phase-02, phase-06]

actuals:
  tokens: 4000
  tasks: 3
  commits: 1

plan_head_before: 6733201005f1b5c916484da56c4ac07d0d41cf1b
plan_head_after: c3c5bbce2598e81f8759aebfeb4bb6172ed077bb
commits: 1

tech-stack:
  added: []
  patterns:
    - "Archive unsigned (CODE_SIGNING_ALLOWED=NO), sign at -exportArchive with cloud-managed distribution signing"
    - "Per-run UTC-timestamp CURRENT_PROJECT_VERSION passed at archive time, never committed"

key-files:
  created:
    - config/ExportOptions.plist
    - scripts/archive-upload.sh
    - .planning/phases/01-brew-your-first-beer/01-USER-SETUP.md
  modified:
    - project.yml
    - BrewFighter.xcodeproj/project.pbxproj
    - .planning/PROJECT.md
    - .planning/names-cleared.md

key-decisions:
  - "Bundle ID com.chuckco.brewfighter and App Store name BrewFighter (one word); trademark proximity to Street Fighter accepted by the user"
  - "Archive is unsigned and the export step signs it: a signed Release archive needs a development profile, which requires a registered device the team does not have"
  - "Build number is a per-run UTC timestamp passed to xcodebuild, because manageAppVersionAndBuildNumber alone did not stop a Redundant Binary Upload"

patterns-established:
  - "Upload script is re-runnable: fresh archive and fresh build number every run, nothing uploaded on failure"

requirements-completed: [PLAT-05]

coverage:
  - id: D1
    description: "Permanent bundle ID com.chuckco.brewfighter in project.yml; no com.example.brewfighter; no committed DEVELOPMENT_TEAM"
    requirement: "PLAT-05"
    verification:
      - kind: other
        ref: "grep -n PRODUCT_BUNDLE_IDENTIFIER project.yml; grep -rn 'DEVELOPMENT_TEAM:' project.yml (empty)"
        status: pass
    human_judgment: false
  - id: D2
    description: "archive-upload.sh passes the test gate, archives Release on the Xcode 27.1 SDK, checks the privacy manifest, MinimumOSVersion 26.0 and encryption flag, then exports and uploads"
    requirement: "PLAT-05"
    verification:
      - kind: integration
        ref: "scripts/archive-upload.sh (full run: swift test and scripts/test-app.sh green); SKIP_TESTS=1 scripts/archive-upload.sh exit 0, 'archive-upload: uploaded 0.1.0 (202610202151)'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Re-running the script after an upload does not collide with the previous build"
    requirement: "PLAT-05"
    verification:
      - kind: integration
        ref: "second run with a fresh timestamp build number exported and uploaded after the first run's build 1 was rejected as redundant"
        status: pass
    human_judgment: false
  - id: D4
    description: "No signing material tracked in git"
    requirement: "PLAT-05"
    verification:
      - kind: other
        ref: "git ls-files -- '*.p8' '*.p12' '*.mobileprovision' (empty)"
        status: pass
    human_judgment: false
  - id: D5
    description: "App Store Connect record, 18+ age rating and internal TestFlight group exist"
    requirement: "PLAT-05"
    verification: []
    human_judgment: true
    rationale: "Dashboard-side facts stated by the user on 2026-10-20 (app record BrewFighter, alcohol references Frequent giving 18+, internal group with the user as tester). No API reads them; the executor could not independently observe them."
  - id: D6
    description: "The uploaded build installs from TestFlight on a real iPhone, launches in portrait, brews the house pale ale, and the beer survives force-quit and relaunch"
    requirement: "PLAT-05"
    verification: []
    human_judgment: true
    rationale: "ROADMAP criterion 1 needs a real-device TestFlight install after App Store Connect finishes processing (typically 5-30 minutes). No script or simulator can do this. Deferred to end-of-phase human verification (workflow.human_verify_mode end-of-phase)."

duration: 26 min
completed: 2026-10-20
status: complete
---

# Phase 01 Plan 10: TestFlight pipeline Summary

**A scripted test-gate, archive, privacy-manifest check, export and upload pipeline put Brew Fighter 0.1.0 into App Store Connect under the permanent bundle ID com.chuckco.brewfighter, with the 18+ rating and identity decisions recorded in PROJECT.md.**

## Performance
- **Duration:** 26 min (the full test gate accounts for most of it)
- **Started:** 2026-10-20T21:26:46Z
- **Completed:** 2026-10-20T21:53:16Z
- **Tasks:** 3 (Tasks 1 and 2 answered by the user's setup; Task 3 executed)
- **Files modified:** 7 (3 created, 4 modified, plus the regenerated project)

## Accomplishments
- Task 1 (decision) and Task 2 (human action) were satisfied by facts the user supplied: bundle ID `com.chuckco.brewfighter`, app name "BrewFighter" with accepted trademark risk, team ID 2M6QRD8T3A, app record, 18+ age rating, internal TestFlight group. Team ID verified as 10 characters; the Apple Development identity and Xcode account signing worked for upload.
- `project.yml` now carries the permanent bundle ID (and `bundleIdPrefix: com.chuckco`) with `CODE_SIGN_STYLE: Automatic`; `xcodegen generate` changed only identifiers and signing style in the project file.
- `scripts/archive-upload.sh` ran end to end: BrewCore tests and the 37 app tests green, archive, privacy-manifest/MinimumOSVersion/encryption checks, export and upload. A rebuilt re-run with `SKIP_TESTS=1` also uploaded and printed `archive-upload: uploaded 0.1.0 (202610202151)`.
- Key Decisions in PROJECT.md now record 18+, the permanent identity, no Declared Age Range in Phase 1, and the Phase 6 screenshot spec.

## Task Commits
1. **Task 1: Choose bundle identifier and name** - no commit (decision supplied by the user)
2. **Task 2: App Store Connect record and 18+ rating** - no commit (human action completed by the user)
3. **Task 3 (tracer): identity, test gate, archive, upload** - `c3c5bbc` (feat)

**Plan metadata:** committed in the docs(01-10) close-out commit.

## Files Created/Modified
- `project.yml` - bundle ID prefix and ID, automatic signing style
- `BrewFighter.xcodeproj/project.pbxproj` - regenerated (identifiers, signing style)
- `config/ExportOptions.plist` - method app-store-connect, destination upload, automatic signing, managed build numbers, symbol upload; no team ID
- `scripts/archive-upload.sh` - the pipeline
- `.planning/PROJECT.md` - four Key Decisions rows
- `.planning/names-cleared.md` - app-name row resolved (accepted risk); the 8 hop rows keep their "USPTO search pending" status
- `.planning/phases/01-brew-your-first-beer/01-USER-SETUP.md` - records the completed Apple setup

## Decisions Made
- Archive unsigned, sign at export (see deviation 1).
- Timestamp build number per run (see deviation 2).
- `CFBundleDisplayName` stays "Brew Fighter" (two words) while the App Store name is "BrewFighter"; noted in names-cleared.md for a later decision. The plan did not ask to change it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Signed Release archive failed: team has no registered devices**
- **Found during:** Task 3, first full run of the script
- **Issue:** `xcodebuild archive` with automatic signing failed with "Your team has no devices from which to generate a provisioning profile" and "No profiles for 'com.chuckco.brewfighter' were found" (it wants an iOS App Development profile).
- **Fix:** Archive with `CODE_SIGNING_ALLOWED=NO`; `-exportArchive` with `signingStyle automatic` signs with the cloud-managed distribution certificate and profile. The archive-time `-allowProvisioningUpdates` and API key flags are dropped; they remain on the export step. The plan's A5 assumption (cloud-managed distribution cert) held.
- **Files modified:** scripts/archive-upload.sh
- **Verification:** archive and export both succeeded; upload reported "Upload succeeded".
- **Commit:** c3c5bbc

**2. [Rule 1 - Bug] Re-run collided with an already-uploaded build number**
- **Found during:** Task 3, second run
- **Issue:** `exportArchive Redundant Binary Upload: build number '1' for version '0.1.0'`. `manageAppVersionAndBuildNumber` did not increment on this path, so the plan's edge-probe truth (safe re-run) was not met.
- **Fix:** Script passes `CURRENT_PROJECT_VERSION=$(date -u +%Y%m%d%H%M)` (overridable with `BUILD_NUMBER`) at archive time, uncommitted. The ExportOptions key stays as a backstop.
- **Files modified:** scripts/archive-upload.sh
- **Verification:** third run exited 0 and uploaded build 202610202151.
- **Commit:** c3c5bbc

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug). **Impact:** none on scope; both are script-internal.

## Authentication Gates
None. Xcode's signed-in account and its cloud-managed distribution signing covered both archive-export and upload; no ASC API key was needed (intentionally not configured).

## Issues Encountered
- App Store Connect now holds three uploaded builds of 0.1.0 (build 1 and two timestamp-numbered builds) from this plan's iterations. The newest, 202610202151, is the one to install. Older ones can be expired in TestFlight if they clutter the list.
- The pipeline's DTAppAnalyzer step prints "not yet complete" progress lines for about 20 seconds during export; harmless.

## User Setup Required
Complete. See `01-USER-SETUP.md`.

## Next Phase Readiness
- **Pending human check (D6, ROADMAP criterion 1):** after App Store Connect finishes processing, install from TestFlight on the iPhone, brew the house pale ale, open the beer, force-quit, relaunch, and confirm the beer and day counter persist. This is deferred to end-of-phase verification (`/gsd-verify-work`); it is not yet confirmed.
- Phase 2 can reuse `scripts/archive-upload.sh` for the planned first external TestFlight build (the Beta App Review canary).
- Confirm in App Store Connect that the build shows no export-compliance prompt (the Info.plist declares `ITSAppUsesNonExemptEncryption` false).

## Known Stubs
None.

## Threat Flags
None. T-1-24 mitigated (no `.p8`, `.p12` or `.mobileprovision` tracked; key values read from env only and never echoed), T-1-25 recorded, T-1-26 satisfied (bundle ID confirmed before upload; no `com.example.brewfighter` remains), T-1-27 satisfied (test gate ran and the archive is checked for the privacy manifest, MinimumOSVersion and encryption flag).

## Self-Check: PASSED
- Created files exist on disk: config/ExportOptions.plist, scripts/archive-upload.sh, 01-USER-SETUP.md.
- Commit `c3c5bbc` is an ancestor of HEAD; `git rev-list --count` from the ledger base gives 1.
- Acceptance criteria re-run: bundle ID grep shows com.chuckco.brewfighter and zero com.example.brewfighter; `DEVELOPMENT_TEAM:` grep empty; ExportOptions.plist lints OK and contains app-store-connect, upload, manageAppVersionAndBuildNumber; the script contains -exportArchive, PrivacyInfo.xcprivacy, BREWFIGHTER_TEAM_ID; `git ls-files` for signing material empty; PROJECT.md contains 18+ and Declared Age Range; the script exits 0 with the `archive-upload: uploaded` line.
- Not self-checkable: the real-device TestFlight install (D6) and the App Store Connect dashboard state (D5), both flagged as human judgment above.

---
*Phase: 01-brew-your-first-beer*
*Completed: 2026-10-20*
