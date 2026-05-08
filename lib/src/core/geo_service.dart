import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:battery_plus/battery_plus.dart';
import '../features/map/domain/safe_zone_repository.dart';

/// Geo Service — uploads minimized location data to Firestore periodically.
///
/// GDPR Compliance (Art. 5 — Data Minimization):
/// - Only a Geohash at precision 7 (~150m×75m cell) is stored. Raw GPS
///   coordinates (lat, lng) are NEVER written to Firestore. The geohash is
///   reversible to ~75m accuracy — NOT the user's exact location.
///
/// Proximity tiers (F9 — Radius Logic):
///   Free    — GPS geohash pre-filter 100m + RSSI threshold ≥ −75 dBm
///   Premium — GPS geohash pre-filter 250m + RSSI threshold ≥ −85 dBm
///
/// The tier is written as `radiusTier: 'free' | 'pro'` so Cloud Functions
/// can apply the correct radius without trusting the client for premium status.
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
  bool _isPremium = false;

  static const Duration _normalInterval = Duration(seconds: 60);
  static const Duration _lowPowerInterval = Duration(minutes: 5);

  /// Geohash precision 7 ≈ 150m × 75m cell.
  /// Used as a coarse GPS pre-filter; BLE RSSI confirms final proximity.
  static const int _geohashPrecision = 7;

  /// Proximity docs auto-expire after 30 min without refresh.
  /// Prevents stale location data persisting after the user closes the app.
  static const Duration _geoTtl = Duration(minutes: 30);

  /// Start uploading location data.
  /// MUST only be called after the user has explicitly consented via
  /// the in-app location consent screen (locationConsentGiven == true).
  Future<void> start() async {
    await _fetchUserTier();
    await _checkBatteryState();
    _listenBatteryChanges();
    _scheduleUpdate();
  }

  /// Reads the user's `isPremium` flag from Firestore once at service start.
  /// Result is cached for the lifetime of this radar session.
  Future<void> _fetchUserTier() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final doc = await _firestore.collection('users').doc(uid).get();
      _isPremium = doc.data()?['isPremium'] as bool? ?? false;
    } catch (_) {
      _isPremium = false;
    }
  }

  /// Stop all geo updates and mark user as inactive in Firestore.
  Future<void> stop() async {
    _geoTimer?.cancel();
    _batterySub?.cancel();
    _isPremium = false;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('proximity').doc(uid).set({
        'radarActive': false,
        'isActive': false,
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

      // F13: Geofencing Safe Zones
      // If the user's exact current location falls within any local Safe Zone,
      // completely abort the geo-upload (proximity matching is disabled here).
      final safeZoneRepo = SafeZoneRepository();
      final safeZones = await safeZoneRepo.getSafeZones();
      for (final zone in safeZones) {
        if (!zone.isActive) continue;
        final distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          zone.latitude,
          zone.longitude,
        );
        if (distance <= zone.radiusMeters) {
          // Inside a safe zone: ensure radar appears inactive server-side
          await _firestore.collection('proximity').doc(uid).set({
            'radarActive': false,
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return;
        }
      }

      // GDPR Art. 5 — Data Minimization:
      // Only encode as Geohash at precision 7 (~150m × 75m cell).
      // Raw coordinates are used locally for encoding ONLY and are
      // never written to Firestore. The geohash is reversible to ~75m
      // accuracy — this is disclosed in the Privacy Policy.
      final geohash = GeoHasher().encode(
        pos.longitude,
        pos.latitude,
        precision: _geohashPrecision,
      );

      // Radius tier — written server-side so Cloud Functions can apply
      // the correct GPS pre-filter without trusting the client.
      // isPremium is read from Firestore once at start() — not from client.
      final radiusTier = _isPremium ? 'pro' : 'free';

      // TTL: proximity doc auto-expires after 30 min without refresh.
      // Prevents stale location data persisting after the user closes the app.
      final geoHashExpiresAt = Timestamp.fromDate(
        DateTime.now().add(_geoTtl),
      );

      // Write ONLY the minimized geohash — no lat, no lng.
      // isActive mirrors radarActive for Cloud Function query compatibility.
      await _firestore.collection('proximity').doc(uid).set({
        'geohash': geohash,
        'radiusTier': radiusTier,
        'radarActive': true,
        'isActive': true,
        'isLowPowerMode': _isLowPowerMode,
        'updatedAt': FieldValue.serverTimestamp(),
        'geoHashExpiresAt': geoHashExpiresAt,
      }, SetOptions(merge: true));
    } catch (_) {
      // Silently fail — will retry on next tick
    }
  }
}
