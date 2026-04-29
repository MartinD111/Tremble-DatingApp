import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../auth/data/auth_repository.dart';
import '../data/gym_repository.dart';
import '../application/gym_mode_controller.dart';
import '../../../core/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymDwellService — event-driven geofence detection for Gym Mode.
//
// V2: Replaces the 1-minute foreground polling timer with GeofenceService
// event listeners. A geofence region is registered for each gym in Firestore.
// When the user enters a region and remains for 10 minutes, GeofenceService
// fires a DWELL event which triggers a local push notification.
//
// State machine per gym:
//   ENTER  → dwell clock starts (inside loiteringDelayMs window)
//   DWELL  → fires after 10 min continuous presence → send notification once
//   EXIT   → resets notification gate so re-entry re-notifies
//
// Platform notes:
//   Android — GeofenceService uses a reactive position stream from geolocator.
//             Background execution beyond OS idle threshold requires adding
//             WillStartForegroundTask (flutter_foreground_task) to the widget
//             tree — deferred to V3 to avoid conflicting with the existing
//             RadarForegroundService notification.
//             V3 path: native Android GeofencingClient via method channel
//             gives 0 % battery cost when app is killed.
//   iOS     — Uses background location stream. Requires
//             NSLocationAlwaysAndWhenInUseUsageDescription (declared) and
//             UIBackgroundModes: location (declared).
//
// Lifecycle: started/stopped by gymDwellServiceProvider based on:
//   - user.gymNotificationsEnabled == true
//   - gym mode is not already active
//   - at least one gym exists in Firestore
// ─────────────────────────────────────────────────────────────────────────────

class GymDwellService {
  GymDwellService({required this.gyms});

  final List<Gym> gyms;

  static const _loiteringDelayMs = 10 * 60 * 1000; // 10 minutes
  static const _notificationId = 9001;
  static const _defaultRadiusMeters = 80.0;

  bool _notificationSent = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void start() {
    final geofenceList = gyms.map(_gymToGeofence).toList();

    GeofenceService.instance
      ..setup(
        interval: 5000, // position check interval (ms) — iOS stream cadence
        accuracy: 100, // acceptable position accuracy (m)
        loiteringDelayMs: _loiteringDelayMs,
        statusChangeDelayMs: 10000, // debounce rapid enter/exit transitions
        useActivityRecognition: false,
        allowMockLocations: false,
        printDevLog: kDebugMode,
        geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
      )
      ..addGeofenceStatusChangeListener(_onGeofenceStatus)
      ..addStreamErrorListener(_onError);

    GeofenceService.instance.start(geofenceList).catchError(_onError);
    debugPrint('[GymDwell] Started — monitoring ${gyms.length} gym(s)');
  }

  void dispose() {
    GeofenceService.instance
      ..removeGeofenceStatusChangeListener(_onGeofenceStatus)
      ..removeStreamErrorListener(_onError)
      ..stop();
    debugPrint('[GymDwell] Stopped');
  }

  // ── Geofence helpers ──────────────────────────────────────────────────────

  Geofence _gymToGeofence(Gym gym) {
    final radius = gym.radiusMeters > 0
        ? gym.radiusMeters.toDouble()
        : _defaultRadiusMeters;
    return Geofence(
      id: gym.id,
      latitude: gym.location.lat,
      longitude: gym.location.lng,
      radius: [
        GeofenceRadius(id: 'radius_${gym.id}', length: radius),
      ],
    );
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  Future<void> _onGeofenceStatus(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus status,
    Location location,
  ) async {
    debugPrint('[GymDwell] ${geofence.id} → $status');

    // Reset notification gate when the user leaves so re-entry re-notifies.
    if (status == GeofenceStatus.EXIT) {
      _notificationSent = false;
      return;
    }

    if (status == GeofenceStatus.DWELL && !_notificationSent) {
      final gym = gyms.firstWhere(
        (g) => g.id == geofence.id,
        orElse: () => gyms.first,
      );
      await _sendNotification(gym.name);
      _notificationSent = true;
    }
  }

  // ignore: avoid_dynamic_calls — ValueChanged<dynamic> required by geofence_service
  void _onError(dynamic error) {
    debugPrint('[GymDwell] GeofenceService error: $error');
  }

  Future<void> _sendNotification(String gymName) async {
    const androidDetails = AndroidNotificationDetails(
      TrembleNotificationChannels.proximity,
      'Tremble — V bližini',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await NotificationService.notifications.show(
      _notificationId,
      'Si v $gymName? 💪',
      'Vklopiš Gym Mode in se poveži z drugimi!',
      details,
      payload: '{"type":"GYM_DWELL"}',
    );
    debugPrint('[GymDwell] DWELL notification sent for $gymName');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FutureProvider for gym list (cached per session)
// ─────────────────────────────────────────────────────────────────────────────

final gymsListProvider = FutureProvider<List<Gym>>((ref) {
  return ref.read(gymRepositoryProvider).getGyms();
});

// ─────────────────────────────────────────────────────────────────────────────
// gymDwellServiceProvider — manages GymDwellService lifecycle.
// Watch this in HomeScreen to keep the geofence listener alive.
// ─────────────────────────────────────────────────────────────────────────────

final gymDwellServiceProvider = Provider.autoDispose<GymDwellService?>((ref) {
  final user = ref.watch(authStateProvider);
  final gymState = ref.watch(gymModeControllerProvider);

  // Only run when the user has opted in and is not already in gym mode.
  if (user?.gymNotificationsEnabled != true) return null;
  if (gymState.isActive) return null;

  final gymsAsync = ref.watch(gymsListProvider);
  return gymsAsync.maybeWhen(
    data: (gyms) {
      if (gyms.isEmpty) return null;
      final service = GymDwellService(gyms: gyms);
      ref.onDispose(service.dispose);
      service.start();
      return service;
    },
    orElse: () => null,
  );
});
