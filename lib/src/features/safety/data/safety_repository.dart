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

  /// Reports a user for moderation and issues a personal block.
  Future<void> reportUser(String reportedUid, List<String> reasons, String explanation) async {
    await _api.call('reportUser', data: {
      'reportedUid': reportedUid,
      'reasons': reasons,
      'explanation': explanation,
    });
  }
}
