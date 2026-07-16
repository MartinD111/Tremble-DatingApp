import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Tracks which devices have already produced a `proximity_events` write during
/// the current scan cycle.
///
/// `FlutterBluePlus.scanResults` re-emits the *cumulative* result list on every
/// advertisement packet, so one nearby device appears in dozens of emissions per
/// scan. Writing per emission saturated the Firestore channel and inflated the
/// monthly recap's near-miss count, which is derived from a `count()` over this
/// collection. One write per device per scan cycle is the contract.
class ScanCycleDedupe {
  final Set<String> _writtenDeviceIds = <String>{};

  /// Drops the previous cycle's device IDs so the next scan reports afresh.
  void beginCycle() => _writtenDeviceIds.clear();

  /// True only the first time [deviceId] is offered within a cycle.
  bool shouldWrite(String deviceId) => _writtenDeviceIds.add(deviceId);
}

/// Tremble BLE Service — advertises presence and scans for other Tremble users.
///
/// Interaction System v3.0:
///   - Advertises Tremble service UUID presence only; no user identity in BLE.
///   - Scans for proximity events (background housekeeping).
///   - High-Frequency mode for active Search Sessions (30m radar games).
///   - Exposes real-time RSSI stream for distance-based feedback.
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  static const String trembleServiceUuid =
      '73a9429f-fd01-4ac9-9e5a-eabd0d31438e'; // Tremble BLE Service UUID

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Battery _battery = Battery();
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _scanTimer;
  final ScanCycleDedupe _scanDedupe = ScanCycleDedupe();

  bool _isLowPowerMode = false;
  bool _isRunning = false;
  bool _isHighFrequency = false;

  // Normal mode: 15s scan every 5 min. Search mode: Continuous 10s scan.
  static const Duration _normalScanInterval = Duration(minutes: 5);
  static const Duration _highFreqScanInterval = Duration(seconds: 15);
  static const Duration _scanDuration = Duration(seconds: 15);

  // Proximity tracking
  final _rssiController = StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get proximityStream => _rssiController.stream;

  /// Returns current radar mode for UI feedback.
  bool get isLowPowerMode => _isLowPowerMode;
  bool get isRunning => _isRunning;

  // ─── Public API ───────────────────────────────────────

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    await _checkBatteryState();
    _listenBatteryChanges();
    _startAdvertising();

    _scheduleScanCycle();
  }

  void stop() {
    _isRunning = false;
    _isHighFrequency = false;
    _scanTimer?.cancel();
    _scanSub?.cancel();
    _batterySub?.cancel();
    _stopAdvertising();
    FlutterBluePlus.stopScan();
  }

  /// Restarts BLE advertising. Call when the background service signals a state
  /// change via 'onRunClubStateChanged'. No-op if BLE is not running.
  Future<void> updateAdvertisingMode() async {
    if (!_isRunning) return;
    await _stopAdvertising();
    await _startAdvertising();
    if (kDebugMode)
      debugPrint(
          '[BleService] Advertising mode updated (RunClub state refreshed)');
  }

  /// Enables or disables high-frequency scanning during a search session.
  void setHighFrequencyMode(bool enabled) {
    if (_isHighFrequency == enabled) return;
    _isHighFrequency = enabled;

    // Restart scan cycle with new intervals
    _scanTimer?.cancel();
    _scheduleScanCycle();
  }

  // ─── BLE Advertising (Peripheral) ──────────────────────

  Future<void> _startAdvertising() async {
    // Presence-only advertisement: service UUID signals a Tremble device.
    // Identity is resolved server-side via geohash proximity (findNearby).
    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: trembleServiceUuid,
      localName: 'Tremble',
    );

    if (await _peripheral.isSupported) {
      await _peripheral.start(advertiseData: advertiseData);
      if (kDebugMode) debugPrint('[BleService] Advertising started');
    }
  }

  Future<void> _stopAdvertising() async {
    await _peripheral.stop();
    if (kDebugMode) debugPrint('[BleService] Advertising stopped');
  }

  // ─── BLE Scanning ─────────────────────────────────────

  void _scheduleScanCycle() {
    final interval = _isHighFrequency
        ? _highFreqScanInterval
        : (_isLowPowerMode ? Duration(minutes: 15) : _normalScanInterval);

    // Immediate first scan
    _runScan();

    _scanTimer = Timer.periodic(interval, (_) {
      _runScan();
    });
  }

  Future<void> _runScan() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return;

      final isOn =
          await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (!isOn) return;

      // Start scan
      await FlutterBluePlus.startScan(
        withServices: [Guid(trembleServiceUuid)],
        timeout: _isHighFrequency ? Duration(seconds: 12) : _scanDuration,
        androidUsesFineLocation: true,
      );

      _scanSub?.cancel();
      _scanDedupe.beginCycle();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        final rssiMap = <String, int>{};
        for (final result in results) {
          // Service UUID presence confirms a Tremble device.
          // Identity is resolved server-side via geohash proximity (findNearby).
          // RSSI threshold: -75 dBm (Free / normal), -85 dBm (Pro / high-freq).
          final rssiThreshold = _isHighFrequency ? -85 : -75;

          if (result.rssi >= rssiThreshold) {
            final deviceId = result.device.remoteId.str;
            rssiMap[deviceId] = result.rssi;
            // This stream re-delivers every device on every advertisement
            // packet, so the write is gated to once per device per cycle.
            if (_scanDedupe.shouldWrite(deviceId)) {
              unawaited(_onDeviceDetected(uid, result));
            }
          }
        }
        if (rssiMap.isNotEmpty) {
          _rssiController.add(rssiMap);
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[BleService] scan error: $e');
    }
  }

  Future<void> _onDeviceDetected(String myUid, ScanResult result) async {
    if (_isHighFrequency)
      return; // Skip Firestore logging during high-freq lock session

    // Write presence signal only — identity resolved server-side via findNearby.
    try {
      final proximityDoc =
          await _firestore.collection('proximity').doc(myUid).get();
      final geohash = proximityDoc.data()?['geohash'] as String?;
      if (geohash == null || geohash.isEmpty) return;

      await _firestore.collection('proximity_events').add({
        'fromUid': myUid,
        'geohash': geohash,
        'rssi': result.rssi,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });
    } catch (e, st) {
      if (kDebugMode) debugPrint('[BLE] proximity write failed: $e');
      // Non-fatal — radar continues operating
      FirebaseCrashlytics.instance.recordError(e, st, fatal: false);
    }
  }

  // ─── Battery Handling ─────────────────────────────────

  Future<void> _checkBatteryState() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      _isLowPowerMode = state != BatteryState.charging && level < 20;
    } catch (_) {
      _isLowPowerMode = false;
    }
  }

  void _listenBatteryChanges() {
    _batterySub = _battery.onBatteryStateChanged.listen((state) async {
      final wasLow = _isLowPowerMode;
      await _checkBatteryState();

      if (wasLow != _isLowPowerMode) {
        _scanTimer?.cancel();
        _scheduleScanCycle();
      }
    });
  }
}

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService();
});

