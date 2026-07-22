import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/dashboard/application/precise_finder_controller.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/application/radar_search_session.dart';
import 'package:tremble/src/features/dashboard/application/warmth_controller.dart';
import 'package:tremble/src/features/dashboard/data/finder_repository.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
import 'package:tremble/src/features/dashboard/domain/warmth_direction.dart';
import 'package:tremble/src/features/dashboard/presentation/widgets/radar_search_overlay.dart';

class _FreshSonar extends SonarPingController {
  @override
  SonarPing build() => const SonarPing(
        radius: 0.3,
        angle: 0,
        signalState: SonarSignalState.fresh,
      );
}

class _NeutralWarmth extends WarmthController {
  @override
  WarmthDirection build() => WarmthDirection.neutral;
}

/// Fake finder controller: fixed initial state, records session calls, never
/// touches the repository/location machinery.
class _FakeFinder extends PreciseFinderController {
  _FakeFinder(this.initial);

  final FinderState initial;
  final optInCalls = <String>[];
  int stopCalls = 0;

  @override
  FinderState build() => initial;

  @override
  Future<void> optInAndStart(String matchId) async {
    optInCalls.add(matchId);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

RadarSearchSession _session({String? matchId = 'match-1'}) =>
    RadarSearchSession(
      partnerName: 'Ana',
      matchId: matchId,
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      onStop: () async {},
    );

Widget _wrap(RadarSearchSession session, List<Override> overrides) =>
    ProviderScope(
      overrides: [
        warmthControllerProvider.overrideWith(() => _NeutralWarmth()),
        sonarPingControllerProvider.overrideWith(() => _FreshSonar()),
        appLanguageProvider.overrideWith(() => AppLanguageNotifier('en')),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(body: RadarSearchOverlay(session: session)),
      ),
    );

void main() {
  testWidgets('idle shows the opt-in button and tapping starts the session',
      (tester) async {
    final finder = _FakeFinder(const FinderState.idle());
    await tester.pumpWidget(_wrap(_session(), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Help us find each other'), findsOneWidget);

    await tester.tap(find.text('Help us find each other'));
    await tester.pump();
    expect(finder.optInCalls, ['match-1']);
  });

  testWidgets('no opt-in button without a real match id (dev sim)',
      (tester) async {
    final finder = _FakeFinder(const FinderState.idle());
    await tester.pumpWidget(_wrap(_session(matchId: null), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Help us find each other'), findsNothing);
  });

  testWidgets('waiting state shows the partner-name microcopy', (tester) async {
    final finder = _FakeFinder(const FinderState.waiting());
    await tester.pumpWidget(_wrap(_session(), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Waiting for Ana…'), findsOneWidget);
    expect(find.text('Help us find each other'), findsNothing);
  });

  testWidgets('active state shows the live distance and hides the button',
      (tester) async {
    final finder = _FakeFinder(
      const FinderState.active(
        FinderReading(partnerSharing: true, bearing: 90, distanceM: 24),
      ),
    );
    await tester.pumpWidget(_wrap(_session(), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('24 m'), findsOneWidget);
    expect(find.text('Help us find each other'), findsNothing);
  });

  testWidgets('fallback state shows the honest look-around microcopy',
      (tester) async {
    final finder = _FakeFinder(FinderState.fallback(reason: 'partner_stale'));
    await tester.pumpWidget(_wrap(_session(), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("They're close — look around"), findsOneWidget);
  });

  testWidgets('backgrounding the app stops the precise session',
      (tester) async {
    final finder = _FakeFinder(
      const FinderState.active(
        FinderReading(partnerSharing: true, bearing: 90, distanceM: 24),
      ),
    );
    await tester.pumpWidget(_wrap(_session(), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(finder.stopCalls, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });

  testWidgets('a transient interruption (inactive) does NOT revoke the session',
      (tester) async {
    final finder = _FakeFinder(
      const FinderState.active(
        FinderReading(partnerSharing: true, bearing: 90, distanceM: 24),
      ),
    );
    await tester.pumpWidget(_wrap(_session(), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    // Incoming-call banner / Control Center / biometric prompt → inactive,
    // while the user is still in the app. Sharing must survive it.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(finder.stopCalls, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });

  testWidgets('the opt-in CTA keeps a 48dp minimum tap target', (tester) async {
    final finder = _FakeFinder(const FinderState.idle());
    await tester.pumpWidget(_wrap(_session(), [
      preciseFinderControllerProvider.overrideWith(() => finder),
    ]));
    await tester.pump(const Duration(milliseconds: 400));

    final gesture = find.ancestor(
      of: find.text('Help us find each other'),
      matching: find.byType(GestureDetector),
    );
    final size = tester.getSize(gesture.first);
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
  });
}
