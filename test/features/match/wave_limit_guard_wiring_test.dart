import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wave UI call sites guard free monthly limit before sendWave', () {
    final profileDetail =
        File('lib/src/features/profile/presentation/profile_detail_screen.dart')
            .readAsStringSync();
    final matchDialog =
        File('lib/src/features/matches/presentation/match_dialog.dart')
            .readAsStringSync();
    final router = File('lib/src/core/router.dart').readAsStringSync();

    for (final source in [profileDetail, matchDialog, router]) {
      expect(source, contains('hasReachedFreeWaveLimit'));
      expect(source, contains('PremiumPaywallBottomSheet.show(context)'));
    }
  });
}
