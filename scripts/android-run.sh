#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"
APK="$ANDROID_DIR/app/build/outputs/apk/debug/app-debug.apk"
PACKAGE="com.mhmdessam.athar"

"$ROOT_DIR/scripts/android-build.sh"

if ! command -v adb >/dev/null 2>&1; then
  echo "❌ adb is not in PATH"
  exit 1
fi

DEVICE="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"

if [ -z "$DEVICE" ]; then
  if ! command -v emulator >/dev/null 2>&1; then
    echo "❌ No connected Android device and emulator is not in PATH"
    exit 1
  fi

  AVD="$(emulator -list-avds | head -1)"
  if [ -z "$AVD" ]; then
    echo "❌ No Android device or AVD found"
    echo "Create one from Android Studio > Device Manager"
    exit 1
  fi

  echo "📱 Starting emulator: $AVD"
  emulator -avd "$AVD" >/tmp/athar-emulator.log 2>&1 &
  adb wait-for-device

  until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 2
  done

  DEVICE="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
fi

echo "📱 Device: $DEVICE"
echo "📦 Installing Athar..."
adb -s "$DEVICE" install -r "$APK"

echo "✨ Launching Athar..."
adb -s "$DEVICE" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null

echo ""
echo "✅ Athar is running on $DEVICE"
