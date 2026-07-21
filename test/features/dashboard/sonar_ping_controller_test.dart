import 'dart:async';

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tremble/src/core/ble_service.dart';
import 'package:tremble/src/core/compass_service.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
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
