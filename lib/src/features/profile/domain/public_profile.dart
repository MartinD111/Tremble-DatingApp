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

  /// Parses the `profile` object returned by the `getPublicProfile` Cloud
  /// Function. A client cannot read another user's `/users` document directly
  /// (Firestore rules: `read: if isSelf`), so the partner's public view always
  /// arrives as a plain map from the callable rather than a Firestore doc.
  factory PublicProfile.fromMap(Map<String, dynamic> data) {
    return PublicProfile(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Neznano',
      age: (data['age'] as num?)?.toInt() ?? 18,
      photoUrls: List<String>.from(data['photoUrls'] ?? const <String>[]),
      hobbies: HobbyUtils.parseHobbies(data['hobbies']),
      lookingFor: data['lookingFor'] as String?,
      isTraveler: data['isTraveler'] as bool? ?? false,
    );
  }

  /// Convenience: returns the first photo URL, or empty string if none.
  String get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';
}
