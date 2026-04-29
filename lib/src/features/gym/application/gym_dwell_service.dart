import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../data/gym_repository.dart';
import '../application/gym_mode_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymDwellService — thin Method Channel bridge to native OS geofencing.
//
// All dwell logic lives on the platform side:
//
//   Android — GeofencingClient (play-services-location) registers a
//             GEOFENCE_TRANSITION_DWELL listener with a 10-minute loitering
//             delay. The OS fires GymGeofenceReceiver via PendingIntent even
//             when the app is killed. Battery cost in idle/killed state: 0 %.
//
//   iOS     — CLLocationManager.startMonitoring registers circular regions
//             (70–100 m, default 80 m). On didEnterRegion a
//             UNTimeIntervalNotificationTrigger is scheduled 10 minutes out.
//             On didExitRegion the pending notification is cancelled.
//             The iOS notification system fires the notification regardless
//             of whether the app is alive. Battery cost in killed state: 0 %.
//
// This class only sends the gym list to native on start and removes it on
// dispose. There is no timer, no location stream, and no polling.
//
// Lifecycle: started/stopped by gymDwellServiceProvider based on:
//   - user.gymNotificationsEnabled == true
//   - gym mode is not already active
//   - at least one gym exists in Firestore
// ─────────────────────────────────────────────────────────────────────────────

class GymDwellService {
  GymDwellService({required this.gyms});

  final List<Gym> gyms;

  static const _channel = MethodChannel('tremble.dating.app/geofence');

  void start() {
    final payload = gyms
        .map(
          (g) => {
            'id': g.id,
            'name': g.name,
            'lat': g.location.lat,
            'lng': g.location.lng,
            'radiusMeters': g.radiusMeters,
          },
        )
        .toList();

    _channel.invokeMethod<void>('startMonitoring', payload).then(
          (_) => debugPrint(
              '[GymDwell] Native monitoring started (${gyms.length} gym(s))'),
          onError: (Object e) =>
              debugPrint('[GymDwell] startMonitoring error: $e'),
        );
  }

  void dispose() {
    _channel.invokeMethod<void>('stopMonitoring').then(
          (_) => debugPrint('[GymDwell] Native monitoring stopped'),
          onError: (Object e) =>
              debugPrint('[GymDwell] stopMonitoring error: $e'),
        );
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
// Watch this in HomeScreen to keep the channel registration alive.
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
