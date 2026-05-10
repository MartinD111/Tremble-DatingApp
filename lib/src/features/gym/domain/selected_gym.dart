/// A gym chosen by the user from Google Places.
///
/// Stored in Firestore under users/{uid}.selectedGyms as a List of Maps.
/// Used by GymDwellService for personal geofencing.
class SelectedGym {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;

  const SelectedGym({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() => {
        'placeId': placeId,
        'name': name,
        'address': address,
        'location': {'lat': lat, 'lng': lng},
      };

  factory SelectedGym.fromMap(Map<String, dynamic> map) {
    final loc = map['location'] as Map<String, dynamic>? ?? {};
    return SelectedGym(
      placeId: map['placeId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      lat: (loc['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (loc['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedGym && other.placeId == placeId;

  @override
  int get hashCode => placeId.hashCode;
}
