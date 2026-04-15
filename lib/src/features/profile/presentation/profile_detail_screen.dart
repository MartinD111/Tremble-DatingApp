import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/tremble_circle_button.dart';
import '../../matches/data/match_repository.dart';
import '../../dashboard/presentation/home_screen.dart'; // For tracking ping/radar
import '../../safety/presentation/widgets/ugc_action_sheet.dart';
import '../../../core/translations.dart';
import '../../../core/utils/icon_utils.dart';

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

  String _formatValue(String raw, String lang) {
    final translated = t(raw, lang);
    if (translated != raw) return _titleCase(translated);
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
    final match = widget.match;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white54 : Colors.black45;
    final lang = ref.watch(appLanguageProvider);

    final photoCount = match.photoUrls.length;
    final hasPhotos = photoCount > 0;

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
                        24, MediaQuery.of(context).padding.top + 12, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        // ── Hobbies ────────────────────────────────────────────────
                        if (match.hobbies.isNotEmpty)
                          _buildGroupedHobbiesCard(
                              match, isDark, textColor, subColor, lang),

                        // ── Lifestyle Section ─────────────────────────
                        _buildLifestyleSection(
                            match, isDark, textColor, subColor, lang),

                        const SizedBox(height: 120), // Extra space for scroll
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
                title: match.name,
                titleOpacity: opacity,
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
                        targetUid: match.id,
                        targetName: match.name,
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
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                    Theme.of(context).scaffoldBackgroundColor,
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
    return Row(
      children: [
        Expanded(
          child: _ActionTextButton(
            text: 'Ignore',
            color: Colors.redAccent,
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
            text: 'Pozdrav',
            color: Colors.greenAccent,
            onTap: () {
              ref.read(matchControllerProvider.notifier).greet();
              ref.read(pingDistanceProvider.notifier).state = 0.8;
              ref.read(pingAngleProvider.notifier).state = 0.5;
              if (context.canPop()) {
                context.pop();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Pozdrav poslan ${match.name}!")),
              );
            },
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
    if (match.isSmoker != null) {
      addBadge(LucideIcons.cigarette,
          match.isSmoker! ? t('smoker', lang) : t('smoke_no', lang));
    }
    if (match.politicalAffiliation != null &&
        match.politicalAffiliation != 'politics_dont_care' &&
        match.politicalAffiliation != 'politics_undisclosed') {
      addBadge(LucideIcons.flag, t(match.politicalAffiliation!, lang));
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

  Widget _buildGroupedHobbiesCard(MatchProfile match, bool isDark,
      Color textColor, Color subColor, String lang) {
    Map<String, List<String>> currentGroups = {};
    for (var hobby in match.hobbies) {
      bool categorized = false;
      for (var entry in _hobbyCategories.entries) {
        if (entry.value.contains(hobby)) {
          currentGroups.putIfAbsent(entry.key, () => []).add(hobby);
          categorized = true;
          break;
        }
      }
      if (!categorized) {
        currentGroups.putIfAbsent('Ostalo ✨', () => []).add(hobby);
      }
    }

    if (currentGroups.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(t('hobbies', lang),
                style: GoogleFonts.instrumentSans(
                    color: subColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          ...currentGroups.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key,
                      style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: entry.value
                        .map((h) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(h,
                                  style:
                                      TextStyle(color: subColor, fontSize: 13)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection(MatchProfile match, bool isDark,
      Color textColor, Color subColor, String lang) {
    final rows = <Widget>[];

    void addRow(IconData icon, String label, String value) {
      final pillBg = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.06);
      final pillBorder = isDark ? Colors.white24 : Colors.black12;

      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: subColor),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: subColor, fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pillBorder),
              ),
              child: Text(value,
                  style: TextStyle(color: subColor, fontSize: 13)),
            ),
          ],
        ),
      ));
    }

    if (match.drinkingHabit != null) {
      addRow(LucideIcons.wine, t('alcohol', lang),
          _formatValue(match.drinkingHabit!, lang));
    }
    if (match.exerciseHabit != null) {
      addRow(LucideIcons.dumbbell, t('exercise', lang),
          _formatValue(match.exerciseHabit!, lang));
    }
    if (match.sleepSchedule != null) {
      addRow(LucideIcons.moon, t('sleep', lang),
          _formatValue(match.sleepSchedule!, lang));
    }
    if (match.petPreference != null) {
      addRow(LucideIcons.dog, t('pets', lang),
          _formatValue(match.petPreference!, lang));
    }
    if (match.childrenPreference != null) {
      addRow(LucideIcons.baby, t('children', lang),
          _formatValue(match.childrenPreference!, lang));
    }
    if (match.religion != null) {
      addRow(IconUtils.getReligionIcon(match.religion!), t('religion', lang),
          t(match.religion!, lang));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(t('lifestyle', lang),
                    style: GoogleFonts.instrumentSans(
                        color: subColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              ...rows,
            ],
          ),
        ),
      ],
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
