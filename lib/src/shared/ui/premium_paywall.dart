import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../features/subscriptions/application/revenuecat_subscription.dart';

class PremiumPaywallBottomSheet {
  const PremiumPaywallBottomSheet._();

  static Future<void> show(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final controller = ProviderScope.containerOf(context, listen: false)
        .read(revenueCatSubscriptionProvider.notifier);

    final result = await controller.presentPaywallIfNeeded();

    if (!context.mounted) return;

    switch (result) {
      case RevenueCatPaywallOutcome.purchased:
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Premium activated.'),
            backgroundColor: TrembleTheme.rose,
          ),
        );
      case RevenueCatPaywallOutcome.restored:
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Purchases restored.'),
            backgroundColor: TrembleTheme.rose,
          ),
        );
      case RevenueCatPaywallOutcome.error:
        final error = ProviderScope.containerOf(context, listen: false)
                .read(revenueCatSubscriptionProvider)
                .errorMessage ??
            'Unable to open the paywall.';
        messenger?.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: TrembleTheme.rose,
          ),
        );
      case RevenueCatPaywallOutcome.notPresented:
      case RevenueCatPaywallOutcome.cancelled:
        break;
    }
  }
}
