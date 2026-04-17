import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/match/data/wave_repository.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../matches/data/match_repository.dart';
import '../../dashboard/presentation/home_screen.dart'; // For tracking ping/radar
import '../../safety/presentation/widgets/ugc_action_sheet.dart';
import '../../../core/translations.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../shared/ui/tremble_circle_button.dart';
import '../../../core/theme.dart';
import '../../auth/data/auth_repository.dart';


class ProfileDetailScreen extends ConsumerStatefulWidget {
  final MatchProfile match;

  const ProfileDetailScreen({super.key, required this.match});

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;
  final ValueNotifier<double> _buttonsOpacity = ValueNotifier(1.0);
  double _lastScrollOffset = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
    _buttonsOpacity.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    final offset = notification.metrics.pixels;
    final delta = offset - _lastScrollOffset;

    if (offset <= 0) {
      _buttonsOpacity.value = 1.0;
    } else if (delta > 2) {
      // Scrolling down -> fade out
      _buttonsOpacity.value = 0.0;
    } else if (delta < -2) {
      // Scrolling up -> fade in
      _buttonsOpacity.value = 1.0;
    }

    _lastScrollOffset = offset;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white54 : Colors.black45;
    final lang = ref.watch(appLanguageProvider);
    final user = ref.watch(authStateProvider);

    final photoCount = match.photoUrls.length;
    final hasPhotos = photoCount > 0;

    final isPrideMode = user?.isPrideMode ?? false;
    final isGenderBasedColor = user?.isGenderBasedColor ?? false;
    final gender = user?.gender;

