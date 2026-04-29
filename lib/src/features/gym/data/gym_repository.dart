import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tremble/src/core/api_client.dart';

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
      radiusMeters: data['radiusMeters'] as int? ?? 200,
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
}

final gymRepositoryProvider = Provider<GymRepository>((ref) => GymRepository());
