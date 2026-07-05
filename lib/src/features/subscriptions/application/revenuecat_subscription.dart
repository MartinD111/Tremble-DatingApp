import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as purchases;
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

const revenueCatEntitlementPremium = 'premium';
const revenueCatDefaultOffering = 'default';
const revenueCatMonthlyProduct = 'monthly';
const revenueCatYearlyProduct = 'yearly';
const revenueCatLifetimeProduct = 'lifetime';
const revenueCatWeeklyProduct = 'weekly';

const revenueCatProductIdentifiers = [
  revenueCatMonthlyProduct,
  revenueCatYearlyProduct,
  revenueCatLifetimeProduct,
  revenueCatWeeklyProduct,
];

typedef RevenueCatCustomerInfoChanged = void Function(
  RevenueCatCustomerInfoSnapshot customerInfo,
);

enum RevenueCatSubscriptionStatus {
  idle,
  configuring,
  ready,
  disabled,
  error,
}

enum RevenueCatPurchaseOutcome {
  purchased,
  restored,
  cancelled,
  alreadyPremium,
  error,
}

enum RevenueCatPaywallOutcome {
  notPresented,
  cancelled,
  error,
  purchased,
  restored,
}

@immutable
class RevenueCatCustomerInfoSnapshot {
  const RevenueCatCustomerInfoSnapshot({
    required this.activeEntitlements,
    required this.activeSubscriptions,
    required this.purchasedProductIdentifiers,
    this.managementUrl,
    this.premiumExpiryDate,
  });

  final Set<String> activeEntitlements;
  final Set<String> activeSubscriptions;
  final Set<String> purchasedProductIdentifiers;
  final String? managementUrl;
  final DateTime? premiumExpiryDate;

  bool get isPremium =>
      activeEntitlements.contains(revenueCatEntitlementPremium);

  static RevenueCatCustomerInfoSnapshot fromCustomerInfo(
    purchases.CustomerInfo customerInfo,
  ) {
    final expiryStr = customerInfo
        .entitlements.active[revenueCatEntitlementPremium]?.expirationDate;
    return RevenueCatCustomerInfoSnapshot(
      activeEntitlements: customerInfo.entitlements.active.keys.toSet(),
      activeSubscriptions: customerInfo.activeSubscriptions.toSet(),
      purchasedProductIdentifiers:
          customerInfo.allPurchasedProductIdentifiers.toSet(),
      managementUrl: customerInfo.managementURL,
      premiumExpiryDate:
          expiryStr != null ? DateTime.tryParse(expiryStr) : null,
    );
  }
}

@immutable
class RevenueCatPackageSnapshot {
  const RevenueCatPackageSnapshot({
    required this.productIdentifier,
    required this.packageIdentifier,
  });

  final String productIdentifier;
  final String packageIdentifier;
}

@immutable
class RevenueCatSubscriptionState {
  const RevenueCatSubscriptionState({
    required this.status,
    required this.isPremium,
    this.customerInfo,
    this.packages = const [],
    this.errorMessage,
  });

  const RevenueCatSubscriptionState.idle()
      : status = RevenueCatSubscriptionStatus.idle,
        isPremium = false,
        customerInfo = null,
        packages = const [],
        errorMessage = null;

  final RevenueCatSubscriptionStatus status;
  final bool isPremium;
  final RevenueCatCustomerInfoSnapshot? customerInfo;
  final List<RevenueCatPackageSnapshot> packages;
  final String? errorMessage;

  RevenueCatSubscriptionState copyWith({
    RevenueCatSubscriptionStatus? status,
    bool? isPremium,
    RevenueCatCustomerInfoSnapshot? customerInfo,
    List<RevenueCatPackageSnapshot>? packages,
    String? errorMessage,
  }) {
    return RevenueCatSubscriptionState(
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      customerInfo: customerInfo ?? this.customerInfo,
      packages: packages ?? this.packages,
      errorMessage: errorMessage,
    );
  }
}

