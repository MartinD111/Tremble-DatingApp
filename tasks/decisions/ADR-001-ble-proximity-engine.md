# ADR-001: BLE Proximity Discovery Engine

Date: 2026-03-10  
Status: Implemented / Resolved
Implemented In: `lib/src/core/background_service.dart`, `lib/src/core/ble_service.dart`, native `NativeMotionService` EventChannel bridge
Risk Level: HIGH  
Requires Founder Approval: YES

---

## Context

Tremble's core value proposition is **passive proximity discovery**: users must be discoverable to each other in the background, without actively opening the app.

Original issue: `background_service.dart` contained a mock timer that randomly simulated matches every 15 seconds. No actual BLE or geolocation scanning was present.

Current status as of 2026-05-25: ADR-001 is resolved. `background_service.dart` uses the NativeMotionService EventChannel bridge for real motion/proximity behavior. The remaining timer usage is for battery/idle notification behavior, not proximity simulation.

We need a real discovery engine that:
- Runs in the background on iOS and Android
- Detects other Tremble users nearby via BLE
- Reports discovered users to Firebase without UI interaction
- Respects iOS background execution limits

---

## Options Evaluated

### Option A: BLE-only Discovery (flutter_blue_plus)
- Advertise a static UUID as "I am a Tremble user"
- Scan for other devices broadcasting that UUID
- **Pro:** Works at close range (0–30m), very battery-efficient
- **Con:** iOS limits BLE advertising/scanning in background (CBCentralManager foreground-only after ~180s)

### Option B: Geolocation-only (geolocator + Firebase)
- Periodically upload GPS coordinates, query nearby users server-side via Geohash
- **Pro:** Works always in background, long range
- **Con:** Drains battery, no "physical proximity" guarantee, can match people across floors

### Option C: Hybrid BLE + Geo (Recommended)
- **BLE** for precise physical proximity (≤30m) — primary trigger
- **Geolocation** for coarse area matching and server-side filtering — secondary filter
- **Pro:** Accurate proximity, battery-aware, real passive experience
- **Con:** More complex implementation

---

## Decision

**Use Option C — Hybrid BLE + Geo.**

- `flutter_blue_plus` for BLE advertising and scanning
- `geolocator` for background GPS coordinates uploaded to Firestore
- `flutter_background_service` as the iOS/Android background isolate host
- Firebase Cloud Functions for server-side proximity filtering

---

## Architecture

```
Background Isolate (flutter_background_service)
  ├── BLE Scanner (flutter_blue_plus)
  │     └── Detects nearby Tremble UUIDs
  │           └── Reports deviceId → Firebase Cloud Function: onBleProximity
  └── Geo Updater (geolocator)
        └── Uploads GPS every 60s → Firestore: users/{uid}/location

Cloud Function: onBleProximity
  └── Validates mutual proximity (both users reported each other)
        └── Creates match candidate → notifies both users via FCM
```

---

## iOS Constraints & Mitigation

| iOS Limit | Mitigation |
|-----------|-----------|
| BLE background scan stops after ~180s when app is suspended | Use `flutter_background_service` foreground service + Core Bluetooth state restoration |  
| No foreground service on iOS | Use `iosConfiguration.onForeground` to keep scanning when app is in foreground |
| Background location needs "Always" permission | Use `permission_handler` to request `LocationAlways` on settings screen |

---

## Consequences

- ADR superseded the mock proximity timer in `background_service.dart`
- Native configuration changes were completed during the BLE / NativeMotionService integration
- Firestore proximity storage remains privacy-minimized and time-limited
- Keep physical iOS verification tied to `BLOCKER-005` provisioning status
