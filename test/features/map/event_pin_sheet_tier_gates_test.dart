// KORAK 3.7c-3 · pair-of-tests per ADR-007 §4 for the event pin sheet
// tier gates named in ADR-007 §3. Read-only regression net — no
// behaviour change ships with these tests.
//
// The widget's `_DevGeofenceControls` renders when `FLAVOR` resolves
// to `dev`, which is the default in test runs (no `--dart-define`).
// The finder queries below scope to the participant-count and
// heatmap rows so the dev block does not interfere.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/map/presentation/event_pin_sheet.dart';

const _lang = 'en';

TrembleEventData _event() => const TrembleEventData(
      id: 'club_monokel',
      name: 'Club Monokel',
      isActive: true,
      startsAt: null,
      peopleCount: 42,
      locationLabel: 'Ljubljana',
    );

Widget _harness(EventPinSheet sheet) => MaterialApp(
      home: Scaffold(body: sheet),
    );

void main() {
  final expectedCountText =
      t('pulsing_here', _lang).replaceAll('{count}', '42');
  final lockedCountText = t('pulsing_here', _lang).replaceAll('{count}', '??');
  final proFeatureLocked = t('pro_feature_locked', _lang);
  final heatmapLocked = t('heatmap_locked', _lang);

  group('ADR-007 §3 — event pin sheet participant count gate', () {
    testWidgets(
        'Free tier: participant count row is locked '
        '(shows "?? Pulsing here" + pro_feature_locked pill, hides the '
        'real count)', (tester) async {
      await tester.pumpWidget(_harness(EventPinSheet(
        event: _event(),
        effectiveIsPremium: false,
        isTasteOfPremium: false,
        isDark: false,
        lang: _lang,
      )));

      expect(find.text(lockedCountText), findsOneWidget,
          reason: 'Free tier must see the "??" placeholder row');
      expect(find.text(proFeatureLocked), findsWidgets,
          reason: 'Free tier must see the pro-locked pill copy');
      expect(find.text(expectedCountText), findsNothing,
          reason: 'Free tier must NEVER see the real participant count — '
              'that is the entire point of the ADR-007 §3 gate');
    });

    testWidgets(
        'Premium tier: participant count row is unlocked '
        '(shows the actual count, hides the locked placeholder)',
        (tester) async {
      await tester.pumpWidget(_harness(EventPinSheet(
        event: _event(),
        effectiveIsPremium: true,
        isTasteOfPremium: false,
        isDark: false,
        lang: _lang,
      )));

      expect(find.text(expectedCountText), findsOneWidget,
          reason: 'Premium tier must see the real participant count per '
              'ADR-007 §3');
      expect(find.text(lockedCountText), findsNothing,
          reason: 'Premium tier must NOT see the "??" placeholder');
      // pro_feature_locked pill belongs to the locked variant of the
      // count row and must not appear on the Premium path.
      expect(find.text(proFeatureLocked), findsNothing,
          reason: 'Premium tier must NOT see the pro_feature_locked pill '
              'on the count row');
    });
  });

  group('ADR-007 §3 — event pin sheet heatmap indicator gate', () {
    testWidgets(
        'Free tier: heatmap row is locked '
        '(shows heatmap_locked pill, hides the LIVE indicator)',
        (tester) async {
      await tester.pumpWidget(_harness(EventPinSheet(
        event: _event(),
        effectiveIsPremium: false,
        isTasteOfPremium: false,
        isDark: false,
        lang: _lang,
      )));

      expect(find.text(heatmapLocked), findsOneWidget,
          reason: 'Free tier must see the "Heatmap — Pro only" pill');
      expect(find.text('LIVE'), findsNothing,
          reason: 'Free tier must NEVER see the LIVE heatmap indicator per '
              'ADR-007 §3');
    });

    testWidgets(
        'Premium tier: heatmap row is unlocked '
        '(shows LIVE indicator, hides the locked pill)', (tester) async {
      await tester.pumpWidget(_harness(EventPinSheet(
        event: _event(),
        effectiveIsPremium: true,
        isTasteOfPremium: false,
        isDark: false,
        lang: _lang,
      )));

      expect(find.text('LIVE'), findsOneWidget,
          reason: 'Premium tier must see the LIVE heatmap indicator per '
              'ADR-007 §3');
      expect(find.text(heatmapLocked), findsNothing,
          reason: 'Premium tier must NOT see the heatmap-locked pill');
    });
  });
}