enum RadarBleIssue {
  bluetoothOff,
  permissionDenied,
}

RadarBleIssue? resolveRadarBleIssue({
  required BluetoothAdapterState? adapterState,
  required PermissionStatus? permissionStatus,
  TargetPlatform? platform,
}) {
  final effectivePlatform = platform ?? defaultTargetPlatform;
  switch (adapterState) {
    case BluetoothAdapterState.off:
    case BluetoothAdapterState.unavailable:
    case BluetoothAdapterState.turningOff:
      return RadarBleIssue.bluetoothOff;
    case BluetoothAdapterState.unauthorized:
      return RadarBleIssue.permissionDenied;
    case BluetoothAdapterState.unknown:
    case BluetoothAdapterState.turningOn:
    case null:
      return null;
    case BluetoothAdapterState.on:
      // On iOS, CoreBluetooth only reports adapterState == .on when the app
      // is authorized (unauthorized apps get .unauthorized). The permission
      // read is therefore redundant — and unreliable, since Permission.bluetooth
      // on iOS can lag the CBCentralManager authorization callback.
      if (effectivePlatform == TargetPlatform.iOS) {
        return null;
      }
      if (permissionStatus == PermissionStatus.denied ||
          permissionStatus == PermissionStatus.permanentlyDenied ||
          permissionStatus == PermissionStatus.restricted) {
        return RadarBleIssue.permissionDenied;
      }
      return null;
  }
}

final bluetoothAdapterStateProvider =
    StreamProvider<BluetoothAdapterState>((ref) {
  return FlutterBluePlus.adapterState;
});

/// Platform-aware Bluetooth authorization read.
///
/// On iOS, `Permission.bluetoothScan` / `bluetoothAdvertise` / `bluetoothConnect`
/// are Android-12+ runtime permissions that have no iOS analogue —
/// permission_handler's iOS backend falls through to `UnknownPermissionStrategy`
/// and returns `PermissionStatusDenied` unconditionally for these. The only
/// iOS-recognized BT permission is `Permission.bluetooth`, which is backed by
/// `CBCentralManager.authorization`.
final bluetoothPermissionStatusProvider =
    FutureProvider<PermissionStatus>((ref) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return Permission.bluetooth.status;
  }
  return Permission.bluetoothScan.status;
});

final radarBleIssueProvider = Provider<RadarBleIssue?>((ref) {
  final adapterState = ref.watch(bluetoothAdapterStateProvider).valueOrNull;
  final permissionStatus =
      ref.watch(bluetoothPermissionStatusProvider).valueOrNull;

  return resolveRadarBleIssue(
    adapterState: adapterState,
    permissionStatus: permissionStatus,
  );
});
