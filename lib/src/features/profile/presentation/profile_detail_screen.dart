import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/match/data/wave_repository.dart';
import 'package:tremble/src/features/match/presentation/wave_controller.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../matches/data/match_repository.dart';
import '../../safety/presentation/widgets/ugc_action_sheet.dart';
import '../../../core/translations.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../shared/ui/tremble_circle_button.dart';
import '../../../core/theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../safety/screen_protection_service.dart';
import '../../dashboard/application/dev_simulation_controller.dart';
import '../../../shared/ui/premium_paywall.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final MatchProfile match;
  final bool showActions;

  const ProfileDetailScreen({
    super.key,
    required this.match,
    this.showActions = true,
  });

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen>
    with TickerProviderStateMixin {
  final PageController _photoPageController = PageController();
  int _currentPhotoPage = 0;
  final ValueNotifier<double> _buttonsOpacity = ValueNotifier(1.0);
  double _lastScrollOffset = 0;
  bool _isRecording = false;
  late final void Function(bool) _recordingListener;

  // Tracks whether "they waved" animation has been triggered so we don't
  // re-trigger on every build after theyWaved becomes true.
  bool _waveAnimTriggered = false;

  @override
  void initState() {
    super.initState();
    _recordingListener = (isRecording) {
      if (mounted) setState(() => _isRecording = isRecording);
    };
    ScreenProtectionService.enable();
    ScreenProtectionService.addRecordingListener(_recordingListener);
  }

  @override
  void dispose() {
    ScreenProtectionService.removeRecordingListener();
    ScreenProtectionService.disable();
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
    // Detect when the other person waves while the profile card is open.
    // Fires the shake + rainbow animation on the wave button exactly once.
    final myUid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    // Dev sim bridge: Firestore stream is absent in dev sim, so watch the
    // sim controller directly and mirror the waveReceived signal here.
    ref.listen(devSimulationControllerProvider, (prev, next) {
      if (_waveAnimTriggered) return;
      final wasReceived = prev?.phase == DevSimPhase.waveReceived;
      final isReceived = next.phase == DevSimPhase.waveReceived;
      if (!wasReceived && isReceived && next.profile?.id == widget.match.id) {
        setState(() => _waveAnimTriggered = true);
        HapticFeedback.heavyImpact();
      }
    });

    ref.listen(getMatchByUserIdProvider(widget.match.id), (prev, next) {
      // Mutual wave while profile card is open → go straight to reveal screen.
      final wasMutual = prev?.isMutual ?? false;
      final nowMutual = next?.isMutual ?? false;
      if (!wasMutual && nowMutual && context.mounted) {
        context.pop();
        context.pushNamed('match_reveal', extra: next);
        return;
      }

      if (_waveAnimTriggered) return;
      final theyWaved = next?.hasWaved(widget.match.id) ?? false;
      final iWaved = next?.hasWaved(myUid) ?? false;
      if (theyWaved && !iWaved) {
        setState(() => _waveAnimTriggered = true);
        HapticFeedback.heavyImpact();
      }
    });

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
    final bottomBgColor = bgColors.isNotEmpty
        ? bgColors.last
        : Theme.of(context).scaffoldBackgroundColor;

    if (_isRecording) return const RecordingShield();

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
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey[900]),
                                      );
                                    },
                                  )
                                else
                                  Image.network(
                                    match.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: Colors.grey[900]),
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
                                // ── Name + Age + Zodiac overlay ──────────────────
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 48, 16, 16),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color(0xCC000000),
                                        ],
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      '${match.name}, ${match.age}',
                                                      style: GoogleFonts
                                                          .instrumentSans(
                                                        color: Colors.white,
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        shadows: [
                                                          const Shadow(
                                                            blurRadius: 8,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (match.isTraveler) ...[
                                                    const SizedBox(width: 8),
                                                    Tooltip(
                                                      message: t(
                                                        'tourist_badge_tooltip',
                                                        lang,
                                                      ),
                                                      child: Container(
                                                        width: 30,
                                                        height: 30,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: const Color(
                                                                  0xFFF4436C)
                                                              .withValues(
                                                                  alpha: 0.18),
                                                          border: Border.all(
                                                            color: const Color(
                                                                    0xFFF4436C)
                                                                .withValues(
                                                                    alpha: 0.5),
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          LucideIcons.plane,
                                                          color:
                                                              Color(0xFFF4436C),
                                                          size: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (match.birthDate != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  ZodiacUtils.getZodiacEmoji(
                                                          match.birthDate) ??
                                                      '',
                                                  style: const TextStyle(
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                  .map((item) => _PreferencePill(
                                        icon: IconUtils.getLookingForIcon(item),
                                        label: t(item, lang),
                                        isGenderBased: isGenderBasedColor,
                                        gender: gender,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ── Info badges ────────────────────────────────────────────
                        Center(
                            child: _buildInfoBadges(match, isDark, subColor,
                                iconColor, lang, isGenderBasedColor, gender)),

                        const SizedBox(height: 24),

                        // ── Lifestyle Preferences ─────────────────────────
                        _buildLifestylePreferences(
                          match,
                          isDark,
                          textColor,
                          subColor,
                          lang,
                          isGenderBasedColor: isGenderBasedColor,
                          gender: gender,
                        ),

                        const SizedBox(height: 24),

                        // ── Hobbies ────────────────────────────────────────────────
                        if (match.hobbies.isNotEmpty)
                          _buildHobbySection(match, isDark, textColor, subColor,
                              isGenderBasedColor, gender),

                        const SizedBox(height: 24),

                        const SizedBox(
                            height: 80), // Space for floating buttons
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
                  if (widget.showActions) {
                    ref.read(matchControllerProvider.notifier).dismiss();
                  }
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
          if (widget.showActions)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
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

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, MatchProfile match) {
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

    // Determine wave state from Firestore match doc
    final waveSendState = ref.watch(waveControllerProvider).valueOrNull;
    final optimisticWaveSent =
        waveSendState?.isOptimisticFor(match.id) ?? false;
    final inlineErrorMessage = waveSendState?.inlineErrorFor(match.id);
    final iWaved = (matchDoc?.hasWaved(myUid) ?? false) || optimisticWaveSent;
    final theyWaved = matchDoc?.hasWaved(match.id) ?? false;
    final isMutual = matchDoc?.isMutual ?? false;

    // Button label
    String waveText = 'Wave';
    bool isSent = false;
    if (iWaved && !theyWaved) {
      waveText =
          "${t('sent', lang).substring(0, 1).toUpperCase()}${t('sent', lang).substring(1)}";
      isSent = true;
    } else if (theyWaved && !iWaved) {
      waveText = 'Wave back';
    } else if (isMutual) {
      waveText = t('radar_lock_active', lang);
      isSent = true;
    }

    void onGreet() {
      final user = ref.read(authStateProvider);
      if (user?.hasReachedFreeWaveLimit == true) {
        PremiumPaywallBottomSheet.show(context);
        return;
      }

      unawaited(
        ref.read(waveControllerProvider.notifier).handleWave(
          match.id,
          writeWave: () async {
            if (matchDoc != null) {
              await ref.read(waveRepositoryProvider).sendGesture(matchDoc.id);
            } else {
              await ref.read(matchControllerProvider.notifier).greet();
            }
          },
        ),
      );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WaveButton(
                text: waveText,
                color:
                    isSent ? primaryColor.withValues(alpha: 0.5) : primaryColor,
                isSent: isSent,
                onTap: isSent ? null : onGreet,
                theyWaved: _waveAnimTriggered,
              ),
              if (inlineErrorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  inlineErrorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                    color: TrembleTheme.rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadges(MatchProfile match, bool isDark, Color subColor,
      Color iconColor, String lang, bool isGenderBasedColor, String? gender) {
    final items = <Widget>[];

    if (match.school != null) {
      items.add(_PreferencePill(
        icon: LucideIcons.graduationCap,
        label: match.school!,
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.graduatedUniversity != null &&
        match.graduatedUniversity!.isNotEmpty) {
      items.add(_PreferencePill(
        icon: LucideIcons.graduationCap,
        label: match.graduatedUniversity!,
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.lookingForNewJob == true) {
      items.add(_PreferencePill(
        icon: LucideIcons.search,
        label: t('looking_for_new_job', lang),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.hairColor != null) {
      items.add(_PreferencePill(
        icon: Icons.circle,
        label: _formatChipText(t(match.hairColor!, lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.ethnicity != null) {
      items.add(_PreferencePill(
        icon: LucideIcons.users,
        label: t('ethnicity_${match.ethnicity}', lang),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: items,
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

  Widget _buildHobbySection(MatchProfile match, bool isDark, Color textColor,
      Color subColor, bool isGenderBasedColor, String? gender) {
    final lang = ref.watch(appLanguageProvider);
    final userHobbies = match.hobbies;

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
                          label: '${h['emoji']} ${h['name']}',
                          isGenderBased: isGenderBasedColor,
                          gender: gender,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ],
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

  Widget _buildLifestylePreferences(
    MatchProfile match,
    bool isDark,
    Color textColor,
    Color subColor,
    String lang, {
    bool isGenderBasedColor = false,
    String? gender,
  }) {
    final pills = <Widget>[];

    // 1. Basic Lifestyle Traits (Pills)
    if (match.exerciseHabit != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(match.exerciseHabit!),
        label: _formatChipText(t(match.exerciseHabit!, lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.drinkingHabit != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(match.drinkingHabit!),
        label: _formatChipText(t(match.drinkingHabit!, lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    for (final product in match.nicotineUse) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon('nicotine_$product'),
        label: _formatChipText(t('nicotine_$product', lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.sleepSchedule != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(match.sleepSchedule!),
        label: _formatChipText(t(match.sleepSchedule!, lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.petPreference != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(match.petPreference!),
        label: _formatChipText(t(match.petPreference!, lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.childrenPreference != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getLifestyleIcon(match.childrenPreference!),
        label: _formatChipText(t(match.childrenPreference!, lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
      ));
    }
    if (match.religion != null) {
      pills.add(_PreferencePill(
        icon: IconUtils.getReligionIcon(match.religion!),
        label: _formatChipText(t(match.religion!, lang)),
        isGenderBased: isGenderBasedColor,
        gender: gender,
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
            isGenderBasedColor: isGenderBasedColor,
            gender: gender,
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final val = _getPoliticalValue(match.politicalAffiliation);
            String currentText = match.politicalAffiliation != null
                ? t(match.politicalAffiliation!, lang)
                : t('politics_undisclosed', lang);
            if (val > 0 && match.politicalAffiliation != null) {
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
              isGenderBasedColor: isGenderBasedColor,
              gender: gender,
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
    bool isGenderBasedColor = false,
    String? gender,
  }) {
    final accentColor = Theme.of(context).primaryColor;
    final cardBg = TrembleTheme.getPillColor(
      isDark: isDark,
      isGenderBased: isGenderBasedColor,
      gender: gender,
    );
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
}

class _PreferencePill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isGenderBased;
  final String? gender;

  const _PreferencePill({
    this.icon,
    required this.label,
    this.isGenderBased = false,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = TrembleTheme.getPillColor(
      isDark: isDark,
      isGenderBased: isGenderBased,
      gender: gender,
    );
    final pillBorder = pillBg.withValues(alpha: isDark ? 0.6 : 0.4);
    final textColor = isDark ? Colors.white : Colors.black87;

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
            Icon(icon, size: 14, color: textColor.withValues(alpha: 0.5)),
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

// ─── Animated wave button ────────────────────────────────────────────────────
// Shakes briefly then shows a cycling rainbow border when theyWaved flips true.

class _WaveButton extends StatefulWidget {
  final String text;
  final Color color;
  final bool isSent;
  final VoidCallback? onTap;
  final bool theyWaved;

  const _WaveButton({
    required this.text,
    required this.color,
    required this.isSent,
    this.onTap,
    this.theyWaved = false,
  });

  @override
  State<_WaveButton> createState() => _WaveButtonState();
}

class _WaveButtonState extends State<_WaveButton>
    with TickerProviderStateMixin {
  static const _rainbow = [
    Color(0xFFFF004D),
    Color(0xFFFF7700),
    Color(0xFFFFE600),
    Color(0xFF00E676),
    Color(0xFF2979FF),
    Color(0xFFD500F9),
    Color(0xFFFF004D),
  ];

  late final AnimationController _shakeCtrl;
  late final AnimationController _rainbowCtrl;
  late final Animation<double> _shakeX;
  bool _rainbowActive = false;
  // True when the current shake was triggered by the user tapping Wave
  // (not by theyWaved), so rainbow doesn't activate afterwards.
  bool _shakeForSent = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -9.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);
    _rainbowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shakeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        final forSent = _shakeForSent;
        _shakeForSent = false;
        if (!forSent) {
          setState(() => _rainbowActive = true);
          _rainbowCtrl.repeat();
        }
      }
    });
    if (widget.theyWaved) _shakeCtrl.forward();
  }

  @override
  void didUpdateWidget(_WaveButton old) {
    super.didUpdateWidget(old);
    if (!old.isSent && widget.isSent) {
      _shakeForSent = true;
      _shakeCtrl.forward(from: 0);
    }
    if (!old.theyWaved && widget.theyWaved) {
      _shakeForSent = false;
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _rainbowCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isSent || widget.onTap == null) return;
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = widget.isSent ? Colors.amber : widget.color;
    final displayText = widget.isSent ? 'Wave sent' : widget.text;

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeCtrl, _rainbowCtrl]),
      builder: (_, __) => Transform.translate(
        offset: Offset(_shakeCtrl.isAnimating ? _shakeX.value : 0, 0),
        child: GestureDetector(
          onTap: widget.isSent ? null : _handleTap,
          child: CustomPaint(
            foregroundPainter: _rainbowActive
                ? _RainbowBorderPainter(_rainbowCtrl.value, _rainbow)
                : null,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(28),
                border: _rainbowActive
                    ? null
                    : Border.all(color: displayColor, width: 2),
              ),
              child: Text(
                displayText,
                style: GoogleFonts.instrumentSans(
                  color: _rainbowActive ? Colors.white : displayColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RainbowBorderPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _RainbowBorderPainter(this.progress, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    final shader = SweepGradient(
      colors: colors,
      startAngle: 0,
      endAngle: 3.14159 * 2,
      transform: GradientRotation(progress * 3.14159 * 2),
    ).createShader(rect);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_RainbowBorderPainter old) => old.progress != progress;
}
