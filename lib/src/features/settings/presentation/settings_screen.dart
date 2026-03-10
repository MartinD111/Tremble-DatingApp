import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/primary_button.dart';
import '../../../shared/ui/premium_paywall.dart'; // Paywall Modal
import '../../auth/data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../../core/api_client.dart';

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

  void _updateProfile(AuthUser updatedUser) {
    final offset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    ref.read(authStateProvider.notifier).updateProfile(updatedUser);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(authStateProvider);

    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(_t('settings'),
              style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
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
                  _buildLifestyleSection(user),
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
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: Text(_t('change_password'),
                  style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _t('old_password'),
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureOld ? LucideIcons.eyeOff : LucideIcons.eye,
                            color: Colors.white54),
                        onPressed: () =>
                            setState(() => obscureOld = !obscureOld),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _t('new_password'),
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                            color: Colors.white54),
                        onPressed: () =>
                            setState(() => obscureNew = !obscureNew),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: _t('confirm_password'),
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureConfirm
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: Colors.white54),
                        onPressed: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_t('cancel'),
                      style: const TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent),
                  onPressed: () async {
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords don't match")),
                      );
                      return;
                    }
                    if (newPasswordController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Password must be at least 8 chars")),
                      );
                      return;
                    }
                    // Call backend
                    await ref.read(authStateProvider.notifier).changePassword(
                        oldPasswordController.text, newPasswordController.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_t('password_changed'))),
                      );
                    }
                  },
                  child: Text(_t('save'),
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
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
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.75),
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
                          style: GoogleFonts.outfit(
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
                              Text(user.location!,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          user.isPremium ? "Premium Member ✨" : "Free Plan",
                          style: GoogleFonts.outfit(
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
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection(AuthUser user) {
    final lang = user.appLanguage;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('app_appearance'),
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('dark_mode'),
                style: const TextStyle(color: Colors.white)),
            value: user.isDarkMode,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.grey[800],
            inactiveTrackColor: Colors.white24,
            onChanged: (val) {
              _updateProfile(user.copyWith(isDarkMode: val));
            },
          ),
          if (user.interestedIn == 'Oba' || user.interestedIn == 'Both')
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t('pride_mode'),
                  style: const TextStyle(color: Colors.white)),
              value: user.isPrideMode,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.purple.withValues(alpha: 0.5),
              inactiveTrackColor: Colors.white24,
              onChanged: (val) {
                _updateProfile(user.copyWith(isPrideMode: val));
              },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('remove_ping'),
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(_t('remove_ping_sub'),
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            value: !user.showPingAnimation,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.grey[800],
            inactiveTrackColor: Colors.white24,
            onChanged: (val) {
              _updateProfile(user.copyWith(showPingAnimation: !val));
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide Navigation bar',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Auto-hide on scroll',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            value: ref.watch(hideNavBarPrefProvider),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.grey[800],
            inactiveTrackColor: Colors.white24,
            onChanged: (val) {
              ref.read(hideNavBarPrefProvider.notifier).state = val;
            },
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 4),
          Text(_t('app_language'),
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: availableLanguages.map((option) {
              final code = option['code']!;
              final label = option['label']!;
              final isSelected = lang == code;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(user.copyWith(appLanguage: code));
                  }
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.black54,
                labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal),
                shape: StadiumBorder(
                    side: BorderSide(
                        color:
                            isSelected ? Colors.transparent : Colors.white24)),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(AuthUser user) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('preferences'),
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Age Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('age_range'),
                  style: const TextStyle(color: Colors.white)),
              Text("${user.ageRangeStart} - ${user.ageRangeEnd}",
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          RangeSlider(
            values: RangeValues(
                user.ageRangeStart.toDouble(), user.ageRangeEnd.toDouble()),
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: Colors.pinkAccent,
            inactiveColor: Colors.white24,
            labels: RangeLabels(
              user.ageRangeStart.toString(),
              user.ageRangeEnd.toString(),
            ),
            onChanged: (RangeValues values) {
              _updateProfile(user.copyWith(
                ageRangeStart: values.start.round(),
                ageRangeEnd: values.end.round(),
              ));
            },
          ),
          const SizedBox(height: 20),

          // Height Range - PREMIUM
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text("${_t('whats_your_height')} (cm)",
                      style: const TextStyle(color: Colors.white)),
                  if (!user.isPremium) ...[
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.lock, size: 14, color: Colors.amber),
                  ]
                ],
              ),
              Text(
                  "${user.heightRangeStart ?? 130} - ${user.heightRangeEnd ?? 250}",
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          RangeSlider(
            values: RangeValues((user.heightRangeStart ?? 130).toDouble(),
                (user.heightRangeEnd ?? 250).toDouble()),
            min: 130,
            max: 250,
            divisions: 120,
            activeColor: Colors.pinkAccent,
            inactiveColor: Colors.white24,
            labels: RangeLabels(
              (user.heightRangeStart ?? 130).toString(),
              (user.heightRangeEnd ?? 250).toString(),
            ),
            onChanged: (RangeValues values) {
              if (user.isPremium) {
                _updateProfile(user.copyWith(
                  heightRangeStart: values.start.round(),
                  heightRangeEnd: values.end.round(),
                ));
              }
            },
          ),
          const SizedBox(height: 20),

          // Interested In
          Text(_t('who_looking_for'),
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              {'label': _t('male'), 'value': 'Moški', 'icon': Icons.male},
              {'label': _t('female'), 'value': 'Ženska', 'icon': Icons.female},
              {'label': _t('both'), 'value': 'Oba', 'icon': LucideIcons.users},
            ].map((option) {
              final label = option['label'] as String;
              final value = option['value'] as String;
              final icon = option['icon'] as IconData;
              final isSelected = user.interestedIn == value;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 16,
                        color: isSelected ? Colors.black : Colors.white),
                    const SizedBox(width: 5),
                    Text(label),
                  ],
                ),
                selected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(user.copyWith(interestedIn: value));
                  }
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.black54,
                labelStyle:
                    TextStyle(color: isSelected ? Colors.black : Colors.white),
                shape: StadiumBorder(
                    side: BorderSide(
                        color:
                            isSelected ? Colors.transparent : Colors.white24)),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Partner Smoking
          Text(_t('partner_smokes'),
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              {'label': _t('no'), 'value': 'Ne'},
              {'label': _t('dont_care'), 'value': 'Vseeno'},
            ].map((option) {
              final label = option['label']!;
              final value = option['value']!;
              final isSelected =
                  (user.partnerSmokingPreference ?? 'Vseeno') == value;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(
                        user.copyWith(partnerSmokingPreference: value));
                  }
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.black54,
                labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal),
                shape: StadiumBorder(
                    side: BorderSide(
                        color:
                            isSelected ? Colors.transparent : Colors.white24)),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // --- Premium Locked Preferences ---
          _buildPremiumPreferenceRow(
              user: user,
              title: _t('religion'),
              currentValue: user.religionPreference,
              options: [
                {'label': _t('christianity'), 'value': 'christianity'},
                {'label': _t('islam'), 'value': 'islam'},
                {'label': _t('hinduism'), 'value': 'hinduism'},
                {'label': _t('buddhism'), 'value': 'buddhism'},
                {'label': _t('judaism'), 'value': 'judaism'},
                {'label': _t('agnostic'), 'value': 'agnostic'},
                {'label': _t('atheist'), 'value': 'atheist'},
              ],
              onUpdate: (val) =>
                  _updateProfile(user.copyWith(religionPreference: val))),
          const SizedBox(height: 20),

          _buildPremiumPreferenceRow(
              user: user,
              title: _t('ethnicity'),
              currentValue: user.ethnicityPreference,
              options: [
                {'label': _t('ethnicity_white'), 'value': 'white'},
                {'label': _t('ethnicity_black'), 'value': 'black'},
                {'label': _t('ethnicity_mixed'), 'value': 'mixed'},
                {'label': _t('ethnicity_asian'), 'value': 'asian'},
              ],
              onUpdate: (val) =>
                  _updateProfile(user.copyWith(ethnicityPreference: val))),
          const SizedBox(height: 20),

          _buildPremiumPreferenceRow(
              user: user,
              title: _t('hair_color'),
              currentValue: user.hairColorPreference,
              options: [
                {'label': _t('hair_blonde'), 'value': 'blonde'},
                {'label': _t('hair_brunette'), 'value': 'brunette'},
                {'label': _t('hair_black'), 'value': 'black'},
                {'label': _t('hair_red'), 'value': 'red'},
                {'label': _t('hair_gray_white'), 'value': 'gray_white'},
                {'label': _t('hair_other'), 'value': 'other'},
              ],
              onUpdate: (val) =>
                  _updateProfile(user.copyWith(hairColorPreference: val))),
          const SizedBox(height: 20),

          _buildPremiumPreferenceRow(
              user: user,
              title: _t('political_affiliation'),
              currentValue: user.politicalAffiliationPreference,
              options: [
                {'label': _t('politics_left'), 'value': 'politics_left'},
                {
                  'label': _t('politics_center_left'),
                  'value': 'politics_center_left'
                },
                {'label': _t('politics_center'), 'value': 'politics_center'},
                {
                  'label': _t('politics_center_right'),
                  'value': 'politics_center_right'
                },
                {'label': _t('politics_right'), 'value': 'politics_right'},
                {
                  'label': _t('politics_match_any'),
                  'value': 'politics_match_any'
                },
                {
                  'label': _t('politics_dont_care'),
                  'value': 'politics_dont_care'
                },
                {
                  'label': _t('politics_undisclosed'),
                  'value': 'politics_undisclosed'
                },
              ],
              onUpdate: (val) {
                _updateProfile(
                    user.copyWith(politicalAffiliationPreference: val));
                if (val != 'politics_match_any' &&
                    val != 'politics_dont_care' &&
                    val != 'politics_undisclosed') {
                  // Show info dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E2E),
                      title: Text(_t('politics_popup_title'),
                          style: const TextStyle(color: Colors.white)),
                      content: Text(_t('politics_popup_body'),
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK',
                              style: TextStyle(color: Color(0xFF00D9A6))),
                        ),
                      ],
                    ),
                  );
                }
              }),
          const SizedBox(height: 20),

          // Introvert/Extrovert
          Text(_t('personality_type'),
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Builder(builder: (context) {
            final raw = (user.introvertScale ?? 50).clamp(0, 100);
            String label = _getIntrovertLabel(_mapIntrovertScaleToBucket(raw));
            return Column(
              children: [
                Slider(
                  value: raw.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: Colors.pinkAccent,
                  inactiveColor: Colors.white24,
                  label: label,
                  onChanged: (val) {
                    final v = val.round().clamp(0, 100);
                    _updateProfile(user.copyWith(introvertScale: v));
                  },
                ),
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection(AuthUser user) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('lifestyle'),
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Exercise
          _buildLifestyleLabel(_t('exercise'), LucideIcons.dumbbell),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'label': _t('exercise_no'), 'value': 'Ne'},
              {'label': _t('exercise_sometimes'), 'value': 'Včasih'},
              {'label': _t('exercise_regularly'), 'value': 'Redno'},
              {'label': _t('exercise_very_active'), 'value': 'Zelo aktiven'},
            ].map((option) {
              final label = option['label']!;
              final value = option['value']!;
              final isSelected = (user.exerciseHabit ?? 'Včasih') == value;
              return _buildChoiceChip(
                label: label,
                isSelected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(user.copyWith(exerciseHabit: value));
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Alcohol
          _buildLifestyleLabel(_t('alcohol'), LucideIcons.wine),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'label': _t('alcohol_never'), 'value': 'Nikoli'},
              {'label': _t('alcohol_socially'), 'value': 'Družabno'},
              {'label': _t('alcohol_occasionally'), 'value': 'Ob priliki'},
            ].map((option) {
              final label = option['label']!;
              final value = option['value']!;
              final isSelected = (user.drinkingHabit ?? 'Družabno') == value;
              return _buildChoiceChip(
                label: label,
                isSelected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(user.copyWith(drinkingHabit: value));
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Sleep Schedule
          _buildLifestyleLabel(_t('sleep'), LucideIcons.moon),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              {
                'label': _t('night_owl'),
                'value': 'Nočna ptica',
                'icon': LucideIcons.moon
              },
              {
                'label': _t('early_bird'),
                'value': 'Jutranja ptica',
                'icon': LucideIcons.sun
              },
            ].map((option) {
              final label = option['label'] as String;
              final value = option['value'] as String;
              final icon = option['icon'] as IconData;
              final isSelected = (user.sleepSchedule ?? 'Nočna ptica') == value;
              return ChoiceChip(
                avatar: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.black : Colors.white,
                ),
                label: Text(label),
                selected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(user.copyWith(sleepSchedule: value));
                  }
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.black54,
                labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal),
                shape: StadiumBorder(
                    side: BorderSide(
                        color:
                            isSelected ? Colors.transparent : Colors.white24)),
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Pets
          _buildLifestyleLabel(_t('pets'), LucideIcons.dog),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              {'label': _t('dog_person'), 'value': 'Dog person'},
              {'label': _t('cat_person'), 'value': 'Cat person'},
            ].map((option) {
              final label = option['label']!;
              final value = option['value']!;
              final isSelected = (user.petPreference ?? 'Dog person') == value;
              return _buildChoiceChip(
                label: label,
                isSelected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(user.copyWith(petPreference: value));
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Children - NEW
          _buildLifestyleLabel(_t('children'), LucideIcons.baby),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'label': _t('children_yes'), 'value': 'Da'},
              {'label': _t('children_no'), 'value': 'Ne'},
              {'label': _t('children_later'), 'value': 'Da, ampak kasneje'},
            ].map((option) {
              final label = option['label']!;
              final value = option['value']!;
              final isSelected = (user.childrenPreference ?? 'Ne') == value;
              return _buildChoiceChip(
                label: label,
                isSelected: isSelected,
                onSelected: (s) {
                  if (s) {
                    _updateProfile(user.copyWith(childrenPreference: value));
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Helper: lifestyle section label with icon
  Widget _buildLifestyleLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  /// Helper: standard ChoiceChip with proper contrast
  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Colors.white,
      backgroundColor: Colors.black54,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: StadiumBorder(
          side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.white24)),
      showCheckmark: false,
    );
  }

  String _getIntrovertLabel(int value) {
    if (value == 1) return _t('full_introvert');
    if (value == 2) return _t('more_introvert');
    if (value == 3) return _t('somewhere_between');
    if (value == 4) return _t('more_extrovert');
    if (value == 5) return _t('full_extrovert');
    return "";
  }

  int _mapIntrovertScaleToBucket(int raw) {
    // raw is 0–100, map to 1–5 buckets
    if (raw <= 20) return 1;
    if (raw <= 40) return 2;
    if (raw <= 60) return 3;
    if (raw <= 80) return 4;
    return 5;
  }

  Widget _buildPremiumPreferenceRow({
    required AuthUser user,
    required String title,
    required String? currentValue,
    required List<Map<String, String>> options,
    required Function(String) onUpdate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            if (!user.isPremium) ...[
              const SizedBox(width: 8),
              const Icon(LucideIcons.lock, size: 14, color: Colors.amber),
            ]
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final label = option['label']!;
              final value = option['value']!;
              final isSelected = currentValue == value;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    if (!user.isPremium) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_t('premium_account')),
                          backgroundColor: Colors.amber[800],
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    if (!isSelected) {
                      onUpdate(value);
                    }
                  },
                  child: Chip(
                    label: Text(label),
                    backgroundColor: isSelected ? Colors.white : Colors.black54,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                        color:
                            isSelected ? Colors.transparent : Colors.white24),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(AuthUser user) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('account_settings'),
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold)),
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
              style: const TextStyle(color: Colors.white),
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
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('admin_mode'),
                style: const TextStyle(color: Colors.white)),
            value: user.isAdmin,
            activeThumbColor: Colors.red,
            activeTrackColor: Colors.red.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.white24,
            onChanged: null, // Admin status is server-managed only
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
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        value: user.isPremium,
        activeThumbColor: Colors.amber,
        activeTrackColor: Colors.amber.withValues(alpha: 0.5),
        inactiveTrackColor: Colors.white24,
        onChanged: null, // Premium status is server-managed only
      ),
    );
  }
}