abstract class RevenueCatClient {
  Future<void> configure({
    required String apiKey,
    required bool isDebug,
  });

  Future<void> logIn(String appUserId);

  Future<void> logOut();

  void addCustomerInfoUpdateListener(
    RevenueCatCustomerInfoChanged onChanged,
  );

  void removeCustomerInfoUpdateListener(
    RevenueCatCustomerInfoChanged onChanged,
  );

  Future<RevenueCatCustomerInfoSnapshot> getCustomerInfo();

  Future<List<RevenueCatPackageSnapshot>> getDefaultOfferingPackages();

  Future<RevenueCatCustomerInfoSnapshot> purchaseProduct(
    String productIdentifier,
  );

  Future<RevenueCatCustomerInfoSnapshot> restorePurchases();

  Future<RevenueCatPaywallOutcome> presentPaywallIfNeeded();

  Future<void> presentCustomerCenter();
}

class PurchasesRevenueCatClient implements RevenueCatClient {
  final Map<RevenueCatCustomerInfoChanged, purchases.CustomerInfoUpdateListener>
      _listeners = {};

  @override
  Future<void> configure({
    required String apiKey,
    required bool isDebug,
  }) async {
    await purchases.Purchases.setLogLevel(
      isDebug ? purchases.LogLevel.debug : purchases.LogLevel.warn,
    );
    await purchases.Purchases.configure(
      purchases.PurchasesConfiguration(apiKey)
        ..purchasesAreCompletedBy =
            const purchases.PurchasesAreCompletedByRevenueCat(),
    );
  }

  @override
  Future<void> logIn(String appUserId) async {
    await purchases.Purchases.logIn(appUserId);
  }

  @override
  Future<void> logOut() async {
    await purchases.Purchases.logOut();
  }

  @override
  void addCustomerInfoUpdateListener(
    RevenueCatCustomerInfoChanged onChanged,
  ) {
    final listener = (purchases.CustomerInfo customerInfo) {
      onChanged(RevenueCatCustomerInfoSnapshot.fromCustomerInfo(customerInfo));
    };
    _listeners[onChanged] = listener;
    purchases.Purchases.addCustomerInfoUpdateListener(listener);
  }

