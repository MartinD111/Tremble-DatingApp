import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recap screens write viewedRecaps only for free users on close', () {
    final runSource = File(
      'lib/src/features/dashboard/presentation/run_recap_screen.dart',
    ).readAsStringSync();
    final eventSource = File(
      'lib/src/features/map/presentation/event_recap_screen.dart',
    ).readAsStringSync();
    final repositorySource = File(
      'lib/src/features/recap/data/viewed_recaps_repository.dart',
    ).readAsStringSync();

    expect(runSource, contains('markViewedRecapsOnClose'));
    expect(runSource, contains("type: 'run'"));
    expect(eventSource, contains('markViewedRecapOnClose'));
    expect(eventSource, contains("type: 'event'"));
    expect(repositorySource, contains('FieldValue.serverTimestamp()'));
    expect(repositorySource, contains("collection('viewedRecaps')"));
  });

  test('history loading filters viewed recaps for free users', () {
    final runSource = File(
      'lib/src/features/dashboard/presentation/run_recap_screen.dart',
    ).readAsStringSync();
    final matchesSource = File(
      'lib/src/features/matches/presentation/matches_screen.dart',
    ).readAsStringSync();

    expect(runSource, contains('viewedRecapIdsProvider(user.id)'));
    expect(runSource, contains('!viewedRecapIds.contains(doc.id)'));
    expect(matchesSource, contains('viewedRecapIdsProvider(user.id)'));
    expect(matchesSource, contains('shouldHideViewedMatchRecap'));
  });

  test('firestore rules allow owner read and write for viewed recaps', () {
    final source = File('firestore.rules').readAsStringSync();

    expect(source, contains('match /users/{uid}/viewedRecaps/{recapId}'));
    expect(source, contains('allow read, write: if isSelf(uid);'));
  });
}
