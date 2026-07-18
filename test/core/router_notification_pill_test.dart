import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/router.dart' show handleNotificationNavigation;
import 'package:tremble/src/shared/ui/wave_pill_service.dart' show WavePillData;

// ---------------------------------------------------------------------------
// Notification-tap → WavePill dispatch
//
// Covers the background/killed path: the user taps an INCOMING_WAVE or
// CROSSING_PATHS system notification, the app opens, and the pill must be
// presented over whatever screen the router lands on.
//
// The presenter is injected so these stay pure Dart — no Firebase, no Overlay.
// ---------------------------------------------------------------------------

void main() {
  // RUN_INTERCEPT reads rootNavigatorKey.currentContext, and GlobalKey needs a
  // live binding even to resolve to null.
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<WavePillData> presented;

  setUp(() => presented = <WavePillData>[]);

  void present(WavePillData data) => presented.add(data);

  group('INCOMING_WAVE tap', () {
    test('presents the pill in waveReceived state with the sender payload',
        () async {
      await handleNotificationNavigation(
        {
          'type': 'INCOMING_WAVE',
          'senderId': 'uid-sender',
          'senderName': 'User Alpha',
          'senderPhotoUrl': 'https://cdn.example/a.jpg',
          'senderAge': '27',
        },
        showWavePill: present,
      );

      expect(presented, hasLength(1));
      expect(presented.single.name, 'User Alpha');
      expect(presented.single.age, 27);
      expect(presented.single.imageUrl, 'https://cdn.example/a.jpg');
      expect(presented.single.targetUid, 'uid-sender');
      expect(presented.single.isIncomingWave, isTrue);
    });

    test('falls back to fromUid when senderId is absent', () async {
      await handleNotificationNavigation(
        {
          'type': 'INCOMING_WAVE',
          'fromUid': 'uid-legacy',
          'senderName': 'User Beta',
        },
        showWavePill: present,
      );

      expect(presented.single.targetUid, 'uid-legacy');
    });
  });

  group('CROSSING_PATHS tap', () {
    test('presents the pill in waitingForAction state', () async {
      await handleNotificationNavigation(
        {
          'type': 'CROSSING_PATHS',
          'senderId': 'uid-nearby',
          'senderName': 'User Beta',
          'senderPhotoUrl': 'https://cdn.example/b.jpg',
          'senderAge': '31',
        },
        showWavePill: present,
      );

      expect(presented.single.isIncomingWave, isFalse);
      expect(presented.single.targetUid, 'uid-nearby');
    });
  });

  group('payload hardening', () {
    test('defaults age to 0 when senderAge is missing or unparseable',
        () async {
      await handleNotificationNavigation(
        {'type': 'INCOMING_WAVE', 'senderId': 'u1', 'senderName': 'A'},
        showWavePill: present,
      );
      await handleNotificationNavigation(
        {
          'type': 'INCOMING_WAVE',
          'senderId': 'u2',
          'senderName': 'B',
          'senderAge': 'not-a-number',
        },
        showWavePill: present,
      );

      expect(presented.map((p) => p.age), everyElement(0));
    });

    test('defaults imageUrl to empty string when senderPhotoUrl is absent',
        () async {
      await handleNotificationNavigation(
        {'type': 'INCOMING_WAVE', 'senderId': 'u1', 'senderName': 'A'},
        showWavePill: present,
      );

      expect(presented.single.imageUrl, isEmpty);
    });

    test('does not present when the sender uid is missing or empty', () async {
      await handleNotificationNavigation(
        {'type': 'INCOMING_WAVE', 'senderName': 'A'},
        showWavePill: present,
      );
      await handleNotificationNavigation(
        {'type': 'INCOMING_WAVE', 'senderId': '', 'senderName': 'A'},
        showWavePill: present,
      );

      expect(presented, isEmpty);
    });

    test('does not present when the sender name is missing or empty', () async {
      await handleNotificationNavigation(
        {'type': 'CROSSING_PATHS', 'senderId': 'u1'},
        showWavePill: present,
      );
      await handleNotificationNavigation(
        {'type': 'CROSSING_PATHS', 'senderId': 'u1', 'senderName': ''},
        showWavePill: present,
      );

      expect(presented, isEmpty);
    });

    test('tolerates a null presenter without throwing', () async {
      await expectLater(
        handleNotificationNavigation({
          'type': 'INCOMING_WAVE',
          'senderId': 'u1',
          'senderName': 'A',
        }),
        completes,
      );
    });
  });

  // The presenter needs `ref` and a live Overlay, so the provider body can't be
  // exercised without Firebase. These pin the wiring at the source level — the
  // same approach as router_foreground_wave_wiring_test.dart.
  group('router wiring', () {
    final routerSource = File('lib/src/core/router.dart').readAsStringSync();

    test('feeds the tap handler into the pill presenter', () {
      expect(routerSource, contains('showWavePill: presentWavePill'));
    });

    test('routes the foreground path through the same presenter', () {
      expect(routerSource, contains('void presentWavePill(WavePillData data)'));
      expect(
        'presentWavePill('.allMatches(routerSource).length,
        greaterThanOrEqualTo(2),
        reason: 'both the tap path and the foreground path must call it',
      );
    });

    test('guards the presenter against unauthenticated users', () {
      final presenter = routerSource.substring(
        routerSource.indexOf('void presentWavePill(WavePillData data)'),
      );
      expect(
        presenter.substring(0, presenter.indexOf('WavePillService.show')),
        contains('authStateProvider'),
        reason: 'a pill must never float over login/onboarding',
      );
    });

    test('does not throw when no Overlay is mounted', () {
      expect(routerSource, contains('Overlay.maybeOf(context)'));
      expect(
        routerSource,
        isNot(contains('Overlay.of(context)')),
        reason: 'Overlay.of throws; the tap path runs at unpredictable times',
      );
    });

    // Slice covering just the presenter body — everything between its
    // signature and the NotificationService.initialize() call that follows it.
    String presenterBody() {
      final start =
          routerSource.indexOf('void presentWavePill(WavePillData data)');
      final end = routerSource.indexOf('NotificationService.initialize', start);
      return routerSource.substring(start, end);
    }

    test('polls for readiness instead of failing closed on the first miss', () {
      // A cold-launch tap (killed app) routinely beats auth restore and the
      // Navigator's Overlay. The original presenter returned on the first null
      // and dropped the pill with no retry. It must now retry within a bounded
      // window rather than give up immediately.
      final body = presenterBody();
      expect(
        body,
        contains('Future.delayed'),
        reason: 'the presenter must re-attempt while auth/overlay warm up',
      );
    });

    test('leaves a readable trace when it ultimately drops the pill', () {
      // Every give-up used to be a silent `return`, which is why a dropped tap
      // was uninvestigable. The final give-up must surface which precondition
      // never became ready.
      final body = presenterBody();
      expect(body, contains('wave pill dropped'));
      expect(
        body,
        contains('Sentry.captureMessage'),
        reason: 'a production drop needs a readable Sentry event, not silence',
      );
    });
  });

  group('no regression on existing types', () {
    test('does not present the pill for RUN_INTERCEPT', () async {
      await handleNotificationNavigation(
        {'type': 'RUN_INTERCEPT'},
        showWavePill: present,
      );

      expect(presented, isEmpty);
    });

    test('does not present the pill for MUTUAL_WAVE', () async {
      await handleNotificationNavigation(
        {'type': 'MUTUAL_WAVE', 'senderId': 'u1', 'senderName': 'A'},
        showWavePill: present,
      );

      expect(presented, isEmpty);
    });

    test('ignores unknown notification types', () async {
      await handleNotificationNavigation(
        {'type': 'SECOND_ENCOUNTER', 'senderId': 'u1', 'senderName': 'A'},
        showWavePill: present,
      );

      expect(presented, isEmpty);
    });
  });
}
