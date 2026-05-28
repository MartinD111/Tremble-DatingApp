import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../auth/data/auth_repository.dart';
import '../../subscriptions/application/revenuecat_subscription.dart';
import '../../../shared/ui/tremble_back_button.dart';

@immutable
class PremiumPlanCard {
  const PremiumPlanCard({
    required this.titleKey,
    required this.price,
    required this.periodKey,
    required this.windowKey,
    required this.features,
    required this.ctaBasicKey,
    required this.ctaPremiumKey,
    required this.color,
    required this.borderColor,
    required this.accent,
    required this.tag,
    required this.icon,
    this.perMonthPrice,
    this.billedAs,
    this.savingsBadge,
    this.productIdentifier,
  });

  final String titleKey;
  final String price;
  final String periodKey;
  final String windowKey;
  final String? perMonthPrice;
  final String? billedAs;
  final String? savingsBadge;
  final List<String> features;
  final String ctaBasicKey;
  final String ctaPremiumKey;
  final Color color;
  final Color borderColor;
  final Color accent;
  final String tag;
  final IconData icon;
  final String? productIdentifier;
}

const premiumPlanCards = [
  PremiumPlanCard(
    titleKey: 'premium_card_premium_title',
    price: '7,99 €',
    periodKey: 'premium_card_premium_period',
    windowKey: '',
    features: [
      'premium_feature_wider_radar',
      'premium_feature_unlimited_geofence',
      'premium_feature_custom_themes',
      'premium_feature_advanced_filters',
    ],
    ctaBasicKey: 'premium_cta_get_premium',
    ctaPremiumKey: 'premium_cta_get_premium',
    color: Color(0xFF1A1A18),
    borderColor: Color(0xFFF4436C),
    accent: Color(0xFFF4436C),
    tag: 'SIGNAL PRIME',
    icon: LucideIcons.sparkles,
    productIdentifier: revenueCatMonthlyProduct,
  ),
  PremiumPlanCard(
    titleKey: 'premium_card_weekend_title',
    price: '2,99 €',
    periodKey: 'premium_card_weekend_period',
    windowKey: 'premium_card_weekend_window',
    features: [
      'premium_feature_wider_radar',
      'premium_feature_unlimited_geofence',
      'premium_feature_custom_themes',
      'premium_feature_advanced_filters',
      'premium_feature_weekend_window',
    ],
    ctaBasicKey: 'premium_cta_get_weekend',
    ctaPremiumKey: 'premium_cta_get_weekend',
    color: Color(0xFF1A1A18),
    borderColor: Color(0xFFF5C842),
    accent: Color(0xFFF5C842),
    tag: 'WEEKEND ACCESS',
    icon: LucideIcons.mountain,
    productIdentifier: revenueCatWeeklyProduct,
  ),
  PremiumPlanCard(
    titleKey: 'premium_card_yearly_title',
    price: '59,99 €',
    periodKey: 'premium_card_yearly_period',
    windowKey: '',
    perMonthPrice: '5,00 €',
    billedAs: 'premium_card_yearly_billed_as',
    savingsBadge: 'premium_yearly_savings_badge',
    features: [
      'premium_feature_all_premium',
      'premium_feature_yearly_access',
      'premium_feature_cancel_anytime',
    ],
    ctaBasicKey: 'premium_cta_get_yearly',
    ctaPremiumKey: 'premium_cta_get_yearly',
    color: Color(0xFF1A1A18),
    borderColor: Color(0xFF00C8FF),
    accent: Color(0xFF00C8FF),
    tag: 'YEARLY ACCESS',
    icon: LucideIcons.calendarDays,
    productIdentifier: revenueCatYearlyProduct,
  ),
  PremiumPlanCard(
    titleKey: 'premium_card_lifetime_title',
    price: '149,99 €',
    periodKey: 'premium_card_lifetime_period',
    windowKey: 'premium_card_lifetime_window',
    features: [
      'premium_feature_all_premium',
      'premium_feature_lifetime_upgrades',
      'premium_feature_priority_support',
    ],
    ctaBasicKey: 'premium_cta_get_lifetime',
    ctaPremiumKey: 'premium_cta_get_lifetime',
    color: Color(0xFF1A1A18),
    borderColor: Color(0xFFFFB347),
    accent: Color(0xFFFFB347),
    tag: 'LIFETIME ACCESS',
    icon: LucideIcons.infinity,
    productIdentifier: revenueCatLifetimeProduct,
  ),
  PremiumPlanCard(
    titleKey: 'premium_card_free_title',
    price: '0,00 €',
    periodKey: '',
    windowKey: '',
    features: [
      'premium_free_gym_mode',
      'premium_free_local_radar',
      'premium_free_wave_limit',
    ],
    ctaBasicKey: 'premium_current_plan',
    ctaPremiumKey: 'premium_switch_to_free',
    color: Color(0xFF1A1A18),
    borderColor: Color(0xFFFAFAF7),
    accent: Color(0xFFFAFAF7),
    tag: 'FREE SIGNAL',
    icon: LucideIcons.user,
  ),
];

