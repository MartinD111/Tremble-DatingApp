# Plan: F10 — Gym Mode

**Plan ID:** 20260429-f10-gym-mode
**Date:** 2026-04-29
**Status:** ✅ IMPLEMENTED & DEPLOYED (tremble-dev)
**Risk Level:** HIGH
**Founder Approval:** GRANTED (manual flow, geolocator, no background geofencing)
**Branch:** main

---

## 1. OBJECTIVE

Users manually activate Gym Mode by selecting a gym. The backend validates they are
within 200m via haversine. Sessions auto-expire after 2 hours (server-side scheduler).
Users who share the same `activeGymId` at wave time receive `matchType: "gym"` on their
match document.

---

## 2. APPROVED DECISIONS

| Decision | Choice | Rationale |
|---|---|---|
| Geofencing library | `geolocator` (already in pubspec) | Free, no license; one-shot position fetch is sufficient |
| Trigger mechanism | Manual only — NO passive background geofencing | MVP scope, battery safety |
| Activation flow | Tap dumbbell → select gym → GPS fetch → backend validates → active | Explicit user intent |
| Session TTL | 2 hours hard limit | Server-side `gymModeUntil` Timestamp; hourly scheduler cleans up |
| Deactivation | Manual OR auto-expire | Both paths clear `activeGymId` + `gymModeUntil` |
| Radius | 200m default; overridable per gym via `radiusMeters` field | Configurable without redeploy |

---

## 3. ARCHITECTURE

### Firestore Schema

```
gyms/{gymId}
  name:          string
  address:       string
  placeId:       string           // Google Places ID (future enrichment)
  location:      { lat, lng }     // WGS84
  radiusMeters:  number           // default 200

users/{uid}
  activeGymId:   string | null
  gymModeUntil:  Timestamp | null
```

### Match Type Priority

```
event > gym > standard
```

When `onWaveCreated` fires and both users share `activeGymId`:
```typescript
matchType = "gym"
matchContext = { gymId: "<id>" }
```

---

## 4. IMPLEMENTATION

### Backend — `functions/src/modules/gym/gym.functions.ts`

| Export | Type | Description |
|---|---|---|
| `onGymModeActivate` | `onCall` | Validates gymId + haversine proximity (≤ radiusMeters), sets `activeGymId` + `gymModeUntil` |
| `onGymModeDeactivate` | `onCall` | Clears `activeGymId` + `gymModeUntil` for current user |
| `expireGymSessions` | `onSchedule` (every 60 min) | Batch-clears expired sessions |

### Backend — `functions/src/modules/matches/matches.functions.ts`

Gym match type detection added after event check:

```typescript
const userAGym = userADoc.data()?.activeGymId;
const userBGym = userBDoc.data()?.activeGymId;

} else if (userAGym && userBGym && userAGym === userBGym) {
    matchType = "gym";
    matchContext = { gymId: userAGym };
}
```

### Flutter

| File | Role |
|---|---|
| `lib/src/features/gym/data/gym_repository.dart` | Firestore `gyms/` read; `onGymModeActivate` / `onGymModeDeactivate` via `TrembleApiClient` |
| `lib/src/features/gym/application/gym_mode_controller.dart` | Riverpod `StateNotifier` — states: inactive / loading / active / error; friendly error mapping |
| `lib/src/features/gym/presentation/gym_mode_sheet.dart` | DraggableScrollableSheet with gym list, active banner, deactivate button, distance error display |
| `lib/src/features/dashboard/presentation/home_screen.dart` | Replaced mock Event Mode icon with `_GymModeButton` (dumbbell + green dot when active) |

---

## 5. DEPLOYMENT STATUS

- [x] `npm run build` — TypeScript compiled, `functions/lib/modules/gym/` created
- [x] `firebase deploy --only functions --project tremble-dev` — all 3 gym functions live
- [x] `flutter analyze` — clean (0 issues)
- [x] `dart format` — clean
- [x] `git commit 0584a38` — `feat(f10): Gym Mode — manual check-in via geolocator + 2h auto-expire`
- [x] `git push` → `main`

---

## 6. REMAINING WORK (next session)

### P0 — Required before device test

1. **Seed `gyms` Firestore collection** (Firebase Console or script):

```json
{
  "name": "FitInn Ljubljana",
  "address": "Šmartinska cesta 53, Ljubljana",
  "placeId": "ChIJxxxx",
  "location": { "lat": 46.0569, "lng": 14.5058 },
  "radiusMeters": 200
}
```

2. **Device test checklist:**
   - [ ] Radar tab → dumbbell icon visible (top-left)
   - [ ] GymModeSheet opens, gym list loads from Firestore
   - [ ] GPS fetch and `onGymModeActivate` call succeed when at gym
   - [ ] Green dot appears on dumbbell icon when active
   - [ ] "Not at gym location" error shown when >200m away
   - [ ] Deactivate button clears state on both client and server
   - [ ] Auto-expire: after `gymModeUntil` passes, next app open shows inactive state

### P1 — Follow-up features

| Item | Description |
|---|---|
| Gym match badge in `matches_screen.dart` | Render gym icon badge on matches with `matchType: "gym"` (same pattern as event) |
| Places API gym search | Replace pre-seeded list with live gym search via Google Places API |
| `gym_mode_until` timer in UI | Show countdown / "Active for X more minutes" in the gym sheet |

---

## 7. KNOWN LIMITATIONS (MVP)

| Limitation | Impact | Planned fix |
|---|---|---|
| No real gym data — requires manual seeding | Empty list without seed docs | Admin panel or Places API search in v2 |
| No Places API integration | User can only select from pre-seeded list | F10 v2 |
| No gym badge in `matches_screen.dart` | Gym matches look like standard matches visually | Follow-up task (P1) |
| iOS location permission stays "When In Use" | Fine — activation requires app to be open | Not needed for this flow |

---

## 8. RISKS RESOLVED

| Risk | Resolution |
|---|---|
| Battery drain | No background geofencing — manual check-in only |
| Simulator testing | Proximity check is server-side; can override coords in dev for testing |
| App Check enforcement | `ENFORCE_APP_CHECK` applied to both activate and deactivate functions |
| Background location permission (iOS/Android) | Not required — `geolocator` with "When In Use" is sufficient |
