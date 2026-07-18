import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/translations.dart';

// ---------------------------------------------------------------------------
// Map cold-offline wiring + i18n coverage.
//
// The map card's error branch reads `ref` and mapInitProvider, so the widget
// tree can't be pumped without Firebase — these pin the wiring at the source
// level (same convention as router_notification_pill_test.dart) plus assert
// every shipped locale has real map-offline copy.
// ---------------------------------------------------------------------------

void main() {
  final mapSource =
      File('lib/src/features/map/presentation/tremble_map_screen.dart')
          .readAsStringSync();

  group('map screen error branch', () {
    test('renders the offline card instead of raw exception text', () {
      expect(mapSource, contains('MapOfflineCard('));
      expect(
        mapSource,
        isNot(contains(r'Error loading map: $e')),
        reason: 'airplane mode must not surface the raw ClientException',
      );
    });

    test('retry re-runs map init via ref.invalidate(mapInitProvider)', () {
      expect(mapSource, contains('ref.invalidate(mapInitProvider)'));
    });

    test('feeds the offline card localized copy', () {
      expect(mapSource, contains("t('map_offline_title', lang)"));
      expect(mapSource, contains("t('map_offline_subtitle', lang)"));
      expect(mapSource, contains("t('try_again', lang)"));
    });
  });

  group('i18n coverage', () {
    test('every shipped locale resolves real map-offline copy', () {
      for (final language in availableLanguages) {
        final code = language['code']!;
        for (final key in ['map_offline_title', 'map_offline_subtitle']) {
          final value = t(key, code);
          expect(value, isNotEmpty, reason: '$key missing for $code');
          expect(value, isNot(equals(key)),
              reason: '$key fell through to the raw key for $code');
        }
      }
    });

    test('primary markets (sl, hr) are localized, not English fallback', () {
      expect(t('map_offline_title', 'sl'), 'Zemljevid ni na voljo');
      expect(t('map_offline_title', 'hr'), 'Karta nije dostupna');
      // hr previously lacked try_again and fell back to English; now localized.
      expect(t('try_again', 'hr'), 'Pokušaj ponovno');
    });
  });
}
