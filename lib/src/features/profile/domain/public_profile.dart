import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfile {
  final String id;
  final String name;
  final int age;
  final List<String> photoUrls;
  final List<String> hobbies;
  final String? lookingFor;

  PublicProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.photoUrls,
    required this.hobbies,
    this.lookingFor,
  });

  factory PublicProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PublicProfile(
      id: doc.id,
      name: data['name'] ?? 'Neznano',
      age: data['age'] ?? 18,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      hobbies: List<String>.from(data['hobbies'] ?? []),
      lookingFor: data['lookingFor'],
    );
  }

  /// Convenience: returns the first photo URL, or empty string if none.
  String get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';
}
