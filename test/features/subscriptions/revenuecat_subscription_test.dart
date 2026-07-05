import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/subscriptions/application/revenuecat_subscription.dart';

void main() {
  test('RevenueCat identifiers match the dashboard contract exactly', () {
    expect(revenueCatEntitlementPremium, 'premium');
    expect(revenueCatDefaultOffering, 'default');
    expect(revenueCatMonthlyProduct, 'monthly');
    expect(revenueCatYearlyProduct, 'yearly');
    expect(revenueCatLifetimeProduct, 'lifetime');
    expect(revenueCatWeeklyProduct, 'weekly');
    expect(revenueCatProductIdentifiers, [
      'monthly',
      'yearly',
      'lifetime',
      'weekly',
    ]);
  });

  test('empty API key leaves subscription controller disabled', () async {
    final client = FakeRevenueCatClient();
    final controller = RevenueCatSubscriptionController(
      client: client,
      apiKey: '',
      isDebug: true,
    );

    await controller.configure();

    expect(client.configureCalls, 0);
    expect(controller.state.status, RevenueCatSubscriptionStatus.disabled);
    expect(controller.state.isPremium, isFalse);
    expect(controller.state.errorMessage, contains('REVENUECAT_APPLE_API_KEY'));
  });

  test('configure loads customer info and detects premium entitlement',
      () async {
    final client = FakeRevenueCatClient(
      initialCustomerInfo: const RevenueCatCustomerInfoSnapshot(
        activeEntitlements: {'premium'},
        activeSubscriptions: {'monthly'},
        purchasedProductIdentifiers: {'monthly'},
      ),
    );
    final controller = RevenueCatSubscriptionController(
      client: client,
      apiKey: 'test-key',
      isDebug: true,
    );

    await controller.configure();

    expect(client.configureCalls, 1);
    expect(client.configuredApiKey, 'test-key');
    expect(controller.state.status, RevenueCatSubscriptionStatus.ready);
    expect(controller.state.isPremium, isTrue);
    expect(controller.state.customerInfo?.activeSubscriptions, {'monthly'});
  });

  test('purchase updates premium state from returned customer info', () async {
    final client = FakeRevenueCatClient();
    final controller = RevenueCatSubscriptionController(
      client: client,
      apiKey: 'test-key',
      isDebug: true,
    );

    await controller.configure();
    final result = await controller.purchaseProduct('yearly');

    expect(client.purchasedProductIdentifiers, ['yearly']);
    expect(result, RevenueCatPurchaseOutcome.purchased);
    expect(controller.state.isPremium, isTrue);
    expect(controller.state.customerInfo?.activeSubscriptions, {'yearly'});
  });

  test('restore updates premium state from restored customer info', () async {
    final client = FakeRevenueCatClient(
      restoreCustomerInfo: const RevenueCatCustomerInfoSnapshot(
        activeEntitlements: {'premium'},
        activeSubscriptions: {'lifetime'},
        purchasedProductIdentifiers: {'lifetime'},
      ),
    );
    final controller = RevenueCatSubscriptionController(
      client: client,
      apiKey: 'test-key',
      isDebug: false,
    );

    await controller.configure();
    final result = await controller.restorePurchases();

    expect(result, RevenueCatPurchaseOutcome.restored);
    expect(controller.state.isPremium, isTrue);
    expect(controller.state.customerInfo?.purchasedProductIdentifiers,
        {'lifetime'});
  });
}

class FakeRevenueCatClient implements RevenueCatClient {
  FakeRevenueCatClient({
    this.initialCustomerInfo = const RevenueCatCustomerInfoSnapshot(
      activeEntitlements: {},
      activeSubscriptions: {},
      purchasedProductIdentifiers: {},
    ),
    this.restoreCustomerInfo = const RevenueCatCustomerInfoSnapshot(
      activeEntitlements: {},
      activeSubscriptions: {},
      purchasedProductIdentifiers: {},
    ),
  });

  final RevenueCatCustomerInfoSnapshot initialCustomerInfo;
  final RevenueCatCustomerInfoSnapshot restoreCustomerInfo;
  final List<String> purchasedProductIdentifiers = [];
  RevenueCatCustomerInfoChanged? listener;
  int configureCalls = 0;
  String? configuredApiKey;

  @override
  Future<void> configure({
    required String apiKey,
    required bool isDebug,
  }) async {
    configureCalls += 1;
    configuredApiKey = apiKey;
  }

  @override
  Future<void> logIn(String appUserId) async {}

  @override
  Future<void> logOut() async {}

  @override
  void addCustomerInfoUpdateListener(
    RevenueCatCustomerInfoChanged onChanged,
  ) {
    listener = onChanged;
  }

  @override
  void removeCustomerInfoUpdateListener(
    RevenueCatCustomerInfoChanged onChanged,
  ) {
    if (listener == onChanged) listener = null;
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> getCustomerInfo() async =>
      initialCustomerInfo;

  @override
  Future<List<RevenueCatPackageSnapshot>> getDefaultOfferingPackages() async =>
      const [
        RevenueCatPackageSnapshot(
          productIdentifier: 'monthly',
          packageIdentifier: r'$rc_monthly',
        ),
        RevenueCatPackageSnapshot(
          productIdentifier: 'yearly',
          packageIdentifier: r'$rc_annual',
        ),
        RevenueCatPackageSnapshot(
          productIdentifier: 'lifetime',
          packageIdentifier: r'$rc_lifetime',
        ),
        RevenueCatPackageSnapshot(
          productIdentifier: 'weekly',
          packageIdentifier: r'$rc_weekly',
        ),
      ];

  @override
  Future<RevenueCatCustomerInfoSnapshot> purchaseProduct(
    String productIdentifier,
  ) async {
    purchasedProductIdentifiers.add(productIdentifier);
    return RevenueCatCustomerInfoSnapshot(
      activeEntitlements: const {'premium'},
      activeSubscriptions: {productIdentifier},
      purchasedProductIdentifiers: {productIdentifier},
    );
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> restorePurchases() async =>
      restoreCustomerInfo;

  @override
  Future<RevenueCatPaywallOutcome> presentPaywallIfNeeded() async =>
      RevenueCatPaywallOutcome.purchased;

  @override
  Future<void> presentCustomerCenter() async {}
}
