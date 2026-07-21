import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tremble/src/core/compass_service.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
import 'package:tremble/src/features/dashboard/presentation/widgets/radar_diagnostic_overlay.dart';
import 'package:tremble/src/features/match/application/match_service.dart';

class _FreshSonar extends SonarPingController {
  @override
  SonarPing build() => const SonarPing(
        radius: 0.42,
        angle: 1.5,
        rssi: -62.5,
        signalState: SonarSignalState.fresh,
      );
}

/// Auth stream that never emits → AuthNotifier stays null (signed-out), zero
/// Firebase. Keeps the diagnostic panel's uid lookup off the platform.
class _FakeAuthRepo implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: [
        // Keep the panel off the platform channels / live match stream in tests.
        currentSearchProvider.overrideWithValue(null),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
        compassHeadingProvider
            .overrideWith((ref) => const Stream<double?>.empty()),
        ...overrides,
      ],
      child: const MaterialApp(
        home: Scaffold(body: RadarDiagnosticOverlay()),
      ),
    );

void main() {
  // Widget tests run in debug mode, so the kDebugMode guard renders the panel.
  testWidgets('renders raw RSSI, radius, angle and signal state', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap([
      sonarPingControllerProvider.overrideWith(() => _FreshSonar()),
    ]));
    await tester.pump();

    expect(find.textContaining('-62.5'), findsOneWidget); // raw RSSI dBm
    expect(find.textContaining('0.42'), findsOneWidget); // radius
    expect(find.textContaining('fresh'), findsOneWidget); // signal state
    // Placeholders for signals that land in B2/B3 (server bearing, compass).
    expect(find.textContaining('bearing'), findsOneWidget);
    expect(find.textContaining('heading'), findsOneWidget);
  });
}
