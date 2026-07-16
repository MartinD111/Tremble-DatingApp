import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/ble_service.dart';

void main() {
  // flutter_blue_plus re-emits the cumulative scan result list on every
  // advertisement packet, so a nearby device appears in dozens of emissions
  // per scan. Each emission previously wrote a proximity_events document,
  // which saturated the Firestore channel and inflated the monthly recap's
  // near-miss count. One write per device per scan cycle is the contract.
  group('ScanCycleDedupe', () {
    test('permits the first write for a device in a cycle', () {
      final dedupe = ScanCycleDedupe();

      expect(dedupe.shouldWrite('AA:BB:CC'), isTrue);
    });

    test('suppresses every repeat emission for the same device in a cycle', () {
      final dedupe = ScanCycleDedupe();
      dedupe.shouldWrite('AA:BB:CC');

      expect(dedupe.shouldWrite('AA:BB:CC'), isFalse);
      expect(dedupe.shouldWrite('AA:BB:CC'), isFalse);
    });

    test('tracks distinct devices independently', () {
      final dedupe = ScanCycleDedupe();

      expect(dedupe.shouldWrite('AA:BB:CC'), isTrue);
      expect(dedupe.shouldWrite('DD:EE:FF'), isTrue);
      expect(dedupe.shouldWrite('AA:BB:CC'), isFalse);
      expect(dedupe.shouldWrite('DD:EE:FF'), isFalse);
    });

    test('a new cycle permits exactly one further write per device', () {
      final dedupe = ScanCycleDedupe();
      dedupe.shouldWrite('AA:BB:CC');

      dedupe.beginCycle();

      expect(dedupe.shouldWrite('AA:BB:CC'), isTrue);
      expect(dedupe.shouldWrite('AA:BB:CC'), isFalse);
    });

    test('a burst of 200 emissions yields a single write', () {
      final dedupe = ScanCycleDedupe();

      final writes = List.generate(200, (_) => dedupe.shouldWrite('AA:BB:CC'))
          .where((permitted) => permitted)
          .length;

      expect(writes, 1);
    });
  });
}
