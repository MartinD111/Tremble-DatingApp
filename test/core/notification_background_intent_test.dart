// BUG-RADAR-OFF-DISCOVERABLE (Rule #105) — the FCM background handler must
// not refresh proximity presence unless the user's stored radar intent is ON.
// Message receipt is not user intent: without this gate a stale
// `isActive: true` proximity doc is kept fresh forever by the very
// notifications it causes (scan → notify → receipt refresh → fresh for the
// next scan), keeping a radar-off user discoverable, wave-able and matchable.

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/notification_service.dart';

void main() {
  Map<String, dynamic> dataOfType(String type) => <String, dynamic>{
        'type': type,
        'gcm.message_id': 'msg-1',
        'fromUid': 'sender-1',
      };

  for (final type in ['CROSSING_PATHS', 'SECOND_ENCOUNTER']) {
    test('$type skips the proximity refresh when radar intent is OFF',
        () async {
      var refreshes = 0;
      var intentChecks = 0;

      await processBackgroundNotificationData(
        dataOfType(type),
        isRadarActive: () async {
          intentChecks++;
          return false;
        },
        refreshProximity: () async => refreshes++,
      );

      expect(intentChecks, 1);
      expect(refreshes, 0);
    });

    test('$type still refreshes proximity when radar intent is ON', () async {
      var refreshes = 0;

      await processBackgroundNotificationData(
        dataOfType(type),
        isRadarActive: () async => true,
        refreshProximity: () async => refreshes++,
      );

      expect(refreshes, 1);
    });
  }

  test('unrelated types touch neither the intent gate nor proximity', () async {
    var refreshes = 0;
    var intentChecks = 0;

    for (final type in ['INCOMING_WAVE', 'MUTUAL_WAVE', 'PULSE_INTERCEPT']) {
      await processBackgroundNotificationData(
        dataOfType(type),
        isRadarActive: () async {
          intentChecks++;
          return true;
        },
        refreshProximity: () async => refreshes++,
      );
    }

    expect(intentChecks, 0);
    expect(refreshes, 0);
  });
}
