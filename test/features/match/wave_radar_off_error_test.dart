// BUG-RADAR-OFF-DISCOVERABLE (Rule #105) — sendWave now rejects targets
// whose radar is off (failed-precondition, reason: target_radar_off). The
// client must surface that as a friendly message, not the generic retry.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/api_client.dart';
import 'package:tremble/src/features/match/data/wave_repository.dart';

void main() {
  group('mapSendWaveException', () {
    test('target_radar_off maps to the friendly radar-off message', () {
      final mapped = mapSendWaveException(TrembleApiException(
        code: 'failed-precondition',
        message: 'Target is not on the radar right now.',
        details: {'reason': 'target_radar_off'},
      ));

      expect(mapped.message, "They're not on the radar right now.");
      expect(mapped.code, 'failed-precondition');
    });

    test('permission-denied keeps the existing friendly message', () {
      final mapped = mapSendWaveException(TrembleApiException(
        code: 'permission-denied',
        message: 'Cannot wave at this user.',
      ));

      expect(mapped.message, "You can't wave at this person right now.");
    });

    test('failed-precondition without the radar reason is left untouched', () {
      final original = TrembleApiException(
        code: 'failed-precondition',
        message: 'some other precondition',
      );

      expect(identical(mapSendWaveException(original), original), isTrue);
    });

    test('unrelated codes are returned unchanged', () {
      final original = TrembleApiException(
        code: 'unavailable',
        message: 'network down',
      );

      expect(identical(mapSendWaveException(original), original), isTrue);
    });
  });

  test('sendWave funnels every TrembleApiException through the mapper', () {
    final source = File('lib/src/features/match/data/wave_repository.dart')
        .readAsStringSync();

    expect(source, contains('mapSendWaveException(e)'));
  });
}
