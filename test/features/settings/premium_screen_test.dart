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
    expect(premiumPlanCards[1].price, '2,99 €');
    expect(
      premiumPlanCards[1].windowKey,
      'premium_card_weekend_window',
    );
    expect(premiumPlanCards[2].perMonthPrice, '5,00 €');
    expect(premiumPlanCards[2].price, '59,99 €');
    expect(premiumPlanCards[2].savingsBadge, 'premium_yearly_savings_badge');
    expect(premiumPlanCards[3].price, '149,99 €');
    expect(premiumPlanCards[3].accent, const Color(0xFFFFB347));
    expect(premiumPlanCards[4].ctaPremiumKey, 'premium_switch_to_free');
  });
}
