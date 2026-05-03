import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/hobby_utils.dart';

class PublicProfile {
  final String id;
  final String name;
  final int age;
  final List<String> photoUrls;
  final List<Map<String, dynamic>> hobbies;
  final String? lookingFor;
  final bool isTraveler;

  PublicProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.photoUrls,
    required this.hobbies,
    this.lookingFor,
    this.isTraveler = false,
  });

  factory PublicProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PublicProfile(
      id: doc.id,
      name: data['name'] ?? 'Neznano',
      age: data['age'] ?? 18,
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      hobbies: HobbyUtils.parseHobbies(data['hobbies']),
      lookingFor: data['lookingFor'],
      isTraveler: data['isTraveler'] as bool? ?? false,
    );
  }

  /// Convenience: returns the first photo URL, or empty string if none.
  String get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';
}
