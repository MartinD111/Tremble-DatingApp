import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/dashboard/presentation/run_recap_screen.dart';

void main() {
  test('safeRecapUserIdsFromData treats missing or malformed userIds as empty',
      () {
    expect(safeRecapUserIdsFromData(const {}), isEmpty);
    expect(safeRecapUserIdsFromData(const {'userIds': 'not-a-list'}), isEmpty);
    expect(
      safeRecapUserIdsFromData(const {
        'userIds': ['me', 7, 'partner'],
      }),
      ['me', 'partner'],
    );
  });

  testWidgets('recap provider error content is visible and brand-colored',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: recapProviderErrorContent(
            Exception('boom'),
            StackTrace.current,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Something went wrong.'));
    expect(text.style?.color, const Color(0xFF6B6B63));
  });

  test('run recap and gym sheets do not silently drop crash-prone paths', () {
    final runRecap = File(
      'lib/src/features/dashboard/presentation/run_recap_screen.dart',
    ).readAsStringSync();
    final eventRecap = File(
      'lib/src/features/map/presentation/event_recap_screen.dart',
    ).readAsStringSync();
    final gymSheet = File(
      'lib/src/features/gym/presentation/gym_mode_sheet.dart',
    ).readAsStringSync();

    expect(runRecap, contains('safeRecapUserIdsFromData'));
    expect(runRecap, contains('RecapProvider error:'));
    expect(runRecap, isNot(contains('error: (_, __) =>')));
    expect(runRecap, contains('sendWave error:'));
    expect(runRecap, contains('wave_failed'));
    expect(runRecap, contains('viewedRecaps write failed:'));
    expect(eventRecap, contains('viewedRecaps write failed:'));
    expect(gymSheet, isNot(contains('ref.read(authStateProvider)!')));
    expect(gymSheet, contains('if (user == null) return;'));
  });
}
