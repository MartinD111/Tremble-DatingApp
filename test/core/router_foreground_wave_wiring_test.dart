import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router wires foreground FCM waves to the wave pill service', () {
    final routerSource = File('lib/src/core/router.dart').readAsStringSync();

    expect(routerSource, contains('onForegroundWave:'));
    // The pill overlay comes from the navigator's own OverlayState — reading it
    // off rootNavigatorKey.currentContext resolves to null. See
    // root_overlay_resolution_test.dart + router_notification_pill_test.dart.
    expect(routerSource, contains('rootNavigatorKey.currentState?.overlay'));
    expect(routerSource, contains('WavePillService.show'));
    expect(routerSource, contains('WavePillData('));
    expect(routerSource, contains('waveRepositoryProvider'));
    expect(routerSource, contains('.sendWave(uid)'));
  });
}
