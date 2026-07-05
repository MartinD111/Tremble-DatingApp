import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:battery_plus/battery_plus.dart';
import '../features/map/domain/safe_zone_repository.dart';

const geoServiceEffectivePremiumPrefsKey = 'geo_effective_is_premium';

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

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _fallbackTimer;
  bool _isLowPowerMode = false;
  bool _isPremium = false;

  // Distance filters (metres). iOS location background mode keeps the process
  // alive while getPositionStream is active — this replaces the wall-clock
  // timer which froze under iOS process suspension.
  static const int _normalDistanceFilter = 50;
  static const int _lowPowerDistanceFilter = 200;

  // Stationary-user fallback: the position stream only fires on 50m+ movement,
  // so a user sitting at a café / lecture / gym would otherwise drop off all
  // radars. This timer forces a heartbeat every 90s regardless of movement.
  // It only ticks while the process is alive — the location stream keeps the
  // iOS process resident in background, so the two mechanisms cover each
  // other: stream keeps us alive, timer keeps us visible.
  static const Duration _fallbackInterval = Duration(seconds: 90);

  /// Geohash precision 7 ≈ 150m × 75m cell.
  /// Used as a coarse GPS pre-filter; BLE RSSI confirms final proximity.
  static const int _geohashPrecision = 7;

  /// Proximity docs auto-expire after 24h without refresh.
  /// Prevents stale location data persisting after the user closes the app.
  static const Duration _geoTtl = Duration(hours: 24);

  /// Start uploading location data.
  /// MUST only be called after the user has explicitly consented via
  /// the in-app location consent screen (locationConsentGiven == true).
  Future<void> start({required bool isPremium}) async {
    _isPremium = isPremium;
    await _checkBatteryState();
    _listenBatteryChanges();
    await _startPositionStream();
    _startFallbackTimer();
  }

  void updatePremiumTier({required bool isPremium}) {
    _isPremium = isPremium;
  }

  /// Stop all geo updates and mark user as inactive in Firestore.
  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _batterySub?.cancel();
    _batterySub = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
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
        await _startPositionStream();
      }
    });
  }

  /// Subscribe to Geolocator.getPositionStream so the OS delivers position
  /// events on movement (distanceFilter). On iOS this keeps the process
  /// alive under the `location` background mode instead of relying on a
  /// wall-clock timer that freezes when the app is suspended.
  ///
  /// IMPORTANT: AppleSettings with allowBackgroundLocationUpdates=true is
  /// required on iOS — without it CLLocationManager does not deliver events
  /// to a suspended process regardless of UIBackgroundModes: location.
  Future<void> _startPositionStream() async {
    await _positionSub?.cancel();
    _positionSub = null;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    } catch (_) {
      return;
    }

    final distanceFilter =
        _isLowPowerMode ? _lowPowerDistanceFilter : _normalDistanceFilter;

    // iOS: AppleSettings sets allowsBackgroundLocationUpdates = true on the
    // underlying CLLocationManager, which is mandatory for the OS to deliver
    // location events when the app is in background. Generic LocationSettings
    // does NOT set this flag — tested and confirmed non-functional.
    // Android: LocationSettings is sufficient (no equivalent restriction).
    final LocationSettings settings = Platform.isIOS
        ? AppleSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: distanceFilter,
            allowBackgroundLocationUpdates: true,
            pauseLocationUpdatesAutomatically: false,
            activityType: ActivityType.fitness,
          )
        : LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: distanceFilter,
          );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      _uploadLocation,
      onError: (Object _) {
        // Silently ignore transient stream errors — subscription stays alive.
      },
    );
  }

  /// Stationary-user fallback. getPositionStream only emits on 50m+ movement,
  /// so this timer forces a heartbeat every [_fallbackInterval] regardless of
  /// motion. Runs in parallel with the stream — no coordination needed since
  /// two writes to the same geohash are idempotent server-side.
  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(_fallbackInterval, (_) async {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
        // Use the last known position for the fallback heartbeat to avoid
        // an additional GPS fix request — the stream already keeps GPS warm.
        // Falls back to getCurrentPosition if no last known position exists.
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: Platform.isIOS
                  ? AppleSettings(
                      accuracy: LocationAccuracy.medium,
                      timeLimit: Duration(seconds: 10),
                      allowBackgroundLocationUpdates: true,
                      pauseLocationUpdatesAutomatically: false,
                    )
                  : LocationSettings(
                      accuracy: LocationAccuracy.medium,
                      timeLimit: Duration(seconds: 10),
                    ),
            );
        await _uploadLocation(pos);
      } catch (_) {
        // Silently ignore — next tick retries.
      }
    });
  }

  Future<void> _uploadLocation(Position pos) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
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

      // Radius tier mirrors the app's effective premium resolution at radar
      // start/update time so RevenueCat-only premium users are treated correctly.
      final radiusTier = _isPremium ? 'pro' : 'free';

      // TTL: proximity doc auto-expires after 24h without refresh.
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
