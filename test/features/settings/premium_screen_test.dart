import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/settings/presentation/premium_screen.dart';

void main() {
  test('premium upgrade cards keep the approved order and pricing', () {
    expect(premiumPlanCards.map((card) => card.titleKey), [
      'premium_card_premium_title',
      'premium_card_weekend_title',
      'premium_card_choices_title',
      'premium_card_free_title',
    ]);

    expect(premiumPlanCards[0].price, '7,99 €');
    expect(premiumPlanCards[1].price, '2,99 €');
    expect(
      premiumPlanCards[1].windowKey,
      'premium_card_weekend_window',
    );
    expect(premiumPlanCards[2].features.length, 3);
    expect(premiumPlanCards[3].ctaPremiumKey, 'premium_switch_to_free');
  });
}
