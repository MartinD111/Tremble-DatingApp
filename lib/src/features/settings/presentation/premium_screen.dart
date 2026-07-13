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
import '../../../core/theme.dart';
import 'package:flutter/foundation.dart';

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

// Feature-bullet order matches ADR-007 (`tasks/decisions/ADR-007-tier-
// matrix.md`). Order chosen for conversion strength: expanded radar
// surface first (visible in the same session), then history/recap
// upgrades (returning users), then long-tail filters/insights.
// Any change to this list must also update ADR-007 and re-run the
// `premium card advertises exactly the ADR-007 Premium-only rows` test
// in `test/features/settings/premium_screen_test.dart`.
const premiumOnlyFeatureBullets = <String>[
  'premium_feature_radar_extended',
  'premium_feature_mutual_waves_20',
  'premium_feature_open_profile_cards',
  'premium_feature_recap_full',
  'premium_feature_near_miss_history',
  'premium_feature_hard_filters',
  'premium_feature_event_insights',
];

// What stays free per ADR-007. Both-tier rows (proximity, waves,
// active radar, Pulse Intercept, event pins, nicotine filter) plus
// the Free-only nearMissCount upsell banner are collapsed into
// user-facing bullets. Gym Mode is intentionally NOT listed — it is
// a mode users opt into, not a tier feature, and therefore falls
// outside ADR-007's scope. Max-distance row retired per ADR-007
// Amendment §5 (no widget ever wired the slider).
const freeTierFeatureBullets = <String>[
  'premium_free_proximity',
  'premium_free_pulse_intercept',
  'premium_free_active_radar',
  'premium_free_mutual_waves_5',
  'premium_free_event_pins',
  'premium_free_nicotine_filter',
];

