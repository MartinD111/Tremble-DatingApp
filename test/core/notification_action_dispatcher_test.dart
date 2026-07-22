import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tremble/src/core/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late List<String> sentTargetUids;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    sentTargetUids = <String>[];
  });

  NotificationActionDispatcher createDispatcher({
    Future<void> Function(String targetUid)? sendWave,
    int maxProcessedActions = 100,
  }) {
    return NotificationActionDispatcher(
      preferences: preferences,
      sendWave: sendWave ??
          (targetUid) async {
            sentTargetUids.add(targetUid);
          },
      maxProcessedActions: maxProcessedActions,
    );
  }

  Map<String, dynamic> incomingWaveData({
    String messageId = 'message-1',
    String senderId = 'sender-1',
  }) {
    return <String, dynamic>{
      'type': 'INCOMING_WAVE',
      'gcm.message_id': messageId,
      'waveId': 'fallback-wave-id',
      'senderId': senderId,
    };
  }

  test('explicit WAVE_BACK_ACTION sends exactly one callable wave', () async {
    final dispatcher = createDispatcher();

    final outcome = await dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: incomingWaveData(),
    );

    expect(outcome.status, NotificationActionDispatchStatus.sent);
    expect(sentTargetUids, <String>['sender-1']);
  });

  test('default, dismiss, type, and click_action never send a wave', () async {
    final dispatcher = createDispatcher();
    final data = incomingWaveData();

    await dispatcher.dispatch(actionIdentifier: null, data: data);
    await dispatcher.dispatch(
      actionIdentifier: 'WAVE_DISMISS_ACTION',
      data: data,
    );
    await dispatcher.dispatch(
      actionIdentifier: null,
      data: <String, dynamic>{
        ...data,
        'actionId': 'WAVE_BACK_ACTION',
        'actionIdentifier': 'WAVE_BACK_ACTION',
      },
    );
    await dispatcher.dispatch(
      actionIdentifier: null,
      data: <String, dynamic>{
        ...data,
        'click_action': 'WAVE_BACK_ACTION',
      },
    );

    expect(sentTargetUids, isEmpty);
  });

  test('malformed explicit action never sends a wave', () async {
    final dispatcher = createDispatcher();

    final cases = <Map<String, dynamic>>[
      <String, dynamic>{
        ...incomingWaveData(messageId: ''),
        'waveId': '',
      },
      incomingWaveData(senderId: ''),
      <String, dynamic>{
        ...incomingWaveData(),
        'type': 'MUTUAL_WAVE',
      },
    ];
    for (final data in cases) {
      await dispatcher.dispatch(
        actionIdentifier: 'WAVE_BACK_ACTION',
        data: data,
      );
    }

    expect(sentTargetUids, isEmpty);
  });

  test('duplicate explicit action sends one callable wave', () async {
    final dispatcher = createDispatcher();
    final data = incomingWaveData();

    final first = await dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: data,
    );
    final duplicate = await dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: data,
    );

    expect(first.status, NotificationActionDispatchStatus.sent);
    expect(
      duplicate.status,
      NotificationActionDispatchStatus.alreadyProcessed,
    );
    expect(sentTargetUids, <String>['sender-1']);
  });

  test('concurrent duplicate is blocked by the in-flight guard', () async {
    final callableStarted = Completer<void>();
    final releaseCallable = Completer<void>();
    var calls = 0;
    final dispatcher = createDispatcher(
      sendWave: (targetUid) async {
        calls++;
        callableStarted.complete();
        await releaseCallable.future;
      },
    );

    final first = dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: incomingWaveData(),
    );
    await callableStarted.future;
    final duplicate = await dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: incomingWaveData(),
    );
    releaseCallable.complete();

    expect(duplicate.status, NotificationActionDispatchStatus.inFlight);
    expect((await first).status, NotificationActionDispatchStatus.sent);
    expect(calls, 1);
  });

  test('failed callable releases guard and remains retryable', () async {
    var attempts = 0;
    final dispatcher = createDispatcher(
      sendWave: (targetUid) async {
        attempts++;
        if (attempts == 1) throw StateError('transient failure');
        sentTargetUids.add(targetUid);
      },
    );

    final failed = await dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: incomingWaveData(),
    );
    final retry = await dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: incomingWaveData(),
    );

    expect(failed.status, NotificationActionDispatchStatus.failed);
    expect(retry.status, NotificationActionDispatchStatus.sent);
    expect(attempts, 2);
    expect(sentTargetUids, <String>['sender-1']);
  });

  test('INCOMING_WAVE background data performs no action', () async {
    final dispatcher = createDispatcher();
    var proximityRefreshes = 0;

    await processBackgroundNotificationData(
      incomingWaveData(),
      isRadarActive: () async => true,
      refreshProximity: () async {
        proximityRefreshes++;
      },
    );
    await dispatcher.dispatch(
      actionIdentifier: null,
      data: incomingWaveData(),
    );

    expect(proximityRefreshes, 0);
    expect(sentTargetUids, isEmpty);
  });

  test('CROSSING_PATHS NEARBY_WAVE_ACTION uses injected callable', () async {
    final dispatcher = createDispatcher();

    final outcome = await dispatcher.dispatch(
      actionIdentifier: 'NEARBY_WAVE_ACTION',
      data: <String, dynamic>{
        'type': 'CROSSING_PATHS',
        'gcm.message_id': 'nearby-message-1',
        'fromUid': 'nearby-user',
      },
    );

    expect(outcome.status, NotificationActionDispatchStatus.sent);
    expect(sentTargetUids, <String>['nearby-user']);
  });

  test('waveId is accepted only as the message ID fallback', () async {
    final dispatcher = createDispatcher();
    final data = incomingWaveData()..remove('gcm.message_id');

    final outcome = await dispatcher.dispatch(
      actionIdentifier: 'WAVE_BACK_ACTION',
      data: data,
    );

    expect(outcome.status, NotificationActionDispatchStatus.sent);
    expect(sentTargetUids, <String>['sender-1']);
  });

  test('processed action history is bounded', () async {
    final dispatcher = createDispatcher(maxProcessedActions: 2);

    for (var index = 0; index < 3; index++) {
      await dispatcher.dispatch(
        actionIdentifier: 'WAVE_BACK_ACTION',
        data: incomingWaveData(messageId: 'message-$index'),
      );
    }

    expect(
      preferences.getStringList(NotificationActionDispatcher.processedKeysKey),
      hasLength(2),
    );
  });

  test('notification sources have one owner and no direct waves writes', () {
    final notificationSource = File(
      'lib/src/core/notification_service.dart',
    ).readAsStringSync();
    final routerSource = File('lib/src/core/router.dart').readAsStringSync();
    final homeSource = File(
      'lib/src/features/dashboard/presentation/home_screen.dart',
    ).readAsStringSync();

    final directWavesCollection = RegExp(
      r'''collection\s*\(\s*['"]waves['"]''',
    );
    expect(notificationSource, isNot(matches(directWavesCollection)));
    expect(routerSource, isNot(matches(directWavesCollection)));
    expect(homeSource, isNot(contains('NotificationService.initialize(')));
    expect(
      RegExp('NotificationService\\.initialize\\(')
          .allMatches(routerSource)
          .length,
      1,
    );
    expect(routerSource, isNot(contains('getInitialMessage()')));
    expect(routerSource, isNot(contains('onMessageOpenedApp.listen')));
  });

  test('AppDelegate persists only explicit wave-back actions for Dart drain',
      () {
    final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(source, contains('UNNotificationResponse'));
    expect(source, contains('response.actionIdentifier == "WAVE_BACK_ACTION"'));
    expect(source, contains('gcm.message_id'));
    expect(source, contains('waveId'));
    expect(source, contains('senderId'));
    expect(source, contains('UserDefaults.standard'));
    expect(source, contains('app.tremble/notification_actions'));
    expect(source, contains('getPendingActions'));
    expect(source, contains('acknowledgeAction'));
    expect(
      source,
      contains(
        'super.userNotificationCenter(center, didReceive: response, '
        'withCompletionHandler: completionHandler)',
      ),
    );
  });
}
