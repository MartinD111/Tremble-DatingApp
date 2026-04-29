import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
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
import '../../../core/theme_provider.dart';
import 'settings_controller.dart';
import 'widgets/preference_pill_row.dart';
import 'widgets/preference_range_slider.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../../core/theme.dart';
import '../../dashboard/application/radar_schedule_controller.dart';
import '../../dashboard/presentation/widgets/radar_schedule_modal.dart';

final hideNavBarPrefProvider = StateProvider<bool>((ref) => false);

/// Admin-only local toggle for bypassing radar proximity requirements (testing).
/// Not persisted to Firestore — resets on app restart.
final bypassRadarProvider = StateProvider<bool>((ref) => false);

/// Debug-only local admin override. Simulates admin role without a Firestore write.
/// Never persisted — resets on app restart. Only active in kDebugMode.
final localAdminModeProvider = StateProvider<bool>((ref) => false);

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
  String? _expandedSection;

  /// Keys for each expandable section to enable auto-scrolling when opened.
  final Map<String, GlobalKey> _sectionKeys = {
    'preferences': GlobalKey(),
    'lifestyle': GlobalKey(),
    'appearance': GlobalKey(),
    'account': GlobalKey(),
  };

  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollUpdate);
  }

  void _onToggleSection(String sectionKey) {
    setState(() {
      if (_expandedSection == sectionKey) {
        _expandedSection = null;
      } else {
        _expandedSection = sectionKey;

        // Auto-scroll to the section after it starts expanding.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // A short delay ensures AnimatedSize has begun its expansion,
          // resulting in a more accurate final scroll position.
          Future.delayed(const Duration(milliseconds: 250), () {
            if (!mounted) return;
            final key = _sectionKeys[sectionKey];
            if (key?.currentContext != null) {
              Scrollable.ensureVisible(
                key!.currentContext!,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                alignment: 0.0,
              );
            }
          });
        });
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    _photoPageController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  void _onScrollUpdate() {
    final offset = _scrollController.offset;
    final newOpacity = (1.0 - (offset / 60)).clamp(0.0, 1.0);
    if (_titleOpacity.value != newOpacity) {
      _titleOpacity.value = newOpacity;
    }
  }

  String _t(String key) {
    final user = ref.read(authStateProvider);
    return t(key, user?.appLanguage ?? 'en');
  }

  /// Maps political scale value 1–5 to a readable label.
  String _politicalLabel(double v) {
    switch (v.round()) {
      case 1:
        return _t('politics_left');
      case 2:
        return _t('politics_center_left');
      case 3:
        return _t('politics_center');
      case 4:
        return _t('politics_center_right');
      case 5:
        return _t('politics_right');
      default:
        return v.round().toString();
    }
  }

  /// Formats the political range display label.
  String _politicalRangeLabel(int? min, int? max) {
    if (min == null || max == null)
      return _t('politics_left') + ' – ' + _t('politics_right');
    if (min == max) return _politicalLabel(min.toDouble());
    return '${_politicalLabel(min.toDouble())} – ${_politicalLabel(max.toDouble())}';
  }

  /// Formats the introvert/extrovert range display label.
  String _introvertRangeLabel(int? min, int? max) {
    final lo = min ?? 0;
    final hi = max ?? 100;
    return '$lo% – $hi%';
  }

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

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileSection(user),
                const SizedBox(height: 20),
                _buildExpandableSection(
                  title: _t('preferences'),
                  sectionKey: 'preferences',
                  icon: LucideIcons.sliders,
                  content: _buildPreferencesContent(user),
                ),
                const SizedBox(height: 20),
                _buildExpandableSection(
                  title: _t('lifestyle'),
                  sectionKey: 'lifestyle',
                  icon: LucideIcons.heart,
                  content: _buildLifestyleContent(user),
                ),
                const SizedBox(height: 20),
                _buildExpandableSection(
                  title: _t('app_appearance'),
                  sectionKey: 'appearance',
                  icon: LucideIcons.palette,
                  content: _buildAppSettingsContent(user),
                ),
                const SizedBox(height: 20),
                _buildExpandableSection(
                  title: _t('account_settings'),
                  sectionKey: 'account',
                  icon: LucideIcons.user,
                  content: _buildAccountContent(user),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _titleOpacity,
            builder: (context, opacity, child) {
              return TrembleHeader(
                title: _t('settings'),
                titleOpacity: opacity,
                showBackButton: false,
              );
            },
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
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
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
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
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
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subTextColor = isDark ? Colors.white70 : Colors.black54;
            final checkBorderColor = confirmed
                ? Colors.redAccent
                : (isDark ? Colors.white38 : Colors.black26);
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                const Icon(LucideIcons.alertTriangle,
                    color: Colors.redAccent, size: 22),
                const SizedBox(width: 10),
                Text('Delete Account',
                    style: GoogleFonts.instrumentSans(
                        color: textColor, fontWeight: FontWeight.bold)),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action is permanent and cannot be undone.\n\n'
                    'All your data will be permanently deleted:\n'
                    '• Your profile and photos\n'
                    '• Your matches and conversations\n'
                    '• Your location history\n'
                    '• Your account credentials',
                    style: TextStyle(color: subTextColor, height: 1.5),
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
                          border: Border.all(color: checkBorderColor, width: 2),
                        ),
                        child: confirmed
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I understand that this action is permanent.',
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      )
                    ]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = isDark ? Colors.white70 : Colors.black54;
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
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFF1A1A18).withValues(alpha: 0.06),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFF1A1A18).withValues(alpha: 0.25),
                        ),
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
                              (isDark ? Colors.black : Colors.white)
                                  .withValues(alpha: 0.15),
                              (isDark ? Colors.black : Colors.white)
                                  .withValues(alpha: 0.75),
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
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.1,
                          ),
                        ),
                        if (user.location != null &&
                            user.location!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.mapPin,
                                  size: 14, color: subColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(user.location!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: subColor, fontSize: 14)),
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
                                : subColor,
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
          // Profile preview button — theme-aware colors
          Builder(builder: (context) {
            final isDarkBtn = Theme.of(context).brightness == Brightness.dark;
            final btnColor = isDarkBtn ? Colors.white : Colors.black87;
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/profile-preview'),
                icon: Icon(LucideIcons.eye, size: 18, color: btnColor),
                label: Text(_t('profile_card_view'),
                    style: GoogleFonts.instrumentSans(
                        color: btnColor, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: btnColor.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String sectionKey,
    required Widget content,
    required IconData icon,
  }) {
    final isExpanded = _expandedSection == sectionKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A18);

    return GlassCard(
      key: _sectionKeys[sectionKey],
      padding: EdgeInsets.zero, // Padding handled by internal slots
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _onToggleSection(sectionKey),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: textColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.25 : 0,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: textColor.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      children: [
                        Divider(
                          height: 1,
                          color: textColor.withValues(alpha: 0.1),
                          indent: 20,
                          endIndent: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 20, top: 20),
                          child: content,
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsContent(AuthUser user) {
    final lang = user.appLanguage;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_t('dark_mode'), style: TextStyle(color: textColor)),
          // Bind to themeModeProvider (SharedPrefs-backed) — not user.isDarkMode
          // (Firestore-backed) — so the toggle always reflects the actual live
          // theme state and the two sources can never visually diverge.
          value: ref.watch(themeModeProvider) == ThemeMode.dark,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: isDark ? Colors.white24 : Colors.black12,
          inactiveTrackColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          onChanged: (val) => _ctrl.toggleDarkMode(val),
        ),
        if (user.interestedIn.length > 1)
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
          activeThumbColor: Theme.of(context).colorScheme.primary,
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
          activeThumbColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: isDark ? Colors.white24 : Colors.black12,
          inactiveTrackColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          onChanged: (val) => _ctrl.togglePingAnimation(val),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_t('proximity_vibration'),
              style: TextStyle(color: textColor)),
          subtitle: Text(_t('proximity_vibration_sub'),
              style: TextStyle(color: subColor, fontSize: 12)),
          value: user.isPingVibrationEnabled,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: isDark ? Colors.white24 : Colors.black12,
          inactiveTrackColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          onChanged: (val) => _ctrl.togglePingVibration(val),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Gym Mode obvestila', style: TextStyle(color: textColor)),
          subtitle: Text('Obvesti me ob prihodu v fitnes',
              style: TextStyle(color: subColor, fontSize: 12)),
          value: user.gymNotificationsEnabled ?? false,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: isDark ? Colors.white24 : Colors.black12,
          inactiveTrackColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          onChanged: (val) => _ctrl.toggleGymNotifications(val),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title:
              Text('Hide Navigation bar', style: TextStyle(color: textColor)),
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
        Divider(
            color:
                isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
        const SizedBox(height: 8),
        PreferencePillRow(
          icon: LucideIcons.languages,
          label: _t('app_language'),
          values: [lang],
          formatter: (code) =>
              availableLanguages
                  .where((l) => l['code'] == code)
                  .map((l) => l['label']!)
                  .firstOrNull ??
              code,
          onEdit: () => _ctrl.openLanguageModal(context),
        ),
      ],
    );
  }

  Widget _buildPreferencesContent(AuthUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Sliders group (first per spec) ──

        PreferenceRangeSlider(
          icon: LucideIcons.calendar,
          label: _t('age_range'),
          valueLabel: '${user.ageRangeStart} – ${user.ageRangeEnd}',
          min: 18,
          max: 100,
          divisions: 82,
          start: user.ageRangeStart.toDouble(),
          end: user.ageRangeEnd.toDouble(),
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
          icon: LucideIcons.ruler,
          label: _t('height_label'),
          valueLabel:
              '${user.heightRangeStart ?? 130} – ${user.heightRangeEnd ?? 250} cm',
          min: 130,
          max: 250,
          divisions: 120,
          start: (user.heightRangeStart ?? 130).toDouble(),
          end: (user.heightRangeEnd ?? 250).toDouble(),
          isPremium: !user.isPremium,
          onEdit: () => _ctrl.openSliderEditModal(
            context: context,
            title: _t('height_label'),
            min: 130,
            max: 250,
            divisions: 120,
            current: RangeValues(
              (user.heightRangeStart ?? 130).toDouble(),
              (user.heightRangeEnd ?? 250).toDouble(),
            ),
            unit: ' cm',
            isPremium: !user.isPremium,
            onUpdate: _ctrl.updateHeightRange,
          ),
        ),
        const SizedBox(height: 16),

        PreferenceRangeSlider(
          icon: LucideIcons.landmark,
          label: _t('political_affiliation'),
          valueLabel: _politicalRangeLabel(
              user.partnerPoliticalMin, user.partnerPoliticalMax),
          min: 1,
          max: 5,
          divisions: 4,
          start: (user.partnerPoliticalMin ?? 1).toDouble(),
          end: (user.partnerPoliticalMax ?? 5).toDouble(),
          startLabel: _t('politics_left'),
          endLabel: _t('politics_right'),
          labelMapper: _politicalLabel,
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
            labelMapper: _politicalLabel,
            onUpdate: _ctrl.updatePartnerPoliticalRange,
          ),
        ),
        const SizedBox(height: 16),

        PreferenceRangeSlider(
          icon: LucideIcons.smile,
          label: _t('introvert_extrovert'),
          valueLabel: _introvertRangeLabel(
              user.partnerIntrovertMin, user.partnerIntrovertMax),
          min: 0,
          max: 100,
          divisions: 10,
          start: (user.partnerIntrovertMin ?? 0).toDouble(),
          end: (user.partnerIntrovertMax ?? 100).toDouble(),
          startLabel: _t('full_introvert'),
          endLabel: _t('full_extrovert'),
          labelMapper: (v) => '${v.round()}%',
          onEdit: () => _ctrl.openSliderEditModal(
            context: context,
            title: _t('introvert_extrovert'),
            min: 0,
            max: 100,
            divisions: 10,
            current: RangeValues(
              (user.partnerIntrovertMin ?? 0).toDouble(),
              (user.partnerIntrovertMax ?? 100).toDouble(),
            ),
            startLabel: _t('full_introvert'),
            endLabel: _t('full_extrovert'),
            labelMapper: (v) => '${v.round()}%',
            onUpdate: _ctrl.updatePartnerIntrovertRange,
          ),
        ),

        Divider(
            color:
                isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
        const SizedBox(height: 8),

        // ── Interested In (multi-select) ──
        PreferencePillRow(
          icon: LucideIcons.users,
          label: _t('gender'),
          values: user.interestedIn.isNotEmpty
              ? user.interestedIn.map((v) => v as String?).toList()
              : <String?>[null],
          formatter: _t,
          iconMapper: (v) {
            if (v == 'male') return Icons.male;
            if (v == 'female') return Icons.female;
            if (v == 'non_binary') return LucideIcons.userX;
            return null;
          },
          onTap: () => _openInterestedInModal(user),
          onEdit: () => _openInterestedInModal(user),
        ),

        Divider(
            color:
                isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
        const SizedBox(height: 8),

        // ── Premium partner preferences (unified pill rows) ──

        _prefPillRow(
          context: context,
          label: _t('religion'),
          icon: LucideIcons.heart,
          currentValue: user.religionPreference,
          isPremium: !user.isPremium,
          options: [
            {
              'label': _t('christianity'),
              'value': 'christianity',
              'icon': IconUtils.getReligionIcon('christianity')
            },
            {
              'label': _t('islam'),
              'value': 'islam',
              'icon': IconUtils.getReligionIcon('islam')
            },
            {
              'label': _t('hinduism'),
              'value': 'hinduism',
              'icon': IconUtils.getReligionIcon('hinduism')
            },
            {
              'label': _t('buddhism'),
              'value': 'buddhism',
              'icon': IconUtils.getReligionIcon('buddhism')
            },
            {
              'label': _t('judaism'),
              'value': 'judaism',
              'icon': IconUtils.getReligionIcon('judaism')
            },
            {
              'label': _t('agnostic'),
              'value': 'agnostic',
              'icon': IconUtils.getReligionIcon('agnostic')
            },
            {
              'label': _t('atheist'),
              'value': 'atheist',
              'icon': IconUtils.getReligionIcon('atheist')
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(religionPreference: val)),
          iconMapper: (v) => IconUtils.getReligionIcon(v),
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
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(ethnicityPreference: val)),
        ),
        const SizedBox(height: 16),

        _prefPillRow(
          context: context,
          label: _t('hair_color'),
          icon: LucideIcons.scissors,
          currentValue: user.hairColorPreference,
          isPremium: !user.isPremium,
          options: [
            {
              'label': _t('hair_blonde'),
              'value': 'blonde',
              'icon': Icons.circle,
              'iconColor': IconUtils.getHairColor('blonde')
            },
            {
              'label': _t('hair_brunette'),
              'value': 'brunette',
              'icon': Icons.circle,
              'iconColor': IconUtils.getHairColor('brunette')
            },
            {
              'label': _t('hair_black'),
              'value': 'black',
              'icon': Icons.circle,
              'iconColor': IconUtils.getHairColor('black')
            },
            {
              'label': _t('hair_red'),
              'value': 'red',
              'icon': Icons.circle,
              'iconColor': IconUtils.getHairColor('red')
            },
            {
              'label': _t('hair_gray_white'),
              'value': 'gray_white',
              'icon': Icons.circle,
              'iconColor': IconUtils.getHairColor('gray_white')
            },
            {
              'label': _t('hair_other'),
              'value': 'other',
              'icon': Icons.circle,
              'iconColor': IconUtils.getHairColor('other')
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(hairColorPreference: val)),
          iconMapper: (v) => Icons.circle,
        ),

        // ── Looking For (multi-select) ──
        // Options use the same keys as the registration DatingPreferencesStep
        // so values round-trip correctly. Legacy stored values ('Short-term fun',
        // Slovenian text, etc.) fall through _t() unchanged and display as-is.
        const SizedBox(height: 16),
        PreferencePillRow(
          icon: LucideIcons.search,
          label: _t('looking_for'),
          values: user.lookingFor.isNotEmpty
              ? user.lookingFor.map((v) => v as String?).toList()
              : <String?>[null],
          formatter: _t, // _t(v) translates known keys; unknown values return v
          iconMapper: (v) => IconUtils.getLookingForIcon(v),
          onTap: () => _openLookingForModal(user),
          onEdit: () => _openLookingForModal(user),
        ),
      ],
    );
  }

  /// Builds a `PreferencePillRow` that opens the unified edit modal via controller.
  Widget _prefPillRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String? currentValue,
    required List<Map<String, dynamic>> options,
    required void Function(String?) onUpdate,
    bool isPremium = false,
    IconData? Function(String)? iconMapper,
  }) {
    // Formatter: handles comma-joined multi-values ("Po meri") and single values.
    final formatter = (String v) {
      if (v.contains(',')) {
        final count = v.split(',').length;
        return 'Izbrano: $count';
      }
      final raw = options
              .where((o) => o['value'] == v)
              .map((o) => o['label']!)
              .firstOrNull ??
          v;
      return raw as String;
    };
    return PreferencePillRow(
      icon: icon,
      label: label,
      values: [currentValue],
      formatter: formatter,
      iconMapper: iconMapper,
      isPremium: isPremium,
      onEdit: () => _ctrl.openPillEditModal(
        context: context,
        title: label,
        options: options,
        currentValue: currentValue,
        onUpdate: onUpdate,
        isPremium: isPremium,
        rowIcon: icon,
        allOptions: options,
        onCustom: (val) => onUpdate(val),
      ),
    );
  }

  /// Opens the Looking For multi-select modal.
  /// Options match the registration DatingPreferencesStep keys exactly.
  /// Legacy stored values (old English / Slovenian text) remain selectable
  /// because the multi-select checks by value equality — they simply won't
  /// match any option pill and will still display via the backward-compat
  /// formatter on the pill row.
  void _openLookingForModal(AuthUser user) {
    _ctrl.openMultiSelectModal(
      context: context,
      title: _t('looking_for'),
      options: [
        {
          'label': _t('short_term_fun'),
          'value': 'short_term_fun',
          'icon': IconUtils.getLookingForIcon('short_term_fun'),
        },
        {
          'label': _t('long_term_partner'),
          'value': 'long_term_partner',
          'icon': IconUtils.getLookingForIcon('long_term_partner'),
        },
        {
          'label': _t('short_open_long'),
          'value': 'short_open_long',
          'icon': IconUtils.getLookingForIcon('short_open_long'),
        },
        {
          'label': _t('long_open_short'),
          'value': 'long_open_short',
          'icon': IconUtils.getLookingForIcon('long_open_short'),
        },
        {
          'label': _t('undecided'),
          'value': 'undecided',
          'icon': IconUtils.getLookingForIcon('undecided'),
        },
      ],
      currentValues: user.lookingFor,
      onUpdate: (vals) => _ctrl.updateUser((u) => u.copyWith(lookingFor: vals)),
    );
  }

  /// Opens the Interested In multi-select modal.
  /// Uses the same keys as the registration WhatToMeetStep.
  void _openInterestedInModal(AuthUser user) {
    _ctrl.openMultiSelectModal(
      context: context,
      title: _t('gender'),
      options: [
        {
          'label': _t('male'),
          'value': 'male',
          'icon': Icons.male,
        },
        {
          'label': _t('female'),
          'value': 'female',
          'icon': Icons.female,
        },
        {
          'label': _t('non_binary'),
          'value': 'non_binary',
          'icon': LucideIcons.userX,
        },
      ],
      currentValues: user.interestedIn,
      onUpdate: (vals) => _ctrl.updateInterestedIn(vals),
    );
  }

  Widget _buildAccountContent(AuthUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              const Icon(LucideIcons.crown, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Text(_t('premium_account'),
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          value: user.isPremium,
          activeThumbColor: Colors.amber,
          activeTrackColor: Colors.amber.withValues(alpha: 0.5),
          inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
          onChanged: null,
        ),
        Divider(color: dividerColor),
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
        // Admin mode — in debug builds toggleable as local override; in prod read-only.
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_t('admin_mode'), style: TextStyle(color: textColor)),
          subtitle: kDebugMode
              ? Text(
                  'Debug override – bypasses radar proximity & loads demo users',
                  style: TextStyle(
                      color: Colors.orange.withValues(alpha: 0.7),
                      fontSize: 11),
                )
              : null,
          value:
              user.isAdmin || (kDebugMode && ref.watch(localAdminModeProvider)),
          activeThumbColor: kDebugMode ? Colors.orange : Colors.red,
          activeTrackColor: kDebugMode
              ? Colors.orange.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.5),
          inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
          onChanged: kDebugMode
              ? (val) {
                  ref.read(localAdminModeProvider.notifier).state = val;
                  // Bypass Radar is the same thing — keep them in sync
                  ref.read(bypassRadarProvider.notifier).state = val;
                }
              : null,
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
        Divider(color: dividerColor),
        Consumer(builder: (context, ref, _) {
          final isActivated = ref.watch(radarScheduleProvider).isActivated;
          final statusColor = isActivated
              ? TrembleTheme.rose
              : (isDark ? Colors.white54 : Colors.black45);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(LucideIcons.clock,
                color: isDark ? Colors.white70 : Colors.black45),
            title:
                Text(_t('schedule_radar'), style: TextStyle(color: textColor)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isActivated ? _t('activated') : _t('not_activated'),
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: isActivated ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight,
                    color: isDark ? Colors.white30 : Colors.black26),
              ],
            ),
            onTap: () => showRadarScheduleModal(context),
          );
        }),
        const SizedBox(height: 24),
        PrimaryButton(
            text: _t('change_password'),
            isSecondary: true,
            onPressed: _showChangePasswordDialog),
        const SizedBox(height: 12),
        PrimaryButton(
            text: _t('logout'),
            isSecondary: true,
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            }),
        const SizedBox(height: 12),
        // GDPR: Right to Erasure (Article 17)
        PrimaryButton(
            text: '🗑️  Delete Account',
            isSecondary: true,
            onPressed: _showDeleteAccountDialog),
      ],
    );
  }

  Widget _buildLifestyleContent(AuthUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _prefPillRow(
          context: context,
          label: _t('exercise'),
          icon: LucideIcons.zap,
          currentValue: user.exerciseHabit,
          options: [
            {
              'label': _t('exercise_active'),
              'value': 'active',
              'icon': LucideIcons.zap,
            },
            {
              'label': _t('exercise_sometimes'),
              'value': 'sometimes',
              'icon': LucideIcons.activity,
            },
            {
              'label': _t('almost_never'),
              'value': 'almost_never',
              'icon': LucideIcons.moon,
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(exerciseHabit: val)),
        ),
        const SizedBox(height: 16),
        _prefPillRow(
          context: context,
          label: _t('alcohol'),
          icon: LucideIcons.wine,
          currentValue: user.drinkingHabit,
          options: [
            {
              'label': _t('alcohol_never'),
              'value': 'never',
              'icon': LucideIcons.ban,
            },
            {
              'label': _t('alcohol_socially'),
              'value': 'socially',
              'icon': LucideIcons.users,
            },
            {
              'label': _t('alcohol_occasionally'),
              'value': 'frequently',
              'icon': LucideIcons.trendingUp,
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(drinkingHabit: val)),
        ),
        const SizedBox(height: 16),
        _prefPillRow(
          context: context,
          label: _t('nicotine_title'),
          icon: LucideIcons.wind,
          currentValue: user.nicotineFilter,
          options: [
            {
              'label': _t('nicotine_pref_no_preference'),
              'value': 'no_preference',
              'icon': LucideIcons.helpCircle,
            },
            {
              'label': _t('nicotine_pref_none_only'),
              'value': 'none_only',
              'icon': LucideIcons.ban,
            },
            {
              'label': _t('nicotine_pref_any'),
              'value': 'any',
              'icon': LucideIcons.heart,
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(nicotineFilter: val)),
        ),
        const SizedBox(height: 16),
        _prefPillRow(
          context: context,
          label: _t('children'),
          icon: LucideIcons.baby,
          currentValue: user.childrenPreference,
          options: [
            {
              'label': _t('children_want_someday'),
              'value': 'want_someday',
              'icon': LucideIcons.heart,
            },
            {
              'label': _t('children_dont_want'),
              'value': 'dont_want',
              'icon': LucideIcons.ban,
            },
            {
              'label': _t('children_have_and_want_more'),
              'value': 'have_and_want_more',
              'icon': LucideIcons.users,
            },
            {
              'label': _t('children_have_and_dont_want_more'),
              'value': 'have_and_dont_want_more',
              'icon': LucideIcons.userCheck,
            },
            {
              'label': _t('children_not_sure'),
              'value': 'not_sure',
              'icon': LucideIcons.helpCircle,
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(childrenPreference: val)),
        ),
        const SizedBox(height: 16),
        _prefPillRow(
          context: context,
          label: _t('sleep'),
          icon: LucideIcons.moon,
          currentValue: user.sleepSchedule,
          options: [
            {
              'label': _t('night_owl'),
              'value': 'night_owl', // Unified key
              'icon': LucideIcons.moon,
            },
            {
              'label': _t('early_bird'),
              'value': 'early_bird', // Unified key
              'icon': LucideIcons.sun,
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(sleepSchedule: val)),
        ),
        const SizedBox(height: 16),
        _prefPillRow(
          context: context,
          label: _t('pets'),
          icon: LucideIcons.dog,
          currentValue: user.petPreference,
          options: [
            {
              'label': _t('dog_person'),
              'value': 'dog',
              'icon': LucideIcons.dog,
            },
            {
              'label': _t('cat_person'),
              'value': 'cat',
              'icon': LucideIcons.cat,
            },
            {
              'label': _t('nothing'),
              'value': 'nothing',
              'icon': LucideIcons.ban,
            },
          ],
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(petPreference: val)),
        ),
      ],
    );
  }
}
