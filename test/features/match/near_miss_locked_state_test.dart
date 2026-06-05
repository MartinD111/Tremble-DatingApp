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

  test('slovenian greeting copy avoids wave terminology', () {
    const expectedSlGreetingCopy = {
      'pulse_intercept_body':
          'Zaznan signal. Pozdrav je bil poslan v vašo smer. Želite prestreči?',
      'mutual_wave': 'Skupni pozdrav',
      'both_sent_wave': 'Oba sta si poslala pozdrav',
      'someone_sent_you_wave': 'Nekdo ti je poslal pozdrav',
      'tutorial_step3_popup_desc':
          'Tukaj se prikažejo ujemanja, pozdravi in odkrite osebe. Po tem koraku te Tremble vrne na radar.',
      'wave_sent': 'Pozdrav poslan.',
      'wave_failed': 'Pozdrava ni bilo mogoce poslati. Poskusi znova.',
      'wave_sent_to': 'Pozdrav poslan — čakamo na {name}!',
      'onb2_title': 'NIČ POTEZ. EN POZDRAV.',
      'onb2_body':
          'Brez feedov. Brez algoritmov. Brez klepetalnic. Le signal bližine in ena odločitev: pozdrav ali naprej.',
      'onb4_body':
          'Odpravi ujemanje ali blokiraj kadarkoli. Enosmerno — nihče ne ve, da si poslal pozdrav, dokler ni vzajemno.',
      'run_wave_sent': 'Pozdrav poslan',
      'run_wave_received': 'Pozdrav prejet',
      'mutual_wave_find': 'Vzajemni pozdrav! Poišči jih.',
      'wave': 'Pozdrav',
    };

    for (final entry in expectedSlGreetingCopy.entries) {
      expect(t(entry.key, 'sl'), entry.value);
      expect(t(entry.key, 'sl').toLowerCase(), isNot(contains('val')));
    }
  });

  test('greet failure translations and match dialog wiring are present', () {
    expect(t('greet_failed', 'en'), 'Could not send greeting. Try again.');
    expect(
      t('greet_failed', 'sl'),
      'Pozdrava ni bilo mogoce poslati. Poskusi znova.',
    );
    expect(
      t('greet_failed', 'hr'),
      'Nije moguce poslati pozdrav. Pokusaj ponovo.',
    );
    expect(
      t('greet_failed', 'de'),
      'Gruss konnte nicht gesendet werden. Versuche es erneut.',
    );
    expect(
      t('greet_failed', 'it'),
      'Impossibile inviare il saluto. Riprova.',
    );
    expect(
      t('greet_failed', 'fr'),
      'Impossible d envoyer la salutation. Reessaie.',
    );
    expect(
      t('greet_failed', 'sr'),
      'Nije moguce poslati pozdrav. Pokusaj ponovo.',
    );
    expect(
      t('greet_failed', 'hu'),
      'Nem sikertult elktildeni az udvozletet. Probald ujra.',
    );

    final matchDialog = File(
      'lib/src/features/matches/presentation/match_dialog.dart',
    ).readAsStringSync();

    expect(matchDialog, contains('Ni uspelo. Poskusi znova.'));
    expect(matchDialog, isNot(contains("t('wave_failed', lang)")));
    expect(matchDialog, isNot(contains('Napaka: \${e.toString()}')));
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
