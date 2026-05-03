import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/translations.dart';
import '../../../core/utils/icon_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../../shared/ui/tremble_circle_button.dart';

class ProfileCardPreview extends ConsumerStatefulWidget {
  const ProfileCardPreview({super.key});

  @override
  ConsumerState<ProfileCardPreview> createState() => _ProfileCardPreviewState();
}

class _ProfileCardPreviewState extends ConsumerState<ProfileCardPreview> {
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;
  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);
  final ValueNotifier<double> _buttonsOpacity = ValueNotifier(1.0);
  double _lastScrollOffset = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
    _titleOpacity.dispose();
    _buttonsOpacity.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    final offset = notification.metrics.pixels;
    final delta = offset - _lastScrollOffset;

    if (offset <= 0) {
      // At top: show everything
      _titleOpacity.value = 1.0;
      _buttonsOpacity.value = 1.0;
    } else if (delta > 2) {
      // Scrolling down: hide everything
      _titleOpacity.value = 0.0;
      _buttonsOpacity.value = 0.0;
    } else if (delta < -2) {
      // Scrolling up (not at top): show buttons only
      _titleOpacity.value = 0.0;
      _buttonsOpacity.value = 1.0;
    }

    _lastScrollOffset = offset;
    return false;
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
                        24, MediaQuery.of(context).padding.top + 25, 24, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),

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
                                // Traveler status badge
                                if (user.isTraveler)
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                            alpha: 0.6),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: const Text('🌴',
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Name + Age ─────────────────────────────────────────────
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${user.name ?? 'Guest'}, ${user.age ?? '?'}',
                                style: GoogleFonts.instrumentSans(
                                  color: textColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (user.birthDate != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  ZodiacUtils.getZodiacIcon(
                                    ZodiacUtils.getZodiacSign(user.birthDate),
                                  ),
                                  size: 20,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t('zodiac_${ZodiacUtils.getZodiacSign(user.birthDate)}',
                                      lang),
                                  style: GoogleFonts.instrumentSans(
                                    color: textColor.withValues(alpha: 0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
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

                        // ── Lifestyle Preferences ─────────────────────────
                        _buildLifestylePreferences(
                            user, isDark, textColor, subColor, lang),

                        const SizedBox(height: 24),

                        // ── Hobbies ────────────────────────────────────────────────
                        if (user.hobbies.isNotEmpty)
                          _buildHobbySection(user, isDark, textColor, subColor),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- Floating Header Content ---
          ListenableBuilder(
            listenable: Listenable.merge([_titleOpacity, _buttonsOpacity]),
            builder: (context, child) {
              return TrembleHeader(
                title: t('my_profile', lang),
                titleOpacity: _titleOpacity.value,
                buttonsOpacity: _buttonsOpacity.value,
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


  String _formatChipText(String text) {
    if (text.isEmpty) return text;
    // Replace underscores with spaces
    String processed = text.replaceAll('_', ' ');

    // Fix specific typos mentioned in bug reports
    if (processed.toLowerCase().contains('burnette')) {
      processed = processed.replaceAll(
          RegExp('burnette', caseSensitive: false), 'Brunette');
    }

    // Ensure the first letter of the entire string is capitalized (Sentence case)
    return processed[0].toUpperCase() + processed.substring(1);
  }

  Widget _buildLifestylePreferences(AuthUser user, bool isDark, Color textColor,
      Color subColor, String lang) {
    final pills = <Widget>[];

    // 1. Basic Lifestyle Traits (Pills)
    if (user.exerciseHabit != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(user.exerciseHabit!),
        label: _formatChipText(t(user.exerciseHabit!, lang)),
      ));
    }
    if (user.drinkingHabit != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(user.drinkingHabit!),
        label: _formatChipText(t(user.drinkingHabit!, lang)),
      ));
    }
    for (final product in user.nicotineUse) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon('nicotine_$product'),
        label: _formatChipText(t('nicotine_$product', lang)),
      ));
    }
    if (user.sleepSchedule != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(user.sleepSchedule!),
        label: _formatChipText(t(user.sleepSchedule!, lang)),
      ));
    }
    if (user.petPreference != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(user.petPreference!),
        label: _formatChipText(t(user.petPreference!, lang)),
      ));
    }
    if (user.childrenPreference != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(user.childrenPreference!),
        label: _formatChipText(t(user.childrenPreference!, lang)),
      ));
    }
    if (user.religion != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getReligionIcon(user.religion!),
        label: _formatChipText(t(user.religion!, lang)),
      ));
    }

    // Political Affiliation - Handled below as a spectrum slider

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(t('lifestyle', lang),
              style: GoogleFonts.instrumentSans(
                  color: subColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: pills,
          ),
          const SizedBox(height: 24),
          _buildGlassSpectrumCard(
            icon: LucideIcons.brain,
            label: t('personality_type', lang),
            value: user.introvertScale?.toDouble() ?? 50.0,
            min: 0,
            max: 100,
            leftLabel: t('introvert', lang),
            rightLabel: t('extrovert', lang),
            currentText: user.introvertScale != null
                ? (user.introvertScale! <= 50
                    ? '${100 - user.introvertScale!}% ${t('introvert', lang)}'
                    : '${user.introvertScale!}% ${t('extrovert', lang)}')
                : '',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final val = _getPoliticalValue(user.politicalAffiliation);
            String currentText = user.politicalAffiliation != null
                ? t(user.politicalAffiliation!, lang)
                : t('politics_undisclosed', lang);
            if (val > 0 && user.politicalAffiliation != null) {
              currentText = _politicsLabelReg(val, lang);
            }
            return _buildGlassSpectrumCard(
              icon: LucideIcons.flag,
              label: t('political_affiliation', lang),
              value: val <= 0 ? 3.0 : val,
              min: 1,
              max: 5,
              leftLabel: t('politics_left', lang),
              rightLabel: t('politics_right', lang),
              currentText: currentText,
              isDark: isDark,
              hideThumb: val <= 0,
            );
          }),
        ],
      ),
    );
  }

  double _getPoliticalValue(String? affiliation) {
    switch (affiliation) {
      case 'politics_left':
        return 1.0;
      case 'politics_center_left':
        return 2.0;
      case 'politics_center':
        return 3.0;
      case 'politics_center_right':
        return 4.0;
      case 'politics_right':
        return 5.0;
      case 'politics_dont_care':
        return 0.0;
      case 'politics_undisclosed':
        return -1.0;
      default:
        return -1.0;
    }
  }

  String _politicsLabelReg(double v, String lang) {
    final idx = v.round().clamp(1, 5) - 1;
    return [
      t('politics_left', lang),
      t('politics_center_left', lang),
      t('politics_center', lang),
      t('politics_center_right', lang),
      t('politics_right', lang),
    ][idx];
  }



  Widget _buildGlassSpectrumCard({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String leftLabel,
    required String rightLabel,
    required String currentText,
    required bool isDark,
    bool hideThumb = false,
  }) {
    final accentColor = Theme.of(context).primaryColor;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.6);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.07);
    final labelColor = isDark ? Colors.white54 : Colors.black45;
    final titleColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: accentColor.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.instrumentSans(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leftLabel,
                  style: TextStyle(color: labelColor, fontSize: 10)),
              Text(rightLabel,
                  style: TextStyle(color: labelColor, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              LayoutBuilder(builder: (context, constraints) {
                if (hideThumb) return const SizedBox.shrink();
                final percent = (value - min) / (max - min);
                const thumbSize = 10.0;
                final leftOffset =
                    (constraints.maxWidth - thumbSize) * percent;
                return Container(
                  margin: EdgeInsets.only(left: leftOffset),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.45),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              currentText,
              style: GoogleFonts.instrumentSans(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'hobby_cat_active':
        return LucideIcons.zap;
      case 'hobby_cat_leisure':
        return LucideIcons.coffee;
      case 'hobby_cat_art':
        return LucideIcons.palette;
      case 'hobby_cat_travel':
        return LucideIcons.map;
      default:
        return LucideIcons.sparkles;
    }
  }

  Widget _buildHobbySection(
      AuthUser user, bool isDark, Color textColor, Color subColor) {
    final lang = user.appLanguage;
    final userHobbies = user.hobbies;

    // Group all hobbies by category
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final h in userHobbies) {
      final cat = h['category'] as String? ?? 'Custom';
      grouped.putIfAbsent(cat, () => []).add(h);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(t('hobbies', lang),
            style: GoogleFonts.instrumentSans(
                color: subColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Column(
          children: [
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(entry.key),
                      size: 12,
                      color: subColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t(entry.key, lang).toUpperCase(),
                      style: GoogleFonts.instrumentSans(
                        color: subColor.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: entry.value
                    .map((h) => _PreferencePill(
                        label: '${h['emoji']} ${h['name']}'))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBadges(
      AuthUser user, bool isDark, Color subColor, Color iconColor) {
    final badges = <Widget>[];
    final lang = user.appLanguage;

    if (user.gender != null) {
      badges.add(
          _badge(LucideIcons.user, user.gender!, isDark, subColor, iconColor));
    }
    if (user.hairColor != null) {
      badges.add(_badge(Icons.circle, _formatChipText(t(user.hairColor!, lang)),
          isDark, subColor, IconUtils.getHairColor(user.hairColor!)));
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
}

class _PreferencePill extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _PreferencePill({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06);
    final pillBorder = isDark ? Colors.white24 : Colors.black12;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
