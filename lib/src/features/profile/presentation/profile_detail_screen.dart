import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/glass_card.dart';
import '../../matches/data/match_repository.dart';
import '../../dashboard/presentation/home_screen.dart'; // For tracking ping/radar
import '../../auth/data/auth_repository.dart';
import '../../safety/presentation/widgets/ugc_action_sheet.dart';
import '../../../core/translations.dart';
import '../../../shared/ui/tremble_back_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileDetailScreen extends ConsumerWidget {
  final MatchProfile match;

  const ProfileDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _showExitWarning(context, ref);
        },
        child: GradientScaffold(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bio Section
                          _buildBioSection(lang),
                          const SizedBox(height: 20),

                          // What they're looking for
                          if (match.lookingFor.isNotEmpty) ...[
                            _buildLookingForSection(lang),
                            const SizedBox(height: 20),
                          ],

                          // Basic Info (Job, School, etc.)
                          _buildInfoBadges(context, ref),
                          const SizedBox(height: 20),

                          // Prompts
                          if (match.prompts.isNotEmpty) ...[
                            _buildPromptsSection(),
                            const SizedBox(height: 20),
                          ],

                          // Lifestyle & Habits
                          _buildLifestyleSection(ref),
                          const SizedBox(height: 20),

                          // Interests
                          _buildInterestsSection(lang),
                          const SizedBox(height: 20),

                          // Personality
                          if (match.introvertLevel != null)
                            _buildPersonalitySection(context, lang),

                          const SizedBox(height: 40),

                          // Action Buttons at the bottom
                          _buildActionButtons(context, ref),
                          const SizedBox(height: 60),
                        ]
                            .animate(interval: 50.ms)
                            .fade(duration: 400.ms, curve: Curves.easeOut)
                            .slideY(
                                begin: 0.1,
                                duration: 400.ms,
                                curve: Curves.easeOut),
                      ),
                    ),
                  ),
                ],
              ),

              // Custom Back Button — top right, pill shaped
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: TrembleBackButton(
                  onPressed: () => _showExitWarning(context, ref),
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ));
  }

  void _showExitWarning(BuildContext context, WidgetRef ref) {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(t('warning', lang),
            style: GoogleFonts.instrumentSans(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(t('ignore_warning_body', lang),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              ref.read(matchControllerProvider.notifier).dismiss();
              if (context.canPop()) {
                context.pop(); // Pop from profile screen
              }
            },
            child: Text(t('ignore', lang),
                style: const TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              ref.read(matchControllerProvider.notifier).dismiss();
              if (context.canPop()) {
                context.pop(); // Pop from profile screen
              }
            },
            child: Text(t('match_again_future', lang),
                style: const TextStyle(color: Color(0xFFF4436C))),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionTextButton(
          text: 'Ignore',
          color: Colors.redAccent,
          onTap: () {
            ref.read(matchControllerProvider.notifier).dismiss();
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        _ActionTextButton(
          text: 'Pozdrav',
          color: Colors.greenAccent,
          onTap: () {
            ref.read(matchControllerProvider.notifier).greet();

            // Set strong directional ping on radar
            ref.read(pingDistanceProvider.notifier).state = 0.8; // Edge
            ref.read(pingAngleProvider.notifier).state =
                0.5; // Example angle, adjust as needed

            if (context.canPop()) {
              context.pop();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Pozdrav poslan ${match.name}!")),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 450,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
          onPressed: () {
            UgcActionSheet.show(
              context,
              targetUid: match.id,
              targetName: match.name,
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              match.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black12,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${match.name}, ${match.age}",
                    style: GoogleFonts.instrumentSans(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  if (match.jobTitle != null || match.school != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.briefcase,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            [match.jobTitle, match.company]
                                .where((e) => e != null)
                                .join(' @ '),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (match.height != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.ruler,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${match.height} cm',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                  if (match.school != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.graduationCap,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          match.school!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('about_me', lang),
            style: GoogleFonts.instrumentSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          match.bio,
          style:
              const TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLookingForSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('looking_for', lang),
            style: GoogleFonts.instrumentSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: match.lookingFor
              .map((item) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4436C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              const Color(0xFFF4436C).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.heart,
                            size: 14, color: const Color(0xFFF4436C)),
                        const SizedBox(width: 6),
                        Text(item,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildInfoBadges(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final lang = user?.appLanguage ?? 'en';
    final items = <Widget>[];

    void addBadge(IconData icon, String text, [Color? color]) {
      items.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color ?? Colors.white70),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            )
          ],
        ),
      ));
    }

    if (match.height != null) {
      addBadge(LucideIcons.ruler, '${match.height} cm');
    }
    if (match.jobTitle != null) {
      addBadge(LucideIcons.briefcase, match.jobTitle!);
    }
    if (match.school != null) {
      addBadge(LucideIcons.graduationCap, match.school!);
    }
    if (match.politicalAffiliation != null &&
        match.politicalAffiliation != 'politics_dont_care' &&
        match.politicalAffiliation != 'politics_undisclosed') {
      addBadge(LucideIcons.flag, t(match.politicalAffiliation!, lang));
    }
    if (match.hairColor != null) {
      addBadge(LucideIcons.scissors, t(match.hairColor!, lang));
    }
    if (match.ethnicity != null) {
      addBadge(LucideIcons.users, t('ethnicity_${match.ethnicity}', lang));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items,
    );
  }

  Widget _buildPromptsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: match.prompts.map((prompt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: GlassCard(
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prompt['question']!,
                    style: GoogleFonts.instrumentSans(
                        fontSize: 14, color: const Color(0xFFF4436C))),
                const SizedBox(height: 8),
                Text(prompt['answer']!,
                    style: GoogleFonts.instrumentSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLifestyleSection(WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final habits = <Widget>[];

    Widget buildHabitItem(IconData icon, String label, String value) {
      return Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            radius: 20,
            child: Icon(icon, size: 20, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      );
    }

    if (match.isSmoker != null) {
      habits.add(buildHabitItem(LucideIcons.cigarette, t('smoking', lang),
          match.isSmoker! ? t('yes', lang) : t('no', lang)));
    }
    if (match.drinkingHabit != null) {
      habits.add(buildHabitItem(
          LucideIcons.wine, t('alcohol', lang), match.drinkingHabit!));
    }
    if (match.exerciseHabit != null) {
      habits.add(buildHabitItem(
          LucideIcons.dumbbell, t('exercise', lang), match.exerciseHabit!));
    }
    if (match.sleepSchedule != null) {
      habits.add(buildHabitItem(
          LucideIcons.moon, t('sleep', lang), match.sleepSchedule!));
    }
    if (match.petPreference != null) {
      habits.add(buildHabitItem(
          LucideIcons.heart,
          t('pets', lang),
          match.petPreference == 'Dog person'
              ? '🐶 Dog person'
              : '🐱 Cat person'));
    }
    if (match.childrenPreference != null) {
      habits.add(buildHabitItem(
          LucideIcons.baby, t('children', lang), match.childrenPreference!));
    }
    if (match.religion != null) {
      habits.add(buildHabitItem(
          LucideIcons.heart, t('religion', lang), t(match.religion!, lang)));
    }
    if (match.ethnicity != null) {
      habits.add(buildHabitItem(
          LucideIcons.users, t('ethnicity', lang), match.ethnicity!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('lifestyle', lang),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        GlassCard(
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: habits,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('interests', lang),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: match.hobbies
              .map((h) => Chip(
                    label: Text(h,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                    backgroundColor: Colors.black54,
                    side: const BorderSide(color: Colors.white24),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.all(4),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPersonalitySection(BuildContext context, String lang) {
    final intLevel = match.introvertLevel ?? 50;
    final val = intLevel.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('personality', lang),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        GlassCard(
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Introvert", style: TextStyle(color: Colors.white70)),
                  Text("Ekstrovert", style: TextStyle(color: Colors.white70)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFF4436C),
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  disabledThumbColor: Colors.white,
                  disabledActiveTrackColor: const Color(0xFFF4436C),
                  disabledInactiveTrackColor: Colors.white24,
                ),
                child: Slider(
                  value: val,
                  min: 0,
                  max: 100,
                  onChanged: null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                intLevel <= 50
                    ? '${100 - intLevel}% introvert'
                    : '$intLevel% ekstrovert',
                style: const TextStyle(
                    color: const Color(0xFFF4436C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2)
            ]),
        child: Text(text,
            style: GoogleFonts.instrumentSans(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
