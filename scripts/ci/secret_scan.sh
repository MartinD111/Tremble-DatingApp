#!/bin/bash
# scripts/ci/secret_scan.sh
# Scans the codebase for accidentally committed secrets.
# Runs in CI (GitHub Actions) and locally before commits.
# Exit code 1 = secrets found (blocks CI). Exit code 0 = clean.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
FOUND=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Tremble Secret Scan"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Gitleaks (preferred) ───────────────────────────────
if command -v gitleaks &>/dev/null; then
  echo "[gitleaks] Running full scan..."
  if ! gitleaks detect \
    --source "$REPO_ROOT" \
    --config "$REPO_ROOT/.gitleaks.toml" \
    --exit-code 1 \
    --no-banner \
    --redact \
    2>&1; then
    echo "[gitleaks] FAILED — secrets detected."
    FOUND=1
  else
    echo "[gitleaks] Clean ✅"
  fi
else
  echo "[gitleaks] Not installed — falling back to pattern scan."
  echo "           Install: brew install gitleaks"
fi

# ── 2. Pattern scan (always runs as belt-and-suspenders) ─
echo ""
echo "[patterns] Scanning tracked files for secret patterns..."

# Files tracked by git (no untracked, no ignored)
TRACKED_FILES=$(git -C "$REPO_ROOT" ls-files)

# Patterns that indicate a real secret (not comments or examples)
SECRET_PATTERNS=(
  # Firebase / Google service keys
  'AIzaSy[A-Za-z0-9_-]{33}'
  # Generic API key assignments
  'api[_-]?key\s*[=:]\s*["'"'"'][A-Za-z0-9_\-]{20,}'
  # Resend API keys
  're_[A-Za-z0-9_]{30,}'
  # AWS / Cloudflare R2 secret keys (64-char hex)
  '[A-Fa-f0-9]{64}'
  # Generic bearer tokens
  'Bearer\s+[A-Za-z0-9\-._~+/]+=*'
  # Private keys
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
  # Upstash / Redis URLs with password
  'redis://[^@]+:[^@]+@'
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  # Search only tracked files; skip binary files
  matches=$(echo "$TRACKED_FILES" | xargs grep -rlP "$pattern" 2>/dev/null \
    --include="*.dart" \
    --include="*.ts" \
    --include="*.js" \
    --include="*.json" \
    --include="*.yaml" \
    --include="*.yml" \
    --include="*.sh" \
    --include="*.md" \
    --include="*.xcconfig" \
    --include="*.plist" \
    --include="*.properties" \
    || true)

  if [[ -n "$matches" ]]; then
    echo "[patterns] MATCH for pattern: $pattern"
    echo "$matches" | while read -r file; do
      echo "           → $file"
    done
    FOUND=1
  fi
done

if [[ $FOUND -eq 0 ]]; then
  echo "[patterns] Clean ✅"
fi

# ── 3. Known-bad file names check ────────────────────────
echo ""
echo "[filenames] Checking for tracked secret files..."

BLOCKED_FILES=(
  "functions/.env"
  "functions/.env.dev"
  "functions/.env.prod"
  "GoogleService-Info.plist"
  "google-services.json"
  "lib/src/core/firebase_options_dev.dart"
  "lib/src/core/firebase_options_prod.dart"
  "ios/Flutter/Debug.xcconfig"
  "ios/Flutter/Release.xcconfig"
  "android/local.properties"
  ".env"
)

for blocked in "${BLOCKED_FILES[@]}"; do
  if git -C "$REPO_ROOT" ls-files --error-unmatch "$blocked" &>/dev/null 2>&1; then
    echo "[filenames] TRACKED (should be gitignored): $blocked"
    FOUND=1
  fi
done

if [[ $FOUND -eq 0 ]]; then
  echo "[filenames] Clean ✅"
fi

# ── Result ────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $FOUND -eq 1 ]]; then
  echo " SCAN FAILED — secrets or blocked files detected."
  echo " Fix the issues above before committing."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
else
  echo " SCAN PASSED — no secrets detected ✅"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi
