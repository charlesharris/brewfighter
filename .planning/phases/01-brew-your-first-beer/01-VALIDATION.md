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
| **Framework** | Swift Testing (bundled with Swift toolchain) |
| **Config file** | none — Wave 0 installs (BrewCore/Package.swift test target) |
| **Quick run command** | `swift test --package-path BrewCore` |
| **Full suite command** | `swift test --package-path BrewCore` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `swift test --package-path BrewCore`
- **After every plan wave:** Run `swift test --package-path BrewCore`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (filled by planner) | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `BrewCore/Package.swift` — Swift package with Testing target
- [ ] `BrewCore/Tests/BrewCoreTests/` — stubs for BREW-01/02/04/06/07, PLAT-03 round-trip
- [ ] Swift toolchain present (Swift 6.1.2 on this Mac — sufficient for BrewCore; app target needs Xcode 26+ per RESEARCH.md)

*App-target build/UI verification is gated on the macOS/Xcode upgrade human checkpoint.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| TestFlight install on real iPhone | PLAT-05 | Requires Apple Developer account, App Store Connect, physical device | Archive, upload, install via TestFlight, launch |
| One-handed portrait usability, 44pt targets | PLAT-01 | Visual/ergonomic judgment on device | Hold phone one-handed, complete a full brew flow |
| Pseudo-localized run shows catalog strings | PLAT-06 | Simulator launch-argument run with visual scan | Launch with -NSDoubleLocalizedStrings YES; scan for undoubled strings |
| Procedural glass visibly distinct per beer | ART-01 | Visual judgment | Brew 3+ different recipes; compare glasses |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
