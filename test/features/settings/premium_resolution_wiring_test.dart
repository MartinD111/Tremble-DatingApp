import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client premium gates use effective premium resolution', () {
    final sources = {
      'matches': File(
        'lib/src/features/matches/presentation/matches_screen.dart',
      ).readAsStringSync(),
      'map': File(
        'lib/src/features/map/presentation/tremble_map_screen.dart',
      ).readAsStringSync(),
      'editProfile': File(
        'lib/src/features/profile/presentation/edit_profile_screen.dart',
      ).readAsStringSync(),
      'profilePreview': File(
        'lib/src/features/profile/presentation/profile_card_preview.dart',
      ).readAsStringSync(),
      'settingsScreen': File(
        'lib/src/features/settings/presentation/settings_screen.dart',
      ).readAsStringSync(),
      'settingsController': File(
        'lib/src/features/settings/presentation/settings_controller.dart',
      ).readAsStringSync(),
      'premiumScreen': File(
        'lib/src/features/settings/presentation/premium_screen.dart',
      ).readAsStringSync(),
      'home': File(
        'lib/src/features/dashboard/presentation/home_screen.dart',
      ).readAsStringSync(),
      'geo': File('lib/src/core/geo_service.dart').readAsStringSync(),
    };

    final forbiddenPatterns = <String, List<String>>{
      'matches': ['final isPremium = user?.isPremium == true;'],
      'map': [
        '!ref.read(authStateProvider)!.isPremium',
        'user?.effectiveIsPremium(',
      ],
      'editProfile': [
        '_isPremium = user.isPremium;',
        'final maxDist = _isPremium ? 100.0 : 50.0;',
      ],
      'profilePreview': ['children: (user.isPremium'],
      'settingsScreen': [
        'if (!user.isPremium)',
        'isPremium: !user.isPremium',
        'value: user.isPremium',
      ],
      'settingsController': [
        'if (user == null || !user.isPremium) return;',
        'if (isPremium && !user.isPremium)',
      ],
      'premiumScreen': ['final isPremium = user.isPremium;'],
      'home': [
        'authStateProvider.select((user) => user?.isPremium == true)',
        'tapUser?.isPremium == true',
      ],
      'geo': ["doc.data()?['isPremium']"],
    };

    for (final entry in forbiddenPatterns.entries) {
      final source = sources[entry.key]!;
      for (final pattern in entry.value) {
        expect(
          source,
          isNot(contains(pattern)),
          reason: '${entry.key} still contains raw premium gate: $pattern',
        );
      }
    }

    expect(sources['matches'], contains('effectiveIsPremiumProvider'));
    expect(sources['map'], contains('effectiveIsPremiumProvider'));
    expect(sources['editProfile'], contains('effectiveIsPremiumProvider'));
    expect(sources['profilePreview'], contains('effectiveIsPremiumProvider'));
    expect(sources['settingsScreen'], contains('effectiveIsPremiumProvider'));
    expect(
        sources['settingsController'], contains('effectiveIsPremiumProvider'));
    expect(sources['premiumScreen'], contains('effectiveIsPremiumProvider'));
    expect(sources['home'], contains('effectiveIsPremiumProvider'));
    expect(sources['geo'], contains('start({required bool isPremium})'));
  });
}
