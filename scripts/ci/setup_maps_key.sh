#!/bin/bash

# Injects MAPS_API_KEY into all three platform config files.
# Called in CI before flutter pub get / flutter build.
# Mirrors the pattern from setup_firebase_options.sh.

set -e

KEY="${MAPS_API_KEY:-}"

if [ -z "$KEY" ]; then
  echo "Warning: MAPS_API_KEY is not set — using placeholder key."
  echo "  Maps will show 'For development purposes only' watermark."
  echo "  Add MAPS_API_KEY as a GitHub Actions repository secret to fix this."
  KEY="PLACEHOLDER_MAPS_KEY_ADD_SECRET"
fi

# ── iOS Debug.xcconfig ──────────────────────────────────────────────────────
mkdir -p ios/Flutter
cat > ios/Flutter/Debug.xcconfig <<EOF
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"
#include "Generated.xcconfig"
// Google Maps API key — injected by CI
MAPS_API_KEY = ${KEY}
EOF
echo "✓ ios/Flutter/Debug.xcconfig written"

# ── iOS Release.xcconfig ─────────────────────────────────────────────────────
cat > ios/Flutter/Release.xcconfig <<EOF
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Generated.xcconfig"
// Google Maps API key — injected by CI
MAPS_API_KEY = ${KEY}
EOF
echo "✓ ios/Flutter/Release.xcconfig written"

# ── Android local.properties ─────────────────────────────────────────────────
# Preserve existing sdk.dir line if present, then append/update MAPS_API_KEY
ANDROID_LP="android/local.properties"
if [ -f "$ANDROID_LP" ]; then
  # Remove any existing MAPS_API_KEY line and re-append
  grep -v "^MAPS_API_KEY=" "$ANDROID_LP" > "${ANDROID_LP}.tmp" && mv "${ANDROID_LP}.tmp" "$ANDROID_LP"
else
  # Create with sdk.dir pointing to Android SDK on GitHub-hosted runners
  echo "sdk.dir=/usr/local/lib/android/sdk" > "$ANDROID_LP"
fi
echo "MAPS_API_KEY=${KEY}" >> "$ANDROID_LP"
echo "✓ android/local.properties updated"

echo "Maps API key setup complete."
