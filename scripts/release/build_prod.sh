#!/usr/bin/env bash
#
# Tremble — production release build + Sentry debug-symbol upload.
#
# This is the ONLY supported way to cut a production build. It exists because
# the two things that must never be forgotten were previously left to a human
# copying commands out of tasks/lessons.md:
#
#   1. --dart-define-from-file=.env.prod.json (Rule #84). A bare
#      --dart-define=FLAVOR=prod empties PLACES_KEY_PROD / RevenueCat / Sentry
#      and ships a DOA binary. Build 17 died exactly this way.
#   2. Debug symbols. Without them every production crash arrives as
#      `<redacted>` and costs a night to read. Session 48 paid ~5 hours for this.
#
# Usage:
#   export SENTRY_AUTH_TOKEN=...        # scopes: project:releases, org:read
#   scripts/release/build_prod.sh                  # both platforms
#   scripts/release/build_prod.sh ios              # iOS only
#   scripts/release/build_prod.sh android          # Android only
#   scripts/release/build_prod.sh ios --no-upload  # build, skip Sentry
#   scripts/release/build_prod.sh all --skip-build # upload/preserve existing artifacts
#
# --skip-build exists because the upload can fail after a 20-minute build; there
# is no reason to rebuild identical bits to retry it. It verifies the on-disk
# archive still matches pubspec before trusting it.
#
# NOTE: run this WITHOUT piping to `tail`/`head`. The script relies on a
# non-zero exit, and a pipeline reports the LAST command's status, which masks
# a failure as success unless the caller also sets pipefail.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
REPO_ROOT="$(pwd)"

RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RST=$'\033[0m'
die()  { echo "${RED}✗ $*${RST}" >&2; exit 1; }
ok()   { echo "${GRN}✓ $*${RST}"; }
warn() { echo "${YLW}! $*${RST}"; }
step() { echo; echo "── $* ─────────────────────────────────────────"; }

TARGET="${1:-all}"
UPLOAD=1
SKIP_BUILD=0
for arg in "$@"; do
  case "$arg" in
    --no-upload)  UPLOAD=0 ;;
    --skip-build) SKIP_BUILD=1 ;;
  esac
done
case "$TARGET" in ios|android|all|--no-upload|--skip-build) ;; *) die "unknown target '$TARGET' (want: ios | android | all)";; esac
case "$TARGET" in --no-upload|--skip-build) TARGET=all ;; esac

# ── Preflight ───────────────────────────────────────────────────────────────
step "Preflight"

[ -f .env.prod.json ] || die ".env.prod.json missing — Rule #84: a build without it is DOA (empty Places/RevenueCat/Sentry keys)."

# These are the exact keys whose emptiness made build 17 dead on arrival: an
# empty value still produces a command line that looks correct, so check the
# values rather than the flag. APP_CHECK_DEBUG_TOKEN_ANDROID is intentionally
# NOT required — it is only read on the dev flavor (main.dart:102-106); prod
# uses AndroidPlayIntegrityProvider and leaves it empty.
python3 - <<'PY' || exit 1
import json, sys
REQUIRED = ['PLACES_KEY_PROD', 'REVENUECAT_APPLE_API_KEY',
            'REVENUECAT_GOOGLE_API_KEY', 'SENTRY_DSN']
try:
    env = json.load(open('.env.prod.json'))
except Exception as e:
    print(f"  .env.prod.json is not valid JSON: {e}"); sys.exit(1)
missing = [k for k in REQUIRED if str(env.get(k, '')).strip() == '']
if missing:
    print(f"  empty/missing required keys: {', '.join(missing)}")
    print("  Rule #84: this ships a DOA binary (dead gym search / silent IAP / no telemetry).")
    sys.exit(1)
if env.get('FLAVOR') != 'prod':
    print(f"  FLAVOR is {env.get('FLAVOR')!r}, expected 'prod'"); sys.exit(1)
print(f"  .env.prod.json: FLAVOR=prod, {len(REQUIRED)} required keys non-empty")
PY
ok ".env.prod.json validated"

# pubspec.yaml is the single source of truth for the version. Never hardcode
# versionCode in android/local.properties — that caused Play Store
# versionCode-1 rejections in the past.
VERSION_LINE=$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')
APP_VERSION="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"
[ -n "$APP_VERSION" ] && [ -n "$BUILD_NUMBER" ] || die "could not parse version from pubspec.yaml"
ok "pubspec version: $APP_VERSION+$BUILD_NUMBER"

if [ -n "$(git status --porcelain)" ]; then
  warn "working tree is dirty — the build will not be reproducible from a commit"
fi

