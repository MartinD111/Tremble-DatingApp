import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The match reveal showed "?" instead of the partner's photo because
/// ProfileRepository read the partner's /users doc directly, which Firestore
/// rules deny (read: if isSelf). It now routes through the getPublicProfile
/// Cloud Function, which returns a whitelisted public view gated on a match.
void main() {
  final source = File('lib/src/features/profile/data/profile_repository.dart')
      .readAsStringSync();

  test('getPublicProfile routes through the getPublicProfile callable', () {
    expect(source, contains("import '../../../core/api_client.dart';"));
    expect(source, contains("_api.call('getPublicProfile'"));
  });

  test('no direct cross-user Firestore read survives', () {
    expect(source, isNot(contains("collection('users')")));
    expect(source, isNot(contains('FirebaseFirestore')));
  });

  test('PublicProfile parses the callable map, not a DocumentSnapshot', () {
    final model = File('lib/src/features/profile/domain/public_profile.dart')
        .readAsStringSync();
    expect(model, contains('factory PublicProfile.fromMap'));
    expect(model, isNot(contains('DocumentSnapshot')));
  });
}
