import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../auth/data/auth_repository.dart';
import '../data/gym_repository.dart';
import '../application/gym_mode_controller.dart';
import '../../../core/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GymDwellService — foreground dwell timer for gym arrival detection.
//
// Polls location every 60 seconds. If the user remains within a gym's radius
// for 10 consecutive minutes, fires a local push notification prompting them
// to activate Gym Mode.
//
// Lifecycle: started/stopped automatically by gymDwellServiceProvider based on:
//   - user.gymNotificationsEnabled == true
//   - gym mode is not already active
//   - at least one gym exists in Firestore
// ─────────────────────────────────────────────────────────────────────────────

class GymDwellService {
  GymDwellService({required this.gyms});

  final List<Gym> gyms;

  Timer? _timer;
  DateTime? _dwellStart;
  String? _dwellingGymId;
  bool _notificationSent = false;

  static const _checkInterval = Duration(minutes: 1);
  static const _dwellThreshold = Duration(minutes: 10);
  static const _notificationId = 9001;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, _tick);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick(Timer _) async {
    if (_notificationSent) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      Gym? nearbyGym;
      for (final gym in gyms) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          gym.location.lat,
          gym.location.lng,
        );
        if (distance <= gym.radiusMeters) {
          nearbyGym = gym;
          break;
        }
      }

      if (nearbyGym == null) {
        // User left all gyms — reset dwell tracking.
        _dwellStart = null;
        _dwellingGymId = null;
        return;
      }

      if (_dwellingGymId != nearbyGym.id) {
        // Entered a new gym — start dwell clock.
        _dwellingGymId = nearbyGym.id;
        _dwellStart = DateTime.now();
        return;
      }

      // Same gym — check how long they've been here.
      final elapsed = DateTime.now().difference(_dwellStart!);
      if (elapsed >= _dwellThreshold) {
        await _sendNotification(nearbyGym.name);
        _notificationSent = true;
      }
    } on Exception catch (e) {
      debugPrint('[GymDwell] Location check failed: $e');
    }
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
    debugPrint('[GymDwell] Notification sent for $gymName');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FutureProvider for gym list (cached)
// ─────────────────────────────────────────────────────────────────────────────

final gymsListProvider = FutureProvider<List<Gym>>((ref) {
  return ref.read(gymRepositoryProvider).getGyms();
});

// ─────────────────────────────────────────────────────────────────────────────
// gymDwellServiceProvider — manages the GymDwellService lifecycle.
// Watch this in HomeScreen to keep it alive.
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
