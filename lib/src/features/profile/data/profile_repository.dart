import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/public_profile.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  ProfileRepository(this._firestore);

  Future<PublicProfile> getPublicProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Profil ne obstaja.');
    return PublicProfile.fromFirestore(doc);
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(FirebaseFirestore.instance);
}

@riverpod
Future<PublicProfile> publicProfile(PublicProfileRef ref, String uid) {
  return ref.read(profileRepositoryProvider).getPublicProfile(uid);
}
