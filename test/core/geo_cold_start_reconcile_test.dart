// BUG-RADAR-OFF-DISCOVERABLE (Rule #105) — unclean termination (force-kill,
// FGS death) never runs GeoService.stop(), so the proximity doc can stay
// `isActive: true` for up to 24h. Reconcile-on-boot is mandatory: when the
// app comes up and the local radar intent is OFF, the server doc must be
// marked inactive.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/geo_service.dart';

void main() {
  group('reconcileRadarIntentCore', () {
    test('local intent ON — leaves the server doc untouched', () async {
      var writes = 0;

      await reconcileRadarIntentCore(
        localIntentActive: true,
        writeInactive: () async => writes++,
        onError: (_) => fail('no error expected'),
      );

      expect(writes, 0);
    });

    test('local intent OFF — writes the inactive reconcile exactly once',
        () async {
      var writes = 0;

      await reconcileRadarIntentCore(
        localIntentActive: false,
        writeInactive: () async => writes++,
        onError: (_) => fail('no error expected'),
      );

      expect(writes, 1);
    });

    test('write failure is reported once and never thrown', () async {
      final errors = <Object>[];

      await reconcileRadarIntentCore(
        localIntentActive: false,
        writeInactive: () async => throw StateError('offline'),
        onError: errors.add,
      );

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
    });
  });

  group('cold-start reconcile wiring', () {
    test('home_screen hooks the reconcile at first auth-ready', () {
      final source = File(
        'lib/src/features/dashboard/presentation/home_screen.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('reconcileColdStartRadarIntent()'),
        reason: 'Dashboard bootstrap must reconcile server presence with '
            'local radar intent (Rule #105 — reconcile-on-boot is mandatory)',
      );
    });

    test('production reconcile writes the full inactive tuple', () {
      final source = File('lib/src/core/geo_service.dart').readAsStringSync();

      expect(source, contains('reconcileColdStartRadarIntent'));
      // The reconcile must revoke BOTH flags + freshness, matching stop().
      expect(source, contains("'radarActive': false"));
      expect(source, contains("'isActive': false"));
    });
  });
}
