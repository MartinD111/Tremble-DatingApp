import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Restarts BLE advertising with the current Run Club state from SharedPreferences.
  /// Call this from the main isolate when the background service signals a Run Club
  /// state change via 'onRunClubStateChanged'. This is a no-op if BLE is not running.
  Future<void> updateAdvertisingMode() async {
    if (!_isRunning) return;
    await _stopAdvertising();
    await _startAdvertising();
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
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final isRunClubActive = prefs.getBool('run_club_active') ?? false;

    final AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: trembleServiceUuid,
      localName: 'Tremble',
      // For Tremble, we use the first 20 bytes of UID as a custom ID.
      // manufacturerId 0xFF01 indicates Run Club mode. 0xFFFF is normal.
      manufacturerId: isRunClubActive ? 0xFF01 : 0xFFFF,
      manufacturerData: Uint8List.fromList(uid.codeUnits.take(20).toList()),
    );

    if (await _peripheral.isSupported) {
      await _peripheral.start(advertiseData: advertiseData);
      debugPrint(
          '[BleService] Advertising started for UID: $uid (RunClub: $isRunClubActive)');
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
          final manufacturerData = result.advertisementData.manufacturerData;
          if (manufacturerData.isNotEmpty) {
            final mId = manufacturerData.keys.first;
            final isPartnerRunning = mId == 0xFF01;
            final partnerUid =
                String.fromCharCodes(manufacturerData.values.first);

            // Apply dynamic RSSI threshold
            // RSSI varies wildly by device. For Run Club (moving targets), we accept a lower threshold (e.g. -85 dBm)
            // For normal walking/standing, we require a stronger signal (e.g. -75 dBm)
            final rssiThreshold = isPartnerRunning ? -85 : -75;

            if (result.rssi >= rssiThreshold) {
              rssiMap[partnerUid] = result.rssi;
              _onDeviceDetected(uid, result,
                  isPartnerRunning: isPartnerRunning);
            }
          }
        }
        if (rssiMap.isNotEmpty) {
          _rssiController.add(rssiMap);
        }
      });
    } catch (e) {
      debugPrint('[BleService] scan error: $e');
    }
  }

  Future<void> _onDeviceDetected(String myUid, ScanResult result,
      {bool isPartnerRunning = false}) async {
    if (_isHighFrequency)
      return; // Skip Firestore logging during high-freq lock session

    final remoteDeviceId = result.device.remoteId.str;

    // If the partner is running, we write to `run_encounters` instead of `proximity_events`
    // to apply the strict 10-minute TTL (Jebiga Rule).
    final collectionName =
        isPartnerRunning ? 'run_encounters' : 'proximity_events';

    try {
      await _firestore.collection(collectionName).add({
        'from': myUid,
        'toDeviceId': remoteDeviceId,
        'rssi': result.rssi,
        'isRunMode': isPartnerRunning,
        'timestamp': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
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
