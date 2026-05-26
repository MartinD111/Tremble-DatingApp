import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:tremble/src/features/matches/presentation/matches_screen.dart';

void main() {
  test('near miss helpers count activity profiles and gate run upsell', () {
    final profiles = [
      const MatchProfile(
        id: 'run-1',
        name: 'Lina',
        age: 28,
        imageUrl: '',
        hobbies: [],
        bio: '',
        matchType: 'activity',
      ),
      const MatchProfile(
        id: 'gym-1',
        name: 'Maja',
        age: 27,
        imageUrl: '',
        hobbies: [],
        bio: '',
        matchType: 'gym',
      ),
      const MatchProfile(
        id: 'run-2',
        name: 'Sara',
        age: 29,
        imageUrl: '',
        hobbies: [],
        bio: '',
        matchType: 'activity',
      ),
    ];

    expect(countNearMissProfiles(profiles), 2);
    expect(
      shouldShowNearMissUpsell(
        activeSection: MatchSection.run,
        isPremium: false,
        nearMissCount: 2,
      ),
      isTrue,
    );
    expect(
      shouldShowNearMissUpsell(
        activeSection: MatchSection.run,
        isPremium: true,
        nearMissCount: 2,
      ),
      isFalse,
    );
  });

  test('near miss upsell translations include count and CTA', () {
    expect(
      nearMissUpsellBody('en', 3),
      'You missed 3 people this week. Pro shows you who.',
    );
    expect(
      nearMissUpsellBody('sl', 3),
      'Ta teden si zamudil/a 3 ljudi. Premium ti pokaže kdo.',
    );
    expect(
      nearMissUpsellBody('hr', 3),
      'Ovaj tjedan propustio/la si 3 ljudi. Premium ti pokazuje tko.',
    );
    expect(t('near_miss_upsell_cta', 'en'), 'See who');
    expect(t('near_miss_upsell_cta', 'sl'), 'Poglej kdo');
    expect(t('near_miss_upsell_cta', 'hr'), 'Pogledaj tko');
  });

  test('matches screen wires locked near miss UI states', () {
    final source = File(
      'lib/src/features/matches/presentation/matches_screen.dart',
    ).readAsStringSync();

    expect(source, contains('ImageFiltered('));
    expect(source, contains('ImageFilter.blur'));
    expect(source, contains('sigmaX: 8.0'));
    expect(source, contains('sigmaY: 8.0'));
    expect(source, contains("t('someone_nearby', lang)"));
    expect(source, contains('LucideIcons.lock'));
    expect(source, contains('Positioned.fill('));
    expect(source, contains('Center('));
    expect(source, contains('isNearMissLocked'));
    expect(source, contains('isNearMissReadOnly'));
    expect(source, contains('_NearMissUpsellCard'));
    expect(source, contains('PrimaryButton'));
    expect(source, contains('PremiumPaywallBottomSheet.show(context)'));
  });
}
