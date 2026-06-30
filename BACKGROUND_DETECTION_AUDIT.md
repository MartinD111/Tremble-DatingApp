# iOS Background Proximity Detection Audit

> **Date:** 2026-06-30  
> **Device:** iPhone 15, iOS 26  
> **Scope:** Does passive proximity detection survive app backgrounding on iOS?  
> **Status:** REPORT ONLY — no code changes

---

## Observed Symptoms

```
[BleService] Advertising stopped          ← on AppLifecycleState.paused
[FBP-iOS] handleMethodCall: stopScan      ← on AppLifecycleState.paused
[BleService] Advertising started          ← on AppLifecycleState.resumed
API MISUSE: <CBCentralManager> has no restore identifier but the delegate
implements centralManager:willRestoreState: — Restoring will not be supported
```

---

## Question 1: Where is BLE scan/advertise stopped on background?

### Answer: Intentional — `home_screen.dart:152-157`

```dart
// lib/src/features/dashboard/presentation/home_screen.dart, lines 151-157
void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      BleService().stop();                          // ← line 153
    } else if (state == AppLifecycleState.resumed) {
      BleService().start();                         // ← line 155
      ref.invalidate(bluetoothPermissionStatusProvider);
    }
  }
```

**This is explicit, intentional code.** `HomeScreen` is a `WidgetsBindingObserver` (registered in `initState` at line 104). When the app enters `paused` (backgrounded), it calls `BleService().stop()` which:

1. Sets `_isRunning = false` — ble_service.dart:68
2. Cancels the scan timer — ble_service.dart:70
3. Cancels the scan subscription — ble_service.dart:71
4. Cancels battery monitoring — ble_service.dart:72
5. Stops advertising via `flutter_ble_peripheral` — ble_service.dart:73
6. Stops scanning via `FlutterBluePlus.stopScan()` — ble_service.dart:74

**BLE (both scan and advertise) is fully torn down every time the app goes to the background.** When the user returns, `BleService().start()` re-initializes everything from scratch.

Additional call sites that stop BLE:
- Radar OFF toggle — home_screen.dart:419, home_screen.dart:1129
- High-frequency search mode end — home_screen.dart:1612

> **IMPORTANT:** BLE runs **only in the main Dart isolate**. The background service (`background_service.dart`) explicitly comments at line 12-17 that BleService is intentionally NOT imported because `flutter_blue_plus` requires an Android Activity (or iOS main engine) which the background isolate does not have.

---

## Question 2: Does GPS→geohash proximity survive backgrounding?

### VERDICT: **Background passive GPS detection WORKS via `GeoService` inside `flutter_background_service`**

### Execution trace:

```
User taps Radar ON
  → home_screen.dart:1088-1091   FlutterBackgroundService().startService()  [iOS path]
    → background_service.dart:108  @pragma('vm:entry-point') void onStart(ServiceInstance service)
      → background_service.dart:157  final geoService = GeoService();
      → background_service.dart:170-173  if (hasConsent) { await geoService.start(isPremium: ...); }
        → geo_service.dart:52-57  start() → _checkBatteryState() → _listenBatteryChanges() → _scheduleUpdate()
          → geo_service.dart:109-113  Timer.periodic(interval, (_) => _uploadLocation())
            → geo_service.dart:115-191  _uploadLocation():
              1. Geolocator.getCurrentPosition()
              2. SafeZone check
              3. GeoHasher().encode(lng, lat, precision: 7)  // ~150m x 75m cell
              4. Firestore.collection('proximity').doc(uid).set({ geohash, radiusTier, ... })
```

**Key facts:**

| Component | Runs in | Background? | File |
|-----------|---------|-------------|------|
| `GeoService` (GPS→geohash→Firestore) | Background isolate | ✅ YES | background_service.dart:157 |
| `BleService` (scan/advertise via FBP) | Main isolate only | ❌ NO — stopped on paused | home_screen.dart:153 |
| `BleRestoreBridge` (native CBCentralManager) | Native iOS process | ✅ YES — has restore ID | BleRestoreBridge.swift:21 |
| `MotionBridge` → Run Club | Main→background bridge | ✅ YES — motion events forwarded | motion_bridge.dart:32-37 |

