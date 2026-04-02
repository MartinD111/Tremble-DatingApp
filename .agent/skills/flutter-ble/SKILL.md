---
name: flutter-ble-proximity
description: Use when writing or reviewing BLE scanning code, background service integration, or proximity event logic in Tremble. Based on the real flutter_blue_plus implementation in this codebase.
origin: Tremble
---

# Flutter BLE Proximity Skill

Tremble-specific patterns for `flutter_blue_plus` scanning, battery-aware operation, background delegation, and Firestore proximity event writes. All patterns are derived directly from `lib/src/core/ble_service.dart` and `lib/src/core/background_service.dart`.

## When to Activate

- Writing or modifying anything in `ble_service.dart`
- Modifying the BLE-related sections of `background_service.dart`
- Adding new proximity detection logic
- Debugging BLE scan results or missed detections
- Reviewing battery/power management for the radar feature

---

## 1. Tremble BLE UUID

```dart
static const String trembleServiceUuid =
    '00001820-0000-1000-8000-00805f9b34fb';
```

**Why it exists:** Every `FlutterBluePlus.startScan()` call filters by this UUID via `withServices`. This ensures Tremble only reacts to other Tremble devices — not arbitrary Bluetooth peripherals. Never scan without this filter; it would drain battery and flood Firestore with junk events.

---

## 2. BleService is a Singleton

```dart
static final BleService _instance = BleService._internal();
factory BleService() => _instance;
BleService._internal();
```

`BleService()` always returns the same instance. This is intentional — there must only be one active scan subscription at any time. Do not attempt to create multiple instances.

---

## 3. Start / Stop Pattern

### Start

```dart
Future<void> start() async {
  if (_isRunning) return;          // Guard against double-start
  _isRunning = true;

  await _checkBatteryState();       // Sets _isLowPowerMode before first scan
  _listenBatteryChanges();          // Subscribes to ongoing battery events

  if (!_isLowPowerMode) {
    _scheduleScanCycle();            // Only scan in full power mode
  }
  // Low power: BLE is skipped. GeoService takes over (see background_service.dart).
}
```

### Stop

```dart
void stop() {
  _isRunning = false;
  _scanTimer?.cancel();
  _scanSub?.cancel();
  _batterySub?.cancel();
  FlutterBluePlus.stopScan();      // Always call stopScan explicitly
}
```

Always call `stop()` before the background service terminates. Failing to call `FlutterBluePlus.stopScan()` leaves the hardware scanner running.

---

## 4. Scan Cycle — Battery-Aware Intervals

```dart
static const Duration _normalScanInterval   = Duration(minutes: 5);
static const Duration _lowPowerScanInterval = Duration(minutes: 15);
static const Duration _scanDuration         = Duration(seconds: 30);
```

| Mode | Scan every | Scan duration |
|---|---|---|
| Normal (battery ≥ 20% or charging) | 5 minutes | 30 seconds |
| Low power (battery < 20%, not charging) | 15 minutes | 30 seconds |

```dart
void _scheduleScanCycle() {
  final interval = _isLowPowerMode ? _lowPowerScanInterval : _normalScanInterval;
  _runScan();                                      // Scan immediately on start
  _scanTimer = Timer.periodic(interval, (_) {
    if (!_isLowPowerMode) _runScan();              // Periodic scans only in full mode
  });
}
```

Do not change scan intervals without considering battery impact. 30s scan every 5min was the ADR-001 decision.

---

## 5. Running a Scan

```dart
Future<void> _runScan() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;                          // Never scan if not authenticated

  final isOn =
      await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  if (!isOn) return;                                // Never scan if BT adapter is off

  await FlutterBluePlus.startScan(
    withServices: [Guid(trembleServiceUuid)],       // ALWAYS filter by UUID
    timeout: _scanDuration,
  );

  _scanSub?.cancel();                               // Cancel previous subscription first
  _scanSub = FlutterBluePlus.scanResults.listen((results) {
    for (final result in results) {
      _onDeviceDetected(uid, result);
    }
  });
}
```

**Two guards before every scan:**
1. `uid == null` → user is logged out, skip
2. `BluetoothAdapterState.on` → hardware is off, skip

Both are silent returns — no error, no retry. The next scheduled scan will try again.

---

## 6. Firestore Proximity Event Write

```dart
Future<void> _onDeviceDetected(String myUid, ScanResult result) async {
  final remoteDeviceId = result.device.remoteId.str;

  try {
    await _firestore.collection('proximity_events').add({
      'from': myUid,
      'toDeviceId': remoteDeviceId,          // Device ID proxy for Tremble UID
      'rssi': result.rssi,                   // Signal strength — used for distance estimate
      'timestamp': FieldValue.serverTimestamp(),
      'ttl': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 10)),
      ),
    });
  } catch (_) {
    // Silently fail — proximity events are best-effort
  }
}
```

