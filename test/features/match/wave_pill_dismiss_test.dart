import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tremble/src/features/match/presentation/widgets/match_notification_pill.dart';
import 'package:tremble/src/shared/ui/wave_pill_service.dart';

// BUG-IS-NEARBY-PERSISTS (Session 55): the "{name} is nearby" pill lingered
// after the user waved to that person and after they entered the match page.
// WavePillService now exposes dismissForTarget(uid) (used once a wave is sent)
// and dismiss() (used on match-page entry).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(WavePillService.dismiss);

  Future<OverlayState> pumpOverlay(WidgetTester tester) async {
    final key = GlobalKey<OverlayState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          key: key,
          initialEntries: [
            OverlayEntry(builder: (_) => const SizedBox.shrink()),
          ],
        ),
      ),
    );
    return key.currentState!;
  }

  WavePillData data(String uid, String name) => WavePillData(
        name: name,
        age: 24,
        imageUrl: '',
        targetUid: uid,
        isIncomingWave: false,
      );

  testWidgets('dismissForTarget removes the pill only for the matching uid',
      (tester) async {
    final overlay = await pumpOverlay(tester);
    WavePillService.show(
      overlay: overlay,
      data: data('ana', 'Ana'),
      onWave: (_) {},
    );
    await tester.pump();
    expect(find.byType(MatchNotificationPill), findsOneWidget);

    // A wave sent to someone else must NOT tear down Ana's pill.
    WavePillService.dismissForTarget('bob');
    await tester.pump();
    expect(find.byType(MatchNotificationPill), findsOneWidget);

    // A wave sent to Ana clears her now-stale nearby pill.
    WavePillService.dismissForTarget('ana');
    await tester.pump();
    expect(find.byType(MatchNotificationPill), findsNothing);
  });

  testWidgets('dismiss clears the pill regardless of uid (match-page entry)',
      (tester) async {
    final overlay = await pumpOverlay(tester);
    WavePillService.show(
      overlay: overlay,
      data: data('ana', 'Ana'),
      onWave: (_) {},
    );
    await tester.pump();
    expect(find.byType(MatchNotificationPill), findsOneWidget);

    WavePillService.dismiss();
    await tester.pump();
    expect(find.byType(MatchNotificationPill), findsNothing);
  });

  testWidgets('dismissForTarget is a safe no-op when no pill is showing',
      (tester) async {
    await pumpOverlay(tester);
    WavePillService.dismissForTarget('ana');
    await tester.pump();
    expect(find.byType(MatchNotificationPill), findsNothing);
  });
}