const premiumPlanCards = [
  PremiumPlanCard(
    titleKey: 'premium_card_premium_title',
    price: '7,99 €',
    periodKey: 'premium_card_premium_period',
    windowKey: '',
    features: premiumOnlyFeatureBullets,
    ctaBasicKey: 'premium_cta_get_premium',
    ctaPremiumKey: 'premium_cta_get_premium',
    color: TrembleTheme.textColor,
    borderColor: TrembleTheme.rose,
    accent: TrembleTheme.rose,
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
      ...premiumOnlyFeatureBullets,
      'premium_feature_weekend_window',
    ],
    ctaBasicKey: 'premium_cta_get_weekend',
    ctaPremiumKey: 'premium_cta_get_weekend',
    color: TrembleTheme.textColor,
    borderColor: TrembleTheme.accentYellow,
    accent: TrembleTheme.accentYellow,
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
    color: TrembleTheme.textColor,
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
    color: TrembleTheme.textColor,
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
    features: freeTierFeatureBullets,
    ctaBasicKey: 'premium_current_plan',
    ctaPremiumKey: 'premium_switch_to_free',
    color: TrembleTheme.textColor,
    borderColor: TrembleTheme.backgroundColor,
    accent: TrembleTheme.backgroundColor,
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
    color: TrembleTheme.backgroundColor,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    height: 1.1,
  );
  late final TextStyle _priceStyle = GoogleFonts.playfairDisplay(
    color: TrembleTheme.backgroundColor,
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
    color: TrembleTheme.backgroundColor,
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
      'female' => TrembleTheme.rose,
      _ => fallback,
    };
  }

  // self-contained localized dictionary for English, Slovenian, German, Croatian, Italian, Spanish, French, and Portuguese languages
  final Map<String, Map<String, String>> _localTranslations = {
    'en': {
      'premium_title': 'Tremble Upgrade',
      'premium_subtitle': 'Elevate your connection game. Discover physically.',
      'premium_cta_get_premium': 'Get the Tremble Premium Plan',
      'premium_cta_get_weekend': 'Get This Weekend',
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
      'premium_card_weekend_window':
          'Activates next Friday 7 PM – Sunday 7 PM (your local time). Auto-renews weekly. Cancel anytime.',
      'premium_card_yearly_title': 'Yearly',
      'premium_card_yearly_period': '/ month',
      'premium_card_yearly_billed_as': 'billed as 59.99 € / year',
      'premium_yearly_savings_badge': 'SAVE 37%',
      'premium_card_lifetime_title': 'Lifetime',
      'premium_card_lifetime_period': 'one-time',
      'premium_card_lifetime_window': 'never pay again',
      'premium_card_free_title': 'Free Tier',
      // Premium-only bullets (ADR-007). Copy describes mechanics
      // (radius, thresholds, counts), not emotions. Pricing appears
      // on the plan cards, not inside individual bullets.
      'premium_feature_radar_extended':
          'Radar reach 250 m with more sensitive proximity (–85 dBm)',
      'premium_feature_mutual_waves_20': '20 mutual waves per month (vs 5)',
      'premium_feature_open_profile_cards':
          'Open full profile cards from Matches, Recaps and Near-Miss',
      'premium_feature_recap_full':
          'Recaps in color + 10-minute wave from a recap + read-only archive after it expires',
      'premium_feature_near_miss_history':
          'Near-Miss history tab — see who passed just outside your radar',
      'premium_feature_hard_filters':
          'Additional hard filters beyond gender, age and nicotine (coming soon)',
      'premium_feature_event_insights':
          'Event participants count + live heatmap data on event pins',
      'premium_feature_weekend_window': 'Active Fri 7 PM – Sun 7 PM your time',
      'premium_feature_all_premium': 'All Premium features',
      'premium_feature_yearly_access': '12 months of uninterrupted access',
      'premium_feature_cancel_anytime': 'Cancel anytime',
      'premium_feature_lifetime_upgrades': 'All future upgrades',
      'premium_feature_priority_support': 'Priority support',
      // Free-tier bullets (ADR-007). List what actually stays free so
      // the paywall does not oversell the downgrade.
      'premium_free_proximity': 'Proximity detection and notifications',
      'premium_free_pulse_intercept':
          'Pulse Intercept — send phone or photo during the 30-min window',
      'premium_free_active_radar':
          '30-minute active radar inside every Trembling Window',
      'premium_free_mutual_waves_5': '5 mutual waves per month',
      'premium_free_event_pins':
          'Event pins on the map + empty heatmap circles',
      'premium_free_nicotine_filter': 'Nicotine exclusion filter',
    },
    'sl': {
      'premium_title': 'Tremble Nadgradnja',
      'premium_subtitle': 'Dvigni raven spoznavanja. Odkrij fizično.',
      'premium_cta_get_premium': 'Aktiviraj Tremble Premium',
      'premium_cta_get_weekend': 'Aktiviraj ta vikend',
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
      'premium_card_weekend_window':
          'Aktivira se naslednji petek ob 19:00 – nedelja 19:00 (tvoj lokalni čas). Samodejno se obnovi. Odpoveš kadarkoli.',
      'premium_card_yearly_title': 'Yearly',
      'premium_card_yearly_period': '/ mesec',
      'premium_card_yearly_billed_as': 'obračunano kot 59,99 € / leto',
      'premium_yearly_savings_badge': 'PRIHRANI 37%',
      'premium_card_lifetime_title': 'Lifetime',
      'premium_card_lifetime_period': 'enkratno',
      'premium_card_lifetime_window': 'nikoli več ne plačaš',
      'premium_card_free_title': 'Brezplačni paket',
      'premium_feature_radar_extended':
          'Radar doseg 250 m z občutljivejšo proximity (–85 dBm)',
      'premium_feature_mutual_waves_20': '20 mutual valov na mesec (namesto 5)',
      'premium_feature_open_profile_cards':
          'Odpiranje celotnih profil kartic v Matches, Recaps in Near-Miss',
      'premium_feature_recap_full':
          'Recap-i v barvah + 10-minutni val iz recapa + read-only arhiv po izteku',
      'premium_feature_near_miss_history':
          'Near-Miss zgodovina — poglej kdo je bil skoraj v tvojem radarju',
      'premium_feature_hard_filters':
          'Dodatni hard filtri poleg spola, starosti in nikotina (kmalu)',
      'premium_feature_event_insights':
          'Število udeležencev + živi heatmap podatki na event pinih',
      'premium_feature_weekend_window':
          'Aktivno pet 19:00 – ned 19:00 tvoj čas',
      'premium_feature_all_premium': 'Vse Premium funkcije',
      'premium_feature_yearly_access': '12 mesecev neprekinjenega dostopa',
      'premium_feature_cancel_anytime': 'Odpoveš kadarkoli',
      'premium_feature_lifetime_upgrades': 'Vse prihodnje nadgradnje',
      'premium_feature_priority_support': 'Prioritetna podpora',
      'premium_free_proximity': 'Proximity detekcija in notifikacije',
      'premium_free_pulse_intercept':
          'Pulse Intercept — pošlji telefon ali foto v 30-min oknu',
      'premium_free_active_radar':
          '30-minutni aktivni radar v vsakem Trembling Window-u',
      'premium_free_mutual_waves_5': '5 mutual valov na mesec',
      'premium_free_event_pins': 'Event pini na mapi + prazni heatmap krogi',
      'premium_free_nicotine_filter': 'Nicotine exclusion filter',
    },
    'de': {
      'premium_card_weekend_window':
          'Aktiviert sich am nächsten Freitag um 19:00 Uhr – Sonntag um 19:00 Uhr (deine Ortszeit). Verlängert sich automatisch wöchentlich. Jederzeit kündbar.',
      'premium_feature_weekend_window':
          'Aktiv Fr 19:00 – So 19:00 Uhr deiner Zeit',
      'premium_feature_hard_filters':
          'Weitere Hard-Filter neben Geschlecht, Alter und Nikotin (bald verfügbar)',
      'premium_cta_get_weekend': 'Hol dir dieses Wochenende',
    },
    'hr': {
      'premium_card_weekend_window':
          'Aktivira se sljedeći petak u 19:00 – nedjelja u 19:00 (tvoje lokalno vrijeme). Automatski se obnavlja tjedno. Otkaži bilo kada.',
      'premium_feature_weekend_window':
          'Aktivno pet 19:00 – ned 19:00 tvoje vrijeme',
      'premium_feature_hard_filters':
          'Dodatni hard filtri osim spola, dobi i nikotina (uskoro)',
      'premium_cta_get_weekend': 'Aktiviraj ovaj vikend',
    },
    'it': {
      'premium_card_weekend_window':
          'Si attiva il prossimo venerdì alle 19:00 – domenica alle 19:00 (ora locale). Si rinnova automaticamente ogni settimana. Disdici in qualsiasi momento.',
      'premium_feature_weekend_window':
          'Attivo ven 19:00 – dom 19:00 ora locale',
      'premium_feature_hard_filters':
          'Filtri hard aggiuntivi oltre a genere, età e nicotina (in arrivo)',
      'premium_cta_get_weekend': 'Attiva questo fine settimana',
    },
    'es': {
      'premium_card_weekend_window':
          'Se activa el próximo viernes a las 19:00 – domingo a las 19:00 (tu hora local). Se renueva automáticamente cada semana. Cancela en cualquier momento.',
      'premium_feature_weekend_window': 'Activo vie 19:00 – dom 19:00 tu hora',
      'premium_feature_hard_filters':
          'Filtros adicionales además de género, edad y nicotina (próximamente)',
      'premium_cta_get_weekend': 'Obtén este fin de semana',
    },
    'fr': {
      'premium_card_weekend_window':
          'S’active le vendredi suivant à 19h00 – dimanche à 19h00 (votre heure locale). Renouvellement hebdomadaire automatique. Annulez à tout moment.',
      'premium_feature_weekend_window':
          'Actif ven 19h00 – dim 19h00 votre heure',
      'premium_feature_hard_filters':
          'Filtres avancés supplémentaires au-delà du genre, âge et nicotine (bientôt disponible)',
      'premium_cta_get_weekend': 'Profiter de ce week-end',
    },
    'pt': {
      'premium_card_weekend_window':
          'Ativa na próxima sexta-feira às 19:00 – domingo às 19:00 (seu horário local). Renova automaticamente toda semana. Cancele a qualquer momento.',
      'premium_feature_weekend_window':
          'Ativo sex 19:00 – dom 19:00 seu horário',
      'premium_feature_hard_filters':
          'Filtros adicionais além de género, idade e nicotina (em breve)',
      'premium_cta_get_weekend': 'Obter este fim de semana',
    }
  };

  String _t(String key, String lang) {
    final code = _localTranslations.containsKey(lang) ? lang : 'en';
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
      if (kDebugMode) debugPrint('[PREMIUM] RevenueCat purchase failed: $e');
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
      if (kDebugMode) debugPrint('[PREMIUM] RevenueCat restore failed: $e');
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
      if (kDebugMode) debugPrint('[PREMIUM] Customer Center failed: $e');
      if (mounted) _showSnack(_t('customer_center_failed', user.appLanguage));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TrembleTheme.rose,
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
          isDark ? TrembleTheme.textColor : const Color(0xFFF2F2F7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: TrembleTheme.rose,
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
                  backgroundColor: TrembleTheme.rose,
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
    final bgColor = isDark ? TrembleTheme.textColor : const Color(0xFFF2F2F7);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final glowOpacity = isDark ? 0.08 : 0.05;
    final glowOpacity2 = isDark ? 0.05 : 0.03;

    final bgColors = TrembleTheme.getGradient(
      isDarkMode: isDark,
      isPrideMode: user.isPrideMode,
      gender: user.gender,
      isGenderBasedColor: user.isGenderBasedColor,
    );

    final genderAccent = _resolveGenderAccent(
      gender: user.gender,
      isGenderBased: user.isGenderBasedColor,
      fallback: TrembleTheme.rose,
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
        systemNavigationBarColor: bgColors.isNotEmpty ? bgColors.last : bgColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
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
                          () =>
                              _selectedIndex = index % premiumPlanCards.length,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CTA
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, bottom: 24),
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
                            onPressed: _isLoading
                                ? null
                                : () => _restorePurchases(user),
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
      ),
    );
  }

  Widget _buildCreditCard(PremiumPlanCard data, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: TrembleTheme.textColor,
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
    final isPremium = ref.watch(effectiveIsPremiumProvider);

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
      1 => TrembleTheme.accentYellow,
      2 => const Color(0xFF00C8FF),
      3 => const Color(0xFFFFB347),
      _ => data.accent,
    };

    final textColor =
        (index == 1 || index == 3) ? TrembleTheme.textColor : Colors.white;

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
    final absOffset = offset.abs();

    // Symmetric, directional layout: future cards (offset > 0) sit to the
    // RIGHT of center, past cards (offset < 0) sit to the LEFT. A left swipe
    // therefore visibly pulls the next card in from the right, and a right
    // swipe pulls the previous card in from the left. Scale, rotation, and
    // opacity fall off identically on both sides so neither direction looks
    // privileged.
    final translationX = offset * (screenWidth * 0.32);
    final scale = (1.0 - (absOffset * 0.10)).clamp(0.0, 1.0);
    final rotY = -offset * 0.20;
    final opacity = (1.0 - (absOffset * 0.35)).clamp(0.0, 1.0);

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
