import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The /matches collection is backend-authoritative — firestore.rules only
/// permits a client to change `seenBy`. Writing status/isFound/foundAt or
/// gestures directly returned permission-denied and crashed the trembling
/// window (Sentry TREMBLE-FUNCTIONS-Z, build 26). Those two writes now route
/// through Cloud Function callables. `markMatchAsSeen` still writes `seenBy`
/// directly because the rules allow it.
void main() {
  final source = File('lib/src/features/match/data/wave_repository.dart')
      .readAsStringSync();

  test('markMatchAsFound routes through the markMatchFound callable', () {
    expect(source, contains("'markMatchFound'"));
    // No direct Firestore write of the found fields survives.
    expect(source, isNot(contains("'isFound': true")));
    expect(source, isNot(contains("'foundAt'")));
  });

  test('sendGesture routes through the sendMatchGesture callable', () {
    expect(source, contains("'sendMatchGesture'"));
    expect(source, isNot(contains('gestures.')));
  });

  test('both migrated writes go through TrembleApiClient', () {
    expect(source, contains("import '../../../core/api_client.dart';"));
    // markMatchFound + sendMatchGesture are invoked via the shared client.
    expect(source, contains("_api.call('markMatchFound'"));
    expect(source, contains("_api.call('sendMatchGesture'"));
  });

  test('markMatchAsSeen still writes seenBy directly (rules permit it)', () {
    expect(source, contains('seenBy'));
    expect(source, contains("FieldValue.arrayUnion"));
  });
}