**Key design decisions:**
- `toDeviceId` is the hardware device ID, not the Tremble UID. In production the device will advertise its Tremble UID in manufacturer data — this is a known Phase 3 TODO.
- TTL is 10 minutes. A Cloud Function handles mutual detection and creates match candidates. Client-side TTL is advisory; server-side deletion jobs are authoritative.
- Errors are silently swallowed. A missed proximity event is acceptable; a crash is not.
- **Never write directly to `matches/`** — that collection is Cloud Function-only (see Firestore Security Rules).

---

## 7. Battery State Handling

```dart
Future<void> _checkBatteryState() async {
  try {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    _isLowPowerMode = state != BatteryState.charging && level < 20;
  } catch (_) {
    _isLowPowerMode = false;      // Fail open — assume full power on error
  }
}
```

Threshold: **< 20% AND not charging** → low power mode. Charging overrides the threshold regardless of level.

Battery transitions are handled live:

```dart
// Restored from low power → resume BLE
if (wasLow && !_isLowPowerMode) {
  _scanTimer?.cancel();
  _scheduleScanCycle();
}

// Entered low power → stop BLE, Geo-only continues
if (!wasLow && _isLowPowerMode) {
  _scanTimer?.cancel();
  _scanSub?.cancel();
  FlutterBluePlus.stopScan();
}
```

---

## 8. Background Service Delegation Pattern

`background_service.dart` owns the service lifecycle. `BleService` owns all BLE logic. The delegation is clean:

```dart
// In onStart() — background isolate
final bleService = BleService();

// GDPR gate — must check before starting
final hasConsent = prefs.getBool('gdpr_ble_location_consent') ?? false;
if (hasConsent) {
  await bleService.start();
}

// UI commands
service.on('stopService').listen((_) async { bleService.stop(); ... });
service.on('pauseRadar').listen((_) async  { bleService.stop(); ... });
service.on('resumeRadar').listen((_) async {
  final consentAtResume = prefs.getBool('gdpr_ble_location_consent') ?? false;
  if (consentAtResume) await bleService.start();
});
```

**Rules:**
- `background_service.dart` never touches `FlutterBluePlus` directly — always goes through `BleService`
- `BleService` never touches `ServiceInstance` — it has no knowledge of the background service
- GDPR consent is checked in `background_service.dart`, not in `BleService` — consent is an app-level concern

---

## 9. Common Pitfalls

| Pitfall | Consequence | Correct pattern |
|---|---|---|
| Scanning without `withServices` filter | Picks up all BLE devices; floods Firestore; drains battery | Always pass `withServices: [Guid(trembleServiceUuid)]` |
| Not cancelling `_scanSub` before re-subscribing | Two active listeners; duplicate Firestore writes | `_scanSub?.cancel()` before every new `FlutterBluePlus.scanResults.listen()` |
| Not calling `FlutterBluePlus.stopScan()` on stop | Hardware scanner keeps running in background | Always call in `stop()` |
| Calling `bleService.start()` without consent check | BLE activates before user has given GDPR consent | Always read `gdpr_ble_location_consent` from SharedPreferences first |
| Starting BLE when BT adapter is off | `startScan` throws or silently fails | Always check `BluetoothAdapterState.on` before scanning |
| Instantiating a new `BleService()` expecting a fresh state | Returns the singleton — old subscriptions may still be live | Call `stop()` before `start()` if re-initializing |

---

## 10. Decision Rules

| Situation | Action |
|---|---|
| Modifying scan UUID or scan interval | HALT — write to `tasks/blockers.md`. This is an ADR-001 change requiring founder approval. |
| Adding new fields to `proximity_events` | HALT — must verify Cloud Function schema accepts the new fields. Do not add fields unilaterally. |
| Changing the 10-minute TTL | HALT — coordinate with Cloud Function TTL deletion job. |
| Changing the battery threshold (< 20%) | Proceed, document in `tasks/debt.md` as a decision. |
| Adding a new `service.on()` event in `background_service.dart` | LOW risk — proceed, keep BLE delegation pattern intact. |
| Any change that would make `background_service.dart` call `FlutterBluePlus` directly | HALT — violates delegation pattern. Route through `BleService`. |

---

## Source Files

| File | Role |
|---|---|
| `lib/src/core/ble_service.dart` | BLE scanning, battery management, Firestore write — source of truth |
| `lib/src/core/background_service.dart` | Background isolate lifecycle, GDPR gate, delegation to BleService |
| `lib/src/core/consent_service.dart` | GDPR consent state (Riverpod) — SharedPreferences key `gdpr_ble_location_consent` |
| `lib/src/core/geo_service.dart` | Geo fallback — takes over when BLE is in low power mode |
