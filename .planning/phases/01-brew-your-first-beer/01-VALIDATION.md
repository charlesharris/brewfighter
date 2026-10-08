---
phase: "1"
slug: "brew-your-first-beer"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-08"
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (BrewCore + app unit tests); XCTest/XCUITest (app UI tests) |
| **Config file** | `Packages/BrewCore/Package.swift` (plan 01-01), `project.yml` → `BrewFighter.xcodeproj` shared scheme (plan 01-02) |
| **Quick run command** | `swift test --package-path Packages/BrewCore` |
| **Full suite command** | `swift test --package-path Packages/BrewCore && swift scripts/check-strings.swift && scripts/test-app.sh` |
| **Estimated runtime** | ~30 seconds quick (no simulator); ~5-10 minutes full (simulator UI tests) |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command (engine tasks: `swift test --package-path Packages/BrewCore --filter <Suite>`; app tasks: `scripts/test-app.sh -only-testing:<Target/Class>`)
- **After every plan wave:** Run `swift test --package-path Packages/BrewCore` plus `swift scripts/check-strings.swift`; from wave 2 on, also `scripts/test-app.sh`
- **Before `/gsd-verify-work`:** Full suite must be green on the iOS 26+ simulator (after plan 01-09), plus the harvested `<human-check>` items
- **Max feedback latency:** 60 seconds for engine tasks; simulator UI-test tasks are slower (minutes) and are scoped with `-only-testing`

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-T1 | 01 | 1 | BREW-02, BREW-04, BREW-07, PLAT-03 | T-1-02, T-1-03, T-1-04 | No RNG in brewing; newer-schema and oversized saves rejected before payload decode | unit (tracer) | `swift test --package-path Packages/BrewCore --filter WalkingSkeletonTests` | ❌ created by task | ⬜ pending |
| 01-01-T2 | 01 | 1 | BREW-06 | — | Style computed from attributes only; Recipe JSON has no style key | unit | `swift test --package-path Packages/BrewCore --filter StyleClassifierTests` | ❌ created by task | ⬜ pending |
| 01-01-T3 | 01 | 1 | BREW-01, BREW-07 | T-1-01 | Recipe bounds validated before Int arithmetic | unit | `swift test --package-path Packages/BrewCore --filter RecipeRulesTests` | ❌ created by task | ⬜ pending |
| 01-02-T1 | 02 | 2 | PLAT-05, PLAT-03, PLAT-01 | T-1-06, T-1-07 | DEBUG-only reset flag; empty privacy manifest bundled | UI (tracer) | `xcodegen generate && scripts/test-app.sh -only-testing:BrewFighterUITests/PersistenceUITests -only-testing:BrewFighterTests` | ❌ created by task | ⬜ pending |
| 01-02-T2 | 02 | 2 | PLAT-03 | T-1-05 | Atomic write, backup copy, fallback load; load never writes | unit (app) | `scripts/test-app.sh -only-testing:BrewFighterTests` | ❌ created by task | ⬜ pending |
| 01-02-T3 | 02 | 2 | PLAT-06, PLAT-01 | — | Catalog coverage; no intoxication vocabulary (BANNED) | script + UI | `swift scripts/check-strings.swift` ; `scripts/test-app.sh -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-03-T1 | 03 | 3 | BREW-02, BREW-04 | T-1-10 | No trademarked hop names in content | unit (tracer) | `swift scripts/gen-brew-tables.swift && swift test --package-path Packages/BrewCore --filter HopContributionTests` | ❌ created by task | ⬜ pending |
| 01-03-T2 | 03 | 3 | BREW-02, PLAT-06 | T-1-09 | Content bounds and referential integrity | unit | `swift test --package-path Packages/BrewCore --filter ContentValidationTests` | ❌ created by task | ⬜ pending |
| 01-03-T3 | 03 | 3 | BREW-02, BREW-04, BREW-07 | — | — | unit | `swift test --package-path Packages/BrewCore --filter LedgerInvariantTests` | ❌ created by task | ⬜ pending |
| 01-04-T1 | 04 | 4 | BREW-02, BREW-04 | T-1-11 | Clamped attenuation and table indices | unit (tracer) | `swift scripts/gen-brew-tables.swift && swift test --package-path Packages/BrewCore --filter StatsTests` | ❌ created by task | ⬜ pending |
| 01-04-T2 | 04 | 4 | ART-01 | — | — | unit | `swift test --package-path Packages/BrewCore --filter GlassSpecTests` | ❌ created by task | ⬜ pending |
| 01-04-T3 | 04 | 4 | BREW-06, PLAT-06 | T-1-12 | ABV framed as a brewing stat; BANNED vocabulary check | unit + script | `swift test --package-path Packages/BrewCore --filter StyleClassifierTests` ; `swift scripts/check-strings.swift` | ❌ created by task | ⬜ pending |
| 01-05-T1 | 05 | 5 | PLAT-03 | T-1-13, T-1-14, T-1-15 | Bounded read, single validated decode path, pre-import backup, untouched state on failure | unit (tracer, engine + app) | `swift test --package-path Packages/BrewCore && scripts/test-app.sh -only-testing:BrewFighterTests` | ❌ created by task | ⬜ pending |
| 01-05-T2 | 05 | 5 | PLAT-03, PLAT-01, PLAT-06 | T-1-14 | Replace only after confirmation | UI + manual | `scripts/test-app.sh -only-testing:BrewFighterUITests/SaveTransferUITests -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-05-T3 | 05 | 5 | PLAT-03 | — | Frozen v1 fixture behind a checksum | unit | `swift test --package-path Packages/BrewCore --filter GoldenSaveTests` | ❌ created by task | ⬜ pending |
| 01-06-T1 | 06 | 6 | BREW-01, PLAT-01 | T-1-17 | All edits routed through RecipeRules | UI (tracer) | `scripts/test-app.sh -only-testing:BrewFighterUITests/WizardUITests -only-testing:BrewFighterUITests/PersistenceUITests` | ❌ created by task | ⬜ pending |
| 01-06-T2 | 06 | 6 | BREW-01, PLAT-01, PLAT-06 | T-1-17 | Refused edits disable controls | UI + manual | `scripts/test-app.sh -only-testing:BrewFighterUITests/WizardUITests -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-06-T3 | 06 | 6 | BREW-01, PLAT-01 | — | — | UI | `scripts/test-app.sh -only-testing:BrewFighterUITests/WizardUITests -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-07-T1 | 07 | 7 | BREW-01, BREW-07 | — | — | UI (tracer) | `scripts/test-app.sh -only-testing:BrewFighterUITests/WizardUITests` | ❌ created by task | ⬜ pending |
| 01-07-T2 | 07 | 7 | BREW-01, BREW-07 | — | — | UI | `scripts/test-app.sh -only-testing:BrewFighterUITests/WizardUITests -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-07-T3 | 07 | 7 | BREW-01, PLAT-01 | T-1-18 | BREW gated on RecipeRules.validate | UI + manual | `scripts/test-app.sh -only-testing:BrewFighterUITests/WizardUITests -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-08-T1 | 08 | 8 | BREW-04, BREW-06 | — | — | UI (tracer) | `scripts/test-app.sh -only-testing:BrewFighterUITests/BeerDetailUITests` | ❌ created by task | ⬜ pending |
| 01-08-T2 | 08 | 8 | ART-01, PLAT-01 | T-1-20 | Bubble cap; static thumbnails | UI + manual | `scripts/test-app.sh -only-testing:BrewFighterUITests/BeerDetailUITests -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-08-T3 | 08 | 8 | BREW-07, PLAT-03 | T-1-19 | Beer committed and saved before the reveal; no timers | UI + grep + manual | `scripts/test-app.sh -only-testing:BrewFighterUITests` ; `! grep -rnE 'Timer\|asyncAfter\|Task\.sleep\|usleep' App/BrewFighter Packages/BrewCore/Sources` | ❌ created by task | ⬜ pending |
| 01-09-T1 | 09 | 9 | PLAT-05 | T-1-21 | Xcode from Apple sources only | manual (human-action) | `xcodebuild -version` (verification after the human step) | n/a | ⬜ pending |
| 01-09-T2 | 09 | 9 | PLAT-05 | — | — | full suite (tracer) | `xcodegen generate && swift test --package-path Packages/BrewCore && scripts/test-app.sh` | ✅ (existing suites) | ⬜ pending |
| 01-09-T3 | 09 | 9 | PLAT-05, PLAT-06, PLAT-01 | T-1-22, T-1-23 | 4+-appropriate icon; settings only on the app target | UI + manual | `swift scripts/gen-app-icon.swift && xcodegen generate && scripts/test-app.sh -only-testing:BrewFighterUITests/ChromeUITests` | ❌ created by task | ⬜ pending |
| 01-10-T1 | 10 | 10 | PLAT-05 | T-1-26 | One-way bundle ID confirmed by a human | decision checkpoint | n/a | n/a | ⬜ pending |
| 01-10-T2 | 10 | 10 | PLAT-05 | T-1-25 | 18+ rating set in ASC | manual (human-action) | n/a | n/a | ⬜ pending |
| 01-10-T3 | 10 | 10 | PLAT-05 | T-1-24, T-1-27 | No committed signing material; test gate before upload | script (tracer) + manual | `bash -n scripts/archive-upload.sh && plutil -lint config/ExportOptions.plist` ; `scripts/archive-upload.sh` | ❌ created by task | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `Packages/BrewCore/Package.swift`: Swift package with a Swift Testing target (plan 01-01 Task 1)
- [ ] `Packages/BrewCore/Tests/BrewCoreTests/`: WalkingSkeletonTests, StyleClassifierTests, RecipeRulesTests covering BREW-01/02/04/06/07 and the PLAT-03 round trip (plan 01-01)
- [ ] `Packages/BrewCore/Tests/BrewCoreTests/Support/RecipeGrid.swift`: shared deterministic recipe enumerator (plan 01-03 Task 3)
- [ ] `project.yml`, app + unit-test + UI-test targets, `scripts/test-app.sh`, `scripts/check-strings.swift`, `App/BrewFighterUITests/UITestSupport.swift` (plan 01-02)
- [ ] `Packages/BrewCore/Tests/BrewCoreTests/Fixtures/save_v1.json`: frozen golden save with checksum (plan 01-05 Task 3)
- [x] Swift toolchain present (Swift 6.1.2 on this Mac: sufficient for BrewCore). Xcode 16.4 + iOS 18.6 simulator: sufficient for the app dev loop at deployment target 18.0 (plans 01-02 to 01-08)

*iOS 26 SDK builds, the final pseudo-localized run and TestFlight are gated on the human macOS/Xcode upgrade checkpoint (plan 01-09 Task 1) and the App Store Connect checkpoints (plan 01-10 Tasks 1-2).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| TestFlight install on real iPhone | PLAT-05 | Requires Apple Developer account, App Store Connect, physical device | Plan 01-10 Task 3 human-check: install from TestFlight, brew, force-quit, relaunch |
| App Store Connect record + 18+ age rating | PLAT-05 | Web-only App Store Connect forms (no API for app records) | Plan 01-10 Task 2 checkpoint |
| One-handed portrait usability, 44pt targets | PLAT-01 | Visual/ergonomic judgment on device (frame checks are automated in ChromeUITests) | Plan 01-06 Task 2 and plan 01-07 Task 3 human-checks |
| Pseudo-localized run shows catalog strings | PLAT-06 | Screenshot scan of doubled strings (raw-key and doubled-label checks are automated) | Plan 01-09 Task 3 human-check over the "pseudo-*" screenshot attachments on iOS 26+ |
| Procedural glass visibly distinct per beer | ART-01 | Visual judgment (GlassSpecTests distance floor is the automated proxy) | Plan 01-08 Task 2 human-check: brew pale ale, stout, pilsner, hazy IPA; compare grid and detail; repeat with Reduce Motion |
| Reveal feel and five-second glance | BREW-07 / D-09 | Subjective timing and juice | Plan 01-08 Task 3 human-check |
| Share-sheet export and file-picker import | PLAT-03 | OS-owned UI that XCUITest cannot drive reliably | Plan 01-05 Task 2 human-check |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (checkpoint tasks 01-09-T1, 01-10-T1, 01-10-T2 are human gates with stated verification)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (no `MISSING` sentinels are used; every suite is created by the task that first runs it)
- [x] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
