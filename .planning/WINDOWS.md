---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 1
total_count: 2
last_updated: 2026-10-08T22:27:23.389Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 01 | stub | Packages/BrewCore/Sources/BrewCore/Content/ContentCatalog.swift |  | containsHop always returns false until hop content lands in plan 01-03 | fixed |  | 2026-10-08T22:05:00.465Z | 2026-10-08T22:27:23.389Z |
| 2 | 01 | stub | Packages/BrewCore/Sources/BrewCore/Engine/Brewer.swift |  | fgPoints/abvTenths/ibuTenths/srmTenths are 0 until plans 01-03 (IBU) and 01-04 (FG, ABV, SRM) | open |  | 2026-10-08T22:05:00.576Z |  |

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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-08T22:05:00.576Z",
    "resolved_at": null,
    "milestone": null
  }
]
````
