#!/bin/bash
# Build BrewFighter and launch it in an iOS simulator with one command.
#
#   scripts/run-sim.sh                  # default device: iPhone 18 Pro
#   scripts/run-sim.sh "iPhone 17e"     # any device name from `xcrun simctl list devices available`
#   BF_SIM_DEVICE="iPhone Air" scripts/run-sim.sh
#
# Note: avoid "iPhone Duo" for visual work — its dual-display framebuffer
# makes screenshots (and some mirroring) come back black.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE_NAME="${1:-${BF_SIM_DEVICE:-iPhone 18 Pro}}"
DERIVED="build/DerivedData"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/BrewFighter.app"

# Resolve the device name to a UDID (first available match, newest runtime listed last wins ties by first match)
UDID=$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | grep -oE '[0-9A-F-]{36}' | head -1)
if [ -z "$UDID" ]; then
  echo "error: no available simulator named '$DEVICE_NAME'." >&2
  echo "Available devices:" >&2
  xcrun simctl list devices available | grep -E '^\s+iPhone|^\s+iPad' >&2
  exit 1
fi
echo "▸ Device: $DEVICE_NAME ($UDID)"

echo "▸ Building (incremental)…"
xcodebuild build \
  -project BrewFighter.xcodeproj \
  -scheme BrewFighter \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED" \
  -quiet

BUNDLE_ID=$(defaults read "$ROOT/$APP/Info" CFBundleIdentifier)

# Boot if needed, then bring up the simulator GUI (DeviceHub in Xcode 27; Simulator before that)
xcrun simctl bootstatus "$UDID" -b >/dev/null
GUI="$(xcode-select -p | sed 's|/Developer$||')/Applications/DeviceHub.app"
if [ -d "$GUI" ]; then
  open "$GUI"
else
  open -a Simulator 2>/dev/null || open -b com.apple.iphonesimulator 2>/dev/null || true
fi

echo "▸ Installing ${BUNDLE_ID}…"
xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
echo "▸ Launching…"
xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
echo "✓ BrewFighter running on $DEVICE_NAME"