  @override
  void removeCustomerInfoUpdateListener(
    RevenueCatCustomerInfoChanged onChanged,
  ) {
    final listener = _listeners.remove(onChanged);
    if (listener == null) return;
    purchases.Purchases.removeCustomerInfoUpdateListener(listener);
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> getCustomerInfo() async {
    final customerInfo = await purchases.Purchases.getCustomerInfo();
    return RevenueCatCustomerInfoSnapshot.fromCustomerInfo(customerInfo);
  }

  @override
  Future<List<RevenueCatPackageSnapshot>> getDefaultOfferingPackages() async {
    final offering = await _getDefaultOffering();
    return offering.availablePackages
        .map(
          (package) => RevenueCatPackageSnapshot(
            productIdentifier: package.storeProduct.identifier,
            packageIdentifier: package.identifier,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> purchaseProduct(
    String productIdentifier,
  ) async {
    final offering = await _getDefaultOffering();
    final package = offering.availablePackages
        .where(
          (package) => package.storeProduct.identifier == productIdentifier,
        )
        .firstOrNull;

    if (package == null) {
      throw RevenueCatSubscriptionException(
        'Product "$productIdentifier" is not available in the default offering.',
      );
    }

    final result = await purchases.Purchases.purchase(
      purchases.PurchaseParams.package(package),
    );
    return RevenueCatCustomerInfoSnapshot.fromCustomerInfo(result.customerInfo);
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> restorePurchases() async {
    final customerInfo = await purchases.Purchases.restorePurchases();
    return RevenueCatCustomerInfoSnapshot.fromCustomerInfo(customerInfo);
  }

  @override
  Future<RevenueCatPaywallOutcome> presentPaywallIfNeeded() async {
    final offering = await _getDefaultOffering();
    final result = await RevenueCatUI.presentPaywallIfNeeded(
      revenueCatEntitlementPremium,
      offering: offering,
      displayCloseButton: true,
    );
    return switch (result) {
      PaywallResult.notPresented => RevenueCatPaywallOutcome.notPresented,
      PaywallResult.cancelled => RevenueCatPaywallOutcome.cancelled,
      PaywallResult.error => RevenueCatPaywallOutcome.error,
      PaywallResult.purchased => RevenueCatPaywallOutcome.purchased,
      PaywallResult.restored => RevenueCatPaywallOutcome.restored,
    };
  }

  @override
  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  Future<purchases.Offering> _getDefaultOffering() async {
    final offerings = await purchases.Purchases.getOfferings();
    final offering = offerings.getOffering(revenueCatDefaultOffering);
    if (offering == null) {
      throw const RevenueCatSubscriptionException(
        'RevenueCat offering "default" is not configured.',
      );
    }
    return offering;
  }
}

class RevenueCatSubscriptionException implements Exception {
  const RevenueCatSubscriptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RevenueCatSubscriptionController
    extends StateNotifier<RevenueCatSubscriptionState> {
  RevenueCatSubscriptionController({
    required RevenueCatClient client,
    required String apiKey,
    required bool isDebug,
  })  : _client = client,
        _apiKey = apiKey,
        _isDebug = isDebug,
        super(const RevenueCatSubscriptionState.idle());

  final RevenueCatClient _client;
  final String _apiKey;
  final bool _isDebug;
  bool _configured = false;
  String? _appUserId;

  Future<void> configure() async {
    if (_configured) return;

    if (_apiKey.trim().isEmpty) {
      state = const RevenueCatSubscriptionState(
        status: RevenueCatSubscriptionStatus.disabled,
        isPremium: false,
        errorMessage:
            'REVENUECAT_APPLE_API_KEY or REVENUECAT_GOOGLE_API_KEY is missing. Pass it with --dart-define.',
      );
      return;
    }

    state = state.copyWith(
      status: RevenueCatSubscriptionStatus.configuring,
      errorMessage: null,
    );

    try {
      await _client.configure(apiKey: _apiKey, isDebug: _isDebug);
      _client.addCustomerInfoUpdateListener(_handleCustomerInfoChanged);
      final customerInfo = await _client.getCustomerInfo();
      _configured = true;
      state = RevenueCatSubscriptionState(
        status: RevenueCatSubscriptionStatus.ready,
        isPremium: customerInfo.isPremium,
        customerInfo: customerInfo,
      );
    } catch (error) {
      state = RevenueCatSubscriptionState(
        status: RevenueCatSubscriptionStatus.error,
        isPremium: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> syncAppUserId(String? appUserId) async {
    if (!_configured || _appUserId == appUserId) return;

    try {
      if (appUserId == null) {
        await _client.logOut();
      } else {
        await _client.logIn(appUserId);
      }
      _appUserId = appUserId;
      await refreshCustomerInfo();
    } catch (error) {
      if (kDebugMode)
        debugPrint('[REVENUECAT] Failed to sync app user id: $error');
    }
  }

  Future<void> refreshCustomerInfo() async {
    if (!_configured) {
      await configure();
      return;
    }

    try {
      final customerInfo = await _client.getCustomerInfo();
      _handleCustomerInfoChanged(customerInfo);
    } catch (error) {
      state = state.copyWith(errorMessage: _messageFromError(error));
    }
  }

  Future<RevenueCatPurchaseOutcome> purchaseProduct(
    String productIdentifier,
  ) async {
    await configure();
    if (!_configured) return RevenueCatPurchaseOutcome.error;

    try {
      final customerInfo = await _client.purchaseProduct(productIdentifier);
      _handleCustomerInfoChanged(customerInfo);
      return customerInfo.isPremium
          ? RevenueCatPurchaseOutcome.purchased
          : RevenueCatPurchaseOutcome.error;
    } on PlatformException catch (error) {
      if (_isPurchaseCancelled(error)) {
        return RevenueCatPurchaseOutcome.cancelled;
      }
      state = state.copyWith(errorMessage: _messageFromError(error));
      return RevenueCatPurchaseOutcome.error;
    } catch (error) {
      state = state.copyWith(errorMessage: _messageFromError(error));
      return RevenueCatPurchaseOutcome.error;
    }
  }

  Future<RevenueCatPurchaseOutcome> restorePurchases() async {
    await configure();
    if (!_configured) return RevenueCatPurchaseOutcome.error;

    try {
      final customerInfo = await _client.restorePurchases();
      _handleCustomerInfoChanged(customerInfo);
      return customerInfo.isPremium
          ? RevenueCatPurchaseOutcome.restored
          : RevenueCatPurchaseOutcome.error;
    } catch (error) {
      state = state.copyWith(errorMessage: _messageFromError(error));
      return RevenueCatPurchaseOutcome.error;
    }
  }

  Future<RevenueCatPaywallOutcome> presentPaywallIfNeeded() async {
    await configure();
    if (!_configured) return RevenueCatPaywallOutcome.error;

    try {
      final result = await _client.presentPaywallIfNeeded();
      if (result == RevenueCatPaywallOutcome.purchased ||
          result == RevenueCatPaywallOutcome.restored) {
        await refreshCustomerInfo();
      }
      return result;
    } catch (error) {
      state = state.copyWith(errorMessage: _messageFromError(error));
      return RevenueCatPaywallOutcome.error;
    }
  }

  Future<bool> presentCustomerCenter() async {
    await configure();
    if (!_configured) return false;

    try {
      await _client.presentCustomerCenter();
      await refreshCustomerInfo();
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: _messageFromError(error));
      return false;
    }
  }

  void _handleCustomerInfoChanged(
    RevenueCatCustomerInfoSnapshot customerInfo,
  ) {
    state = state.copyWith(
      status: RevenueCatSubscriptionStatus.ready,
      isPremium: customerInfo.isPremium,
      customerInfo: customerInfo,
      errorMessage: null,
    );
  }

  bool _isPurchaseCancelled(PlatformException error) {
    try {
      return purchases.PurchasesErrorHelper.getErrorCode(error) ==
          purchases.PurchasesErrorCode.purchaseCancelledError;
    } catch (_) {
      return false;
    }
  }

  String _messageFromError(Object error) {
    if (error is RevenueCatSubscriptionException) {
      return error.message;
    }
    if (error is PlatformException) {
      final message = error.message;
      if (message != null && message.isNotEmpty) return message;
      return 'RevenueCat platform error: ${error.code}';
    }
    return 'RevenueCat error: $error';
  }

  @override
  void dispose() {
    _client.removeCustomerInfoUpdateListener(_handleCustomerInfoChanged);
    super.dispose();
  }
}

final revenueCatApiKeyProvider = Provider<String>((ref) {
  if (Platform.isIOS || Platform.isMacOS) {
    return const String.fromEnvironment('REVENUECAT_APPLE_API_KEY');
  } else if (Platform.isAndroid) {
    return const String.fromEnvironment('REVENUECAT_GOOGLE_API_KEY');
  }
  return '';
});

final revenueCatClientProvider = Provider<RevenueCatClient>((ref) {
  return PurchasesRevenueCatClient();
});

final revenueCatSubscriptionProvider = StateNotifierProvider<
    RevenueCatSubscriptionController, RevenueCatSubscriptionState>((ref) {
  final controller = RevenueCatSubscriptionController(
    client: ref.watch(revenueCatClientProvider),
    apiKey: ref.watch(revenueCatApiKeyProvider),
    isDebug: kDebugMode,
  );
  unawaited(controller.configure());
  return controller;
});

final revenueCatIsPremiumProvider = Provider<bool>((ref) {
  return ref.watch(revenueCatSubscriptionProvider).isPremium;
});
