import 'dart:convert';

/// Represents a local safe zone where proximity matching is disabled.
class SafeZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }

  factory SafeZone.fromMap(Map<String, dynamic> map) {
    return SafeZone(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      radiusMeters: map['radiusMeters']?.toDouble() ?? 500.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SafeZone.fromJson(String source) =>
      SafeZone.fromMap(json.decode(source));
}
