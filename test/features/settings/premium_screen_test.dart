import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/settings/presentation/premium_screen.dart';

void main() {
  test('premium upgrade cards keep the approved order and pricing', () {
    expect(premiumPlanCards.map((card) => card.titleKey), [
      'premium_card_premium_title',
      'premium_card_weekend_title',
      'premium_card_yearly_title',
      'premium_card_lifetime_title',
      'premium_card_free_title',
    ]);

    expect(premiumPlanCards[0].price, '7,99 €');
    expect(premiumPlanCards[0].productIdentifier, 'monthly');
    expect(premiumPlanCards[1].price, '2,99 €');
    expect(premiumPlanCards[1].productIdentifier, 'weekly');
    expect(
      premiumPlanCards[1].windowKey,
      'premium_card_weekend_window',
    );
    expect(premiumPlanCards[2].perMonthPrice, '5,00 €');
    expect(premiumPlanCards[2].price, '59,99 €');
    expect(premiumPlanCards[2].productIdentifier, 'yearly');
    expect(premiumPlanCards[2].savingsBadge, 'premium_yearly_savings_badge');
    expect(premiumPlanCards[3].price, '149,99 €');
    expect(premiumPlanCards[3].productIdentifier, 'lifetime');
    expect(premiumPlanCards[3].accent, const Color(0xFFFFB347));
    expect(premiumPlanCards[4].ctaPremiumKey, 'premium_switch_to_free');
    expect(premiumPlanCards[4].productIdentifier, isNull);
  });

  group('paywall copy matches ADR-007 tier matrix', () {
    test(
        'Premium (monthly) card lists exactly the ADR-007 Premium-only bullets',
        () {
      expect(premiumPlanCards[0].features, premiumOnlyFeatureBullets);
      // Precise assertion of the ordered set — any drift from ADR-007
      // fails here and forces a matching ADR update.
      expect(premiumOnlyFeatureBullets, const [
        'premium_feature_radar_extended',
        'premium_feature_mutual_waves_20',
        'premium_feature_open_profile_cards',
        'premium_feature_recap_full',
        'premium_feature_near_miss_history',
        'premium_feature_hard_filters',
        'premium_feature_event_insights',
        'premium_feature_distance_100',
      ]);
    });

    test('Weekend card = Premium bullets + weekend-window suffix', () {
      expect(
        premiumPlanCards[1].features,
        [...premiumOnlyFeatureBullets, 'premium_feature_weekend_window'],
      );
    });

    test('Free card lists exactly the ADR-007 Free-tier bullets', () {
      expect(premiumPlanCards[4].features, freeTierFeatureBullets);
      expect(freeTierFeatureBullets, const [
        'premium_free_proximity',
        'premium_free_pulse_intercept',
        'premium_free_active_radar',
        'premium_free_mutual_waves_5',
        'premium_free_event_pins',
        'premium_free_nicotine_filter',
        'premium_free_distance_50',
      ]);
    });

    test('retired paywall keys are fully removed from the source file', () {
      final source = File(
        'lib/src/features/settings/presentation/premium_screen.dart',
      ).readAsStringSync();
      // Copy that pre-dated ADR-007 and misrepresented what Premium
      // actually gates. Must NOT re-appear anywhere in the file
      // (feature list, translation map, comments).
      for (final retired in const [
        'premium_feature_wider_radar',
        'premium_feature_unlimited_geofence',
        'premium_feature_custom_themes',
        'premium_feature_advanced_filters',
        'premium_free_gym_mode',
        'premium_free_local_radar',
        'premium_free_wave_limit',
      ]) {
        expect(source, isNot(contains(retired)),
            reason: '$retired must be gone per ADR-007 §Consequences');
      }
    });

    test('copy rules — no forbidden phrases in user-facing paywall copy', () {
      // ADR-007 §3 copy rules apply to user-facing STRINGS, not to
      // internal code comments (e.g. "swipe" appears in a card-
      // gesture comment). Scope the scan to translation entries by
      // matching `'key': 'value',` lines whose key starts with a
      // paywall prefix.
      final source = File(
        'lib/src/features/settings/presentation/premium_screen.dart',
      ).readAsStringSync();
      final entryPattern = RegExp(
        r"'(premium_[a-z_0-9]+|features|close|loading|restore_[a-z_]+|"
        r"purchase_[a-z_]+|activation_[a-z_]+|downgrade_[a-z_]+|"
        r"confirm_downgrade|yes_revert|no_keep|customer_center_failed)'"
        r"\s*:\s*'([^']*)'",
      );
      final userFacingCopy = entryPattern
          .allMatches(source)
          .map((m) => m.group(2) ?? '')
          .join(' • ')
          .toLowerCase();

      for (final banned in const [
        'revolutionary',
        'seamless',
        'game-changing',
        'find love today',
        'find your person',
        'swipe',
        'match queue',
        'chat',
      ]) {
        expect(userFacingCopy, isNot(contains(banned)),
            reason: '$banned violates ADR-007 §3 copy rules');
      }
    });
  });
}
