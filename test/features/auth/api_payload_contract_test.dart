import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';

// Contract tests for AuthUser.toApiPayload() against the Cloud Functions
// completeOnboarding/updateProfile Zod schema. If a test fails, do not loosen
// these assertions in this task; open a separate serialization fix task and
// update the client/server contract deliberately.
void main() {
  group('AuthUser.toApiPayload contract', () {
    test('hobbies serialize as List<String> IDs only', () {
      const user = AuthUser(
        id: 'user-1',
        hobbies: [
          {'id': 'running', 'name': 'Running'},
          {'id': 'music', 'name': 'Music'},
        ],
      );

      final payload = user.toApiPayload();
      final hobbies = payload['hobbies'];

      expect(payload, contains('hobbies'));
      expect(hobbies, isA<List<String>>());
      expect(hobbies, everyElement(isA<String>()));
      expect(hobbies, ['running', 'music']);
      expect(hobbies, isNot(contains(isA<Map<dynamic, dynamic>>())));
    });

    test('nicotineUse serializes as a single String or null, never a list', () {
      const nicotineUser = AuthUser(
        id: 'user-1',
        nicotineUse: ['vape', 'cigarettes'],
      );
      final nicotinePayload = nicotineUser.toApiPayload();

      expect(nicotinePayload, contains('nicotineUse'));
      expect(nicotinePayload['nicotineUse'], isA<String>());
      expect(nicotinePayload['nicotineUse'], 'vape');
      expect(nicotinePayload['nicotineUse'], isNot(isA<List<dynamic>>()));

      const nicotineFreeUser = AuthUser(id: 'user-2');
      final nicotineFreePayload = nicotineFreeUser.toApiPayload();

      expect(nicotineFreePayload, contains('nicotineUse'));
      expect(nicotineFreePayload['nicotineUse'], isNull);
      expect(nicotineFreePayload['nicotineUse'], isNot(isA<List<dynamic>>()));
    });

    test('nicotineFilter is absent when null', () {
      const user = AuthUser(id: 'user-1');

      final payload = user.toApiPayload();

      expect(payload.containsKey('nicotineFilter'), isFalse);
    });

    test('lookingFor serializes as List<String>', () {
      const user = AuthUser(
        id: 'user-1',
        lookingFor: ['long_term_partner', 'short_open_long'],
      );

      final payload = user.toApiPayload();
      final lookingFor = payload['lookingFor'];

      expect(payload, contains('lookingFor'));
      expect(lookingFor, isA<List<String>>());
      expect(lookingFor, everyElement(isA<String>()));
      expect(lookingFor, ['long_term_partner', 'short_open_long']);
    });

    test('server-managed privilege fields are not serialized', () {
      const user = AuthUser(
        id: 'user-1',
        isPremium: true,
        isAdmin: true,
      );

      final payload = user.toApiPayload();

      expect(payload.containsKey('isPremium'), isFalse);
      expect(payload.containsKey('isAdmin'), isFalse);
    });
  });
}
