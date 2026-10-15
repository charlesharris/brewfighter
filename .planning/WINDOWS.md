---
schema_version: 1
open_count: 5
waived_count: 0
fixed_count: 3
total_count: 8
last_updated: 2026-10-15T18:51:36.313Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | stub | Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift |  | containsHop always returns false until hop content lands in plan 01-03 | fixed |  | 2026-10-08T22:05:00.465Z | 2026-10-08T22:27:23.389Z |
| 2 | 01 | stub | Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift |  | fgPoints/abvTenths/ibuTenths/srmTenths are 0 until plans 01-03 (IBU) and 01-04 (FG, ABV, SRM) | fixed |  | 2026-10-08T22:05:00.576Z | 2026-10-14T19:04:39.262Z |
| 3 | 01 | deviation | Packages/BrewCore/Sources/BrewCore/Resources/Content/srm_colors.json |  | SRM stops 1, 10-11, 13-16, 18, 21-23, 25-27, 29-33 and 35-40 are not independently verified against a published chart (only 15 stops cross-checked); verify and tune by eye in plan 01-08 | fixed |  | 2026-10-14T19:04:39.377Z | 2026-10-15T18:36:37.476Z |
| 4 | 01 | unrun-verify | App/BrewFighter/Cellar/SaveTransferSheet.swift |  | Share sheet and document picker round trip (research assumption A9, ShareLink with a temp file URL) needs a manual run on a simulator or device | open |  | 2026-10-14T19:16:23.655Z |  |
| 5 | 01 | unrun-verify | App/BrewFighter/Wizard/MashStageView.swift |  | One-thumb ergonomics of the Mash and Boil stages (reach, chunky dial feel) has not been checked by hand on a simulator or device (plan 01-06 Task 2 human-check) | open |  | 2026-10-15T17:34:56.431Z |  |
| 6 | 01 | unrun-verify | App/BrewFighter/Wizard/RecipeWizardView.swift |  | 01-07 Task 3 human-check not run: one-thumb walk composing a full recipe (all five stages) and brewing on simulator or device | open |  | 2026-10-15T18:07:03.824Z |  |
| 7 | 01 | unrun-verify | App/BrewFighter/Glass/GlassView.swift |  | 01-08 Task 2 human-check not run by hand: four brewed beers (pale ale, stout, pilsner, hazy IPA) compared in the Cellar grid, bubble rate vs carbonation, and Reduce Motion fade-in on simulator or device. Glass silhouettes were only reviewed from a synthetic gallery. | open |  | 2026-10-15T18:51:36.196Z |  |
| 8 | 01 | unrun-verify | App/BrewFighter/Reveal/BrewRevealView.swift |  | 01-08 Task 3 human-check not run by hand: reveal timing/feel (anticipation then payoff in 3-5 s), Skip, and Reduce Motion on simulator or device. Automated tests cover sequencing and skip only. | open |  | 2026-10-15T18:51:36.313Z |  |

````json
[
  {
    "id": 1,
    "kind": "stub",
    "phase": "01",
    "file": "Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift",
    "line": null,
    "description": "containsHop always returns false until hop content lands in plan 01-03",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-08T22:05:00.465Z",
    "resolved_at": "2026-10-08T22:27:23.389Z",
    "milestone": null
  },
  {
    "id": 2,
    "kind": "stub",
    "phase": "01",
    "file": "Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift",
    "line": null,
    "description": "fgPoints/abvTenths/ibuTenths/srmTenths are 0 until plans 01-03 (IBU) and 01-04 (FG, ABV, SRM)",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-08T22:05:00.576Z",
    "resolved_at": "2026-10-14T19:04:39.262Z",
    "milestone": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "01",
    "file": "Packages/BrewCore/Sources/BrewCore/Resources/Content/srm_colors.json",
    "line": null,
    "description": "SRM stops 1, 10-11, 13-16, 18, 21-23, 25-27, 29-33 and 35-40 are not independently verified against a published chart (only 15 stops cross-checked); verify and tune by eye in plan 01-08",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-14T19:04:39.377Z",
    "resolved_at": "2026-10-15T18:36:37.476Z",
    "milestone": null
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "App/BrewFighter/Cellar/SaveTransferSheet.swift",
    "line": null,
    "description": "Share sheet and document picker round trip (research assumption A9, ShareLink with a temp file URL) needs a manual run on a simulator or device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-14T19:16:23.655Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "App/BrewFighter/Wizard/MashStageView.swift",
    "line": null,
    "description": "One-thumb ergonomics of the Mash and Boil stages (reach, chunky dial feel) has not been checked by hand on a simulator or device (plan 01-06 Task 2 human-check)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-15T17:34:56.431Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 6,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "App/BrewFighter/Wizard/RecipeWizardView.swift",
    "line": null,
    "description": "01-07 Task 3 human-check not run: one-thumb walk composing a full recipe (all five stages) and brewing on simulator or device",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-15T18:07:03.824Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "App/BrewFighter/Glass/GlassView.swift",
    "line": null,
    "description": "01-08 Task 2 human-check not run by hand: four brewed beers (pale ale, stout, pilsner, hazy IPA) compared in the Cellar grid, bubble rate vs carbonation, and Reduce Motion fade-in on simulator or device. Glass silhouettes were only reviewed from a synthetic gallery.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-15T18:51:36.196Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "01",
    "file": "App/BrewFighter/Reveal/BrewRevealView.swift",
    "line": null,
    "description": "01-08 Task 3 human-check not run by hand: reveal timing/feel (anticipation then payoff in 3-5 s), Skip, and Reduce Motion on simulator or device. Automated tests cover sequencing and skip only.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-15T18:51:36.313Z",
    "resolved_at": null,
    "milestone": null
  }
]
````
