---
name: flutter-ble-proximity
description: Use this skill when implementing BLE scanning, advertising, geofencing, proximity detection, or the 30-minute radar mechanic in Tremble. Covers flutter_blue_plus patterns, permission handling, background execution, RSSI-to-distance mapping, and the current scanProximityPairs Cloud Function architecture. Always use this skill before modifying geo_service.dart, BleService, RadarManager, or any Cloud Function that handles proximity pairs or run encounters.
origin: Tremble
---

# Flutter BLE Proximity Skill

Patterns for Tremble's core passive proximity mechanic: BLE scanning + advertising, RSSI-based proximity estimation, and the 30-minute radar window.

**Last verified:** 6 Jun 2026

## When to Activate

- Implementing or modifying BLE scan/advertise logic
- Working on radar (findNearby, updateLocation, setInactive, scanProximityPairs)
- Handling background BLE execution (iOS background modes, Android foreground service)
- Debugging proximity accuracy or battery drain
- Implementing geofencing or location-based radar triggers
- Writing or reviewing any Cloud Function that touches proximity_events or run_encounters

---

## 1. BLE Architecture Overview

Tremble's proximity stack as of Jun 2026:

```
Flutter (BLE layer)
  ├── flutter_blue_plus — scan only (foreground)
  ├── flutter_ble_peripheral — advertise (service UUID only)
  ├── BleService — singleton, manages scan/advertise lifecycle
  ├── RadarService — proximity logic, RSSI → distance → match threshold
  └── geo_service.dart — geofencing, geohash for Firestore, isPremium param

Firebase Functions (europe-west1, Node.js v22)
  ├── updateLocation(geohash) — called when location changes >100m
  ├── findNearby(geohash) — returns users within radar radius
  ├── scanProximityPairs — SCHEDULED (1-min interval), geohash-based pair detection
  └── setInactive — marks user offline in proximity collection
```

### What changed from original design — CRITICAL

`onBleProximity` and `onRunEncounter` Firestore triggers are **DELETED**. They were dead — field name mismatch post-BLE redesign. Do not reference them in any new code or debugging.

**Current proximity detection:** `scanProximityPairs` scheduled CF runs every 1 minute, reads proximity collection, finds geohash pairs, writes to proximity_events.

**iOS advertising:** iOS CoreBluetooth ignores custom manufacturerData in background. Solution: service-UUID-only advertising (`73a9429f-fd01-4ac9-9e5a-eabd0d31438e`), identity resolved server-side via `findNearby` geohash lookup. Works both iOS + Android.

---

## 2. flutter_blue_plus Patterns

### Scanning

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  // Tremble service UUID — never change without updating scanProximityPairs CF
  static const _serviceUuid = Guid('73a9429f-fd01-4ac9-9e5a-eabd0d31438e');
  static const _scanDuration = Duration(seconds: 10);

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Stream<List<ScanResult>> startScan() {
    return FlutterBluePlus.scanResults.map((results) =>
      results
        .where((r) => r.advertisementData.serviceUuids.contains(_serviceUuid))
        .toList()
    );
  }

  Future<void> beginScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint('[BleService] BLE not supported on this device');
      return;
    }
    await FlutterBluePlus.startScan(
      withServices: [_serviceUuid],
      timeout: _scanDuration,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }
}
```

### Advertising (iOS + Android)

```dart
// iOS: service-UUID-only advertising in background
// Android: full background advertising supported
// NEVER include custom manufacturerData — iOS ignores it in background

// flutter_ble_peripheral handles advertising:
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

final _peripheral = FlutterBlePeripheral();

Future<void> startAdvertising() async {
  final advertiseData = AdvertiseData(
    serviceUuid: '73a9429f-fd01-4ac9-9e5a-eabd0d31438e',
    // NO manufacturerData — iOS background limitation
  );
  await _peripheral.start(advertiseData: advertiseData);
}
```

---

## 3. RSSI → Proximity Estimation

RSSI is noisy — smooth before proximity decisions:

```dart
enum ProximityZone { immediate, near, far, outOfRange }

class RssiProcessor {
  static const _windowSize = 5;
  final _history = <int>[];

  int smooth(int rawRssi) {
    _history.add(rawRssi);
    if (_history.length > _windowSize) _history.removeAt(0);
    return _history.reduce((a, b) => a + b) ~/ _history.length;
  }

  ProximityZone classify(int smoothedRssi) {
    if (smoothedRssi >= -60) return ProximityZone.immediate;  // ~1m
    if (smoothedRssi >= -75) return ProximityZone.near;       // Free tier threshold
    if (smoothedRssi >= -85) return ProximityZone.far;        // Pro tier threshold
    return ProximityZone.outOfRange;
  }
}
```

**Radius by tier:**
- Free: 100m (RSSI ≥ −75 dBm)
- Pro (Signal Prime): 250m (RSSI ≥ −85 dBm)

**Rule:** Never show users exact distances — only zones. Never expose raw RSSI values in UI.

---

## 4. Radar Lifecycle (30-minute window)

```dart
class RadarManager {
  static const radarDuration = Duration(minutes: 30);
  Timer? _radarTimer;
  bool _isActive = false;

