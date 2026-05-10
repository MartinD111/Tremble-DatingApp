import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/public_profile.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;
  ProfileRepository(this._firestore);

  Future<PublicProfile> getPublicProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) throw Exception('Profile not found for uid=$uid');
      return PublicProfile.fromFirestore(doc);
    } catch (e, st) {
      debugPrint('[ProfileRepository] getPublicProfile($uid) failed: $e\n$st');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository(FirebaseFirestore.instance);
}

@riverpod
Future<PublicProfile> publicProfile(PublicProfileRef ref, String uid) {
  return ref.watch(profileRepositoryProvider).getPublicProfile(uid);
}