# The SDK derives its release as <bundleId>@<version>+<build> and dist as
# <build> (confirmed on live event TREMBLE-FUNCTIONS-Q). The plugin would
# otherwise default to pubspec name@version ('tremble@...'), which does not
# match what the crashes are tagged with.
BUNDLE_ID="tremble.dating.app"
SENTRY_RELEASE="${BUNDLE_ID}@${APP_VERSION}+${BUILD_NUMBER}"
SENTRY_DIST="${BUILD_NUMBER}"
ok "sentry release: $SENTRY_RELEASE (dist $SENTRY_DIST)"

if [ "$UPLOAD" = "1" ]; then
  [ -n "${SENTRY_AUTH_TOKEN:-}" ] || die "SENTRY_AUTH_TOKEN unset. Mint one at https://aleksandar-bojic.sentry.io/settings/auth-tokens/ (scopes: project:releases, org:read), or pass --no-upload."
  ok "SENTRY_AUTH_TOKEN present"
else
  warn "--no-upload: symbols will be built but NOT uploaded"
fi

SYMROOT="build/symbols"
ARCHIVE="build/ios/archive/Runner.xcarchive"
PRESERVE="release-symbols/b${BUILD_NUMBER}"

# ── Build ───────────────────────────────────────────────────────────────────
# --save-obfuscation-map is what turns Sentry issue titles from `lM: Cancelled`
# into real type names. --split-debug-info alone does not do it.
build_ios() {
  step "Building iOS IPA ($APP_VERSION+$BUILD_NUMBER)"
  rm -rf "$SYMROOT/ios"; mkdir -p "$SYMROOT/ios"
  flutter build ipa --release --flavor prod \
    --dart-define-from-file=.env.prod.json \
    --obfuscate --split-debug-info="$SYMROOT/ios" \
    --extra-gen-snapshot-options=--save-obfuscation-map="$REPO_ROOT/$SYMROOT/ios/obfuscation_map.json" \
    --export-options-plist=ios/ExportOptions.plist

  # A stale archive silently yields symbols for the wrong build — the failure
  # mode is invisible until an incident, so fail loudly here instead.
  local archived
  archived=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$ARCHIVE/Info.plist" 2>/dev/null || echo "")
  [ "$archived" = "$BUILD_NUMBER" ] || die "archive CFBundleVersion is '$archived', expected '$BUILD_NUMBER' — stale build/ios/archive"
  [ -d "$ARCHIVE/dSYMs" ] || die "no dSYMs in $ARCHIVE — nothing to symbolicate with"
  ok "iOS archive verified: build $archived, $(ls -1 "$ARCHIVE/dSYMs" | wc -l | tr -d ' ') dSYMs"
}

build_android() {
  step "Building Android AAB ($APP_VERSION+$BUILD_NUMBER)"
  rm -rf "$SYMROOT/android"; mkdir -p "$SYMROOT/android"
  flutter build appbundle --release --flavor prod \
    --dart-define-from-file=.env.prod.json \
    --obfuscate --split-debug-info="$SYMROOT/android"

  local aab
  aab=$(find build/app/outputs/bundle -name "*-release.aab" 2>/dev/null | head -1) || true
  [ -n "$aab" ] || die "no AAB produced"
  ok "Android AAB built"
  verify_android_version "$aab"
}

# Guard against shipping a duplicate/lower versionCode, which Play Store rejects
# only after a full upload round-trip. The chain is: `flutter build` rewrites
# android/local.properties' flutter.versionCode from pubspec
# (gradle_utils.dart:1168), then Gradle reads it back (FlutterPlugin.kt:130 —
# note it defaults to "1" when the key is ABSENT, so those lines must exist and
# must never be hand-edited). This function checks the bundle itself when
# bundletool is available, and otherwise checks the value Gradle actually
# resolved. It never aborts the build on its own failure to read — a guard that
# cannot read is a reason to warn, not to throw away a good build.
verify_android_version() {
  local aab="$1" vc=""

  if command -v bundletool >/dev/null 2>&1; then
    vc=$(bundletool dump manifest --bundle="$aab" --xpath=/manifest/@android:versionCode 2>/dev/null | tr -dc '0-9') || vc=""
    [ -n "$vc" ] && ok "AAB manifest versionCode: $vc (read from the bundle)"
  fi

  if [ -z "$vc" ]; then
    vc=$(grep -E '^flutter\.versionCode=' android/local.properties 2>/dev/null | cut -d= -f2 | tr -dc '0-9') || vc=""
    [ -n "$vc" ] && warn "bundletool absent — checked the versionCode Gradle resolved ($vc), not the bundle manifest itself"
  fi

  if [ -z "$vc" ]; then
    warn "could not determine versionCode — verify manually before any Play upload"
    return 0
  fi
  [ "$vc" = "$BUILD_NUMBER" ] || die "versionCode is '$vc', expected '$BUILD_NUMBER' — Play Store would reject this"
  ok "Android versionCode $vc matches pubspec"
}

