---
name: flutter-ble-proximity
description: Use this skill when implementing BLE scanning, advertising, geofencing, proximity detection, or the 30-minute radar mechanic in Tremble. Covers flutter_blue_plus patterns, permission handling, background execution, and RSSI-to-distance mapping.
origin: Tremble
---

# Flutter BLE Proximity Skill

Patterns for Tremble's core passive proximity mechanic: BLE scanning + advertising, RSSI-based proximity estimation, and the 30-minute radar window.

## When to Activate

- Implementing or modifying BLE scan/advertise logic
- Working on the radar feature (findNearby, updateLocation, setInactive)
- Handling background BLE execution (iOS background modes, Android foreground service)
- Debugging proximity accuracy or battery drain
- Implementing geofencing or location-based radar triggers

---

## 1. BLE Architecture Overview

Tremble's proximity stack:

```
Flutter (BLE layer)
  ├── flutter_blue_plus — scan + advertise
  ├── BleService — singleton, manages scan/advertise lifecycle
  ├── RadarService — proximity logic, RSSI → distance → match threshold
  └── LocationService — geofencing, geohash for Firestore

Firebase Functions
  ├── updateLocation(geohash) — called when location changes significantly
  ├── findNearby(geohash) — returns users within radar radius
  └── onBleProximity(trigger) — Firestore trigger, no App Check
```

---

## 2. flutter_blue_plus Patterns

### Scanning

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  static const _serviceUuid = Guid('YOUR-TREMBLE-SERVICE-UUID');
  static const _scanDuration = Duration(seconds: 10);

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Start scanning for nearby Tremble devices.
  /// Returns a stream of ScanResult batches.
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

### Advertising (iOS limitations)

```dart
// iOS: Cannot advertise in foreground with custom service UUID when app is background
// Use flutter_blue_plus for foreground, system CoreBluetooth for background advertising
// Android: Full background advertising supported

// For iOS background advertising, use native channel or background_locator
// This is a known limitation — document in code:

/// NOTE: iOS background BLE advertising requires a native Swift plugin.
/// flutter_blue_plus advertising is foreground-only on iOS.
/// Current workaround: advertise iBeacon UUID instead of GATT service.
```

---

## 3. RSSI → Proximity Estimation

RSSI is noisy — smooth it before using for proximity decisions:

```dart
enum ProximityZone { immediate, near, far, outOfRange }

class RssiProcessor {
  // Sliding window average for noise reduction
  static const _windowSize = 5;
  final _history = <int>[];

  int smooth(int rawRssi) {
    _history.add(rawRssi);
    if (_history.length > _windowSize) _history.removeAt(0);
    return _history.reduce((a, b) => a + b) ~/ _history.length;
  }

  /// Map smoothed RSSI to proximity zone.
  /// Calibrate these thresholds for your hardware.
  ProximityZone classify(int smoothedRssi) {
    if (smoothedRssi >= -60) return ProximityZone.immediate;  // ~1m
    if (smoothedRssi >= -75) return ProximityZone.near;       // ~3-5m
    if (smoothedRssi >= -85) return ProximityZone.far;        // ~10m
    return ProximityZone.outOfRange;
  }

  /// Approximate distance (meters) — Friis path loss model.
  /// Use only as rough estimate, not for exact positioning.
  double estimateDistance(int rssi, {int txPower = -59}) {
    if (rssi == 0) return -1.0;
    final ratio = rssi / txPower;
    if (ratio < 1.0) return pow(ratio, 10).toDouble();
    return (0.89976) * pow(ratio, 7.7095) + 0.111;
  }
}
```

**Important**: Never show users exact distances — only zones. Exact RSSI-to-distance is unreliable and creates wrong expectations.

---

## 4. Radar Lifecycle (30-minute window)

```dart
class RadarManager {
  static const radarDuration = Duration(minutes: 30);
  Timer? _radarTimer;
  bool _isActive = false;

  /// Start a radar session. Automatically expires after 30 minutes.
  Future<void> startRadar() async {
    if (_isActive) return;
    _isActive = true;

    // 1. Update location in Firestore
    await _locationService.updateLocation();

    // 2. Start BLE scan
    await _bleService.beginScan();

    // 3. Start expiry timer
    _radarTimer = Timer(radarDuration, () => stopRadar());

    debugPrint('[RadarManager] radar started, expires in 30 min');
  }

  Future<void> stopRadar() async {
    if (!_isActive) return;
    _isActive = false;
    _radarTimer?.cancel();
    _radarTimer = null;

    await _bleService.stopScan();
    await _cloudFunctions.setInactive(); // mark user as offline in proximity
    debugPrint('[RadarManager] radar stopped');
  }

  // ALWAYS stop on app background
  Future<void> onAppBackground() => stopRadar();
}
```

---

## 5. Permission Handling

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all permissions required for BLE radar.
  /// Returns true only if ALL permissions are granted.
  Future<bool> requestRadarPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // Android BLE requirement
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

  /// Check if BLE is currently on and permissions are granted.
  Future<bool> get canScan async {
    final bleOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    final permsOk = await requestRadarPermissions();
    return bleOn && permsOk;
  }
}
```

---

## 6. Geohash + Firestore Integration

```dart
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class LocationService {
  static const _updateThresholdMeters = 100.0; // only update if moved >100m

  GeoFirePoint? _lastKnownPoint;

  Future<void> updateLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final newPoint = GeoFirePoint(GeoPoint(position.latitude, position.longitude));

    // Throttle updates
    if (_lastKnownPoint != null) {
      final distanceKm = _lastKnownPoint!.distanceBetweenInKm(
        geopoint: newPoint.geopoint
      );
      if (distanceKm * 1000 < _updateThresholdMeters) return;
    }

    _lastKnownPoint = newPoint;

    // Call Cloud Function — never write proximity data client-side
    await _functions.httpsCallable('updateLocation').call({
      'geohash': newPoint.geohash,
      // Do NOT send raw lat/lng — geohash is sufficient for findNearby
    });
  }
}
```

**Rule**: Never write raw GPS coordinates to Firestore from the client. Always use geohash and let Cloud Functions handle proximity queries.

---

## 7. Battery Optimization

```dart
// Scan duty cycle: scan for 10s, pause for 20s (reduces battery by ~60%)
class DutyCycleScanner {
  static const _scanOn = Duration(seconds: 10);
  static const _scanOff = Duration(seconds: 20);

  Timer? _cycleTimer;

  void start() {
    _runCycle();
  }

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

---

## 8. Testing BLE Logic

BLE hardware is not available in unit tests — always abstract behind interfaces:

```dart
abstract interface class BleScanner {
  Stream<List<ScanResult>> get scanResults;
  Future<void> startScan();
  Future<void> stopScan();
}

// Production
class FlutterBluePlusScanner implements BleScanner { ... }

// Tests
class FakeBleScanner implements BleScanner {
  final StreamController<List<ScanResult>> _controller = StreamController();

  @override
  Stream<List<ScanResult>> get scanResults => _controller.stream;

  void emitResults(List<ScanResult> results) => _controller.add(results);

  @override Future<void> startScan() async {}
  @override Future<void> stopScan() async {}
}
```

## Agent Support

- Use **architect** agent when redesigning the BLE/location stack
- Use **security-reviewer** agent when modifying permission handling or data transmission
