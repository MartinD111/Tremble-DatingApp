import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// Provider for the SafetyRepository
final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(TrembleApiClient());
});

class SafetyRepository {
  final TrembleApiClient _api;

  SafetyRepository(this._api);

  /// Blocks a user fully and permanently.
  Future<void> blockUser(String targetUid) async {
    await _api.call('blockUser', data: {'targetUid': targetUid});
  }

  /// Unblocks a user.
  Future<void> unblockUser(String targetUid) async {
    await _api.call('unblockUser', data: {'targetUid': targetUid});
  }

  /// Lists the caller's blocked users with display info (id, name, imageUrl).
  ///
  /// Goes through the `getBlockedUsers` callable because Firestore rules
  /// forbid a client from reading other users' `/users/{id}` docs directly
  /// (self-only reads) — a client fan-out over `blockedUserIds` fails with
  /// PERMISSION_DENIED whenever the list is non-empty. `imageUrl` may be null
  /// when the blocked user has no photos.
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final result = await _api.call('getBlockedUsers');
    final list = result['blockedUsers'] as List<dynamic>? ?? [];
    return list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  /// Reports a user for moderation and issues a personal block.
  Future<void> reportUser(
      String reportedUid, List<String> reasons, String explanation) async {
    await _api.call('reportUser', data: {
      'reportedUid': reportedUid,
      'reasons': reasons,
      'explanation': explanation,
    });
  }
}
