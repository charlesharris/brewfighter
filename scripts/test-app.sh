#!/usr/bin/env bash
# Resolve an available iPhone simulator and run xcodebuild test with passthrough args.
set -euo pipefail
cd "$(dirname "$0")/.."

UDID="${SIM_UDID:-}"
NAME="(from SIM_UDID)"
if [ -z "$UDID" ]; then
  # First iPhone listed under the LAST "-- iOS x.y --" section (newest runtime).
  LINE=$(xcrun simctl list devices available | awk '
    /^-- / { inios = ($0 ~ /^-- iOS /); if (inios) pick = ""; next }
    inios && pick == "" && /iPhone/ { pick = $0 }
    END { print pick }
  ')
  if [ -n "$LINE" ]; then
    UDID=$(printf '%s' "$LINE" | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
    NAME=$(printf '%s' "$LINE" | sed -E 's/^ *(.*) \([0-9A-Fa-f-]{36}\).*/\1/')
  fi
fi
if [ -z "$UDID" ]; then
  echo "test-app: no available iPhone simulator found (set SIM_UDID to override)" >&2
  exit 2
fi
echo "test-app: using $NAME $UDID" >&2

exec xcodebuild test \
  -project BrewFighter.xcodeproj \
  -scheme BrewFighter \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData \
  "$@"
