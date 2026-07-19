import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api_client.dart';
import '../domain/public_profile.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  final TrembleApiClient _api;
  ProfileRepository({TrembleApiClient? api}) : _api = api ?? TrembleApiClient();

  /// Fetches a partner's public profile via the `getPublicProfile` Cloud
  /// Function. Firestore rules forbid a client from reading another user's
  /// `/users` document directly (`read: if isSelf`) — a direct read returned
  /// permission-denied, which surfaced as the "?" placeholder on the match
  /// reveal. The callable (Admin SDK) returns a whitelisted public view and is
  /// gated on an existing match between the two users.
  Future<PublicProfile> getPublicProfile(String uid) async {
    final res = await _api.call('getPublicProfile', data: {'userId': uid});
    final profile = res['profile'];
    if (profile == null) {
      throw Exception('Public profile unavailable for uid=$uid');
    }
    return PublicProfile.fromMap(Map<String, dynamic>.from(profile as Map));
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepository();
}

@riverpod
Future<PublicProfile> publicProfile(PublicProfileRef ref, String uid) {
  return ref.watch(profileRepositoryProvider).getPublicProfile(uid);
}
