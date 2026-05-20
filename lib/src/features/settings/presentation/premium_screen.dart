import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme_provider.dart';
import '../../../shared/ui/gradient_scaffold.dart';
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
  });

  final String titleKey;
  final String price;
  final String periodKey;
  final String windowKey;
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
    titleKey: 'premium_card_choices_title',
    price: '59,99 €',
    periodKey: 'premium_card_choices_period',
    windowKey: '',
    features: [
      'premium_choice_monthly',
      'premium_choice_yearly',
      'premium_choice_lifetime',
    ],
    ctaBasicKey: 'premium_cta_get_choices',
    ctaPremiumKey: 'premium_cta_get_choices',
    color: Color(0xFF1A1F26),
    borderColor: Color(0x88FAFAF7),
    accent: Color(0xFFFAFAF7),
    tag: 'DURATION MATRIX',
    icon: LucideIcons.calendarDays,
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
  final PageController _pageController = PageController(viewportFraction: 0.76);
  double _currentPage = 0.0;
  int _lastHapticPage = 0;
  bool _isLoading = false;

  // self-contained localized dictionary for English and Slovenian languages
  final Map<String, Map<String, String>> _localTranslations = {
    'en': {
      'premium_title': 'Upgrade Tremble',
      'premium_subtitle': 'Elevate your connection game. Discover physically.',
      'premium_cta_get_premium': 'Get the Tremble Premium Plan',
      'premium_cta_get_weekend': 'Get the Weekend Getaway Plan',
      'premium_cta_get_choices': 'Get the Duration Choice Plan',
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
      'premium_card_choices_title': 'Choices',
      'premium_card_choices_period': '/ Year',
      'premium_card_free_title': 'Free Tier',
      'premium_feature_wider_radar': '50% wider radar scan',
      'premium_feature_unlimited_geofence': 'Unlimited geofence pings',
      'premium_feature_custom_themes': 'Custom themes',
      'premium_feature_advanced_filters': 'Advanced filtering matrix',
      'premium_feature_weekend_window': 'Active during the getaway window',
      'premium_choice_monthly': 'Monthly: 7.99 € / Month',
      'premium_choice_yearly':
          'Yearly: 59.99 € / Year (~5.00 € / month, Save 37%)',
      'premium_choice_lifetime': 'Lifetime: 149.99 € / One-time',
      'premium_free_gym_mode': 'Gym mode access',
      'premium_free_local_radar': '30-min local radar',
      'premium_free_wave_limit': 'Standard mutual wave limit',
    },
    'sl': {
      'premium_title': 'Nadgradi Tremble',
      'premium_subtitle': 'Dvigni raven spoznavanja. Odkrij fizično.',
      'premium_cta_get_premium': 'Aktiviraj Tremble Premium',
      'premium_cta_get_weekend': 'Aktiviraj Weekend Getaway',
      'premium_cta_get_choices': 'Izberi trajanje paketa',
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
      'premium_card_choices_title': 'Choices',
      'premium_card_choices_period': '/ leto',
      'premium_card_free_title': 'Brezplačni paket',
      'premium_feature_wider_radar': '50% širši domet radarja',
      'premium_feature_unlimited_geofence': 'Neomejeni geofence pingi',
      'premium_feature_custom_themes': 'Prilagojene teme',
      'premium_feature_advanced_filters': 'Napredna matrika filtrov',
      'premium_feature_weekend_window': 'Aktivno med getaway oknom',
      'premium_choice_monthly': 'Mesečno: 7.99 € / mesec',
      'premium_choice_yearly':
          'Letno: 59.99 € / leto (~5.00 € / mesec, 37% prihranek)',
      'premium_choice_lifetime': 'Doživljenjsko: 149.99 € / enkratno',
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
    _pageController.addListener(() {
      final newPage = _pageController.page ?? 0.0;
      final int snapped = newPage.round().clamp(0, premiumPlanCards.length - 1);
      if (snapped != _lastHapticPage) {
        _lastHapticPage = snapped;
        HapticFeedback.selectionClick();
      }
      setState(() => _currentPage = newPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSans(
                  color: Colors.white70, height: 1.4),
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
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A18);
    final subTextColor = isDark
        ? Colors.white.withValues(alpha: 0.87)
        : const Color(0xFF1A1A18).withValues(alpha: 0.75);
    final int selectedIndex =
        _currentPage.round().clamp(0, premiumPlanCards.length - 1);

    return GradientScaffold(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main Layout Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Navigation Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    TrembleBackButton(onPressed: () => context.pop()),
                    const Spacer(),
                    Text(
                      _t('premium_title', lang),
                      style: GoogleFonts.playfairDisplay(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
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
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                    height: 1.3,
                  ),
                ),
              ),

                const SizedBox(height: 16),

                // PageView handles gesture/physics; Stack renders cards in z-order
                // Google Wallet–style card carousel
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final W = constraints.maxWidth;
                      // Card fills most of the width; adjacent cards peek ~10% from each side
                      final cardWidth = W * 0.82;
                      // peek amount ≈ spacing (distance from active center to adjacent center)
                      final spacing = W * 0.11;

                      // Farthest card painted first (bottom), active painted last (top)
                      final sortedIndices =
                          List.generate(premiumPlanCards.length, (i) => i)
                            ..sort((a, b) {
                              final dA = (_currentPage - a).abs();
                              final dB = (_currentPage - b).abs();
                              return dB.compareTo(dA);
                            });

                      return Stack(
                        children: [
                          // Invisible PageView — provides native swipe physics & snap
                          PageView.builder(
                            controller: _pageController,
                            itemCount: premiumPlanCards.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (_, __) => const SizedBox.expand(),
                          ),
                          // Visible cards with correct z-order
                          Positioned.fill(
                            child: IgnorePointer(
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              alignment: Alignment.center,
                              children: sortedIndices.map((i) {
                                final double offset = i - _currentPage;
                                final double absOff = offset.abs();
                                // Only render immediate neighbours
                                if (absOff > 1.5) return const SizedBox.shrink();

                                final double scale =
                                    (1.0 - absOff * 0.04).clamp(0.92, 1.0);
                                final double opacity =
                                    (1.0 - absOff * 0.3).clamp(0.0, 1.0);
                                // tx = peek amount × sign of offset
                                final double tx = offset * spacing;

                                return Transform.translate(
                                  offset: Offset(tx, 0),
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: SizedBox(
                                        width: cardWidth,
                                        child: _buildCreditCard(
                                            premiumPlanCards[i], lang),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Interactive Dynamic Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(premiumPlanCards.length, (i) {
                    final double distance = (i - _currentPage).abs();
                    final double factor = (1.0 - distance).clamp(0.0, 1.0);
                    final inactiveColor = isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.2);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8 + (factor * 12),
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Color.lerp(inactiveColor, const Color(0xFFF4436C), factor),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Contextual CTA Button Area matching the active card
                Padding(
                  padding:
                      const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: _buildCTAButton(
                    selectedIndex,
                    premiumPlanCards[selectedIndex],
                    user,
                  ),
                ),
              ],
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
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.color,
            Color.lerp(data.color, Colors.black, 0.35)!,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: data.borderColor, width: 1.5),
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
                          style: GoogleFonts.instrumentSans(
                            color: data.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Icon(data.icon, color: data.accent, size: 24),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Plan Title
                  Text(
                    _t(data.titleKey, lang),
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        data.price,
                        style: GoogleFonts.instrumentSans(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (data.periodKey.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          _t(data.periodKey, lang),
                          style: GoogleFonts.instrumentSans(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (data.windowKey.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _t(data.windowKey, lang),
                      style: GoogleFonts.instrumentSans(
                        color: data.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
                    style: GoogleFonts.instrumentSans(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
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
                                style: GoogleFonts.instrumentSans(
                                  color: Colors.white.withValues(alpha: 0.87),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
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

    // Index 3 is the Free Tier Card
    if (index == 3) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isPremium ? () => _showDowngradeConfirmation(user) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPremium
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
            disabledForegroundColor: Colors.white30,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
            elevation: 0,
          ),
          child: Text(
            'Switch back to free',
            style: GoogleFonts.instrumentSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Standard upgrade plans
    final String ctaText = index == 0
        ? _t(data.ctaBasicKey, user.appLanguage)
        : index == 1
            ? _t(data.ctaBasicKey, user.appLanguage)
            : _t(data.ctaBasicKey, user.appLanguage);

    final buttonBg = index == 0
        ? const Color(0xFFF4436C) // Strong rose for premium tier
        : index == 1
            ? const Color(0xFFF5C842) // Warm signal yellow for weekend
            : const Color(0xFF00C8FF); // Vibrant cyan for options

    final textColor = index == 1 ? const Color(0xFF1A1A18) : Colors.white;

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
