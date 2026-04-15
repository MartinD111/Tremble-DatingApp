import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../../shared/ui/tremble_circle_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../../core/translations.dart';
import '../../../core/utils/icon_utils.dart';

class ProfileCardPreview extends ConsumerStatefulWidget {
  const ProfileCardPreview({super.key});

  @override
  ConsumerState<ProfileCardPreview> createState() => _ProfileCardPreviewState();
}

class _ProfileCardPreviewState extends ConsumerState<ProfileCardPreview> {
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;
  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);

  @override
  void dispose() {
    _photoPageController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    final offset = notification.metrics.pixels;
    final newOpacity = (1.0 - (offset / 60)).clamp(0.0, 1.0);
    if (_titleOpacity.value != newOpacity) {
      _titleOpacity.value = newOpacity;
    }
    return false;
  }

  SettingsController get _ctrl => ref.read(settingsControllerProvider);

  /// Converts raw stored values to proper display format.
  /// "want_someday" → "Want someday", "active" → "Active"
  String _formatValue(String raw, String lang) {
    // Try translation first
    final translated = t(raw, lang);
    // If translation returned a different value, use it (title-cased)
    if (translated != raw) return _titleCase(translated);
    // Otherwise clean up the raw value: underscores → spaces, title case
    return _titleCase(raw.replaceAll('_', ' '));
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white54 : Colors.black45;

    if (user == null) {
      return const GradientScaffold(child: Center(child: Text('No user')));
    }

    final hasPhotos = user.photoUrls.isNotEmpty;
    final photoCount = user.photoUrls.length;
    final lang = user.appLanguage;

    return GradientScaffold(
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        24, MediaQuery.of(context).padding.top + 12, 24, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header title scrolling away naturally
                        const SizedBox(height: 20),
                        const SizedBox(height: 20),

                        // ── Photo gallery ──────────────────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
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
                                                  Container(
                                                      color: Colors.grey[900]))
                                          : Image.file(File(url),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                      color: Colors.grey[900]));
                                    },
                                  )
                                else
                                  Container(
                                    color: Colors.white10,
                                    child: const Center(
                                      child: Icon(Icons.person,
                                          size: 80, color: Colors.white24),
                                    ),
                                  ),
                                // Dot indicators
                                if (photoCount > 1)
                                  Positioned(
                                    top: 12,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(photoCount, (i) {
                                        return AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          width:
                                              _currentPhotoPage == i ? 20 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: _currentPhotoPage == i
                                                ? Colors.white
                                                : Colors.white
                                                    .withValues(alpha: 0.4),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Name + Age ─────────────────────────────────────────────
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.instrumentSans(
                                color: textColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                    text:
                                        '${user.name ?? 'Guest'}, ${user.age ?? '?'}'),
                                if (ZodiacUtils.getZodiacEmoji(
                                        user.birthDate) !=
                                    null)
                                  TextSpan(
                                    text:
                                        '  ${ZodiacUtils.getZodiacEmoji(user.birthDate)}',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Job / Occupation
                        Builder(
                          builder: (context) {
                            String displayOccupation = '';
                            if (user.jobStatus != null) {
                              final statusLabel = t(user.jobStatus!, lang);
                              if (user.occupation != null &&
                                  user.occupation!.isNotEmpty) {
                                displayOccupation =
                                    '$statusLabel, ${user.occupation}';
                              } else {
                                displayOccupation = statusLabel;
                              }
                            } else if (user.occupation?.isNotEmpty ?? false) {
                              displayOccupation = user.occupation!;
                            }

                            if (displayOccupation.isEmpty)
                              return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.briefcase,
                                      size: 16, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayOccupation,
                                    style: TextStyle(
                                        color: subColor, fontSize: 15),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Height
                        if (user.height != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.ruler,
                                  size: 16, color: iconColor),
                              const SizedBox(width: 4),
                              Text('${user.height} cm',
                                  style:
                                      TextStyle(color: subColor, fontSize: 15)),
                            ],
                          ),
                        ],

                        // Location
                        if (user.location?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.mapPin,
                                  size: 16, color: iconColor),
                              const SizedBox(width: 4),
                              Text(user.location ?? '',
                                  style:
                                      TextStyle(color: subColor, fontSize: 15)),
                            ],
                          ),
                        ],

                        // Looking for
                        if (user.lookingFor.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: (user.isPremium
                                      ? user.lookingFor
                                      : user.lookingFor
                                          .where((item) =>
                                              item != 'undecided' &&
                                              item != 'friendship' &&
                                              item != 'meeting' &&
                                              item != 'spontaneous_meeting')
                                          .toList())
                                  .map((item) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isDark
                                                  ? Colors.white
                                                  : Colors.black)
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: (isDark
                                                      ? Colors.white
                                                      : Colors.black)
                                                  .withValues(alpha: 0.15)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                                IconUtils.getLookingForIcon(
                                                    item),
                                                size: 12,
                                                color: iconColor),
                                            const SizedBox(width: 4),
                                            Text(t(item, lang),
                                                style: TextStyle(
                                                    color: subColor,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ── Info badges ────────────────────────────────────────────
                        Center(
                            child: _buildInfoBadges(
                                user, isDark, subColor, iconColor)),

                        const SizedBox(height: 24),

                        // ── Hobbies ────────────────────────────────────────────────
                        if (user.hobbies.isNotEmpty)
                          ..._buildGroupedHobbies(
                              user, isDark, textColor, subColor),

                        // ── Lifestyle (editable pill rows) ─────────────────────────
                        _buildLifestyleSection(
                            user, isDark, textColor, subColor),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- Floating Header Content ---
          ValueListenableBuilder<double>(
            valueListenable: _titleOpacity,
            builder: (context, opacity, child) {
              return TrembleHeader(
                title: 'My Profile',
                titleOpacity: opacity,
                actions: [
                  TrembleCircleButton(
                    icon: LucideIcons.pencil,
                    onPressed: () => context.push('/edit-profile'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static const Map<String, List<String>> _hobbyCategories = {
    'Active 🏋️': [
      'Fitnes',
      'Pilates',
      'Sprehodi',
      'Tek',
      'Smučanje',
      'Snowboarding',
      'Plezanje',
      'Plavanje',
    ],
    'Prosti čas ☕': [
      'Branje',
      'Kava',
      'Čaj',
      'Kuhanje',
      'Filmi',
      'Serije',
      'Videoigre',
      'Glasba',
    ],
    'Umetnost 🎨': [
      'Slikanje',
      'Fotografija',
      'Pisanje',
      'Muzeji',
      'Gledališče',
    ],
    'Potovanja ✈️': [
      'Roadtrips',
      'Camping',
      'City breaks',
      'Backpacking',
    ],
  };

  List<Widget> _buildGroupedHobbies(
      AuthUser user, bool isDark, Color textColor, Color subColor) {
    final predefined = _hobbyCategories.values.expand((e) => e).toSet();
    final customHobbies =
        user.hobbies.where((h) => !predefined.contains(h)).toList();
    final widgets = <Widget>[];

    for (final entry in _hobbyCategories.entries) {
      final matched =
          entry.value.where((h) => user.hobbies.contains(h)).toList();
      if (matched.isEmpty) continue;

      widgets.add(Align(
        alignment: Alignment.centerLeft,
        child: Text(entry.key,
            style: GoogleFonts.instrumentSans(
                color: subColor, fontSize: 14, fontWeight: FontWeight.w600)),
      ));
      widgets.add(const SizedBox(height: 8));
      widgets.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: matched
            .map((h) => Chip(
                  label: Text(h,
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.w500)),
                  backgroundColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  side: BorderSide(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.2)),
                  shape: const StadiumBorder(),
                ))
            .toList(),
      ));
      widgets.add(const SizedBox(height: 12));
    }

    if (customHobbies.isNotEmpty) {
      widgets.add(Align(
        alignment: Alignment.centerLeft,
        child: Text('Custom ✨',
            style: GoogleFonts.instrumentSans(
                color: subColor, fontSize: 14, fontWeight: FontWeight.w600)),
      ));
      widgets.add(const SizedBox(height: 8));
      widgets.add(Wrap(
        spacing: 8,
        runSpacing: 8,
        children: customHobbies
            .map((h) => Chip(
                  label: Text(h,
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.w500)),
                  backgroundColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  side: BorderSide(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.2)),
                  shape: const StadiumBorder(),
                ))
            .toList(),
      ));
      widgets.add(const SizedBox(height: 12));
    }

    if (widgets.isNotEmpty) {
      widgets.insert(
        0,
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(t('hobbies', user.appLanguage),
                style: GoogleFonts.instrumentSans(
                    color: subColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Widget _buildInfoBadges(
      AuthUser user, bool isDark, Color subColor, Color iconColor) {
    final badges = <Widget>[];
    final lang = user.appLanguage;

    if (user.gender != null) {
      badges.add(
          _badge(LucideIcons.user, user.gender!, isDark, subColor, iconColor));
    }
    if (user.isSmoker == true) {
      badges.add(_badge(LucideIcons.cigarette, t('smoker', lang), isDark,
          subColor, iconColor));
    }
    if (user.politicalAffiliation != null &&
        user.politicalAffiliation != 'politics_dont_care' &&
        user.politicalAffiliation != 'politics_undisclosed') {
      badges.add(_badge(LucideIcons.flag, t(user.politicalAffiliation!, lang),
          isDark, subColor, iconColor));
    }
    if (user.religion != null) {
      badges.add(_badge(IconUtils.getReligionIcon(user.religion!),
          t(user.religion!, lang), isDark, subColor, iconColor));
    }
    if (user.hairColor != null) {
      badges.add(_badge(Icons.circle, t(user.hairColor!, lang), isDark,
          subColor, IconUtils.getHairColor(user.hairColor!)));
    }
    if (user.ethnicity != null) {
      badges.add(_badge(LucideIcons.users,
          t('ethnicity_${user.ethnicity}', lang), isDark, subColor, iconColor));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: badges,
    );
  }

  Widget _badge(IconData icon, String text, bool isDark, Color subColor,
      Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Lifestyle section — editable PreferencePillRow items ──────────────────

  Widget _buildLifestyleSection(
      AuthUser user, bool isDark, Color textColor, Color subColor) {
    final lang = user.appLanguage;
    final items = <Widget>[];

    if (user.exerciseHabit != null) {
      items.add(_lifestylePillRow(
        icon: LucideIcons.zap,
        label: t('exercise', lang),
        value: _formatValue(user.exerciseHabit!, lang),
        isDark: isDark,
        textColor: textColor,
        subColor: subColor,
        onEdit: () => _ctrl.openPillEditModal(
          context: context,
          title: t('exercise', lang),
          rowIcon: LucideIcons.zap,
          options: [
            {
              'label': t('exercise_active', lang),
              'value': 'active',
              'icon': LucideIcons.zap,
            },
            {
              'label': t('exercise_sometimes', lang),
              'value': 'sometimes',
              'icon': LucideIcons.activity,
            },
            {
              'label': t('almost_never', lang),
              'value': 'almost_never',
              'icon': LucideIcons.moon,
            },
          ],
          currentValue: user.exerciseHabit,
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(exerciseHabit: val)),
        ),
      ));
    }

    if (user.drinkingHabit != null) {
      items.add(_lifestylePillRow(
        icon: LucideIcons.wine,
        label: t('alcohol', lang),
        value: _formatValue(user.drinkingHabit!, lang),
        isDark: isDark,
        textColor: textColor,
        subColor: subColor,
        onEdit: () => _ctrl.openPillEditModal(
          context: context,
          title: t('alcohol', lang),
          rowIcon: LucideIcons.wine,
          options: [
            {
              'label': t('alcohol_never', lang),
              'value': 'Nikoli',
              'icon': LucideIcons.ban,
            },
            {
              'label': t('alcohol_socially', lang),
              'value': 'Družabno',
              'icon': LucideIcons.users,
            },
            {
              'label': t('alcohol_occasionally', lang),
              'value': 'Ob priliki',
              'icon': LucideIcons.trendingUp,
            },
          ],
          currentValue: user.drinkingHabit,
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(drinkingHabit: val)),
        ),
      ));
    }

    if (user.sleepSchedule != null) {
      items.add(_lifestylePillRow(
        icon: LucideIcons.moon,
        label: t('sleep', lang),
        value: _formatValue(user.sleepSchedule!, lang),
        isDark: isDark,
        textColor: textColor,
        subColor: subColor,
        onEdit: () => _ctrl.openPillEditModal(
          context: context,
          title: t('sleep', lang),
          rowIcon: LucideIcons.moon,
          options: [
            {
              'label': t('night_owl', lang),
              'value': 'Nočna ptica',
              'icon': LucideIcons.moon,
            },
            {
              'label': t('early_bird', lang),
              'value': 'Jutranja ptica',
              'icon': LucideIcons.sun,
            },
          ],
          currentValue: user.sleepSchedule,
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(sleepSchedule: val)),
        ),
      ));
    }

    if (user.petPreference != null) {
      items.add(_lifestylePillRow(
        icon: LucideIcons.dog,
        label: t('pets', lang),
        value: _formatValue(user.petPreference!, lang),
        isDark: isDark,
        textColor: textColor,
        subColor: subColor,
        onEdit: () => _ctrl.openPillEditModal(
          rowIcon: LucideIcons.dog,
          context: context,
          title: t('pets', lang),
          options: [
            {'label': t('dog_person', lang), 'value': 'Dog person'},
            {'label': t('cat_person', lang), 'value': 'Cat person'},
          ],
          currentValue: user.petPreference,
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(petPreference: val)),
        ),
      ));
    }

    if (user.childrenPreference != null) {
      items.add(_lifestylePillRow(
        icon: LucideIcons.baby,
        label: t('children', lang),
        value: _formatValue(user.childrenPreference!, lang),
        isDark: isDark,
        textColor: textColor,
        subColor: subColor,
        onEdit: () => _ctrl.openPillEditModal(
          context: context,
          title: t('children', lang),
          rowIcon: LucideIcons.baby,
          options: [
            {
              'label': t('children_want_someday', lang),
              'value': 'want_someday',
              'icon': LucideIcons.heart,
            },
            {
              'label': t('children_dont_want', lang),
              'value': 'dont_want',
              'icon': LucideIcons.ban,
            },
            {
              'label': t('children_have_and_want_more', lang),
              'value': 'have_and_want_more',
              'icon': LucideIcons.users,
            },
            {
              'label': t('children_have_and_dont_want_more', lang),
              'value': 'have_and_dont_want_more',
              'icon': LucideIcons.userCheck,
            },
            {
              'label': t('children_not_sure', lang),
              'value': 'not_sure',
              'icon': LucideIcons.helpCircle,
            },
          ],
          currentValue: user.childrenPreference,
          onUpdate: (val) =>
              _ctrl.updateUser((u) => u.copyWith(childrenPreference: val)),
        ),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(t('lifestyle', user.appLanguage),
                style: GoogleFonts.instrumentSans(
                    color: subColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  /// A single lifestyle row: icon + label + value pill + edit circle.
  /// Matches the PreferencePillRow visual style from settings.
  Widget _lifestylePillRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required VoidCallback onEdit,
  }) {
    final pillBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);
    final pillBorder = isDark ? Colors.white24 : Colors.black12;
    final iconColor = isDark ? Colors.white70 : Colors.black45;
    final editIconColor = isDark ? Colors.white54 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: subColor, fontSize: 13)),
          const Spacer(),
          // Value pill
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: pillBorder),
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Edit circle
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pillBg,
                border: Border.all(color: pillBorder),
              ),
              child: Icon(LucideIcons.pencil, size: 14, color: editIconColor),
            ),
          ),
        ],
      ),
    );
  }
}