class PremiumUpgradeScreen extends ConsumerStatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  ConsumerState<PremiumUpgradeScreen> createState() =>
      _PremiumUpgradeScreenState();
}

// Large multiple of premiumPlanCards.length so we can scroll freely in both
// directions before bumping into the virtual list bounds.
const int _kInfiniteInitialPage = 5000;

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> {
  PageController? _pageController;
  int _selectedIndex = 0;
  int _lastHapticPage = _kInfiniteInitialPage;
  bool _isLoading = false;

  // Theme-independent card-level text styles (cards are always dark).
  late final TextStyle _cardTagStyle = GoogleFonts.instrumentSans(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  late final TextStyle _cardTitleStyle = GoogleFonts.instrumentSans(
    color: const Color(0xFFFAFAF7),
    fontSize: 26,
    fontWeight: FontWeight.bold,
    height: 1.1,
  );
  late final TextStyle _priceStyle = GoogleFonts.playfairDisplay(
    color: const Color(0xFFFAFAF7),
    fontSize: 34,
    fontWeight: FontWeight.w800,
  );
  late final TextStyle _periodStyle = GoogleFonts.instrumentSans(
    color: const Color(0xFFA0A09A),
    fontSize: 14,
  );
  late final TextStyle _billedAsStyle = GoogleFonts.instrumentSans(
    color: const Color(0xFFA0A09A),
    fontSize: 12,
    height: 1.3,
  );
  late final TextStyle _badgeStyle = GoogleFonts.instrumentSans(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  late final TextStyle _featureTitleStyle = GoogleFonts.instrumentSans(
    color: const Color(0xFF6B6B63),
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );
  late final TextStyle _featureStyle = GoogleFonts.instrumentSans(
    color: const Color(0xFFFAFAF7),
    fontSize: 12,
    height: 1.3,
  );

  // Resolve accent color from gender when the setting is on.
  static Color _resolveGenderAccent({
    required String? gender,
    required bool isGenderBased,
    required Color fallback,
  }) {
    if (!isGenderBased) return fallback;
    return switch (gender?.toLowerCase()) {
      'male' => const Color(0xFF4A9EFF),
      'female' => const Color(0xFFF4436C),
      _ => fallback,
    };
  }

  // self-contained localized dictionary for English and Slovenian languages
  final Map<String, Map<String, String>> _localTranslations = {
    'en': {
      'premium_title': 'Tremble Upgrade',
      'premium_subtitle': 'Elevate your connection game. Discover physically.',
      'premium_cta_get_premium': 'Get the Tremble Premium Plan',
      'premium_cta_get_weekend': 'Get the Weekend Getaway Plan',
      'premium_cta_get_yearly': 'Activate Yearly — 59.99 € / year',
      'premium_cta_get_lifetime': 'Activate Lifetime — 149.99 €',
      'premium_current_plan': 'Current Plan',
      'premium_switch_to_free': 'Want to switch back to free plan?',
      'premium_manage_subscription': 'Manage subscription',
      'restore_purchases': 'Restore purchases',
      'confirm_downgrade': 'Confirm Downgrade',
      'downgrade_prompt':
          'Are you sure you want to cancel your Premium features and revert to the basic Free Tier?',
      'yes_revert': 'Yes, Switch to Free',
      'no_keep': 'No, Keep Premium',
      'activation_success': 'Upgrade Activated!',
      'activation_success_sub':
          'Your Premium entitlement is active in RevenueCat.',
      'downgrade_success': 'Reverted to Free',
      'downgrade_success_sub':
          'Open RevenueCat Customer Center to change or cancel your subscription.',
      'purchase_cancelled': 'Purchase cancelled.',
      'purchase_failed': 'Purchase failed. Please try again.',
      'restore_success': 'Purchases restored.',
      'restore_failed': 'No active Premium purchase was found.',
      'customer_center_failed': 'Customer Center is unavailable right now.',
      'close': 'Dismiss',
      'loading': 'Securing transaction...',
      'features': 'Upgrades Included',
      'premium_card_premium_title': 'Tremble Premium',
      'premium_card_premium_period': '/ Month',
      'premium_card_weekend_title': 'Weekend Getaway',
      'premium_card_weekend_period': '/ Weekend',
      'premium_card_weekend_window': 'Friday 7:00 PM to Sunday 7:00 PM',
      'premium_card_yearly_title': 'Yearly',
      'premium_card_yearly_period': '/ month',
      'premium_card_yearly_billed_as': 'billed as 59.99 € / year',
      'premium_yearly_savings_badge': 'SAVE 37%',
      'premium_card_lifetime_title': 'Lifetime',
      'premium_card_lifetime_period': 'one-time',
      'premium_card_lifetime_window': 'never pay again',
      'premium_card_free_title': 'Free Tier',
      'premium_feature_wider_radar': '50% wider radar scan',
      'premium_feature_unlimited_geofence': 'Unlimited geofence pings',
      'premium_feature_custom_themes': 'Custom themes',
      'premium_feature_advanced_filters': 'Advanced filtering matrix',
      'premium_feature_weekend_window': 'Active during the getaway window',
      'premium_feature_all_premium': 'All Premium features',
      'premium_feature_yearly_access': '12 months of uninterrupted access',
      'premium_feature_cancel_anytime': 'Cancel anytime',
      'premium_feature_lifetime_upgrades': 'All future upgrades',
      'premium_feature_priority_support': 'Priority support',
      'premium_free_gym_mode': 'Gym mode access',
      'premium_free_local_radar': '30-min local radar',
      'premium_free_wave_limit': 'Standard mutual wave limit',
    },
    'sl': {
      'premium_title': 'Tremble Nadgradnja',
      'premium_subtitle': 'Dvigni raven spoznavanja. Odkrij fizično.',
      'premium_cta_get_premium': 'Aktiviraj Tremble Premium',
      'premium_cta_get_weekend': 'Aktiviraj Weekend Getaway',
      'premium_cta_get_yearly': 'Aktiviraj Yearly — 59,99 € / leto',
      'premium_cta_get_lifetime': 'Aktiviraj Lifetime — 149,99 €',
      'premium_current_plan': 'Trenutni plan',
      'premium_switch_to_free': 'Se želiš vrniti na brezplačen plan?',
      'premium_manage_subscription': 'Upravljaj naročnino',
      'restore_purchases': 'Obnovi nakupe',
      'confirm_downgrade': 'Potrdi Prekinitev',
      'downgrade_prompt':
          'Ali si prepričan, da želiš preklicati svoje Premium funkcije in se vrniti na osnovni brezplačni paket?',
      'yes_revert': 'Da, Vrni na Brezplačno',
      'no_keep': 'Ne, Obdrži Premium',
      'activation_success': 'Nadgradnja aktivirana!',
      'activation_success_sub':
          'Tvoja Premium pravica je aktivna v RevenueCat.',
      'downgrade_success': 'Preklopljeno na Brezplačno',
      'downgrade_success_sub':
          'Za spremembo ali preklic naročnine odpri RevenueCat Customer Center.',
      'purchase_cancelled': 'Nakup preklican.',
      'purchase_failed': 'Nakup ni uspel. Poskusi znova.',
      'restore_success': 'Nakupi so obnovljeni.',
      'restore_failed': 'Aktiven Premium nakup ni bil najden.',
      'customer_center_failed': 'Customer Center trenutno ni na voljo.',
      'close': 'Zapri',
      'loading': 'Zavarovanje transakcije...',
      'features': 'Vključene Nadgradnje',
      'premium_card_premium_title': 'Tremble Premium',
      'premium_card_premium_period': '/ mesec',
      'premium_card_weekend_title': 'Weekend Getaway',
      'premium_card_weekend_period': '/ vikend',
      'premium_card_weekend_window': 'Petek 19:00 do nedelja 19:00',
      'premium_card_yearly_title': 'Yearly',
      'premium_card_yearly_period': '/ mesec',
      'premium_card_yearly_billed_as': 'obračunano kot 59,99 € / leto',
      'premium_yearly_savings_badge': 'PRIHRANI 37%',
      'premium_card_lifetime_title': 'Lifetime',
      'premium_card_lifetime_period': 'enkratno',
      'premium_card_lifetime_window': 'nikoli več ne plačaš',
      'premium_card_free_title': 'Brezplačni paket',
      'premium_feature_wider_radar': '50% širši domet radarja',
      'premium_feature_unlimited_geofence': 'Neomejeni geofence pingi',
      'premium_feature_custom_themes': 'Prilagojene teme',
      'premium_feature_advanced_filters': 'Napredna matrika filtrov',
      'premium_feature_weekend_window': 'Aktivno med getaway oknom',
      'premium_feature_all_premium': 'Vse Premium funkcije',
      'premium_feature_yearly_access': '12 mesecev neprekinjenega dostopa',
      'premium_feature_cancel_anytime': 'Odpoveš kadarkoli',
      'premium_feature_lifetime_upgrades': 'Vse prihodnje nadgradnje',
      'premium_feature_priority_support': 'Prioritetna podpora',
      'premium_free_gym_mode': 'Dostop do Gym načina',
      'premium_free_local_radar': '30-min lokalni radar',
      'premium_free_wave_limit': 'Standardna omejitev mutual wave',
    }
  };

  String _t(String key, String lang) {
    final code = (lang == 'sl') ? 'sl' : 'en';
    return _localTranslations[code]?[key] ??
        _localTranslations['en']?[key] ??
        key;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.76,
      initialPage: _kInfiniteInitialPage,
    )..addListener(() {
        final controller = _pageController;
        if (controller == null || !controller.hasClients) return;
        final page = controller.page ?? controller.initialPage.toDouble();
        final snapped = page.round();
        if (snapped == _lastHapticPage) return;
        _lastHapticPage = snapped;
        HapticFeedback.selectionClick();
      });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _pageController = null;
    super.dispose();
  }

  Future<void> _purchasePlan(AuthUser user, PremiumPlanCard plan) async {
    final productIdentifier = plan.productIdentifier;
    if (productIdentifier == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(revenueCatSubscriptionProvider.notifier)
          .purchaseProduct(productIdentifier);

      if (!mounted) return;

      switch (result) {
        case RevenueCatPurchaseOutcome.purchased:
        case RevenueCatPurchaseOutcome.restored:
        case RevenueCatPurchaseOutcome.alreadyPremium:
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _buildSuccessDialog(
              title: _t('activation_success', user.appLanguage),
              subtitle: _t('activation_success_sub', user.appLanguage),
              lang: user.appLanguage,
            ),
          );
        case RevenueCatPurchaseOutcome.cancelled:
          _showSnack(_t('purchase_cancelled', user.appLanguage));
        case RevenueCatPurchaseOutcome.error:
          final error = ref.read(revenueCatSubscriptionProvider).errorMessage ??
              _t('purchase_failed', user.appLanguage);
          _showSnack(error);
      }
    } catch (e) {
      debugPrint('[PREMIUM] RevenueCat purchase failed: $e');
      if (mounted) _showSnack(_t('purchase_failed', user.appLanguage));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases(AuthUser user) async {
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(revenueCatSubscriptionProvider.notifier)
          .restorePurchases();

      if (!mounted) return;

      if (result == RevenueCatPurchaseOutcome.restored) {
        _showSnack(_t('restore_success', user.appLanguage));
      } else {
        final error = ref.read(revenueCatSubscriptionProvider).errorMessage ??
            _t('restore_failed', user.appLanguage);
        _showSnack(error);
      }
    } catch (e) {
      debugPrint('[PREMIUM] RevenueCat restore failed: $e');
      if (mounted) _showSnack(_t('restore_failed', user.appLanguage));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCustomerCenter(AuthUser user) async {
    setState(() => _isLoading = true);
    try {
      final opened = await ref
          .read(revenueCatSubscriptionProvider.notifier)
          .presentCustomerCenter();
      if (!mounted || opened) return;
      _showSnack(_t('customer_center_failed', user.appLanguage));
    } catch (e) {
      debugPrint('[PREMIUM] Customer Center failed: $e');
      if (mounted) _showSnack(_t('customer_center_failed', user.appLanguage));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF4436C),
      ),
    );
  }

  Widget _buildSuccessDialog({
    required String title,
    required String subtitle,
    required String lang,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor:
          isDark ? const Color(0xFF1A1A18) : const Color(0xFFF2F2F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4436C),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4436C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                child: Text(_t('close', lang),
                    style: GoogleFonts.instrumentSans(
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final lang = user.appLanguage;
    final pageController = _pageController;

    if (pageController == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A18) : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final glowOpacity = isDark ? 0.08 : 0.05;
    final glowOpacity2 = isDark ? 0.05 : 0.03;

    final genderAccent = _resolveGenderAccent(
      gender: user.gender,
      isGenderBased: user.isGenderBasedColor,
      fallback: const Color(0xFFF4436C),
    );

    final screenTitleStyle = GoogleFonts.playfairDisplay(
      color: textColor,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    );
    final screenSubtitleStyle = GoogleFonts.instrumentSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: subtextColor,
      height: 1.4,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: bgColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Decorative glow effects
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: genderAccent.withValues(alpha: glowOpacity),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: genderAccent.withValues(alpha: glowOpacity2),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        TrembleBackButton(onPressed: () => context.pop()),
                        const Spacer(),
                        Text(
                          _t('premium_title', lang),
                          style: screenTitleStyle,
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Subtitle
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      _t('premium_subtitle', lang),
                      textAlign: TextAlign.center,
                      style: screenSubtitleStyle,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Carousel
                  Expanded(
                    child: _PremiumCarousel(
                      pageController: pageController,
                      cardBuilder: (card, language) =>
                          _buildCreditCard(card, language),
                      lang: lang,
                      accentColor: genderAccent,
                      isDark: isDark,
                      onPageChanged: (index) => setState(
                        () => _selectedIndex = index % premiumPlanCards.length,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CTA
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCTAButton(
                          _selectedIndex,
                          premiumPlanCards[_selectedIndex],
                          user,
                          genderAccent,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed:
                              _isLoading ? null : () => _restorePurchases(user),
                          child: Text(
                            _t('restore_purchases', lang),
                            style: GoogleFonts.instrumentSans(
                              color: subtextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(genderAccent),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _t('loading', lang),
                            style: GoogleFonts.instrumentSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(PremiumPlanCard data, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: data.accent, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.12),
                    width: 2,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: data.accent, width: 1.0),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          data.tag,
                          style: _cardTagStyle.copyWith(color: data.accent),
                        ),
                      ),
                      Icon(data.icon, color: data.accent, size: 24),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Text(
                    _t(data.titleKey, lang),
                    style: _cardTitleStyle,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        data.perMonthPrice ?? data.price,
                        style: _priceStyle,
                      ),
                      if (data.periodKey.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          _t(data.periodKey, lang),
                          style: _periodStyle,
                        ),
                      ],
                    ],
                  ),
                  if (data.perMonthPrice != null && data.billedAs != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _t(data.billedAs!, lang),
                      style: _billedAsStyle,
                    ),
                  ],
                  if (data.windowKey.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _t(data.windowKey, lang),
                      style: _periodStyle.copyWith(
                        color: data.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (data.savingsBadge != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: data.accent, width: 1.0),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _t(data.savingsBadge!, lang),
                        style: _badgeStyle.copyWith(color: data.accent),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF2E2E2C), height: 1),
                  const SizedBox(height: 16),
                  Text(
                    _t('features', lang).toUpperCase(),
                    style: _featureTitleStyle,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 12,
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: data.features.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.check,
                              color: data.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _t(data.features[index], lang),
                                style: _featureStyle,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton(
      int index, PremiumPlanCard data, AuthUser user, Color genderAccent) {
    final isPremium = user.isPremium;

    if (index == 4) {
      if (isPremium) {
        return GestureDetector(
          onTap: () => _openCustomerCenter(user),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: const Color(0xFF2A2A2E),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.arrowLeftRight,
                    size: 16, color: Colors.white60),
                const SizedBox(width: 10),
                Text(
                  _t('premium_manage_subscription', user.appLanguage),
                  style: GoogleFonts.instrumentSans(
                    color: Colors.white60,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(
              _t(data.ctaBasicKey, user.appLanguage),
              style: GoogleFonts.instrumentSans(
                color: Colors.white30,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      }
    }

    final ctaText = _t(
      isPremium ? data.ctaPremiumKey : data.ctaBasicKey,
      user.appLanguage,
    );

    // Index 0 (premium card) uses gender-based accent; others keep their card accent.
    final buttonBg = switch (index) {
      0 => genderAccent,
      1 => const Color(0xFFF5C842),
      2 => const Color(0xFF00C8FF),
      3 => const Color(0xFFFFB347),
      _ => data.accent,
    };

    final textColor =
        (index == 1 || index == 3) ? const Color(0xFF1A1A18) : Colors.white;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _purchasePlan(user, data),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 4,
          shadowColor: buttonBg.withValues(alpha: 0.3),
        ),
        child: Text(
          ctaText,
          style: GoogleFonts.instrumentSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _PremiumCarousel extends StatelessWidget {
  const _PremiumCarousel({
    required this.pageController,
    required this.cardBuilder,
    required this.lang,
    required this.accentColor,
    required this.isDark,
    required this.onPageChanged,
  });

  final PageController pageController;
  final Widget Function(PremiumPlanCard card, String lang) cardBuilder;
  final String lang;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder is outermost so screen dimensions are computed only on
    // actual layout changes — not on every scroll frame.
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.82;
        final cardHeight = constraints.maxHeight - 8 - 24; // minus dots + gap

        return AnimatedBuilder(
          animation: pageController,
          builder: (context, _) {
            final currentPage = pageController.hasClients
                ? pageController.page ?? pageController.initialPage.toDouble()
                : pageController.initialPage.toDouble();

            // Render a window of virtual pages around the current page so the
            // card at the wrap boundary stays visible while scrolling.
            const window = 3;
            final base = currentPage.round();
            final virtualPages = <int>[
              for (int p = base - window; p <= base + window; p++) p,
            ]..sort((a, b) {
                final dA = (currentPage - a).abs();
                final dB = (currentPage - b).abs();
                return dB.compareTo(dA);
              });

            return Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: pageController,
                        // null itemCount → infinite scroll in both directions.
                        itemCount: null,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: onPageChanged,
                        itemBuilder: (_, __) => const SizedBox.expand(),
                      ),
                      IgnorePointer(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (final p in virtualPages)
                              _PremiumCarouselCard(
                                data: premiumPlanCards[
                                    p % premiumPlanCards.length],
                                virtualPage: p,
                                lang: lang,
                                currentPage: currentPage,
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                screenWidth: constraints.maxWidth,
                                cardBuilder: cardBuilder,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _PremiumCarouselDots(
                  currentPage: currentPage,
                  accentColor: accentColor,
                  isDark: isDark,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PremiumCarouselCard extends StatelessWidget {
  const _PremiumCarouselCard({
    required this.data,
    required this.virtualPage,
    required this.lang,
    required this.currentPage,
    required this.cardWidth,
    required this.cardHeight,
    required this.screenWidth,
    required this.cardBuilder,
  });

  final PremiumPlanCard data;
  final int virtualPage;
  final String lang;
  final double currentPage;
  final double cardWidth;
  final double cardHeight;
  final double screenWidth;
  final Widget Function(PremiumPlanCard card, String lang) cardBuilder;

  @override
  Widget build(BuildContext context) {
    final offset = virtualPage - currentPage;

    final double translationX;
    final double scale;
    final double rotY;
    final double opacity;

    if (offset >= 0) {
      translationX = -offset * (screenWidth * 0.44);
      scale = 1.0 - (offset * 0.12);
      rotY = -offset * 0.24;
      opacity = (1.0 - (offset * 0.4)).clamp(0.0, 1.0);
    } else {
      translationX = offset * (screenWidth * 0.12);
      scale = 1.0 - (offset.abs() * 0.08);
      rotY = -offset * 0.16;
      opacity = (1.0 - (offset.abs() * 0.3)).clamp(0.0, 1.0);
    }

    return RepaintBoundary(
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..translateByDouble(
            translationX,
            0.0,
            -offset.abs() * 100.0,
            1.0,
          )
          ..scaleByDouble(scale, scale, scale, 1.0)
          ..rotateY(rotY),
        alignment: Alignment.center,
        child: SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Opacity(
            opacity: opacity,
            alwaysIncludeSemantics: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: cardBuilder(data, lang),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCarouselDots extends StatelessWidget {
  const _PremiumCarouselDots({
    required this.currentPage,
    required this.accentColor,
    required this.isDark,
  });

  final double currentPage;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.2);
    final length = premiumPlanCards.length;
    // Project the virtual page onto [0, length) so wrapping past the last
    // card keeps the dots animation smooth.
    final normalized = currentPage - (currentPage / length).floor() * length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        // Shortest distance considering wrap-around in both directions.
        final raw = (i - normalized).abs();
        final distance = math.min(raw, length - raw);
        final factor = (1.0 - distance).clamp(0.0, 1.0);
        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8 + (factor * 12),
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Color.lerp(inactiveColor, accentColor, factor),
            ),
          ),
        );
      }),
    );
  }
}
