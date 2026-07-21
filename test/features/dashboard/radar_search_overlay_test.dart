import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/dashboard/application/proximity_ping_controller.dart';
import 'package:tremble/src/features/dashboard/application/radar_search_session.dart';
import 'package:tremble/src/features/dashboard/application/warmth_controller.dart';
import 'package:tremble/src/features/dashboard/domain/sonar_ping.dart';
import 'package:tremble/src/features/dashboard/domain/warmth_direction.dart';
import 'package:tremble/src/features/dashboard/presentation/widgets/radar_search_overlay.dart';

class _SearchingSonar extends SonarPingController {
  @override
  SonarPing build() => const SonarPing(signalState: SonarSignalState.searching);
}

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

RadarSearchSession _session() => RadarSearchSession(
      partnerName: 'Ana',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      onStop: () async {},
    );

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: [
        warmthControllerProvider.overrideWith(() => _NeutralWarmth()),
        appLanguageProvider.overrideWith(() => AppLanguageNotifier('en')),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(body: RadarSearchOverlay(session: _session())),
      ),
    );

void main() {
  testWidgets('shows the Searching caption when the signal is lost',
      (tester) async {
    await tester.pumpWidget(_wrap([
      sonarPingControllerProvider.overrideWith(() => _SearchingSonar()),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350)); // settle fadeIn

    expect(find.text('SEARCHING…'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose → cancel timers
  });

  testWidgets('hides the Searching caption while the signal is fresh',
      (tester) async {
    await tester.pumpWidget(_wrap([
      sonarPingControllerProvider.overrideWith(() => _FreshSonar()),
    ]));
    await tester.pump();

    expect(find.text('SEARCHING…'), findsNothing);
  });
}
