---
plan: 06-03
status: complete
tasks_completed: 2/2
commits:
  - bff2a45: "chore(06-03): gitignore iOS xcconfig files and untrack from git"
  - 3d5ca80: "feat(06-03): inject MAPS_API_KEY via CI for all platform build targets"
human_checkpoint: verified (key confirmed active, GitHub secret added; map screen test deferred)
---

# 06-03 Summary — Maps API Key Wiring

## What was done

**Task 1 — Wire MAPS_API_KEY to iOS Release.xcconfig:**
- Discovered that both `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` were tracked in git — Debug.xcconfig already contained the real key (pre-existing security gap)
- Added both xcconfig files to `.gitignore` and untracked them via `git rm --cached`
- Wrote MAPS_API_KEY into `ios/Flutter/Release.xcconfig` (local only, never committed)
- Committed only the `.gitignore` change

**Human checkpoint — Aleksandar verified:**
- Key `REVOKED_KEY_REMOVED` confirmed active in Google Cloud Console
- Maps SDK for iOS and Maps SDK for Android confirmed enabled
- `MAPS_API_KEY` added as GitHub Actions repository secret
- Map screen test on device deferred (will be done later)

**Task 2 (added scope) — CI secret injection:**
- Created `scripts/ci/setup_maps_key.sh` — writes key into all three platform files (Debug.xcconfig, Release.xcconfig, android/local.properties) from the `MAPS_API_KEY` CI secret
- Wired the step into `ci.yml` (Flutter job) and `deploy.yml` (build-apk job)
- Graceful fallback to placeholder key with warning if secret is unset

## Requirements satisfied
- BRAND-05: Maps API key wired on all platforms for all build variants ✓

## Notes
- Pre-existing: `ios/Flutter/Debug.xcconfig` was committed with real key before this plan. Now untracked.
- Map screen render test (map tiles visible) still pending — to be done on next device test run.
