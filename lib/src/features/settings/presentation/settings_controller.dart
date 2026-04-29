import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../../core/theme_provider.dart';
import 'widgets/preference_edit_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsController — owns all business logic for the settings screen.
// No widgets, no BuildContext stored as state. Pure controller.
// ─────────────────────────────────────────────────────────────────────────────

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});

class SettingsController {
  final Ref _ref;

  SettingsController(this._ref);

  AuthUser? get _user => _ref.read(authStateProvider);
  String get _lang => _user?.appLanguage ?? 'en';

  // ── Generic preference update ──────────────────────────────────────────────

  void updateUser(AuthUser Function(AuthUser) mutator) {
    final user = _user;
    if (user == null) return;
    _ref.read(authStateProvider.notifier).updateProfile(mutator(user));
  }

  // ── Toggle: dark mode (dual-write: Firestore + SharedPreferences) ──────────

  void toggleDarkMode(bool enabled) {
    updateUser((u) => u.copyWith(isDarkMode: enabled));
    _ref.read(themeModeProvider.notifier).setThemeMode(
          enabled ? ThemeMode.dark : ThemeMode.light,
        );
  }

  // ── Toggle: pride mode ─────────────────────────────────────────────────────

  void togglePrideMode(bool enabled) {
    updateUser((u) => u.copyWith(isPrideMode: enabled));
  }

  // ── Toggle: ping animation (inverted: toggle is "remove ping") ────────────

  void togglePingAnimation(bool removePing) {
    updateUser((u) => u.copyWith(showPingAnimation: !removePing));
  }

  void togglePingVibration(bool enabled) {
    updateUser((u) => u.copyWith(isPingVibrationEnabled: enabled));
  }

  void toggleGymNotifications(bool enabled) {
    updateUser((u) => u.copyWith(gymNotificationsEnabled: enabled));
  }

  // ── Toggle: gender-based color theming ────────────────────────────────────

  void toggleGenderBasedColor(bool enabled) {
    updateUser((u) => u.copyWith(
          isGenderBasedColor: enabled,
          isClassicAppearance: !enabled,
        ));
  }

  // ── Language (dual-write: Firestore + appLanguageProvider) ────────────────

  void setLanguage(String code) {
    updateUser((u) => u.copyWith(appLanguage: code));
    _ref.read(appLanguageProvider.notifier).setLanguage(code);
  }

  // ── Range sliders ──────────────────────────────────────────────────────────

  void updateAgeRange(RangeValues values) {
    updateUser((u) => u.copyWith(
          ageRangeStart: values.start.round(),
          ageRangeEnd: values.end.round(),
        ));
  }

  void updateHeightRange(RangeValues values) {
    final user = _user;
    if (user == null || !user.isPremium) return;
    updateUser((u) => u.copyWith(
          heightRangeStart: values.start.round(),
          heightRangeEnd: values.end.round(),
        ));
  }

  void updateIntrovertScale(double value) {
    updateUser((u) => u.copyWith(introvertScale: value.round().clamp(0, 100)));
  }

  void updatePartnerPoliticalRange(RangeValues values) {
    updateUser((u) => u.copyWith(
          partnerPoliticalMin: values.start.round(),
          partnerPoliticalMax: values.end.round(),
        ));
  }

  void updatePartnerIntrovertRange(RangeValues values) {
    updateUser((u) => u.copyWith(
          partnerIntrovertMin: values.start.round(),
          partnerIntrovertMax: values.end.round(),
        ));
  }

  void updateMaxDistance(double value) {
    updateUser((u) => u.copyWith(maxDistance: value.round()));
  }

  // ── Enum single-select update ──────────────────────────────────────────────

  void updateInterestedIn(List<String> values) {
    updateUser((u) => u.copyWith(interestedIn: values));
  }

  // ── Clear partner political/introvert preferences ─────────────────────────

  void clearPartnerPolitical() {
    updateUser((u) => u.copyWith(
          partnerPoliticalMin: null,
          partnerPoliticalMax: null,
        ));
  }

  void clearPartnerIntrovert() {
    updateUser((u) => u.copyWith(
          partnerIntrovertMin: null,
          partnerIntrovertMax: null,
        ));
  }

  // ── Open pill edit modal ───────────────────────────────────────────────────
  // Opens a bottom-sheet and returns after user confirms with Save/Cancel.
  // onUpdate receives null when the user selects "Vseeno mi je".
  // allOptions/onCustom enable the "Po meri" multi-select sub-modal.

  Future<void> openPillEditModal({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> options,
    required String? currentValue,
    required ValueChanged<String?> onUpdate,
    bool isPremium = false,
    IconData? rowIcon,
    List<Map<String, dynamic>>? allOptions,
    ValueChanged<String>? onCustom,
  }) async {
    final user = _user;
    if (user == null) return;
    if (isPremium && !user.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('premium_account', _lang)),
          backgroundColor: Colors.amber[800],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await showPreferenceEditModal(
      context: context,
      title: title,
      options: options,
      currentValue: currentValue,
      onUpdate: onUpdate,
      rowIcon: rowIcon,
      allOptions: allOptions,
      onCustom: onCustom,
    );
  }

  // ── Open slider edit modal ─────────────────────────────────────────────────

  Future<void> openSliderEditModal({
    required BuildContext context,
    required String title,
    required double min,
    required double max,
    required RangeValues current,
    required ValueChanged<RangeValues> onUpdate,
    int? divisions,
    String? startLabel,
    String? endLabel,
    String Function(double)? labelMapper,
    String? unit,
    bool isPremium = false,
  }) async {
    final user = _user;
    if (user == null) return;
    if (isPremium && !user.isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('premium_account', _lang)),
          backgroundColor: Colors.amber[800],
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await showSliderEditModal(
      context: context,
      title: title,
      min: min,
      max: max,
      current: current,
      divisions: divisions,
      startLabel: startLabel,
      endLabel: endLabel,
      labelMapper: labelMapper,
      unit: unit,
      onSave: onUpdate,
    );
  }

  // ── Open multi-select modal ────────────────────────────────────────────────

  Future<void> openMultiSelectModal({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> options,
    required List<String> currentValues,
    required ValueChanged<List<String>> onUpdate,
  }) async {
    // Directly open the multi-select editing modal as requested by the user.
    await showMultiSelectModal(
      context: context,
      title: title,
      options: options,
      currentValues: currentValues,
      onSave: onUpdate,
    );
  }

  // ── Open language modal ────────────────────────────────────────────────────

  Future<void> openLanguageModal(BuildContext context) async {
    final options = availableLanguages
        .map((l) => {'label': l['label']!, 'value': l['code']!})
        .toList();
    // Use showLanguageEditModal so the user must explicitly tap Save before
    // the language is applied — immediate-save gave no confirmation step.
    await showLanguageEditModal(
      context: context,
      title: t('app_language', _lang),
      options: options,
      currentValue: _lang,
      onSave: setLanguage,
    );
  }
}
