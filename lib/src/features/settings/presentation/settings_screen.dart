import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/primary_button.dart';
import '../../../shared/ui/premium_paywall.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../../core/api_client.dart';
import 'settings_controller.dart';
import 'widgets/preference_pill_row.dart';
import 'widgets/preference_range_slider.dart';

final hideNavBarPrefProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    _photoPageController.dispose();
    super.dispose();
  }

  String _t(String key) {
    final user = ref.read(authStateProvider);
    return t(key, user?.appLanguage ?? 'en');
  }

  /// Maps a 0–100 introvert value to one of 5 text positions.
  String _introvertLabel(double v) {
    if (v <= 12) return 'Introvert';
    if (v <= 37) return 'Center-left';
    if (v <= 62) return 'Ambivert';
    if (v <= 87) return 'Center-right';
    return 'Extrovert';
  }

  /// Converts a string to Title Case (e.g. "dog person" → "Dog Person").
  String _toTitleCase(String s) => s
      .split(' ')
      .map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  SettingsController get _ctrl => ref.read(settingsControllerProvider);

  /// Thin shim so all existing `_updateProfile(user.copyWith(...))` calls
  /// route through the controller without a mass-rewrite.
  void _updateProfile(AuthUser updatedUser) {
    _ctrl.updateUser((_) => updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(authStateProvider);

    if (user == null) {
      return Center(
        child: Text(_t('error_user_not_found'),
            style: GoogleFonts.instrumentSans(color: Colors.white)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Center(
            child: Text(_t('settings'),
                style: GoogleFonts.instrumentSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: titleColor)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  _buildProfileSection(user),
                  const SizedBox(height: 20),
                  _buildPreferencesSection(user),
                  const SizedBox(height: 20),
                  _buildAccountSection(user),
                  const SizedBox(height: 20),
                  _buildPremiumSection(user),
                  const SizedBox(height: 20),
                  _buildAppSettingsSection(user),
                  const SizedBox(height: 30),
                  PrimaryButton(
                      text: _t('change_password'),
                      isSecondary: true,
                      onPressed: _showChangePasswordDialog),
                  const SizedBox(height: 15),
                  PrimaryButton(
                      text: _t('logout'),
                      isSecondary: true,
                      onPressed: () {
                        ref.read(authStateProvider.notifier).logout();
                      }),
                  const SizedBox(height: 15),
                  // GDPR: Right to Erasure (Article 17)
                  PrimaryButton(
                      text: '🗑️  Delete Account',
                      isSecondary: true,
                      onPressed: _showDeleteAccountDialog),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;
            final iconColor = isDark ? Colors.white54 : Colors.black54;

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _t('change_password'),
                        style: GoogleFonts.instrumentSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: oldPasswordController,
                        obscureText: obscureOld,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('old_password'),
                          labelStyle: TextStyle(color: iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                                obscureOld
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                color: iconColor),
                            onPressed: () =>
                                setState(() => obscureOld = !obscureOld),
                          ),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: iconColor)),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: const Color(0xFFF4436C))),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('new_password'),
                          labelStyle: TextStyle(color: iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                                obscureNew
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                color: iconColor),
                            onPressed: () =>
                                setState(() => obscureNew = !obscureNew),
                          ),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: iconColor)),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: const Color(0xFFF4436C))),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _t('confirm_password'),
                          labelStyle: TextStyle(color: iconColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                                obscureConfirm
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                color: iconColor),
                            onPressed: () => setState(
                                () => obscureConfirm = !obscureConfirm),
                          ),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: iconColor)),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: const Color(0xFFF4436C))),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(_t('cancel'),
                                style: TextStyle(color: iconColor)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                )),
                            onPressed: () async {
                              if (newPasswordController.text !=
                                  confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Passwords don't match")),
                                );
                                return;
                              }
                              if (newPasswordController.text.length < 8) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Password must be at least 8 chars")),
                                );
                                return;
                              }
                              // Call backend
                              await ref
                                  .read(authStateProvider.notifier)
                                  .changePassword(oldPasswordController.text,
                                      newPasswordController.text);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(_t('password_changed'))),
                                );
                              }
                            },
                            child: Text(_t('save'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// GDPR Article 17 — Right to Erasure.
  /// Permanently deletes all user data from Firestore and Firebase Auth.
  void _showDeleteAccountDialog() {
    bool confirmed = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                const Icon(LucideIcons.alertTriangle,
                    color: Colors.redAccent, size: 22),
                const SizedBox(width: 10),
                Text('Delete Account',
                    style: GoogleFonts.instrumentSans(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.bold)),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action is permanent and cannot be undone.\n\n'
                    'All your data will be permanently deleted:\n'
                    '• Your profile and photos\n'
                    '• Your matches and conversations\n'
                    '• Your location history\n'
                    '• Your account credentials',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => setDialogState(() => confirmed = !confirmed),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color:
                              confirmed ? Colors.redAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color:
                                  confirmed ? Colors.redAccent : Colors.white38,
                              width: 2),
                        ),
                        child: confirmed
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I understand that this action is permanent.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      )
                    ]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: (!confirmed || isLoading)
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);
                          try {
                            await TrembleApiClient().call('deleteUserAccount');
                            if (context.mounted) {
                              Navigator.pop(context);
                              // Force logout and back to login
                              await ref
                                  .read(authStateProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Deletion failed: ${e.toString()}')),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Delete My Account',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfileSection(AuthUser user) {
    final hasPhotos = user.photoUrls.isNotEmpty;
    final photoCount = user.photoUrls.length;

    return GlassCard(
      child: Column(
        children: [
          // Hero image with PageView gallery
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 360,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhotos)
                    PageView.builder(
                      controller: _photoPageController,
                      itemCount: photoCount,
                      onPageChanged: (i) =>
                          setState(() => _currentPhotoPage = i),
                      itemBuilder: (context, index) {
                        final url = user.photoUrls[index];
                        return url.startsWith('http')
                            ? Image.network(url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[900]))
                            : Image.file(File(url),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[900]));
                      },
                    )
                  else
                    Container(
                      color: Colors.white10,
                      child: const Center(
                        child:
                            Icon(Icons.person, size: 80, color: Colors.white24),
                      ),
                    ),
                  // Gradient overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Name + age overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${user.name ?? 'Guest'}, ${user.age ?? '?'}",
                          style: GoogleFonts.instrumentSans(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        if (user.location != null &&
                            user.location!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(user.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          user.isPremium ? "Premium Member ✨" : "Free Plan",
                          style: GoogleFonts.instrumentSans(
                            color: user.isPremium
                                ? const Color(0xFFFFD700)
                                : Colors.white70,
                            fontWeight: user.isPremium
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (!user.isPremium) ...[
                          const SizedBox(height: 10),
                          PrimaryButton(
                            text: "Nadgradnja",
                            width: 120,
                            height: 36,
                            onPressed: () {
                              PremiumPaywallBottomSheet.show(context);
                            },
                          )
                        ]
                      ],
                    ),
                  ),
                  // Dot indicators
                  if (photoCount > 1)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photoCount, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPhotoPage == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPhotoPage == i
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Profile preview button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/profile-preview'),
              icon: const Icon(LucideIcons.eye, size: 18, color: Colors.white),
              label: Text(_t('profile_card_view'),
                  style: GoogleFonts.instrumentSans(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection(AuthUser user) {
    final lang = user.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(_t('app_appearance'),
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('dark_mode'), style: TextStyle(color: textColor)),
            value: user.isDarkMode,
            activeThumbColor: const Color(0xFFF4436C),
            activeTrackColor: isDark ? Colors.white24 : Colors.black12,
            inactiveTrackColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            onChanged: (val) => _ctrl.toggleDarkMode(val),
          ),
          if (user.interestedIn == 'Oba' || user.interestedIn == 'Both')
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t('pride_mode'), style: TextStyle(color: textColor)),
              value: user.isPrideMode,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.purple.withValues(alpha: 0.5),
              inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
              onChanged: (val) => _ctrl.togglePrideMode(val),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Gender-based color', style: TextStyle(color: textColor)),
            subtitle: Text('Adapt theme tones to match',
                style: TextStyle(color: subColor, fontSize: 12)),
            value: user.isGenderBasedColor,
            activeThumbColor: const Color(0xFFF4436C),
            activeTrackColor: isDark ? Colors.white24 : Colors.black12,
            inactiveTrackColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            onChanged: (val) => _ctrl.toggleGenderBasedColor(val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('remove_ping'), style: TextStyle(color: textColor)),
            subtitle: Text(_t('remove_ping_sub'),
                style: TextStyle(color: subColor, fontSize: 12)),
            value: !user.showPingAnimation,
            activeThumbColor: Colors.white,
            activeTrackColor: isDark ? Colors.grey[800] : Colors.grey[400],
            inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
            onChanged: (val) => _ctrl.togglePingAnimation(val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Hide Navigation bar', style: TextStyle(color: textColor)),
            subtitle: Text('Auto-hide on scroll',
                style: TextStyle(color: subColor, fontSize: 12)),
            value: ref.watch(hideNavBarPrefProvider),
            activeThumbColor: Colors.white,
            activeTrackColor: isDark ? Colors.grey[800] : Colors.grey[400],
            inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
            onChanged: (val) {
              ref.read(hideNavBarPrefProvider.notifier).state = val;
            },
          ),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
          const SizedBox(height: 8),
          PreferencePillRow(
            icon: LucideIcons.languages,
            label: _t('app_language'),
            values: [lang],
            formatter: (code) =>
                availableLanguages
                    .where((l) => l['code'] == code)
                    .map((l) => l['label']!)
                    .firstOrNull ?? code,
            onEdit: () => _ctrl.openLanguageModal(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(AuthUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(_t('preferences'),
                style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // ── Sliders group (first per spec) ──

          PreferenceRangeSlider(
            label: _t('age_range'),
            valueLabel: '${user.ageRangeStart} – ${user.ageRangeEnd}',
            min: 18,
            max: 100,
            divisions: 82,
            start: user.ageRangeStart.toDouble(),
            end: user.ageRangeEnd.toDouble(),
            onChanged: _ctrl.updateAgeRange,
            onEdit: () => _ctrl.openSliderEditModal(
              context: context,
              title: _t('age_range'),
              min: 18,
              max: 100,
              divisions: 82,
              current: RangeValues(
                  user.ageRangeStart.toDouble(), user.ageRangeEnd.toDouble()),
              onUpdate: _ctrl.updateAgeRange,
            ),
          ),
          const SizedBox(height: 16),

          PreferenceRangeSlider(
            label: _t('height'),
            valueLabel:
                '${user.heightRangeStart ?? 130} – ${user.heightRangeEnd ?? 250} cm',
            min: 130,
            max: 250,
            divisions: 120,
            start: (user.heightRangeStart ?? 130).toDouble(),
            end: (user.heightRangeEnd ?? 250).toDouble(),
            isPremium: !user.isPremium,
            onChanged: _ctrl.updateHeightRange,
            onEdit: () => _ctrl.openSliderEditModal(
              context: context,
              title: _t('height'),
              min: 130,
              max: 250,
              divisions: 120,
              current: RangeValues(
                (user.heightRangeStart ?? 130).toDouble(),
                (user.heightRangeEnd ?? 250).toDouble(),
              ),
              isPremium: !user.isPremium,
              onUpdate: _ctrl.updateHeightRange,
            ),
          ),
          const SizedBox(height: 16),

          PreferenceRangeSlider(
            label: _t('political_affiliation'),
            valueLabel: user.partnerPoliticalMin != null
                ? '${user.partnerPoliticalMin} – ${user.partnerPoliticalMax}'
                : _t('no_preference'),
            min: 1,
            max: 5,
            divisions: 4,
            start: (user.partnerPoliticalMin ?? 1).toDouble(),
            end: (user.partnerPoliticalMax ?? 5).toDouble(),
            startLabel: _t('politics_left'),
            endLabel: _t('politics_right'),
            isPremium: !user.isPremium,
            onChanged: user.isPremium ? _ctrl.updatePartnerPoliticalRange : (_) {},
            onEdit: () => _ctrl.openSliderEditModal(
              context: context,
              title: _t('political_affiliation'),
              min: 1,
              max: 5,
              divisions: 4,
              current: RangeValues(
                (user.partnerPoliticalMin ?? 1).toDouble(),
                (user.partnerPoliticalMax ?? 5).toDouble(),
              ),
              startLabel: _t('politics_left'),
              endLabel: _t('politics_right'),
              isPremium: !user.isPremium,
              onUpdate: _ctrl.updatePartnerPoliticalRange,
            ),
          ),
          const SizedBox(height: 16),

          PreferenceRangeSlider(
            label: _t('introvert_extrovert'),
            valueLabel: user.partnerIntrovertMin != null
                ? '${_introvertLabel((user.partnerIntrovertMin!).toDouble())} – '
                  '${_introvertLabel((user.partnerIntrovertMax ?? 100).toDouble())}'
                : _t('no_preference'),
            min: 0,
            max: 100,
            divisions: 4,
            start: (user.partnerIntrovertMin ?? 0).toDouble(),
            end: (user.partnerIntrovertMax ?? 100).toDouble(),
            startLabel: _t('full_introvert'),
            endLabel: _t('full_extrovert'),
            labelMapper: _introvertLabel,
            onChanged: _ctrl.updatePartnerIntrovertRange,
            onEdit: () => _ctrl.openSliderEditModal(
              context: context,
              title: _t('introvert_extrovert'),
              min: 0,
              max: 100,
              divisions: 4,
              current: RangeValues(
                (user.partnerIntrovertMin ?? 0).toDouble(),
                (user.partnerIntrovertMax ?? 100).toDouble(),
              ),
              startLabel: _t('full_introvert'),
              endLabel: _t('full_extrovert'),
              labelMapper: _introvertLabel,
              onUpdate: _ctrl.updatePartnerIntrovertRange,
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 8),

          // ── Interested In ──
          _prefPillRow(
            context: context,
            label: _t('who_looking_for'),
            icon: LucideIcons.users,
            currentValue: user.interestedIn,
            options: [
              {'label': _t('male'), 'value': 'Moški'},
              {'label': _t('female'), 'value': 'Ženska'},
              {'label': _t('both'), 'value': 'Oba'},
            ],
            onUpdate: (val) => _ctrl.updateInterestedIn(val),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 8),

          // ── Lifestyle + enum prefs (pill rows) ──

          _prefPillRow(
            context: context,
            label: _t('exercise'),
            icon: LucideIcons.dumbbell,
            currentValue: user.exerciseHabit,
            options: [
              {'label': _t('exercise_no'), 'value': 'Ne'},
              {'label': _t('exercise_sometimes'), 'value': 'Včasih'},
              {'label': _t('exercise_regularly'), 'value': 'Redno'},
              {'label': _t('exercise_very_active'), 'value': 'Zelo aktiven'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(exerciseHabit: val)),
          ),
          const SizedBox(height: 16),

          _prefPillRow(
            context: context,
            label: _t('alcohol'),
            icon: LucideIcons.wine,
            currentValue: user.drinkingHabit,
            options: [
              {'label': _t('alcohol_never'), 'value': 'Nikoli'},
              {'label': _t('alcohol_socially'), 'value': 'Družabno'},
              {'label': _t('alcohol_occasionally'), 'value': 'Ob priliki'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(drinkingHabit: val)),
          ),
          const SizedBox(height: 16),

          _prefPillRow(
            context: context,
            label: _t('smoking'),
            icon: LucideIcons.cigarette,
            currentValue: user.partnerSmokingPreference,
            options: [
              {'label': _t('no'), 'value': 'Ne'},
              {'label': _t('dont_care'), 'value': 'Vseeno'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(partnerSmokingPreference: val)),
          ),
          const SizedBox(height: 16),

          _prefPillRow(
            context: context,
            label: _t('children'),
            icon: LucideIcons.baby,
            currentValue: user.childrenPreference,
            options: [
              {'label': _t('children_yes'), 'value': 'Da'},
              {'label': _t('children_no'), 'value': 'Ne'},
              {'label': _t('children_later'), 'value': 'Da, ampak kasneje'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(childrenPreference: val)),
          ),
          const SizedBox(height: 16),

          _prefPillRow(
            context: context,
            label: _t('sleep'),
            icon: LucideIcons.moon,
            currentValue: user.sleepSchedule,
            options: [
              {'label': _t('night_owl'), 'value': 'Nočna ptica'},
              {'label': _t('early_bird'), 'value': 'Jutranja ptica'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(sleepSchedule: val)),
          ),
          const SizedBox(height: 16),

          _prefPillRow(
            context: context,
            label: _t('pets'),
            icon: LucideIcons.dog,
            currentValue: user.petPreference,
            options: [
              {'label': _t('dog_person'), 'value': 'Dog person'},
              {'label': _t('cat_person'), 'value': 'Cat person'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(petPreference: val)),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 8),

          // ── Premium partner preferences (unified pill rows) ──

          _prefPillRow(
            context: context,
            label: _t('religion'),
            icon: LucideIcons.heart,
            currentValue: user.religionPreference,
            isPremium: !user.isPremium,
            options: [
              {'label': _t('christianity'), 'value': 'christianity'},
              {'label': _t('islam'), 'value': 'islam'},
              {'label': _t('hinduism'), 'value': 'hinduism'},
              {'label': _t('buddhism'), 'value': 'buddhism'},
              {'label': _t('judaism'), 'value': 'judaism'},
              {'label': _t('agnostic'), 'value': 'agnostic'},
              {'label': _t('atheist'), 'value': 'atheist'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(religionPreference: val)),
          ),
          const SizedBox(height: 16),

          _prefPillRow(
            context: context,
            label: _t('ethnicity'),
            icon: LucideIcons.users,
            currentValue: user.ethnicityPreference,
            isPremium: !user.isPremium,
            options: [
              {'label': _t('ethnicity_white'), 'value': 'white'},
              {'label': _t('ethnicity_black'), 'value': 'black'},
              {'label': _t('ethnicity_mixed'), 'value': 'mixed'},
              {'label': _t('ethnicity_asian'), 'value': 'asian'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(ethnicityPreference: val)),
          ),
          const SizedBox(height: 16),

          _prefPillRow(
            context: context,
            label: _t('hair_color'),
            icon: LucideIcons.scissors,
            currentValue: user.hairColorPreference,
            isPremium: !user.isPremium,
            options: [
              {'label': _t('hair_blonde'), 'value': 'blonde'},
              {'label': _t('hair_brunette'), 'value': 'brunette'},
              {'label': _t('hair_black'), 'value': 'black'},
              {'label': _t('hair_red'), 'value': 'red'},
              {'label': _t('hair_gray_white'), 'value': 'gray_white'},
              {'label': _t('hair_other'), 'value': 'other'},
            ],
            onUpdate: (val) => _ctrl.updateUser((u) => u.copyWith(hairColorPreference: val)),
          ),

          // ── Looking For (multi-select) ──
          const SizedBox(height: 16),
          PreferencePillRow(
            icon: LucideIcons.search,
            label: _t('looking_for'),
            values: user.lookingFor.isNotEmpty
                ? user.lookingFor.map((v) => v as String?).toList()
                : [null],
            formatter: (v) {
              const opts = {
                'Short-term fun': 'Short-Term Fun',
                'Long-term relationship': 'Long-Term Relationship',
                'Friendship': 'Friendship',
                'Meeting': 'Meeting',
              };
              return _toTitleCase(opts[v] ?? v);
            },
            onTap: () => _ctrl.openMultiSelectModal(
              context: context,
              title: _t('looking_for'),
              options: [
                {'label': _t('short_term'), 'value': 'Short-term fun'},
                {'label': _t('long_term'), 'value': 'Long-term relationship'},
                {'label': _t('friendship'), 'value': 'Friendship'},
                {'label': _t('meeting'), 'value': 'Meeting'},
              ],
              currentValues: user.lookingFor,
              onUpdate: (vals) =>
                  _ctrl.updateUser((u) => u.copyWith(lookingFor: vals)),
            ),
            onEdit: () => _ctrl.openMultiSelectModal(
              context: context,
              title: _t('looking_for'),
              options: [
                {'label': _t('short_term'), 'value': 'Short-term fun'},
                {'label': _t('long_term'), 'value': 'Long-term relationship'},
                {'label': _t('friendship'), 'value': 'Friendship'},
                {'label': _t('meeting'), 'value': 'Meeting'},
              ],
              currentValues: user.lookingFor,
              onUpdate: (vals) =>
                  _ctrl.updateUser((u) => u.copyWith(lookingFor: vals)),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a `PreferencePillRow` that opens the unified edit modal via controller.
  Widget _prefPillRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String? currentValue,
    required List<Map<String, String>> options,
    required void Function(String) onUpdate,
    bool isPremium = false,
  }) {
    final formatter = (String v) {
      final raw = options.where((o) => o['value'] == v).map((o) => o['label']!).firstOrNull ?? v;
      return _toTitleCase(raw);
    };
    return PreferencePillRow(
      icon: icon,
      label: label,
      values: [currentValue],
      formatter: formatter,
      isPremium: isPremium,
      onEdit: () => _ctrl.openPillEditModal(
        context: context,
        title: label,
        options: options,
        currentValue: currentValue,
        onUpdate: onUpdate,
        isPremium: isPremium,
      ),
    );
  }

  Widget _buildAccountSection(AuthUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(_t('account_settings'),
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              user.isEmailVerified
                  ? LucideIcons.checkCircle
                  : LucideIcons.alertCircle,
              color: user.isEmailVerified ? Colors.green : Colors.orange,
            ),
            title: Text(
              user.isEmailVerified
                  ? _t('email_verified')
                  : _t('email_not_verified'),
              style: TextStyle(color: textColor),
            ),
            trailing: !user.isEmailVerified
                ? TextButton(
                    onPressed: () {
                      _updateProfile(user.copyWith(isEmailVerified: true));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_t('email_verified'))),
                      );
                    },
                    child: Text(_t('verify')),
                  )
                : null,
          ),
          Divider(color: dividerColor),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('admin_mode'), style: TextStyle(color: textColor)),
            value: user.isAdmin,
            activeThumbColor: Colors.red,
            activeTrackColor: Colors.red.withValues(alpha: 0.5),
            inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
            onChanged: null, // Admin status is server-managed only
          ),
          Divider(color: dividerColor),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(LucideIcons.userX,
                color: isDark ? Colors.white70 : Colors.black45),
            title: Text(_t('blocked_users'), style: TextStyle(color: textColor)),
            trailing: Icon(LucideIcons.chevronRight,
                color: isDark ? Colors.white30 : Colors.black26),
            onTap: () {
              context.push('/blocked-users');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(AuthUser user) {
    return GlassCard(
      borderColor: Colors.amber,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            const Icon(LucideIcons.crown, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            Text(_t('premium_account'),
                style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        value: user.isPremium,
        activeThumbColor: Colors.amber,
        activeTrackColor: Colors.amber.withValues(alpha: 0.5),
        inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : Colors.black12,
        onChanged: null, // Premium status is server-managed only
      ),
    );
  }
}
