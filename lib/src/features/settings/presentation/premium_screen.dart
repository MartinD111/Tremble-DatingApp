import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../../auth/data/auth_repository.dart';

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
    color: Color(0xFF1E1E22),
    borderColor: Color(0x99F4436C),
    accent: Color(0xFFF4436C),
    tag: 'SIGNAL PRIME',
    icon: LucideIcons.sparkles,
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
    color: Color(0xFF242220),
    borderColor: Color(0x99F5C842),
    accent: Color(0xFFF5C842),
    tag: 'WEEKEND ACCESS',
    icon: LucideIcons.mountain,
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
    color: Color(0xFF1A1F26),
    borderColor: Color(0x9900C8FF),
    accent: Color(0xFF00C8FF),
    tag: 'YEARLY ACCESS',
    icon: LucideIcons.calendarDays,
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
    color: Color(0xFF22180A),
    borderColor: Color(0x99FFB347),
    accent: Color(0xFFFFB347),
    tag: 'LIFETIME ACCESS',
    icon: LucideIcons.infinity,
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
    color: Color(0xFF1C1C1E),
    borderColor: Color(0x33FAFAF7),
    accent: Color(0x99FAFAF7),
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

class _PremiumUpgradeScreenState extends ConsumerState<PremiumUpgradeScreen> {
  PageController? _pageController;
  int _selectedIndex = 0;
  int _lastHapticPage = 0;
  bool _isLoading = false;