### How the background GPS path works:

1. **`flutter_background_service`** spawns a **separate Dart isolate** on iOS via `BGTaskScheduler` (task identifier: `app.tremble.radar` — AppDelegate.swift:256, Info.plist:99).

2. This isolate runs `onStart()` (background_service.dart:108) which:
   - Initializes Firebase in the background isolate (line 118)
   - Creates a fresh `GeoService()` instance (line 157)
   - If GDPR consent exists, starts the geo update timer (line 171-173)

3. **`GeoService._uploadLocation()`** (geo_service.dart:115) runs on a `Timer.periodic`:
   - Normal mode: every **60 seconds** (line 38)
   - Low power (<20% battery): every **5 minutes** (line 39)
   - Each tick: `Geolocator.getCurrentPosition()` → geohash encode → Firestore `proximity/{uid}` write

4. The server-side `scanProximityPairs` Cloud Function reads `proximity` docs and detects when two users share a geohash cell, triggering FCM notifications.

### Caveat: iOS background execution limits

> **WARNING:** On iOS, `flutter_background_service` uses `BGAppRefreshTaskRequest` for background execution, NOT a persistent foreground service (that's Android-only via `isForegroundMode: true`). iOS grants BGAppRefresh approximately **every 15-30 minutes** depending on device usage patterns, battery state, and app priority. The 60s `Timer.periodic` inside `GeoService` only ticks during active BGTask windows, NOT continuously. Between BGTask wake-ups, the timer is suspended.
>
> This means the "phone in pocket" geo write cadence on iOS is realistically **15-30 min between updates**, not 60s. The 30-minute `_geoTtl` (geo_service.dart:47) means the proximity doc could expire between BGTask runs, causing the user to appear offline intermittently.

---

## Question 3: UIBackgroundModes in Info.plist

Info.plist lines 89-96:

| Mode | Present | Purpose |
|------|---------|---------|
| `location` | ✅ | Enables background GPS via `Geolocator` |
| `bluetooth-central` | ✅ | Enables background BLE scanning |
| `bluetooth-peripheral` | ✅ | Enables background BLE advertising |
| `fetch` | ✅ | Enables `BGAppRefreshTaskRequest` for `flutter_background_service` |
| `remote-notification` | ✅ | Enables silent push → FCM data messages |
| `processing` | ❌ ABSENT | Would allow `BGProcessingTaskRequest` for longer background execution |
| `audio` | ❌ ABSENT | Not needed |

Also present:
- `BGTaskSchedulerPermittedIdentifiers`: `["app.tremble.radar"]` — Info.plist:97-100

All three Bluetooth and location background modes are **correctly declared**.

---

## Question 4: CBCentralManager restoration identifier — intentional or gap?

### Two CBCentralManagers exist in the app:

| Manager | Owner | Has Restore ID | Implements `willRestoreState` | Background Scan |
|---------|-------|----------------|-------------------------------|-----------------|
| **BleRestoreBridge** (native Swift) | `BleRestoreBridge.swift` | ✅ `"app.tremble.ble.central"` | ✅ Line 121-129 | ✅ Scans for Tremble UUID |
| **flutter_blue_plus** (FBP plugin) | `FlutterBluePlusPlugin.m` | ❌ `restoreState` defaults to `NO` | ✅ Implemented but never called | ❌ No background scan |

### Source of the API MISUSE warning:

The warning `"<CBCentralManager> has no restore identifier but the delegate implements centralManager:willRestoreState:"` comes from **flutter_blue_plus's CBCentralManager**, NOT from BleRestoreBridge.

- FBP darwin 8.2.1 (FlutterBluePlusPlugin.m:130-132) only sets the restore identifier if `self.restoreState` is `YES`.
- FBP defaults `restoreState` to `NO` (FlutterBluePlusPlugin.m:72).
- The app never calls `FlutterBluePlus.setOptions(restoreState: true)`.
- FBP's `willRestoreState:` delegate method **exists** in the code (FlutterBluePlusPlugin.m:1092) even when restore is disabled, which is what triggers iOS's API MISUSE warning.

### Is this intentional?

**Partially.** The architecture is a **dual-manager design** (documented at BleRestoreBridge.swift:7-8):

- `BleRestoreBridge` (native Swift) **is the intended background BLE scanner**. It has the restore identifier, implements `willRestoreState`, and streams discoveries to Dart via EventChannel → `BleRestoreService` → Firestore `proximity_events`.
- `flutter_blue_plus`'s CBCentralManager **is the foreground-only scanner** managed by `BleService`. It's intentionally stopped on background and has no restore ID.

The API MISUSE warning is a **cosmetic issue from FBP's code structure** (delegate method exists even when restore is off), not from BleRestoreBridge which is correctly configured.

---

## Consolidated Verdict

### Background passive detection WORKS via `GeoService` in the `flutter_background_service` background isolate (background_service.dart:157-173).

The "phone in pocket" mechanic does NOT rely on BLE. It relies on:
1. **GPS → geohash → Firestore `proximity/{uid}`** writes from the background isolate
2. **Server-side `scanProximityPairs`** Cloud Function that reads proximity docs and FCM-notifies matched pairs

BLE (via `flutter_blue_plus` / `BleService`) is a **foreground-only enhancement** that is intentionally stopped on background by `didChangeAppLifecycleState`.

### However, there are reliability concerns:

| Concern | Severity | Details |
|---------|----------|---------|
| iOS BGTask wake-up frequency | ⚠️ MEDIUM | iOS controls when `BGAppRefreshTask` fires (~15-30 min intervals). The 60s `Timer.periodic` in `GeoService` only ticks during active BGTask windows. |
| Proximity doc TTL vs BGTask gap | ⚠️ MEDIUM | `geoHashExpiresAt` is set to `now + 30 min`. If iOS delays BGTask beyond 30 min, the doc expires and the user appears offline. |
| `BleRestoreBridge` restore events need FlutterEngine | 🟡 LOW | `BleRestoreService` listens via `EventChannel` which requires the Flutter engine to be alive. After a true force-quit + iOS restore, the Dart side may not be running to receive events. |
| FBP API MISUSE warning | 🟢 COSMETIC | No functional impact. FBP's `willRestoreState` delegate exists in code but is never invoked without a restore ID. |
| `processing` background mode absent | 🟡 LOW | Adding `processing` to `UIBackgroundModes` would allow `BGProcessingTaskRequest` for longer execution windows, but this is an enhancement, not a blocker. |

### Architecture summary:

```
┌─────────────────────────────────────────────────────────┐
│ FOREGROUND (Main Isolate)                                │
│                                                          │
│  BleService (flutter_blue_plus)                          │
│  ├── Scan for Tremble UUID                               │
│  ├── Advertise via flutter_ble_peripheral                │
│  └── ❌ STOPPED on AppLifecycleState.paused              │
│                                                          │
│  BleRestoreService (Dart EventChannel listener)          │
│  └── Receives events from native BleRestoreBridge        │
├──────────────────────────────────────────────────────────┤
│ BACKGROUND (Separate Isolate via flutter_background_svc) │
│                                                          │
│  GeoService                                              │
│  ├── Timer.periodic(60s) → Geolocator.getCurrentPosition │
│  ├── geohash encode (precision 7, ~150m cell)            │
│  ├── Firestore proximity/{uid} write                     │
│  └── ✅ SURVIVES backgrounding (BGTask on iOS)           │
│                                                          │
│  Run Club motion → notification logic                    │
│  └── Receives motionStateChanged from main isolate       │
├──────────────────────────────────────────────────────────┤
│ NATIVE iOS (always alive if BT is on)                    │
│                                                          │
│  BleRestoreBridge (CBCentralManager + restore ID)        │
│  ├── Scan for Tremble UUID in background                 │
│  ├── Emit {rssi, uuid} via EventChannel                  │
│  └── ✅ SURVIVES force-quit via iOS state restoration    │
│                                                          │
│  flutter_blue_plus CBCentralManager (NO restore ID)      │
│  └── ❌ Not restored — foreground only                   │
└─────────────────────────────────────────────────────────┘
```
