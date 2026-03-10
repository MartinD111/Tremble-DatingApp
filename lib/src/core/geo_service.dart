import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:battery_plus/battery_plus.dart';

/// Geo Service — uploads minimized location data to Firestore periodically.
///
/// GDPR Compliance (Art. 5 — Data Minimization):
/// - Only a Geohash at precision 8 (~38x19m) is stored. Raw GPS coordinates
///   (lat, lng) are NEVER written to Firestore. This prevents identification
///   of a user's exact address or home location.
///
/// Proximity tiers:
///   Free users  — radar shows users in the same geohash cell (~38m)
///   Premium     — radar shows users in current + 8 adjacent cells (~100m)
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

  /// Geohash precision 8 ≈ 38m × 19m cell.
  /// Free users see matches in the same cell (~38m).
  /// Premium users see matches across a 3×3 grid (~100m).
  static const int _geohashPrecision = 8;

  /// Start uploading location data.
  /// MUST only be called after the user has explicitly consented via
  /// the in-app location consent screen (locationConsentGiven == true).
  Future<void> start() async {
    await _checkBatteryState();
    _listenBatteryChanges();
    _scheduleUpdate();
  }

  /// Stop all geo updates and mark user as inactive in Firestore.
  Future<void> stop() async {
    _geoTimer?.cancel();
    _batterySub?.cancel();

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('proximity').doc(uid).set({
        'radarActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-critical — silently fail
    }
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
        _geoTimer?.cancel();
        _scheduleUpdate();
      }
    });
  }

  void _scheduleUpdate() {
    final interval = _isLowPowerMode ? _lowPowerInterval : _normalInterval;
    _geoTimer = Timer.periodic(interval, (_) => _uploadLocation());
    _uploadLocation();
  }

  Future<void> _uploadLocation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // GDPR Art. 5 — Data Minimization:
      // Only encode as Geohash at precision 8 (~38m cell).
      // Raw coordinates are used locally for encoding ONLY and are
      // never written to Firestore.
      final geohash = GeoHasher().encode(
        pos.longitude,
        pos.latitude,
        precision: _geohashPrecision,
      );

      // TTL field: proximity doc auto-expires if not refreshed for 2 hours.
      // This prevents stale location data persisting after the user closes the app.
      final ttl = Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 2)),
      );

      // Write ONLY the minimized geohash — no lat, no lng.
      await _firestore.collection('proximity').doc(uid).set({
        'geohash': geohash,
        'radarActive': true,
        'isLowPowerMode': _isLowPowerMode,
        'updatedAt': FieldValue.serverTimestamp(),
        'ttl': ttl, // Firestore TTL — delete if stale > 2h
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently fail — will retry on next tick
    }
  }
}
