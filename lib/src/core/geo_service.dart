import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:battery_plus/battery_plus.dart';

/// Geo Service — uploads GPS coordinates to Firestore periodically.
/// Adjusts update interval based on battery/power-saving state.
class GeoService {
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Battery _battery = Battery();

  Timer? _geoTimer;
  StreamSubscription<BatteryState>? _batterySub;
  bool _isLowPowerMode = false;

  static const Duration _normalInterval = Duration(seconds: 60);
  static const Duration _lowPowerInterval = Duration(minutes: 5);

  /// Start uploading GPS coordinates.
  Future<void> start() async {
    await _checkBatteryState();
    _listenBatteryChanges();
    _scheduleUpdate();
  }

  /// Stop all geo updates.
  void stop() {
    _geoTimer?.cancel();
    _batterySub?.cancel();
  }

  /// Returns whether geo is running in degraded (low power) mode.
  bool get isLowPowerMode => _isLowPowerMode;

  // ─── Private ──────────────────────────────────────────

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
        // Power mode changed — reschedule at appropriate interval
        _geoTimer?.cancel();
        _scheduleUpdate();
      }
    });
  }

  void _scheduleUpdate() {
    final interval = _isLowPowerMode ? _lowPowerInterval : _normalInterval;
    _geoTimer = Timer.periodic(interval, (_) => _uploadLocation());
    // Upload immediately on start
    _uploadLocation();
  }

  Future<void> _uploadLocation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Encode geohash at precision 7 (~150m radius queries)
      final geohash =
          GeoHasher().encode(pos.longitude, pos.latitude, precision: 7);

      await _firestore.collection('users').doc(uid).set({
        'location': {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'geohash': geohash,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'radarActive': true,
        'isLowPowerMode': _isLowPowerMode,
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently fail — will retry on next tick
    }
  }
}