    final bgColors = TrembleTheme.getGradient(
      isDarkMode: isDark,
      isPrideMode: isPrideMode,
      gender: gender,
      isGenderBasedColor: isGenderBasedColor,
    );
    final bottomBgColor = bgColors.isNotEmpty ? bgColors.last : Theme.of(context).scaffoldBackgroundColor;

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
                        24, MediaQuery.of(context).padding.top + 12, 24, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

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
                                      final url = match.photoUrls[index];
                                      return Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey[900]),
                                      );
                                    },
                                  )
                                else
                                  Image.network(
                                    match.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[900]),
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
                                    text: '${match.name}, ${match.age}'),
                                if (ZodiacUtils.getZodiacEmoji(
                                        match.birthDate) !=
                                    null)
                                  TextSpan(
                                    text:
                                        '  ${ZodiacUtils.getZodiacEmoji(match.birthDate)}',
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
                            if (match.jobStatus != null) {
                              final statusLabel = t(match.jobStatus!, lang);
                              if (match.occupation != null &&
                                  match.occupation!.isNotEmpty) {
                                displayOccupation =
                                    '$statusLabel, ${match.occupation}';
                              } else {
                                displayOccupation = statusLabel;
                              }
                            } else if (match.occupation?.isNotEmpty ?? false) {
                              displayOccupation = match.occupation!;
                            }

                            if (displayOccupation.isEmpty) {
                              return const SizedBox.shrink();
                            }

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
                        if (match.height != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.ruler,
                                  size: 16, color: iconColor),
                              const SizedBox(width: 4),
                              Text('${match.height} cm',
                                  style:
                                      TextStyle(color: subColor, fontSize: 15)),
                            ],
                          ),
                        ],

                        // Looking for
                        if (match.lookingFor.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: match.lookingFor
                                  .where((item) =>
                                      item != 'undecided' &&
                                      item != 'friendship' &&
                                      item != 'meeting' &&
                                      item != 'spontaneous_meeting')
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
                                match, isDark, subColor, iconColor, lang)),

                        const SizedBox(height: 24),

                        // ── Lifestyle Preferences ─────────────────────────
                        _buildLifestylePreferences(
                            match, isDark, textColor, subColor, lang),

                        const SizedBox(height: 24),

                        // ── Hobbies ────────────────────────────────────────────────
                        if (match.hobbies.isNotEmpty)
                          _buildHobbySection(match, isDark, textColor, subColor),

                        const SizedBox(height: 24),

                        const SizedBox(height: 80), // Space for floating buttons
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Floating Header Content ---
          ValueListenableBuilder<double>(
            valueListenable: _buttonsOpacity,
            builder: (context, opacity, child) {
              return TrembleHeader(
                title: '', // Name is in content
                titleOpacity: 0.0,
                buttonsOpacity: opacity,
                onBack: () {
                  ref.read(matchControllerProvider.notifier).dismiss();
                  if (context.canPop()) context.pop();
                },
                actions: [
                  TrembleCircleButton(
                    icon: LucideIcons.moreVertical,
                    onPressed: () {
                      UgcActionSheet.show(
                        context,
                        targetUid: widget.match.id,
                        targetName: widget.match.name,
                      );
                    },
                  ),
                ],
              );
            },
          ),

          // --- Action Buttons ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24,
                  MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bottomBgColor.withValues(alpha: 0),
                    bottomBgColor.withValues(alpha: 0.9),
                    bottomBgColor,
                  ],
                ),
              ),
              child: _buildActionButtons(context, ref, match),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, MatchProfile match) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(appLanguageProvider);
    final myUid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
    
    // Find active match document for this user
    final matchDoc = ref.watch(getMatchByUserIdProvider(match.id));

    // Dynamic brand-coordinated ignore color
    final ignoreColor = isDark 
        ? TrembleTheme.rose.withValues(alpha: 0.7) 
        : TrembleTheme.rose.withValues(alpha: 0.6);

    // Default state: No gesture sent
    String greetText = t('greet', lang);
    bool isSent = false;
    VoidCallback onGreet = () async {
      if (matchDoc != null) {
        await ref.read(waveRepositoryProvider).sendGesture(matchDoc.id);
      } else {
        // Fallback or initial creation if no match doc yet (unlikely in this view)
        await ref.read(matchControllerProvider.notifier).greet();
      }
      
      if (context.mounted) {
        final sentMsg = "${t('greet', lang)} ${t('sent', lang)} ${match.name}!";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sentMsg)));
      }
    };

    if (matchDoc != null) {
      final iWaved = matchDoc.hasWaved(myUid);
      final theyWaved = matchDoc.hasWaved(match.id);

      if (iWaved && !theyWaved) {
        greetText = "${t('sent', lang).substring(0, 1).toUpperCase()}${t('sent', lang).substring(1)}"; // "Poslan"
        isSent = true;
      } else if (theyWaved && !iWaved) {
        greetText = t('accept', lang); // "Sprejmi"
      } else if (matchDoc.isMutual) {
        greetText = t('radar_lock_active', lang);
        isSent = true; 
      }
    }

    return Row(
      children: [
        Expanded(
          child: _ActionTextButton(
            text: t('ignore', lang),
            color: ignoreColor,
            onTap: () {
              ref.read(matchControllerProvider.notifier).dismiss();
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionTextButton(
            text: greetText,
            color: isSent ? primaryColor.withValues(alpha: 0.5) : primaryColor,
            onTap: isSent ? () {} : onGreet,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadges(MatchProfile match, bool isDark, Color subColor,
      Color iconColor, String lang) {
    final items = <Widget>[];

    void addBadge(IconData icon, String text, [Color? color]) {
      items.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color ?? iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subColor, fontSize: 12)),
            )
          ],
        ),
      ));
    }

    if (match.school != null) {
      addBadge(LucideIcons.graduationCap, match.school!);
    }
    if (match.hairColor != null) {
      addBadge(Icons.circle, t(match.hairColor!, lang),
          IconUtils.getHairColor(match.hairColor!));
    }
    if (match.ethnicity != null) {
      addBadge(LucideIcons.users, t('ethnicity_${match.ethnicity}', lang));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items,
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
      'Plavanje'
    ],
    'Prosti čas ☕': [
      'Branje',
      'Kava',
      'Čaj',
      'Kuhanje',
      'Filmi',
      'Serije',
      'Videoigre',
      'Glasba'
    ],
    'Umetnost 🎨': ['Slikanje', 'Fotografija', 'Pisanje', 'Muzeji', 'Gledališče'],
    'Potovanja ✈️': [
      'Izleti',
      'Narava',
      'Gore',
      'Morje',
      'Mestna potepanja',
      'Kampiranje'
    ],
  };

  Widget _buildHobbySection(
      MatchProfile match, bool isDark, Color textColor, Color subColor) {
    final lang = ref.watch(appLanguageProvider);
    final userHobbies = match.hobbies.toList();
    final categorizedHobbies = _hobbyCategories.values.expand((e) => e).toSet();
    final customHobbies = userHobbies.where((h) => !categorizedHobbies.contains(h)).toList();
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(t('hobbies', lang),
            style: GoogleFonts.instrumentSans(
                color: subColor, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in _hobbyCategories.entries) ...[
                if (userHobbies.any((h) => entry.value.contains(h)))
                  Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            color: subColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: entry.value
                              .where((h) => userHobbies.contains(h))
                              .map((h) => _PreferencePill(label: _formatChipText(h)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
              ],
              if (customHobbies.isNotEmpty)
                Container(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t('hobby_other', lang),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSans(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: customHobbies
                            .map((h) => _PreferencePill(label: _formatChipText(h)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatChipText(String text) {
    if (text.isEmpty) return text;
    // Replace underscores with spaces
    String processed = text.replaceAll('_', ' ');
    // Handle the specific typo mentioned ("_v" or similar) if needed, but replaceAll covers it broadly
    
    // Title Case: capitalize every word
    return processed.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildLifestylePreferences(
      MatchProfile match, bool isDark, Color textColor, Color subColor, String lang) {
    final pills = <Widget>[];

    // 1. Basic Lifestyle Traits (Pills)
    if (match.exerciseHabit != null) {
      pills.add(_PreferencePill(
        icon: LucideIcons.zap,
        label: _formatChipText(t(match.exerciseHabit!, lang)),
      ));
    }
    if (match.drinkingHabit != null) {
      pills.add(_PreferencePill(
        icon: LucideIcons.wine,
        label: _formatChipText(t(match.drinkingHabit!, lang)),
      ));
    }
    if (match.isSmoker != null) {
      pills.add(_PreferencePill(
        icon: LucideIcons.cigarette,
        label: _formatChipText(match.isSmoker! ? t('smoker', lang) : t('smoke_no', lang)),
      ));
    }
    if (match.sleepSchedule != null) {
      pills.add(_PreferencePill(
        icon: LucideIcons.moon,
        label: _formatChipText(t(match.sleepSchedule!, lang)),
      ));
    }
    if (match.petPreference != null) {
      pills.add(_PreferencePill(
        icon: LucideIcons.dog,
        label: _formatChipText(t(match.petPreference!, lang)),
      ));
    }
    if (match.childrenPreference != null) {
      pills.add(_PreferencePill(
        icon: LucideIcons.baby,
        label: _formatChipText(t(match.childrenPreference!, lang)),
      ));
    }
    if (match.religion != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getReligionIcon(match.religion!),
        label: _formatChipText(t(match.religion!, lang)),
      ));
    }

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

        // 2. Spectrum Indicators (Sliders)
        _buildSpectrumIndicator(
          icon: LucideIcons.brain,
          label: t('personality_type', lang),
          value: match.introvertLevel?.toDouble() ?? 50.0,
          min: 0,
          max: 100,
          leftLabel: t('introvert', lang),
          rightLabel: t('extrovert', lang),
          currentText: match.introvertLevel != null
              ? (match.introvertLevel! <= 50
                  ? '${100 - match.introvertLevel!}% ${t('introvert', lang)}'
                  : '${match.introvertLevel!}% ${t('extrovert', lang)}')
              : '',
          isDark: isDark,
        ),
        const SizedBox(height: 32),
        if (match.politicalAffiliation != null)
          _buildSpectrumIndicator(
            icon: LucideIcons.flag,
            label: t('political_affiliation', lang),
            value: _getPoliticsValue(match.politicalAffiliation!),
            min: 1,
            max: 5,
            leftLabel: t('politics_left', lang),
            rightLabel: t('politics_right', lang),
            currentText: t(match.politicalAffiliation!, lang),
            isDark: isDark,
          ),
      ],
    ),
  );
}

  double _getPoliticsValue(String key) {
    switch (key) {
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
      default:
        return 3.0;
    }
  }

  Widget _buildSpectrumIndicator({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String leftLabel,
    required String rightLabel,
    required String currentText,
    required bool isDark,
  }) {
    final trackColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);
    final accentColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Centered Header (Match Edit Profile style)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: accentColor.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Range Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: TextStyle(color: textColor, fontSize: 12)),
            Text(rightLabel, style: TextStyle(color: textColor, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        // Progress Track
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              final percent = (value - min) / (max - min);
              final thumbSize = 12.0;
              final leftOffset = (constraints.maxWidth - thumbSize) * percent;
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
                        color: accentColor.withValues(alpha: 0.4),
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
        const SizedBox(height: 12),
        // Selected Value Text (Bold)
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            currentText,
            style: GoogleFonts.instrumentSans(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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

class _ActionTextButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ActionTextButton(
      {required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          text,
          style: GoogleFonts.instrumentSans(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
