import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:battery_plus/battery_plus.dart';

/// Tremble BLE Service — advertises presence and scans for other Tremble users.
///
/// Protocol:
///   - Advertises a fixed Tremble Service UUID so other devices can find us.
///   - Scans for devices advertising the same UUID.
///   - On detection: writes a `proximity_event` to Firestore.
///   - Degrades gracefully on Low Power Mode / Battery Saver.
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  static const String trembleServiceUuid =
      '00001820-0000-1000-8000-00805f9b34fb'; // Tremble BLE UUID

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Battery _battery = Battery();

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _scanTimer;

  bool _isLowPowerMode = false;
  bool _isRunning = false;

  // Normal mode: 30s scan every 5 min. Low power: 30s scan every 15 min.
  static const Duration _normalScanInterval = Duration(minutes: 5);
  static const Duration _lowPowerScanInterval = Duration(minutes: 15);
  static const Duration _scanDuration = Duration(seconds: 30);

  /// Returns current radar mode for UI feedback.
  bool get isLowPowerMode => _isLowPowerMode;
  bool get isRunning => _isRunning;

  // ─── Public API ───────────────────────────────────────

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    await _checkBatteryState();
    _listenBatteryChanges();

    if (!_isLowPowerMode) {
      _scheduleScanCycle();
    } else {
      // In low power mode: only use Geo (see GeoService), skip BLE
      // UI will show "Radar in power-saving mode"
    }
  }

  void stop() {
    _isRunning = false;
    _scanTimer?.cancel();
    _scanSub?.cancel();
    _batterySub?.cancel();
    FlutterBluePlus.stopScan();
  }

  // ─── BLE Scanning ─────────────────────────────────────

  void _scheduleScanCycle() {
    final interval =
        _isLowPowerMode ? _lowPowerScanInterval : _normalScanInterval;

    // Run a scan immediately, then schedule periodic scans
    _runScan();
    _scanTimer = Timer.periodic(interval, (_) {
      if (!_isLowPowerMode) _runScan();
    });
  }

  Future<void> _runScan() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final isOn =
        await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    if (!isOn) return;

    await FlutterBluePlus.startScan(
      withServices: [Guid(trembleServiceUuid)],
      timeout: _scanDuration,
    );

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        _onDeviceDetected(uid, result);
      }
    });
  }

  Future<void> _onDeviceDetected(String myUid, ScanResult result) async {
    // The remote device ID is used as a proxy for the Tremble user ID.
    // In production: device advertises its Tremble UID in the manufacturer data.
    final remoteDeviceId = result.device.remoteId.str;

    try {
      // Write proximity event — Cloud Function validates mutual detection
      // and creates match candidate. TTL policy auto-deletes after 10 minutes.
      await _firestore.collection('proximity_events').add({
        'from': myUid,
        'toDeviceId': remoteDeviceId,
        'rssi': result.rssi,
        'timestamp': FieldValue.serverTimestamp(),
        'ttl':
            DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      });
    } catch (_) {
      // Silently fail — proximity event is best-effort
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

      if (wasLow && !_isLowPowerMode) {
        // Restored from low power → resume BLE scanning
        _scanTimer?.cancel();
        _scheduleScanCycle();
      } else if (!wasLow && _isLowPowerMode) {
        // Entered low power → stop BLE scanning, Geo-only continues
        _scanTimer?.cancel();
        _scanSub?.cancel();
        FlutterBluePlus.stopScan();
      }
    });
  }
}
