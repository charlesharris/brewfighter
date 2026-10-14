---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 2
total_count: 4
last_updated: 2026-10-14T19:16:23.655Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | stub | Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift |  | containsHop always returns false until hop content lands in plan 01-03 | fixed |  | 2026-10-08T22:05:00.465Z | 2026-10-08T22:27:23.389Z |
| 2 | 01 | stub | Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift |  | fgPoints/abvTenths/ibuTenths/srmTenths are 0 until plans 01-03 (IBU) and 01-04 (FG, ABV, SRM) | fixed |  | 2026-10-08T22:05:00.576Z | 2026-10-14T19:04:39.262Z |
| 3 | 01 | deviation | Packages/BrewCore/Sources/BrewCore/Resources/Content/srm_colors.json |  | SRM stops 1, 10-11, 13-16, 18, 21-23, 25-27, 29-33 and 35-40 are not independently verified against a published chart (only 15 stops cross-checked); verify and tune by eye in plan 01-08 | open |  | 2026-10-14T19:04:39.377Z |  |
| 4 | 01 | unrun-verify | App/BrewFighter/Cellar/SaveTransferSheet.swift |  | Share sheet and document picker round trip (research assumption A9, ShareLink with a temp file URL) needs a manual run on a simulator or device | open |  | 2026-10-14T19:16:23.655Z |  |

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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-14T19:04:39.377Z",
    "resolved_at": null,
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
  }
]
````
