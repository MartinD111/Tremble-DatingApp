import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router wires foreground FCM waves to the wave pill service', () {
    final routerSource = File('lib/src/core/router.dart').readAsStringSync();

    expect(routerSource, contains('onForegroundWave:'));
    expect(routerSource, contains('rootNavigatorKey.currentContext'));
    expect(routerSource, contains('Overlay.of(context)'));
    expect(routerSource, contains('WavePillService.show'));
    expect(routerSource, contains('WavePillData('));
    expect(routerSource, contains('waveRepositoryProvider'));
    expect(routerSource, contains('.sendWave(uid)'));
  });
}
