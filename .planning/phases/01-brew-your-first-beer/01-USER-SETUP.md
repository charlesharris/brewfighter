# Phase 01: User Setup Required

**Generated:** 2026-10-20
**Phase:** 01-brew-your-first-beer (plan 01-10)
**Status:** Complete

Setup the user completed by hand for the Apple Developer Program, App Store Connect and TestFlight.

## Environment Variables

| Status | Variable | Source | Add to |
|--------|----------|--------|--------|
| Set | `BREWFIGHTER_TEAM_ID` = `2M6QRD8T3A` | developer.apple.com -> Account -> Membership details -> Team ID | Exported per shell invocation (not in the shell profile); `scripts/archive-upload.sh` reads it from the environment |
| Skipped (optional) | `ASC_KEY_ID` | App Store Connect -> Users and Access -> Integrations -> App Store Connect API | Not configured; Xcode's signed-in account is used instead |
| Skipped (optional) | `ASC_ISSUER_ID` | Same page as `ASC_KEY_ID` | Not configured |
| Skipped (optional) | `ASC_KEY_PATH` | Absolute path to the downloaded `AuthKey_*.p8`, stored outside the repository | Not configured |

## Account Setup

- [x] Apple Developer Program enrollment is active (Team ID 2M6QRD8T3A)

## Dashboard Configuration

- [x] **Register the permanent bundle identifier** `com.chuckco.brewfighter`
  - Location: developer.apple.com -> Certificates, Identifiers & Profiles -> Identifiers
- [x] **Create the app record** with name "BrewFighter", primary language English (U.S.)
  - Location: App Store Connect -> Apps -> +
- [x] **Answer the age rating questionnaire** with alcohol references = Frequent (result 18+)
  - Location: App Store Connect -> App -> App Information -> Age Rating
- [x] **Create an internal TestFlight group** and add yourself as tester
  - Location: App Store Connect -> App -> TestFlight -> Internal Testing

## Verification

```bash
# Team ID is 10 characters
export BREWFIGHTER_TEAM_ID=2M6QRD8T3A
printf '%s' "$BREWFIGHTER_TEAM_ID" | wc -c

# Project carries the permanent identity and no committed team ID
grep -n PRODUCT_BUNDLE_IDENTIFIER project.yml
grep -rn "DEVELOPMENT_TEAM:" project.yml

# Archive and upload (test gate, archive, privacy manifest check, export/upload)
scripts/archive-upload.sh
```

Expected: the identifier line shows `com.chuckco.brewfighter`, the `DEVELOPMENT_TEAM:` grep prints nothing, and the script ends with `archive-upload: uploaded <version> (<build>)`.

---

**Once all items complete:** Mark status as "Complete" at top of file.
