#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$(find "$ROOT_DIR" -maxdepth 3 -name "*.xcodeproj" -print -quit)"

if [ -z "$PROJECT" ]; then
  echo "❌ No .xcodeproj found under $ROOT_DIR"
  exit 1
fi

SCHEME="${SCHEME:-Athar}"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏗️  Building Athar"
echo "📦 Project: $PROJECT"
echo "🎯 Scheme:  $SCHEME"
echo "📁 Build:   $DERIVED_DATA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

echo ""
echo "✅ BUILD SUCCEEDED"