  Future<void> startRadar() async {
    if (_isActive) return;
    _isActive = true;

    await _locationService.updateLocation();
    await _bleService.beginScan();
    _radarTimer = Timer(radarDuration, () => stopRadar());

    debugPrint('[RadarManager] radar started, expires in 30 min');
  }

  Future<void> stopRadar() async {
    if (!_isActive) return;
    _isActive = false;
    _radarTimer?.cancel();
    _radarTimer = null;

    await _bleService.stopScan();
    await _cloudFunctions.setInactive();
    debugPrint('[RadarManager] radar stopped');
  }

  // ALWAYS stop on app background
  Future<void> onAppBackground() => stopRadar();
}
```

---

## 5. geo_service.dart — isPremium param

`geo_service.dart` requires `isPremium` parameter. Always use `effectiveIsPremiumProvider`, never raw `isPremium` field from Firestore.

```dart
// CORRECT
final isPremium = ref.watch(effectiveIsPremiumProvider);
geoService.updateLocation(isPremium: isPremium);

// WRONG — do not use
final isPremium = userDoc['isPremium']; // raw Firestore field, bypasses RevenueCat
```

`effectiveIsPremiumProvider` combines RevenueCat entitlement + Firestore fallback. ~36 files were migrated to this pattern Jun 2026 — maintain it.

---

## 6. Permission Handling

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestRadarPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();
    final allGranted = statuses.values.every((s) => s.isGranted);

    if (!allGranted) {
      final denied = statuses.entries
          .where((e) => !e.value.isGranted)
          .map((e) => e.key.toString())
          .toList();
      debugPrint('[PermissionService] denied: $denied');
    }

    return allGranted;
  }

  Future<bool> get canScan async {
    final bleOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    final permsOk = await requestRadarPermissions();
    return bleOn && permsOk;
  }
}
```

---

## 7. Geohash + Firestore Integration

```dart
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class LocationService {
  static const _updateThresholdMeters = 100.0;
  GeoFirePoint? _lastKnownPoint;

  Future<void> updateLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final newPoint = GeoFirePoint(GeoPoint(position.latitude, position.longitude));

    if (_lastKnownPoint != null) {
      final distanceKm = _lastKnownPoint!.distanceBetweenInKm(
        geopoint: newPoint.geopoint
      );
      if (distanceKm * 1000 < _updateThresholdMeters) return;
    }

    _lastKnownPoint = newPoint;

    // NEVER send raw lat/lng — geohash only
    await _functions.httpsCallable('updateLocation').call({
      'geohash': newPoint.geohash,
    });
  }
}
```

**Rule:** Never write raw GPS coordinates to Firestore from the client. GPS is computed in Cloud Function RAM only — never stored.

---

## 8. TTL Fields for Proximity Collections

See `references/ttl-field-map.md` for the full table.

Quick reference:
- `proximity_events` → `expiresAt` (24h)
- `run_encounters` → `expiresAt` (24h)
- `proximity` geohash doc → `geoHashExpiresAt`

**Never use `ttl` on proximity_events or run_encounters** — this caused a prod bug. The correct field is `expiresAt`.

---

## 9. Battery Optimization

```dart
// Duty cycle: scan 10s, pause 20s → ~60% battery reduction
class DutyCycleScanner {
  static const _scanOn = Duration(seconds: 10);
  static const _scanOff = Duration(seconds: 20);
  Timer? _cycleTimer;

  void start() => _runCycle();

  void _runCycle() async {
    await _bleService.beginScan();
    _cycleTimer = Timer(_scanOn, () async {
      await _bleService.stopScan();
      _cycleTimer = Timer(_scanOff, _runCycle);
    });
  }

  void stop() {
    _cycleTimer?.cancel();
    _bleService.stopScan();
  }
}
```

Run Club mode target: <1%/hr battery drain.

---

## 10. Testing BLE Logic

BLE hardware unavailable in unit tests — always abstract:

```dart
abstract interface class BleScanner {
  Stream<List<ScanResult>> get scanResults;
  Future<void> startScan();
  Future<void> stopScan();
}

class FakeBleScanner implements BleScanner {
  final StreamController<List<ScanResult>> _controller = StreamController();

  @override
  Stream<List<ScanResult>> get scanResults => _controller.stream;

  void emitResults(List<ScanResult> results) => _controller.add(results);

  @override Future<void> startScan() async {}
  @override Future<void> stopScan() async {}
}
```

Pending device tests (require physical hardware): BLE E2E, B006 photo upload E2E, F1 Protomaps iOS tile.

---

## Composability

**This skill is called by:**
- `tremble:deploy-workflow` — verifies BLE architecture before prod deploy
- `tremble:compliance-checker` — checks proximity-related code for violations

**This skill calls:**
- `firebase-security` — when BLE changes touch Cloud Functions or Firestore rules
- `references/ttl-field-map.md` — for any proximity collection TTL field

**Agent support:**
- Use `security-reviewer` agent when modifying permission handling or data transmission
- Use `architect` agent when redesigning the BLE/location stack
