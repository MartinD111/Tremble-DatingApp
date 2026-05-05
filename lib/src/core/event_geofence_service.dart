import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// A single event location target for geofence proximity checks.
class GeofenceTarget {
  final String id;
  final String name;
  final double lat;
  final double lng;

  /// Geofence radius in metres. Default 500 m is appropriate for venue-scale
  /// events (clubs, festivals). Adjust per-event once real data is available.
  final double radiusMeters;

  const GeofenceTarget({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.radiusMeters = 500.0,
  });
}

/// In-memory event geofence state.
///
/// Tracks whether the user is inside a Tremble event geofence and provides
/// real-time GPS-based enter/exit detection. State is NEVER persisted to
/// Firestore — it is a runtime-only flag used exclusively for the
/// "Taste of Premium" UX during live events.
///
/// The GeoService continues to write radiusTier: 'free' for Free users even
/// when inEventGeofence is true — the backend is not affected.
class EventGeofenceService extends ChangeNotifier {
  bool _inEventGeofence = false;
  String? _activeEventId;
  String? _activeEventName;

  List<GeofenceTarget> _targets = [];
  StreamSubscription<Position>? _positionSub;

  bool get inEventGeofence => _inEventGeofence;
  String? get activeEventId => _activeEventId;
  String? get activeEventName => _activeEventName;

  // ── Manual enter/exit (dev simulation + unit tests) ─────────────────────

  void enterEvent({required String eventId, required String eventName}) {
    if (_inEventGeofence && _activeEventId == eventId) return;
    _inEventGeofence = true;
    _activeEventId = eventId;
    _activeEventName = eventName;
    notifyListeners();
  }

  void exitEvent() {
    if (!_inEventGeofence) return;
    _inEventGeofence = false;
    _activeEventId = null;
    _activeEventName = null;
    notifyListeners();
  }

  // ── GPS-based geofence ───────────────────────────────────────────────────

  /// Register the set of active events to watch via GPS.
  ///
  /// Starts listening to location updates once targets are provided and
  /// location permission has been granted. Safe to call multiple times —
  /// subsequent calls replace the target set without restarting the stream.
  Future<void> setActiveEvents(List<GeofenceTarget> targets) async {
    _targets = targets;
    if (_targets.isEmpty) {
      _stopListening();
      exitEvent();
      return;
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    if (_positionSub != null) return; // already running

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[GeofenceService] location permission not granted — '
          'geofence GPS inactive. Will use manual enter/exit only.');
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      // Re-evaluate geofence every 50 m of movement — balances accuracy
      // against battery drain for venue-scale (~150–500 m) radii.
      distanceFilter: 50,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: (Object e) {
      debugPrint('[GeofenceService] position stream error: $e');
    });
  }

  void _stopListening() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _onPosition(Position position) {
    for (final target in _targets) {
      final distM = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        target.lat,
        target.lng,
      );
      if (distM <= target.radiusMeters) {
        enterEvent(eventId: target.id, eventName: target.name);
        return;
      }
    }
    exitEvent();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}

/// Singleton geofence service. Uses [ChangeNotifierProvider] so any widget
/// watching this provider rebuilds immediately when geofence state changes.
final eventGeofenceServiceProvider =
    ChangeNotifierProvider<EventGeofenceService>(
  (ref) => EventGeofenceService(),
);