# ── Sentry upload ───────────────────────────────────────────────────────────
# One scoped pass per platform. symbols_path is narrowed each time so the
# dart-symbol-map collector cannot pair one platform's obfuscation map with the
# other platform's debug ID (see the comment in pubspec.yaml).
upload_ios() {
  step "Uploading iOS symbols to Sentry"
  local map_arg=()
  if [ -f "$SYMROOT/ios/obfuscation_map.json" ]; then
    map_arg=(--sentry-define=dart_symbol_map_path="$SYMROOT/ios/obfuscation_map.json")
  else
    warn "no iOS obfuscation map — Dart issue titles will stay obfuscated"
  fi
  SENTRY_RELEASE="$SENTRY_RELEASE" SENTRY_DIST="$SENTRY_DIST" \
    dart run sentry_dart_plugin \
      --sentry-define=symbols_path="$SYMROOT/ios" \
      "${map_arg[@]}"
  ok "iOS symbols uploaded"
}

upload_android() {
  step "Uploading Android symbols to Sentry"
  # No dart_symbol_map_path: the collector would pair it with the iOS
  # App.framework.dSYM still sitting in build/ios. A wrong map is worse than
  # none — it renames types incorrectly, exactly when you are reading a crash.
  SENTRY_RELEASE="$SENTRY_RELEASE" SENTRY_DIST="$SENTRY_DIST" \
    dart run sentry_dart_plugin \
      --sentry-define=symbols_path="$SYMROOT/android"
  ok "Android symbols uploaded"
}

# ── Preserve ────────────────────────────────────────────────────────────────
# release-symbols/ is gitignored. Keeping the dSYMs means a future incident on
# this build is readable even after `flutter clean`. Build 23's dSYMs survived
# only by luck.
preserve() {
  step "Preserving build $BUILD_NUMBER artifacts"
  mkdir -p "$PRESERVE"
  if [ -d "$SYMROOT/ios" ];     then mkdir -p "$PRESERVE/ios";     cp -R "$SYMROOT/ios/."     "$PRESERVE/ios/"; fi
  if [ -d "$SYMROOT/android" ]; then mkdir -p "$PRESERVE/android"; cp -R "$SYMROOT/android/." "$PRESERVE/android/"; fi
  if [ -d "$ARCHIVE/dSYMs" ]; then
    mkdir -p "$PRESERVE/ios-dsyms"
    cp -R "$ARCHIVE/dSYMs/." "$PRESERVE/ios-dsyms/"
    if [ -d "$PRESERVE/ios-dsyms/Runner.app.dSYM" ]; then
      echo "  Runner.app.dSYM $(dwarfdump --uuid "$PRESERVE/ios-dsyms/Runner.app.dSYM" 2>/dev/null | head -1 | awk '{print $2}')"
    fi
  fi
  find build -maxdepth 4 \( -name "*.ipa" -o -name "*-release.aab" \) -exec cp {} "$PRESERVE/" \; 2>/dev/null || true
  ok "preserved to $PRESERVE ($(du -sh "$PRESERVE" | cut -f1))"
}

# ── Run ─────────────────────────────────────────────────────────────────────
if [ "$SKIP_BUILD" = "1" ]; then
  step "Skipping build — verifying the artifacts already on disk"
  archived=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$ARCHIVE/Info.plist" 2>/dev/null || echo "")
  [ "$archived" = "$BUILD_NUMBER" ] || die "on-disk archive is build '$archived', expected '$BUILD_NUMBER' — rebuild instead of uploading stale symbols"
  ok "on-disk archive is build $archived"
  aab=$(find build/app/outputs/bundle -name "*-release.aab" 2>/dev/null | head -1) || true
  [ -n "$aab" ] && verify_android_version "$aab"
fi

case "$TARGET" in
  ios)
    [ "$SKIP_BUILD" = "1" ] || build_ios
    [ "$UPLOAD" = "1" ] && upload_ios ;;
  android)
    [ "$SKIP_BUILD" = "1" ] || build_android
    [ "$UPLOAD" = "1" ] && upload_android ;;
  all)
    if [ "$SKIP_BUILD" != "1" ]; then build_ios; build_android; fi
    if [ "$UPLOAD" = "1" ]; then upload_ios; upload_android; fi
    ;;
esac

preserve

step "Done"
echo "  version : $APP_VERSION+$BUILD_NUMBER"
echo "  release : $SENTRY_RELEASE"
echo "  symbols : $PRESERVE"
echo
echo "Next: verify Sentry lists debug files for dist $SENTRY_DIST BEFORE uploading to TestFlight."
echo "  https://aleksandar-bojic.sentry.io/settings/projects/tremble-functions/debug-symbols/"