  late final TextStyle _screenTitleStyle = GoogleFonts.instrumentSans(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );
  late final TextStyle _screenSubtitleStyle = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.3,
  );
  late final TextStyle _dialogTitleStyle = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  late final TextStyle _dialogSubtitleStyle = GoogleFonts.instrumentSans(
    color: Colors.white70,
    height: 1.4,
  );
  late final TextStyle _cardTagStyle = GoogleFonts.instrumentSans(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  late final TextStyle _cardTitleStyle = GoogleFonts.playfairDisplay(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    height: 1.1,
  );
  late final TextStyle _priceStyle = GoogleFonts.instrumentSans(
    color: Colors.white,
    fontSize: 34,
    fontWeight: FontWeight.w800,
  );
  late final TextStyle _periodStyle = GoogleFonts.instrumentSans(
    color: Colors.white60,
    fontSize: 14,
  );
  late final TextStyle _billedAsStyle = GoogleFonts.instrumentSans(
    color: Colors.white60,
    fontSize: 12,
    height: 1.3,
  );
  late final TextStyle _badgeStyle = GoogleFonts.instrumentSans(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  late final TextStyle _featureTitleStyle = GoogleFonts.instrumentSans(
    color: Colors.white38,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );
  late final TextStyle _featureStyle = GoogleFonts.instrumentSans(
    color: Colors.white.withValues(alpha: 0.87),
    fontSize: 12,
    height: 1.3,
  );

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
      'confirm_downgrade': 'Confirm Downgrade',
      'downgrade_prompt':
          'Are you sure you want to cancel your Premium features and revert to the basic Free Tier?',
      'yes_revert': 'Yes, Switch to Free',
      'no_keep': 'No, Keep Premium',
      'activation_success': 'Upgrade Activated!',
      'activation_success_sub':
          'Your premium features have been provisioned locally for UI validation. RevenueCat billing is still gated.',
      'downgrade_success': 'Reverted to Free',
      'downgrade_success_sub':
          'The simulated premium state has been cleared for this session.',
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
      'confirm_downgrade': 'Potrdi Prekinitev',
      'downgrade_prompt':
          'Ali si prepričan, da želiš preklicati svoje Premium funkcije in se vrniti na osnovni brezplačni paket?',
      'yes_revert': 'Da, Vrni na Brezplačno',
      'no_keep': 'Ne, Obdrži Premium',
      'activation_success': 'Nadgradnja aktivirana!',
      'activation_success_sub':
          'Premium stanje je lokalno simulirano za preverjanje UI. RevenueCat plačila so še blokirana.',
      'downgrade_success': 'Preklopljeno na Brezplačno',
      'downgrade_success_sub':
          'Simulirano premium stanje je odstranjeno za to sejo.',
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
    _pageController = PageController(viewportFraction: 0.76)
      ..addListener(() {
        final controller = _pageController;
        if (controller == null || !controller.hasClients) return;
        final page = controller.page ?? controller.initialPage.toDouble();
        final snapped = page.round().clamp(0, premiumPlanCards.length - 1);
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

  Future<void> _simulateUpgrade(AuthUser user, String planName) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    try {
      final updatedUser = user.copyWith(isPremium: true);
      ref.read(authStateProvider.notifier).setUser(updatedUser);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(
            title: _t('activation_success', user.appLanguage),
            subtitle: _t('activation_success_sub', user.appLanguage),
            lang: user.appLanguage,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PREMIUM] Simulation failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateDowngrade(AuthUser user) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      final updatedUser = user.copyWith(isPremium: false);
      ref.read(authStateProvider.notifier).setUser(updatedUser);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(
            title: _t('downgrade_success', user.appLanguage),
            subtitle: _t('downgrade_success_sub', user.appLanguage),
            lang: user.appLanguage,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PREMIUM] Downgrade failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDowngradeConfirmation(AuthUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t('confirm_downgrade', user.appLanguage),
          style: GoogleFonts.instrumentSans(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          _t('downgrade_prompt', user.appLanguage),
          style:
              GoogleFonts.instrumentSans(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _t('no_keep', user.appLanguage),
              style: GoogleFonts.instrumentSans(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateDowngrade(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF4436C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Text(
              _t('yes_revert', user.appLanguage),
              style: GoogleFonts.instrumentSans(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDialog({
    required String title,
    required String subtitle,
    required String lang,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A18),
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
              style: _dialogTitleStyle,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: _dialogSubtitleStyle,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.pop(); // Go back to settings
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
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A18),
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A18), // Deep graphite default
      body: Stack(
        children: [
          // Elegant decorative subtle glow effects in the background
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
                    color: const Color(0xFFF4436C).withValues(alpha: 0.08),
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
                    color: const Color(0xFFF5C842).withValues(alpha: 0.05),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clean Premium Navigation Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.arrowLeft,
                            color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        _t('premium_title', lang),
                        style: _screenTitleStyle,
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance for alignment
                    ],
                  ),
                ),

                // Subtitle introduction
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    _t('premium_subtitle', lang),
                    textAlign: TextAlign.center,
                    style: _screenSubtitleStyle,
                  ),
                ),

                const SizedBox(height: 16),

                // 3D Horizontal Card Shuffle Stack Viewport Area
                Expanded(
                  child: _PremiumCarousel(
                    pageController: pageController,
                    cardBuilder: (card, language) =>
                        _buildCreditCard(card, language),
                    lang: lang,
                    onPageChanged: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                ),

                const SizedBox(height: 24),

                // Contextual CTA Button Area matching the active card
                Padding(
                  padding:
                      const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: _buildCTAButton(
                    _selectedIndex,
                    premiumPlanCards[_selectedIndex],
                    user,
                  ),
                ),
              ],
            ),
          ),

          // Loading screen overlay during mock transactional events
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
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFF4436C)),
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
    );
  }

  Widget _buildCreditCard(PremiumPlanCard data, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: data.borderColor, width: 1.5),
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
            // Elegant background line vectors simulating a premium card design
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
                  // Header badge tag + chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: data.accent.withValues(alpha: 0.15),
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

                  // Plan Title
                  Text(
                    _t(data.titleKey, lang),
                    style: _cardTitleStyle,
                  ),

                  const SizedBox(height: 8),

                  // Price
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
                        color: data.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        _t(data.savingsBadge!, lang),
                        style: _badgeStyle.copyWith(color: data.accent),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 16),

                  // Included Features Title
                  Text(
                    _t('features', lang).toUpperCase(),
                    style: _featureTitleStyle,
                  ),

                  const SizedBox(height: 10),

                  // Bullet Points list
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

  Widget _buildCTAButton(int index, PremiumPlanCard data, AuthUser user) {
    final isPremium = user.isPremium;

    // Index 4 is the Free Tier card.
    if (index == 4) {
      if (isPremium) {
        return SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _showDowngradeConfirmation(user),
            icon: const Icon(LucideIcons.arrowLeftRight,
                size: 18, color: Colors.white60),
            label: Text(
              _t(data.ctaPremiumKey, user.appLanguage),
              style: GoogleFonts.instrumentSans(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: null, // Disabled as it is the current basic plan
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

    // Standard upgrade plans
    final ctaText = _t(
      isPremium ? data.ctaPremiumKey : data.ctaBasicKey,
      user.appLanguage,
    );

    final buttonBg = switch (index) {
      0 => const Color(0xFFF4436C),
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
        onPressed: () =>
            _simulateUpgrade(user, _t(data.titleKey, user.appLanguage)),
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
    required this.onPageChanged,
  });

  final PageController pageController;
  final Widget Function(PremiumPlanCard card, String lang) cardBuilder;
  final String lang;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, _) {
        final currentPage = pageController.hasClients
            ? pageController.page ?? pageController.initialPage.toDouble()
            : pageController.initialPage.toDouble();

        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth * 0.82;
                  final sortedIndices =
                      List.generate(premiumPlanCards.length, (i) => i)
                        ..sort((a, b) {
                          final dA = (currentPage - a).abs();
                          final dB = (currentPage - b).abs();
                          return dB.compareTo(dA);
                        });

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: pageController,
                        itemCount: premiumPlanCards.length,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: onPageChanged,
                        itemBuilder: (_, __) => const SizedBox.expand(),
                      ),
                      IgnorePointer(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            for (final i in sortedIndices)
                              _PremiumCarouselCard(
                                data: premiumPlanCards[i],
                                lang: lang,
                                currentPage: currentPage,
                                cardWidth: cardWidth,
                                cardHeight: constraints.maxHeight,
                                screenWidth: constraints.maxWidth,
                                cardBuilder: cardBuilder,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _PremiumCarouselDots(currentPage: currentPage),
          ],
        );
      },
    );
  }
}

