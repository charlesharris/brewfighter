#!/usr/bin/env bash
# Test gate -> archive -> privacy-manifest check -> export/upload to App Store Connect (TestFlight).
#
# Required env:  BREWFIGHTER_TEAM_ID   10-character Apple Developer Team ID
# Optional env:  ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH   App Store Connect API key (headless upload);
#                without all three, Xcode's signed-in account is used.
#                SKIP_TESTS=1   skip the engine and app test gate
#
# Safe to re-run: every run rebuilds the archive from scratch with a fresh timestamp build number,
# so it cannot collide with a previous attempt (App Store Connect rejects a repeated build number).
# A failed run uploads nothing.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${BREWFIGHTER_TEAM_ID:-}" ]; then
  echo "archive-upload: BREWFIGHTER_TEAM_ID is not set (your 10-character Apple Developer Team ID)" >&2
  exit 2
fi
if [ "${#BREWFIGHTER_TEAM_ID}" -ne 10 ]; then
  echo "archive-upload: BREWFIGHTER_TEAM_ID must be 10 characters" >&2
  exit 2
fi

AUTH_ARGS=()
if [ -n "${ASC_KEY_PATH:-}" ] && [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ]; then
  if [ ! -f "$ASC_KEY_PATH" ]; then
    echo "archive-upload: ASC_KEY_PATH does not point to a file" >&2
    exit 2
  fi
  AUTH_ARGS=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
  echo "archive-upload: using App Store Connect API key authentication" >&2
else
  echo "archive-upload: using Xcode's signed-in account for signing and upload" >&2
fi

if [ "${SKIP_TESTS:-0}" != "1" ]; then
  echo "archive-upload: test gate (BrewCore)" >&2
  swift test --package-path Packages/BrewCore
  echo "archive-upload: test gate (app)" >&2
  scripts/test-app.sh
else
  echo "archive-upload: SKIP_TESTS=1, skipping the test gate" >&2
fi

xcodegen generate

# Each run gets a fresh, strictly increasing build number (UTC timestamp, never committed), so a
# re-run after a failed or interrupted upload cannot collide with an earlier attempt. Override with
# BUILD_NUMBER=<n> if needed. manageAppVersionAndBuildNumber stays on in ExportOptions.plist as a backstop.
BUILD_NUMBER="${BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"

ARCHIVE=build/BrewFighter.xcarchive
EXPORT=build/export
rm -rf "$ARCHIVE" "$EXPORT" build/ExportOptions.plist

# The archive is deliberately unsigned (CODE_SIGNING_ALLOWED=NO). A signed Release archive makes Xcode
# look for an iOS App Development profile, which fails on a team with no registered devices. The
# -exportArchive step below signs with the cloud-managed distribution certificate and profile
# (signingStyle automatic), which needs no registered device.
xcodebuild archive \
  -project BrewFighter.xcodeproj \
  -scheme BrewFighter \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$BREWFIGHTER_TEAM_ID" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  CODE_SIGNING_ALLOWED=NO

APP="$ARCHIVE/Products/Applications/BrewFighter.app"
if [ ! -f "$APP/PrivacyInfo.xcprivacy" ]; then
  echo "archive-upload: archived app is missing PrivacyInfo.xcprivacy" >&2
  exit 1
fi
MIN_OS=$(plutil -extract MinimumOSVersion raw "$APP/Info.plist")
if [ "$MIN_OS" != "26.0" ]; then
  echo "archive-upload: archived MinimumOSVersion is $MIN_OS, expected 26.0" >&2
  exit 1
fi
ENC=$(plutil -extract ITSAppUsesNonExemptEncryption raw "$APP/Info.plist")
if [ "$ENC" != "false" ]; then
  echo "archive-upload: archived ITSAppUsesNonExemptEncryption is $ENC, expected false" >&2
  exit 1
fi

mkdir -p build
cp config/ExportOptions.plist build/ExportOptions.plist
plutil -insert teamID -string "$BREWFIGHTER_TEAM_ID" build/ExportOptions.plist

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath "$EXPORT" \
  -allowProvisioningUpdates \
  ${AUTH_ARGS[@]+"${AUTH_ARGS[@]}"}

VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP/Info.plist")
BUILD=$(plutil -extract CFBundleVersion raw "$APP/Info.plist")
echo "archive-upload: uploaded $VERSION ($BUILD)"
