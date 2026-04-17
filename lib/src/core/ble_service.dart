import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tremble BLE Service — advertises presence and scans for other Tremble users.
///
/// Interaction System v3.0:
///   - Advertises current User UID so matched partners can find us in real-time.
///   - Scans for proximity events (background housekeeping).
///   - High-Frequency mode for active Search Sessions (30m radar games).
///   - Exposes real-time RSSI stream for distance-based feedback.
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  static const String trembleServiceUuid =
      '00001820-0000-1000-8000-00805f9b34fb'; // Tremble BLE UUID

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Battery _battery = Battery();
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _scanTimer;

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
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: trembleServiceUuid,
      localName: 'Tremble',
      // Store UID in manufacturer data or service data if supported.
      // For Tremble, we use the first 16 bytes of UID as a custom ID.
      manufacturerId: 0xFFFF,
      manufacturerData: Uint8List.fromList(uid.codeUnits.take(20).toList()),
    );

    if (await _peripheral.isSupported) {
      await _peripheral.start(advertiseData: advertiseData);
      debugPrint('[BleService] Advertising started for UID: $uid');
    }
  }

  Future<void> _stopAdvertising() async {
    await _peripheral.stop();
    debugPrint('[BleService] Advertising stopped');
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
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        final rssiMap = <String, int>{};
        for (final result in results) {
          // Identify partner UID from manufacturer data
          final manufacturerData = result.advertisementData.manufacturerData;
          if (manufacturerData.isNotEmpty) {
            final partnerUid =
                String.fromCharCodes(manufacturerData.values.first);
            rssiMap[partnerUid] = result.rssi;
          }
          _onDeviceDetected(uid, result);
        }
        if (rssiMap.isNotEmpty) {
          _rssiController.add(rssiMap);
        }
      });
    } catch (e) {
      debugPrint('[BleService] scan error: $e');
    }
  }

  Future<void> _onDeviceDetected(String myUid, ScanResult result) async {
    if (_isHighFrequency)
      return; // Skip Firestore logging during high-freq lock session

    final remoteDeviceId = result.device.remoteId.str;
    try {
      await _firestore.collection('proximity_events').add({
        'from': myUid,
        'toDeviceId': remoteDeviceId,
        'rssi': result.rssi,
        'timestamp': FieldValue.serverTimestamp(),
        'ttl': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });
    } catch (_) {}
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
