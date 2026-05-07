import 'dart:convert';

/// Represents a local safe zone where proximity matching is disabled.
class SafeZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;

  SafeZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.isActive = true,
  });

  SafeZone copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    bool? isActive,
  }) {
    return SafeZone(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'isActive': isActive,
    };
  }

  factory SafeZone.fromMap(Map<String, dynamic> map) {
    return SafeZone(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      radiusMeters: map['radiusMeters']?.toDouble() ?? 500.0,
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory SafeZone.fromJson(String source) =>
      SafeZone.fromMap(json.decode(source));
}
