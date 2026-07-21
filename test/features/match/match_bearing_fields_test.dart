import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/match/domain/match.dart';

Match _match({Map<String, double>? bearingFor, String? distanceBucket}) =>
    Match(
      id: 'a_b',
      userIds: const ['a', 'b'],
      createdAt: DateTime(2026, 7, 21),
      seenBy: const [],
      bearingFor: bearingFor ?? const {},
      distanceBucket: distanceBucket,
    );

void main() {
  group('Match.parseBearingFor', () {
    test('coerces Firestore num values (int or double) to double', () {
      final parsed = Match.parseBearingFor({'a': 90, 'b': 270.5});
      expect(parsed['a'], 90.0);
      expect(parsed['b'], 270.5);
      expect(parsed['a'], isA<double>());
    });

    test('null or wrong-typed input yields an empty map', () {
      expect(Match.parseBearingFor(null), isEmpty);
      expect(Match.parseBearingFor('nope'), isEmpty);
    });
  });

  group('Match.bearingForUser', () {
    test('returns the stored bearing for the given uid', () {
      expect(_match(bearingFor: const {'a': 42.0}).bearingForUser('a'), 42.0);
    });

    test('returns null when no bearing is stored for the uid', () {
      expect(_match(bearingFor: const {'a': 42.0}).bearingForUser('b'), isNull);
      expect(_match().bearingForUser('a'), isNull);
    });
  });

  test('distanceBucket defaults to null', () {
    expect(_match().distanceBucket, isNull);
    expect(_match(distanceBucket: '~50m').distanceBucket, '~50m');
  });
}
