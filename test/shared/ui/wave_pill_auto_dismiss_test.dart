import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tremble/src/features/match/presentation/widgets/match_notification_pill.dart';
import 'package:tremble/src/shared/ui/wave_pill_service.dart';

// ---------------------------------------------------------------------------
// Wave pill auto-dismiss
//
// An unanswered pill must not sit on screen forever — it covers the UI and the
// proximity claim behind it goes stale. It self-closes after a quiet period.
//
// The load-bearing behaviour is CANCELLATION, not the timer: any user reaction
// must cancel it, or a Wave tapped just before the deadline gets torn down
// mid-request.
//
// A short duration is injected so these run in milliseconds rather than three
// real minutes. flutter_test asserts on timers still pending when the tree is
// disposed, so a leaked timer fails the test on its own.
// ---------------------------------------------------------------------------

const _pillData = WavePillData(
  name: 'User Alpha',
  age: 27,
  imageUrl: '',
  targetUid: 'uid-sender',
  isIncomingWave: false, // waitingForAction — no rainbow/shake entry animation
);

const _shortDismiss = Duration(seconds: 30);

Future<OverlayState> _pumpOverlayHost(WidgetTester tester) async {
  late OverlayState overlay;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          overlay = Overlay.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return overlay;
}

/// Advances past the entry animation so the pill reaches its interactive state.
Future<void> _settleEntry(WidgetTester tester) async {
  await tester.pump(); // insert the entry, start the drop
  await tester.pump(const Duration(milliseconds: 900)); // drop completes
  await tester.pump(const Duration(milliseconds: 500)); // expand completes
}

Finder get _pill => find.byType(MatchNotificationPill);

void main() {
  setUp(() async {
    // Park the swipe-hint counter past its threshold so show() takes the
    // no-write path and the tests do not depend on execution order.
    SharedPreferences.setMockInitialValues({'wave_pill_hint_count': 3});
    await WavePillService.preloadHintCount();
  });

  tearDown(WavePillService.dismiss);

  testWidgets('closes an unanswered pill once the quiet period elapses',
      (tester) async {
    final overlay = await _pumpOverlayHost(tester);

    WavePillService.show(
      overlay: overlay,
      data: _pillData,
      onWave: (_) async {},
      autoDismissAfter: _shortDismiss,
    );
    await _settleEntry(tester);
    expect(_pill, findsOneWidget);

    await tester.pump(_shortDismiss);
    await tester.pump();

    expect(_pill, findsNothing);
  });

  testWidgets('keeps the pill up until the quiet period is actually reached',
      (tester) async {
    final overlay = await _pumpOverlayHost(tester);

    WavePillService.show(
      overlay: overlay,
      data: _pillData,
      onWave: (_) async {},
      autoDismissAfter: _shortDismiss,
    );
    await _settleEntry(tester);

    // Well inside the window (~21s of 30s elapsed).
    await tester.pump(const Duration(seconds: 20));

    expect(_pill, findsOneWidget);

    WavePillService.dismiss(); // disarm before teardown
    await tester.pump();
  });

  testWidgets('a Wave tap cancels auto-dismiss so a slow send is not cut off',
      (tester) async {
    final overlay = await _pumpOverlayHost(tester);
    final inFlight = Completer<void>();
    var waveCalls = 0;

    WavePillService.show(
      overlay: overlay,
      data: _pillData,
      onWave: (_) {
        waveCalls++;
        return inFlight.future; // send that never resolves in this test
      },
      autoDismissAfter: _shortDismiss,
    );
    await _settleEntry(tester);

    await tester.tap(find.byIcon(LucideIcons.hand));
    await tester.pump();
    expect(waveCalls, 1);

    // Push well past the original deadline while the send is still in flight.
    await tester.pump(const Duration(seconds: 31));

    // Uncancelled, the timer would have ripped the pill out from under the
    // user mid-request.
    expect(_pill, findsOneWidget);

    WavePillService.dismiss();
    await tester.pump();
  });

  testWidgets('an explicit dismiss cancels the pending timer', (tester) async {
    final overlay = await _pumpOverlayHost(tester);

    WavePillService.show(
      overlay: overlay,
      data: _pillData,
      onWave: (_) async {},
      autoDismissAfter: _shortDismiss,
    );
    await _settleEntry(tester);

    WavePillService.dismiss();
    await tester.pump();

    expect(_pill, findsNothing);
    // A timer surviving the dismiss would fail this test at teardown.
  });

  testWidgets('replacing a pill does not leave the old timer armed',
      (tester) async {
    final overlay = await _pumpOverlayHost(tester);

    WavePillService.show(
      overlay: overlay,
      data: _pillData,
      onWave: (_) async {},
      autoDismissAfter: const Duration(seconds: 5),
    );
    await _settleEntry(tester);

    WavePillService.show(
      overlay: overlay,
      data: _pillData,
      onWave: (_) async {},
      autoDismissAfter: _shortDismiss,
    );
    await _settleEntry(tester);

    // Past the first pill's 5s deadline: a surviving timer would dismiss the
    // replacement early.
    await tester.pump(const Duration(seconds: 6));
    expect(_pill, findsOneWidget);

    await tester.pump(_shortDismiss);
    await tester.pump();
    expect(_pill, findsNothing);
  });

  testWidgets('defaults to a three-minute quiet period', (tester) async {
    final overlay = await _pumpOverlayHost(tester);

    expect(WavePillService.defaultAutoDismissAfter, const Duration(minutes: 3));

    WavePillService.show(
      overlay: overlay,
      data: _pillData,
      onWave: (_) async {},
    );
    await _settleEntry(tester);

    // ~171s elapsed — inside three minutes.
    await tester.pump(const Duration(seconds: 170));
    expect(_pill, findsOneWidget);

    // ~191s elapsed — past it.
    await tester.pump(const Duration(seconds: 20));
    await tester.pump();
    expect(_pill, findsNothing);
  });
}
