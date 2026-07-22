// BUG-RADAR-OFF-DISCOVERABLE (Rule #105) — the isActive:false revocation
// write in GeoService.stop() is the MOST critical proximity write: if it is
// silently swallowed the user stays discoverable, wave-able and matchable
// for up to the 24h TTL. It must retry before giving up, surface the final
// failure (Sentry in production), and never throw into stop() callers.

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/geo_service.dart';

void main() {
  group('runRevocationWriteWithRetry', () {
    test('returns true on first-attempt success without waiting', () async {
      var attempts = 0;
      final waits = <Duration>[];

      final ok = await runRevocationWriteWithRetry(
        () async => attempts++,
        wait: (d) async => waits.add(d),
        onFinalFailure: (_, __) => fail('must not report failure on success'),
      );

      expect(ok, isTrue);
      expect(attempts, 1);
      expect(waits, isEmpty);
    });

    test('retries a failing write and succeeds on a later attempt', () async {
      var attempts = 0;
      final waits = <Duration>[];

      final ok = await runRevocationWriteWithRetry(
        () async {
          attempts++;
          if (attempts < 3) throw StateError('transient firestore failure');
        },
        wait: (d) async => waits.add(d),
        onFinalFailure: (_, __) => fail('must not report failure on success'),
      );

      expect(ok, isTrue);
      expect(attempts, 3);
      expect(waits, hasLength(2), reason: 'backs off between attempts');
    });

    test(
        'returns false and reports exactly one final failure when every '
        'attempt fails — never throws', () async {
      var attempts = 0;
      final reported = <Object>[];

      final ok = await runRevocationWriteWithRetry(
        () async {
          attempts++;
          throw StateError('permanent firestore failure');
        },
        wait: (_) async {},
        onFinalFailure: (error, stackTrace) => reported.add(error),
      );

      expect(ok, isFalse);
      expect(attempts, 3, reason: 'defaults to 3 attempts');
      expect(reported, hasLength(1));
      expect(reported.single, isA<StateError>());
    });
  });
}
