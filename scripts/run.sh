#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Athar.app"
BUNDLE_ID="com.mhmdessam.Athar"

SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 16e}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Athar — Build & Run"
echo "📱 Preferred Simulator: $SIMULATOR_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

"$ROOT_DIR/scripts/build.sh"

echo ""
echo "📱 Looking for $SIMULATOR_NAME..."

DEVICE_ID="$(
  xcrun simctl list devices available |
  grep "$SIMULATOR_NAME (" |
  head -1 |
  sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
)"

if [ -z "$DEVICE_ID" ]; then
  echo "❌ Could not find simulator: $SIMULATOR_NAME"
  exit 1
fi

DEVICE_INFO="$(
  xcrun simctl list devices available |
  grep "$DEVICE_ID" |
  head -1
)"

echo "📱 Simulator: $SIMULATOR_NAME"
echo "🆔 Device ID: $DEVICE_ID"

if ! echo "$DEVICE_INFO" | grep -q "Booted"; then
  echo "🔌 Booting simulator..."
  xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
fi

open -a Simulator

echo "⏳ Waiting for simulator..."
xcrun simctl bootstatus "$DEVICE_ID" -b

if [ ! -d "$APP_PATH" ]; then
  echo "❌ Athar.app not found:"
  echo "$APP_PATH"
  exit 1
fi

echo "📦 Installing Athar..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "✨ Launching Athar..."
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo ""
echo "✅ Athar is running on $SIMULATOR_NAME"