class _PremiumCarouselCard extends StatelessWidget {
  const _PremiumCarouselCard({
    required this.data,
    required this.lang,
    required this.currentPage,
    required this.cardWidth,
    required this.cardHeight,
    required this.screenWidth,
    required this.cardBuilder,
  });

  final PremiumPlanCard data;
  final String lang;
  final double currentPage;
  final double cardWidth;
  final double cardHeight;
  final double screenWidth;
  final Widget Function(PremiumPlanCard card, String lang) cardBuilder;

  @override
  Widget build(BuildContext context) {
    final index = premiumPlanCards.indexOf(data);
    final offset = index - currentPage;

    final double translationX;
    final double scale;
    final double rotY;
    final double blurSigma;
    final double opacity;

    if (offset >= 0) {
      translationX = -offset * (screenWidth * 0.44);
      scale = 1.0 - (offset * 0.12);
      rotY = -offset * 0.24;
      blurSigma = offset * 4.5;
      opacity = (1.0 - (offset * 0.4)).clamp(0.0, 1.0);
    } else {
      translationX = offset * (screenWidth * 0.12);
      scale = 1.0 - (offset.abs() * 0.08);
      rotY = -offset * 0.16;
      blurSigma = offset.abs() * 2.0;
      opacity = (1.0 - (offset.abs() * 0.3)).clamp(0.0, 1.0);
    }

    Widget cardWidget = Transform(
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
        child: RepaintBoundary(
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

    if (blurSigma > 0.1) {
      cardWidget = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class _PremiumCarouselDots extends StatelessWidget {
  const _PremiumCarouselDots({required this.currentPage});

  final double currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(premiumPlanCards.length, (i) {
        final distance = (i - currentPage).abs();
        final factor = (1.0 - distance).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8 + (factor * 12),
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Color.lerp(
              Colors.white.withValues(alpha: 0.3),
              const Color(0xFFF4436C),
              factor,
            ),
          ),
        );
      }),
    );
  }
}
