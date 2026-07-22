import 'dart:async';

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/core/compass_service.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/dashboard/application/precise_finder_controller.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/data/finder_repository.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_math.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/match/domain/match.dart';

/// Minimal BleService stand-in — only proximityStream + setHighFrequencyMode
/// are exercised; everything else defers to noSuchMethod (never called here).
class _FakeBle implements BleService {
  _FakeBle(this._stream);
  final Stream<Map<String, int>> _stream;

  @override
  Stream<Map<String, int>> get proximityStream => _stream;

  @override
  void setHighFrequencyMode(bool enabled) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake AuthRepository whose auth stream never emits → AuthNotifier stays at
/// null (signed-out) with zero Firebase. Partner then resolves to userIds.first.
class _FakeAuthRepo implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake finder controller whose state the test drives directly. Overrides the
/// session methods so no repository/location machinery is ever constructed.
class _MutablePreciseFinder extends PreciseFinderController {
  @override
  FinderState build() => const FinderState.idle();

  void setState(FinderState next) => state = next;

  @override
  Future<void> optInAndStart(String matchId) async {}

  @override
  Future<void> stop() async {}
}

Match _mutualSearch() => Match(
      id: 'm1',
      // getPartnerId('') returns userIds.first, so 'partner' is the target
      // without needing to override the heavy authStateProvider.
      userIds: const ['partner', 'me'],
      createdAt: DateTime(2026),
      seenBy: const [],
      gestures: const {'partner': true, 'me': true}, // isMutual == true
    );

void main() {
  test('emits a center radius from a close partner RSSI during a search',
      () async {
    final controller = StreamController<Map<String, int>>.broadcast();
    addTearDown(controller.close);

    final container = ProviderContainer(overrides: [
      bleServiceProvider.overrideWithValue(_FakeBle(controller.stream)),
      currentSearchProvider.overrideWithValue(_mutualSearch()),
      effectiveIsPremiumProvider.overrideWithValue(false),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
      compassHeadingProvider
          .overrideWith((ref) => const Stream<double?>.empty()),
    ]);
    addTearDown(container.dispose);

    // Hold a listener so the autoDispose controller stays alive (production
    // keeps it alive via ref.watch in _RadarSection) and its BLE subscription
    // survives long enough to process the emission.
    final keepAlive = container.listen(sonarPingControllerProvider, (_, __) {});
    addTearDown(keepAlive.close);

    controller.add({'partner': -40}); // very close
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final ping = container.read(sonarPingControllerProvider);
    expect(ping.radius, isNotNull);
    expect(ping.radius, closeTo(0.0, 0.05)); // close → center
    expect(ping.signalState, SonarSignalState.fresh);
  });

  test('points the dot at the real bearing once a heading is available',
      () async {
    final controller = StreamController<Map<String, int>>.broadcast();
    addTearDown(controller.close);

    // myUid resolves to '' in this harness (null auth), so key the bearing on
    // '' — partner is due-right (90°), device faces north (heading 0).
    final search = Match(
      id: 'm1',
      userIds: const ['partner', 'me'],
      createdAt: DateTime(2026),
      seenBy: const [],
      gestures: const {'partner': true, 'me': true},
      bearingFor: const {'': 90.0},
      distanceBucket: '~150m',
    );

    final container = ProviderContainer(overrides: [
      bleServiceProvider.overrideWithValue(_FakeBle(controller.stream)),
      currentSearchProvider.overrideWithValue(search),
      effectiveIsPremiumProvider.overrideWithValue(false),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
      compassHeadingProvider.overrideWith((ref) => Stream.value(0.0)),
    ]);
    addTearDown(container.dispose);

    final keepAlive = container.listen(sonarPingControllerProvider, (_, __) {});
    addTearDown(keepAlive.close);

    controller.add({'partner': -50});
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final ping = container.read(sonarPingControllerProvider);
    // bearing 90°, heading 0° → partner to the right → painter angle 0.
    expect(ping.angle, closeTo(0.0, 1e-6));
    expect(ping.angle, isNot(closeTo(2 * math.pi, 1e-6)));
  });

  test('ignores a coarse bearing at close range and keeps orbiting', () async {
    final bleController = StreamController<Map<String, int>>.broadcast();
    final compassController = StreamController<double?>.broadcast();
    addTearDown(bleController.close);
    addTearDown(compassController.close);

    // If used, bearing 0° and heading 0° would place the dot at the top
    // (3π/2). A close bucket must instead retain the near-zero orbit fallback.
    final search = Match(
      id: 'm1',
      userIds: const ['partner', 'me'],
      createdAt: DateTime(2026),
      seenBy: const [],
      gestures: const {'partner': true, 'me': true},
      bearingFor: const {'': 0.0},
      distanceBucket: 'close',
    );

    final container = ProviderContainer(overrides: [
      bleServiceProvider.overrideWithValue(_FakeBle(bleController.stream)),
      currentSearchProvider.overrideWithValue(search),
      effectiveIsPremiumProvider.overrideWithValue(false),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
      compassHeadingProvider.overrideWith((ref) => compassController.stream),
    ]);
    addTearDown(container.dispose);

    final freshPing = Completer<SonarPing>();
    final keepAlive = container.listen(sonarPingControllerProvider, (_, next) {
      if (next.signalState == SonarSignalState.fresh &&
          !freshPing.isCompleted) {
        freshPing.complete(next);
      }
    });
    addTearDown(keepAlive.close);

    final headingReady = container.read(compassHeadingProvider.future);
    compassController.add(0.0);
    expect(await headingReady, 0.0);

    bleController.add({'partner': -50});
    final ping = await freshPing.future.timeout(const Duration(seconds: 1));
    expect(ping.angle, isNot(closeTo(3 * math.pi / 2, 1e-6)));
  });

  test('an active precise finder overrides the coarse dot with a solid fix',
      () async {
    final compassController = StreamController<double?>.broadcast();
    addTearDown(compassController.close);

    // Coarse inputs alone would orbit here: bucket 'close' suppresses the
    // geohash bearing (Task 5). The precise reading must take priority.
    final search = Match(
      id: 'm1',
      userIds: const ['partner', 'me'],
      createdAt: DateTime(2026),
      seenBy: const [],
      gestures: const {'partner': true, 'me': true},
      bearingFor: const {'': 0.0},
      distanceBucket: 'close',
    );

    final container = ProviderContainer(overrides: [
      bleServiceProvider.overrideWithValue(
        _FakeBle(const Stream<Map<String, int>>.empty()),
      ),
      currentSearchProvider.overrideWithValue(search),
      effectiveIsPremiumProvider.overrideWithValue(false),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
      compassHeadingProvider.overrideWith((ref) => compassController.stream),
      preciseFinderControllerProvider
          .overrideWith(() => _MutablePreciseFinder()),
    ]);
    addTearDown(container.dispose);

    final keepAlive = container.listen(sonarPingControllerProvider, (_, __) {});
    addTearDown(keepAlive.close);

    final headingReady = container.read(compassHeadingProvider.future);
    compassController.add(0.0);
    expect(await headingReady, 0.0);

    final finder = container.read(preciseFinderControllerProvider.notifier)
        as _MutablePreciseFinder;
    finder.setState(
      const FinderState.active(
        FinderReading(partnerSharing: true, bearing: 90, distanceM: 30),
      ),
    );

    // No BLE sample ever arrives — the freshness tick must still render a
    // solid dot from the precise reading alone.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final ping = container.read(sonarPingControllerProvider);
    expect(ping.radius, closeTo(preciseRadius(30), 1e-9));
    // bearing 90°, heading 0° → partner to the right → painter angle 0.
    expect(ping.angle, closeTo(0.0, 1e-6));
    expect(ping.signalState, SonarSignalState.fresh);
  });

  test('dropping out of precise mode returns to the honest searching state',
      () async {
    final container = ProviderContainer(overrides: [
      bleServiceProvider.overrideWithValue(
        _FakeBle(const Stream<Map<String, int>>.empty()),
      ),
      currentSearchProvider.overrideWithValue(_mutualSearch()),
      effectiveIsPremiumProvider.overrideWithValue(false),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
      compassHeadingProvider.overrideWith((ref) => Stream.value(0.0)),
      preciseFinderControllerProvider
          .overrideWith(() => _MutablePreciseFinder()),
    ]);
    addTearDown(container.dispose);

    final keepAlive = container.listen(sonarPingControllerProvider, (_, __) {});
    addTearDown(keepAlive.close);

    final finder = container.read(preciseFinderControllerProvider.notifier)
        as _MutablePreciseFinder;
    finder.setState(
      const FinderState.active(
        FinderReading(partnerSharing: true, bearing: 90, distanceM: 30),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(
      container.read(sonarPingControllerProvider).signalState,
      SonarSignalState.fresh,
    );

    finder.setState(FinderState.fallback(reason: 'partner_stale'));
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final ping = container.read(sonarPingControllerProvider);
    expect(ping.signalState, SonarSignalState.searching);
    expect(ping.radius, isNot(closeTo(preciseRadius(30), 1e-9)));
  });

  test('stays empty when no search is active', () {
    final container = ProviderContainer(overrides: [
      bleServiceProvider.overrideWithValue(
        _FakeBle(const Stream<Map<String, int>>.empty()),
      ),
      currentSearchProvider.overrideWithValue(null),
      effectiveIsPremiumProvider.overrideWithValue(false),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
      compassHeadingProvider
          .overrideWith((ref) => const Stream<double?>.empty()),
    ]);
    addTearDown(container.dispose);

    final ping = container.read(sonarPingControllerProvider);
    expect(ping.radius, isNull);
    expect(ping.signalState, SonarSignalState.searching);
  });
}
