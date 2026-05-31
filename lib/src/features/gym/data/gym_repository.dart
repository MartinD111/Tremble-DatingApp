import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tremble/src/core/api_client.dart';

class TrembleEvent {
  final String id;
  final String name;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final double? lat;
  final double? lng;
  final int radiusMeters;
  final String? locationLabel;

  const TrembleEvent({
    required this.id,
    required this.name,
    this.startsAt,
    this.endsAt,
    this.lat,
    this.lng,
    this.radiusMeters = 500,
    this.locationLabel,
  });

  factory TrembleEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final loc = data['location'] as Map<String, dynamic>? ?? {};
    return TrembleEvent(
      id: doc.id,
      name: data['name'] as String? ?? 'Event',
      startsAt: (data['startsAt'] as Timestamp?)?.toDate(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
      lat: (loc['lat'] as num?)?.toDouble(),
      lng: (loc['lng'] as num?)?.toDouble(),
      radiusMeters: data['radiusMeters'] as int? ?? 500,
      locationLabel: data['locationLabel'] as String?,
    );
  }
}

class GymLocation {
  final double lat;
  final double lng;

  const GymLocation({required this.lat, required this.lng});
}

class Gym {
  final String id;
  final String name;
  final String address;
  final GymLocation location;
  final int radiusMeters;

  const Gym({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.radiusMeters,
  });

  factory Gym.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final loc = data['location'] as Map<String, dynamic>? ?? {};
    return Gym(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown Gym',
      address: data['address'] as String? ?? '',
      location: GymLocation(
        lat: (loc['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (loc['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      radiusMeters: data['radiusMeters'] as int? ?? 80,
    );
  }
}

class GymRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TrembleApiClient _api = TrembleApiClient();

  /// Fetches all available gyms ordered by name.
  Future<List<Gym>> getGyms() async {
    final snap = await _db.collection('gyms').orderBy('name').get();
    return snap.docs.map((doc) => Gym.fromFirestore(doc)).toList();
  }

  /// Activates gym mode for the current user.
  ///
  /// [gymId] — Firestore gym document ID.
  /// [latitude] / [longitude] — current device coordinates from geolocator.
  /// Backend validates the user is within the gym's [radiusMeters].
  Future<Map<String, dynamic>> activateGymMode({
    required String gymId,
    required double latitude,
    required double longitude,
  }) async {
    return _api.call('onGymModeActivate', data: {
      'gymId': gymId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Manually deactivates gym mode for the current user.
  Future<void> deactivateGymMode() async {
    await _api.call('onGymModeDeactivate');
  }

  /// Returns currently active events (active == true, not yet ended).
  Future<List<TrembleEvent>> getActiveEvents() async {
    final snap = await _db
        .collection('events')
        .where('active', isEqualTo: true)
        .where('endsAt', isGreaterThan: Timestamp.now())
        .get();
    return snap.docs.map((doc) => TrembleEvent.fromFirestore(doc)).toList();
  }

  /// Activates event mode for the current user.
  /// [latitude] / [longitude] — backend validates the user is within the event radius.
  Future<Map<String, dynamic>> activateEventMode({
    required String eventId,
    required String eventName,
    required double latitude,
    required double longitude,
  }) async {
    return _api.call('onEventModeActivate', data: {
      'eventId': eventId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<void> deactivateEventMode() async {
    await _api.call('onEventModeDeactivate');
  }

  /// Activates run mode for the current user.
  Future<Map<String, dynamic>> activateRunMode() async {
    return _api.call('onRunModeActivate');
  }

  Future<void> deactivateRunMode() async {
    await _api.call('onRunModeDeactivate');
  }
}

final gymRepositoryProvider = Provider<GymRepository>((ref) => GymRepository());
