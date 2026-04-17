---
phase: 07-wave-mechanic-push
plan: 01
subsystem: backend+mobile
tags: [wave, match, push-notifications, fcm, apns, firebase-messaging, cloud-functions, riverpod]

requires: [06-brand-alignment-wave-mechanic]
provides:
  - "WaveRepository.sendWave() — direct Firestore write to waves/ collection"
  - "onWaveCreated Cloud Function — mutual detection → match creation → FCM dispatch"
  - "match_service.dart — 30-minute session constraint with stream-based match detection"
  - "NotificationService — FCM foreground/background handler (firebase_messaging)"
  - "ProximityPingController — RSSI-based vibration ping loop (mutual-only)"
  - "match_reveal_screen.dart — brand-aligned match reveal with partner profile"
affects:
  - "dashboard — radar_search_overlay wired to WaveRepository"
  - "matches — activeMatchesStreamProvider from Firestore"
  - "notification_service — all 3 notification types live"

tech-stack:
  added:
    - firebase_messaging (FCM + APNs)
    - flutter_local_notifications
    - vibration
  patterns:
    - "Wave mechanic: one-tap sendWave() → server-side mutual detection (no client-side confirmation)"
    - "Match session: 30-minute expiry enforced in match_service.dart currentSearchProvider"
    - "Privacy: unidirectional interest hidden — INCOMING_WAVE notification has no sender identity"
    - "ProximityPingController: EMA-smoothed RSSI → vibration interval (200ms–4000ms)"

key-files:
  created:
    - lib/src/features/match/data/wave_repository.dart
    - lib/src/features/match/application/match_service.dart
    - lib/src/features/match/presentation/match_reveal_screen.dart
    - lib/src/features/match/presentation/widgets/match_background_animation.dart
    - lib/src/features/match/domain/match.dart
    - lib/src/features/match/domain/wave.dart
    - lib/src/features/dashboard/application/proximity_ping_controller.dart
    - lib/src/core/notification_service.dart
    - functions/src/modules/matches/matches.functions.ts
  modified:
    - lib/src/features/dashboard/presentation/home_screen.dart
    - lib/src/features/dashboard/presentation/widgets/radar_search_overlay.dart

key-decisions:
  - "No in-app chat — ever. Match reveal is the final in-app step. IRL meeting is the product."
  - "Wave send has no confirmation dialog — one tap triggers sendWave() directly"
  - "INCOMING_WAVE notification carries no sender name/photo — unidirectional privacy enforced"
  - "Background wave-back via FCM action button (WAVE_BACK_ACTION) without opening app"
  - "PUSH-03 (24h inactivity) removed — obsolete since chat mechanic never existed"

requirements-completed: [WAVE-01, WAVE-02, WAVE-03, WAVE-04, WAVE-05, WAVE-06, PUSH-01, PUSH-02, PUSH-04, PUSH-05]

note: "Phase executed outside GSD planning framework — no PLAN files created. Implementation delivered as Interaction System v2.1 + iOS Notification Service Extension. SUMMARY reconstructed 2026-04-18 from code inspection."

duration: "~1 day (2026-04-09)"
completed: 2026-04-09
---

# Phase 7: Wave Mechanic + Push Notifications — Summary

**Phase shipped:** 2026-04-09  
**Note:** Executed outside GSD framework. This SUMMARY reconstructed 2026-04-18 from direct code inspection and ROADMAP notes.

## What Was Delivered

### Wave Mechanic (WAVE-01 through WAVE-06)

**`WaveRepository.sendWave(targetUid)`**
- Direct Firestore write to `waves/` collection
- No confirmation dialog — one tap (WAVE-02 ✅)
- `waves` collection: `{fromUid, toUid, createdAt}`

**`onWaveCreated` Cloud Function (`matches.functions.ts`)**
- Triggers on `waves/{waveId}` creation
- Checks for reciprocal wave: if B already waved A → mutual
- On mutual: creates `matches/{matchId}` doc in Firestore (WAVE-04 ✅)
- Sends `INCOMING_WAVE` to recipient (no sender identity — WAVE-03 ✅)
- Sends `MUTUAL_WAVE` to both (WAVE-05 ✅)

**`match_service.dart`**
- `activeMatchesStreamProvider` — real-time Firestore stream on `matches/` (WAVE-04 ✅)
- `currentSearchProvider` — 30-minute session constraint filter (`expiry = createdAt + 30min`)

**`match_reveal_screen.dart`**
- Glassmorphic brand animation (WAVE-06 ✅)
- Shows partner name, photo, bio (WAVE-05 ✅)

**`ProximityPingController`**
- EMA-smoothed RSSI → vibration frequency (200ms–4000ms interval)
- Only activates when `search.isMutual == true`
- `setHighFrequencyMode(true)` during active search

### Push Notifications (PUSH-01, PUSH-02, PUSH-04, PUSH-05)

**`NotificationService`** (`notification_service.dart`)
- Firebase Messaging foreground + background handler
- `firebaseMessagingBackgroundHandler` — isolate-safe, direct Firestore write
- `WAVE_BACK_ACTION` — send reciprocal wave from notification without opening app

**Notification types wired:**
| Type | Trigger | Content | Req |
|------|---------|---------|-----|
| CROSSING_PATHS | `proximity.functions.ts` BLE event | "Someone nearby." — no name/photo | PUSH-01 ✅ |
| INCOMING_WAVE | `matches.functions.ts` one-sided wave | No sender identity, action button "Pomahaj nazaj" | PUSH-02 partial |
| MUTUAL_WAVE | `matches.functions.ts` mutual wave | Deep link to /radar, matchId payload | PUSH-02 ✅ |

No marketing notifications, no gamification, no "see who liked you" (PUSH-04 ✅)

**FCM + APNs:** `firebase_messaging` configured, `notification_service.dart` initialises on app start (PUSH-05 ✅)

**PUSH-03:** Closed as N/A — obsolete (references "no chat started"; in-app chat was removed per Rule #3).

## Verification Gates

| Gate | Status |
|------|--------|
| `flutter analyze` | ✅ 0 issues (per context.md 2026-04-18) |
| Wave → Firestore write | ✅ WaveRepository confirmed |
| Mutual detection server-side | ✅ matches.functions.ts:58 |
| Match created on mutual | ✅ matches.functions.ts:75 |
| 30-min session constraint | ✅ match_service.dart:29-31 |
| No sender identity in INCOMING_WAVE | ✅ code comment + design decision |
| FCM background handler isolate-safe | ✅ `@pragma('vm:entry-point')` |

## Known Deferred Items

- Map screen tile rendering — deferred physical device test (from Phase 6, BRAND-05)
- `npm run build` clean for latest functions — needs `firebase deploy --only functions --project tremble-dev` (pending since 2026-04-18)
