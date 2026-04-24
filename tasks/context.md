- Active Task: Plan 20260424-UI-Icon-Stability (PARTIALLY EXECUTED — context handoff)
- Environment: Dev (Android/iOS)
- Modified Files: notification_service.dart, proximity.functions.ts, flutter_native_splash.yaml, Logo/tremble_splash_source.png, all Android/iOS splash drawables, CLAUDE.md
- Open Problems: ADR-001 (iOS BLE background) | UI-Icon-Stability plan 50% done
- System Status: Build passing. Splash fixed. Launcher icons + UI code fixes NOT YET DONE.

---

## Session Handoff — 2026-04-24 (Context limit — mid-plan)

### What Was Done This Session
| Item | Fix | Status |
|------|-----|--------|
| BUILD-001 | notification_service.dart — const DarwinInitializationSettings fix | ✅ Committed |
| BUILD-002 | proximity.functions.ts — imageUrl key + remove haversineDistance | ✅ Committed |
| SPLASH-001 | Splash logo — replaced white transparent with rose icon at 50% canvas | ✅ Committed |

### Plan 20260424-UI-Icon-Stability — REMAINING ITEMS
All items below are DIAGNOSED but NOT YET executed. Resume with this exact knowledge:

#### 1. Launcher Icons (HIGHEST PRIORITY)
**Problem:** `flutter_launcher_icons.yaml` uses `tremble_icon_clean_transparent.png` for both
`image_path` and `adaptive_icon_foreground` → white outline on dark bg → monochrome in app switcher.
**Fix:**
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "Logo/tremble_icon_clean.png"
  adaptive_icon_background: "#1A1A18"
  adaptive_icon_foreground: "Logo/tremble_splash_source.png"
```
Then run: `flutter pub run flutter_launcher_icons:main`

#### 2. Radar Pulse Radius
**File:** `lib/src/shared/widgets/radar_painter.dart` line 24
**Fix:** Change `size.width * 0.45` → `size.width * 0.5`

#### 3. Matches Screen Title/? Overlap
**File:** `lib/src/features/matches/presentation/matches_screen.dart` lines 121-162
**Problem:** Centered title `Text` in Stack + `Positioned(right:0)` with helpCircle+pencil buttons (combined ~93px wide) overlap.
**Fix:** Wrap the centered title Text in `Padding(padding: EdgeInsets.symmetric(horizontal: 100))` or add `maxWidth` constraint.

#### 4. Card Open Animation
**File:** `lib/src/features/dashboard/presentation/home_screen.dart` lines 264-287
**Problem:** `AnimatedSwitcher` with `FadeTransition + ScaleTransition(0.98→1.0)` on tab switches.
**Decision needed:** Remove scale (keep fade only) OR remove both. Need to also check GoRouter push transition for `/profile` route in `router.dart` — not yet read.

### Open Blockers
- ADR-001: iOS BLE background state restoration — not yet implemented
- BLOCKER-003: Legal/RevenueCat — Phase 8 on hold (AMS Solutions d.o.o. unregistered)
- D-37: Map toggle test — pending Martin on Samsung S25 Ultra

### Next Action
Resume Plan 20260424-UI-Icon-Stability with: `/gsd:autonomous`
Start with launcher icons fix (item 1 above), then items 2-4 in order.

### Resume Command
/gsd:autonomous

---

## Phase 1 & 2: Registration Resilience ✅ COMPLETE

| Item | Status |
|------|--------|
| Checkpoint | ✅ `onboardingCheckpoint` in Firestore |
| Auth Loop  | ✅ router.dart allows drafts to resume /onboarding |
| Signal Calibration | ✅ Hardware Rebrand, zero-writing policy, Signal Lock |
| Dedup (007) | ✅ Upstash Redis rate-limiting |

---

- **Security Update**: Phase 11 complete. Cloud Functions deployed to `tremble-dev`.
- **Infrastructure**: `.firebaserc` aliases `dev` and `prod` strictly mapped.
- **Privacy Fix**: SEC-002 resolved. lat/lng removed from proximity writes. Deployed dev + prod 2026-04-24.
- **Prod Firestore**: Full rules (users, drafts, matches, waves, proximity, proximity_events, rateLimits, idempotencyKeys, gdprRequests, default deny) deployed to am---dating-app 2026-04-24.
- **Prod Backup**: Point-in-time recovery (7 days) + daily backup (7 days expiry) enabled 2026-04-24.
