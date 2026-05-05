import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tremble/src/shared/ui/glass_card.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/match/domain/match.dart' as wave_match;
import 'package:tremble/src/features/safety/presentation/widgets/ugc_action_sheet.dart';
import 'package:tremble/src/core/theme.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/core/utils/icon_utils.dart';
import 'package:tremble/src/features/gym/application/gym_mode_controller.dart';
import 'package:tremble/src/features/gym/presentation/gym_mode_sheet.dart';
import 'package:tremble/src/features/dashboard/presentation/home_screen.dart'
    show showModeInfoDialog, RadarModeKind;

enum MatchSection { gym, event, run, matches }

String _historyKey(HistoryFilter filter) => switch (filter) {
      HistoryFilter.lastWeek => 'history_last_week',
      HistoryFilter.lastMonth => 'history_last_month',
      HistoryFilter.last3Months => 'history_last_3months',
      HistoryFilter.last12Months => 'history_last_12months',
      HistoryFilter.all => 'history_all',
    };

final matchSectionProvider =
    StateProvider<MatchSection>((ref) => MatchSection.matches);

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  final Set<String> _removedIds = {};

  late final TabController _tabController;

  static const _tabs = <(String, String?)>[
    ('match_tab_all', null),
    ('match_tab_event', 'event'),
    ('match_tab_activity', 'activity'),
    ('match_tab_gym', 'gym'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final current = ref.read(matchFilterProvider);
      ref.read(matchFilterProvider.notifier).state = MatchFilterState(
        historyFilter: current.historyFilter,
        matchType: _tabs[_tabController.index].$2,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openProfile(MatchProfile match) {
    context.push('/profile?showActions=false', extra: match);
  }

  void _removeMatch(String matchId, String name) {
    final lang = ref.read(appLanguageProvider);
    setState(() => _removedIds.add(matchId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('removed_msg', lang).replaceAll('{name}', name)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: t('undo', lang),
          textColor: Theme.of(context).primaryColor,
          onPressed: () => setState(() => _removedIds.remove(matchId)),
        ),
      ),
    );
  }

  void _setHistoryFilter(HistoryFilter filter) {
    final current = ref.read(matchFilterProvider);
    ref.read(matchFilterProvider.notifier).state = MatchFilterState(
      historyFilter: filter,
      matchType: current.matchType,
    );
  }

  // ── Section picker — bottom sheet ────────────────────────────────────────
  /// Resolves the gym pill accent color based on gender-based mode setting.
  /// male → blue, female → rose, other/null → theme primary.
  /// Always returns a color with sufficient contrast on the pill background.
  static Color _resolveGymPillColor({
    required BuildContext context,
    required String? gender,
    required bool isGenderBased,
    required Color fallback,
  }) {
    if (!isGenderBased) return fallback;
    return switch (gender?.toLowerCase()) {
      'male' => const Color(0xFF4A9EFF),
      'female' => const Color(0xFFF4436C),
      _ => fallback,
    };
  }

  void _showSectionPicker() {
    final lang = ref.read(appLanguageProvider);
    final primary = Theme.of(context).primaryColor;
    final activeSection = ref.read(matchSectionProvider);
    final user = ref.read(authStateProvider);
    final gymPillColor = _resolveGymPillColor(
      context: context,
      gender: user?.gender,
      isGenderBased: user?.isGenderBasedColor ?? false,
      fallback: primary,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => _SectionPickerSheet(
        lang: lang,
        primary: primary,
        gymPillColor: gymPillColor,
        activeSection: activeSection,
        onSelect: (section) {
          ref.read(matchSectionProvider.notifier).state = section;
          final tabIndex = switch (section) {
            MatchSection.gym => 3,
            MatchSection.event => 1,
            MatchSection.run => 2,
            MatchSection.matches => 0,
          };
          _tabController.animateTo(tabIndex);
          final current = ref.read(matchFilterProvider);
          ref.read(matchFilterProvider.notifier).state = MatchFilterState(
            historyFilter: current.historyFilter,
            matchType: _tabs[tabIndex].$2,
          );
          Navigator.pop(sheetCtx);
        },
        onOpenGymSheet: () {
          Navigator.pop(sheetCtx);
          GymModeSheet.show(context);
        },
      ),
    );
  }

  // ── Filter bottom sheet ───────────────────────────────────────────────────
  void _showFilterMenu(BuildContext ctx) {
    final lang = ref.read(appLanguageProvider);
    final activeFilter = ref.read(matchFilterProvider).historyFilter;
    final primary = Theme.of(ctx).primaryColor;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white60 : Colors.black54;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1A18).withValues(alpha: 0.97)
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
            padding: EdgeInsets.fromLTRB(
                0, 12, 0, MediaQuery.of(sheetCtx).padding.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: HistoryFilter.values.map((filter) {
                    final selected = activeFilter == filter;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 2),
                      leading: Icon(
                        selected ? LucideIcons.checkCircle : LucideIcons.circle,
                        size: 16,
                        color: selected ? primary : subtextColor,
                      ),
                      title: Text(
                        t(_historyKey(filter), lang),
                        style: GoogleFonts.instrumentSans(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? textColor : subtextColor,
                        ),
                      ),
                      onTap: () {
                        _setHistoryFilter(filter);
                        Navigator.pop(sheetCtx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Help dialog ───────────────────────────────────────────────────────────
  void _showHelpDialog() {
    final lang = ref.read(appLanguageProvider);
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white54 : Colors.black54;

    final sections = [
      (LucideIcons.dumbbell, 'section_your_gym', 'section_your_gym_desc'),
      (LucideIcons.calendar, 'section_your_event', 'section_your_event_desc'),
      (LucideIcons.personStanding, 'section_your_run', 'section_your_run_desc'),
      (LucideIcons.users, 'section_your_matches', 'section_your_matches_desc'),
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          opacity: isDark ? 0.2 : 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.helpCircle, color: primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    t('matches_help_title', lang),
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...sections.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(s.$1, size: 14, color: primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t(s.$2, lang),
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t(s.$3, lang),
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 12,
                                  color: subtextColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    t('ok', lang),
                    style:
                        TextStyle(color: primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredMatchesProvider);
    final activeMatchesAsync = ref.watch(activeMatchesStreamProvider);
    final activeFilter = ref.watch(matchFilterProvider);
    final user = ref.watch(authStateProvider);
    final isPremium = user?.isPremium == true;
    final lang = ref.watch(appLanguageProvider);
    final gymState = ref.watch(gymModeControllerProvider);
    final activeSection = ref.watch(matchSectionProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final dimColor = isDark ? Colors.white24 : Colors.black26;
    final primary = Theme.of(context).primaryColor;

    // Gender-based pill color: when enabled, derive from the user's gender so
    // the "Your Gym" pill stays readable across dark, light, and themed modes.
    // Falls back to the standard theme primary when the feature is off.
    final Color gymPillColor = _resolveGymPillColor(
      context: context,
      gender: user?.gender,
      isGenderBased: user?.isGenderBasedColor ?? false,
      fallback: primary,
    );

    final sectionLabel = switch (activeSection) {
      MatchSection.gym => t('section_your_gym', lang),
      MatchSection.event => t('section_your_event', lang),
      MatchSection.run => t('section_your_run', lang),
      MatchSection.matches => t('section_your_matches', lang),
    };

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                // Title — tap opens bottom sheet picker
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showSectionPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sectionLabel,
                        style: TrembleTheme.displayFont(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      // Green dot when gym mode active
                      if (activeSection == MatchSection.gym &&
                          gymState.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // Mode activation icon — matches current section
                _ModeIconButton(
                  section: activeSection,
                  lang: lang,
                ),

                IconButton(
                  icon: Icon(LucideIcons.helpCircle,
                      size: 20, color: subtextColor),
                  onPressed: _showHelpDialog,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(LucideIcons.slidersHorizontal,
                        size: 20, color: subtextColor),
                    onPressed: () => _showFilterMenu(ctx),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isEditMode ? LucideIcons.check : LucideIcons.pencil,
                    size: 20,
                    color: _isEditMode ? primary : subtextColor,
                  ),
                  onPressed: () => setState(() => _isEditMode = !_isEditMode),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Active filter period pill
          if (activeFilter.historyFilter != HistoryFilter.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: GestureDetector(
                onTap: () => _setHistoryFilter(HistoryFilter.all),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.clock3, size: 11, color: primary),
                      const SizedBox(width: 5),
                      Text(
                        t(_historyKey(activeFilter.historyFilter), lang),
                        style: GoogleFonts.instrumentSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.x, size: 10, color: primary),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // ── Sub-header bar ───────────────────────────────────────────
          // "Your Matches" → tab bar; others → context bar
          if (activeSection == MatchSection.matches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: primary,
                indicatorWeight: 2,
                labelColor: primary,
                unselectedLabelColor: subtextColor,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.instrumentSans(
                    fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.instrumentSans(
                    fontSize: 13, fontWeight: FontWeight.w500),
                tabs: _tabs.map((tab) => Tab(text: t(tab.$1, lang))).toList(),
              ),
            )
          else if (activeSection == MatchSection.gym)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _SectionContextBar(
                section: activeSection,
                gymState: gymState,
                lang: lang,
                primary: primary,
                gymPillColor: gymPillColor,
                onChangeGym: () => GymModeSheet.show(context),
              ),
            ),

          const SizedBox(height: 8),

          // ── Match List ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: filteredAsync.when(
                loading: () => Center(
                  child:
                      CircularProgressIndicator(color: primary, strokeWidth: 2),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.wifiOff, size: 48, color: dimColor),
                      const SizedBox(height: 12),
                      Text(t('loading_error', lang),
                          style: GoogleFonts.instrumentSans(
                              color: subtextColor, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(matchesStreamProvider),
                        child: Text(t('try_again', lang),
                            style: TextStyle(color: primary)),
                      ),
                    ],
                  ),
                ),
                data: (filteredProfiles) {
                  final activeMatches = activeMatchesAsync.value ?? [];

                  final matchesToDisplay = <_MatchDisplayItem>[];
                  for (final profile in filteredProfiles) {
                    final matchData = activeMatches.firstWhere(
                      (m) => m.getPartnerId(user?.id ?? '') == profile.id,
                      orElse: () => wave_match.Match(
                        id: '',
                        userIds: [],
                        createdAt: DateTime.now(),
                        seenBy: [],
                        status: 'expired',
                        isFound: true,
                      ),
                    );

                    if (isPremium ||
                        matchData.isFound ||
                        profile.matchType == 'event') {
                      matchesToDisplay.add(
                          _MatchDisplayItem(profile: profile, isLocked: false));
                    } else if (!matchData.isFound) {
                      matchesToDisplay.add(
                          _MatchDisplayItem(profile: profile, isLocked: true));
                    }
                  }

                  final visibleItems = matchesToDisplay
                      .where((item) => !_removedIds.contains(item.profile.id))
                      .toList();

                  if (visibleItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.users, size: 48, color: dimColor),
                          const SizedBox(height: 12),
                          Text(
                            t('no_matches', lang),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.instrumentSans(
                                color: subtextColor, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: visibleItems.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];
                      final profile = item.profile;
                      final isLocked = item.isLocked;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: (isLocked || _isEditMode)
                              ? null
                              : () => _openProfile(profile),
                          child: Opacity(
                            opacity: isLocked ? 0.6 : 1.0,
                            child: GlassCard(
                              opacity: 0.15,
                              borderRadius: 999,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  if (!isLocked)
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundImage:
                                          NetworkImage(profile.imageUrl),
                                      backgroundColor: Colors.white12,
                                    )
                                  else
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.06),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.12)),
                                      ),
                                      child: const Icon(LucideIcons.user,
                                          color: Colors.white24, size: 28),
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isLocked
                                              ? t('hidden_person', lang)
                                              : profile.name,
                                          style: TrembleTheme.displayFont(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: textColor,
                                          ),
                                        ),
                                        if (!isLocked) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                '${profile.age} ${t('years', lang)}',
                                                style:
                                                    GoogleFonts.instrumentSans(
                                                  fontSize: 13,
                                                  color: subtextColor,
                                                ),
                                              ),
                                              if (profile.birthDate !=
                                                  null) ...[
                                                const SizedBox(width: 8),
                                                Icon(
                                                  ZodiacUtils.getZodiacIcon(
                                                    ZodiacUtils.getZodiacSign(
                                                        profile.birthDate),
                                                  ),
                                                  size: 14,
                                                  color: subtextColor
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ],
                                              if (profile.matchType !=
                                                  'standard') ...[
                                                const SizedBox(width: 8),
                                                _MatchTypeBadge(
                                                  type: profile.matchType,
                                                  primary: primary,
                                                ),
                                              ],
                                              if (profile.isTraveler) ...[
                                                const SizedBox(width: 6),
                                                const Text('🌴',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isLocked)
                                    const Icon(LucideIcons.lock,
                                        color: Colors.white24, size: 16)
                                  else if (_isEditMode)
                                    GestureDetector(
                                      onTap: () => _removeMatch(
                                          profile.id, profile.name),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.red.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.red
                                                  .withValues(alpha: 0.4)),
                                        ),
                                        child: const Icon(LucideIcons.x,
                                            color: Colors.red, size: 18),
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: Icon(LucideIcons.moreVertical,
                                          color: subtextColor),
                                      onPressed: () {
                                        UgcActionSheet.show(
                                          context,
                                          targetUid: profile.id,
                                          targetName: profile.name,
                                        );
                                      },
                                    ),
                                  const SizedBox(width: 5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ModeIconButton — dumbbell/calendar/person icon in header that opens the
// mode info popup for the current section (gym/event/run).
// Hidden when in the Matches section (no mode to activate).
// ─────────────────────────────────────────────────────────────────────────────
class _ModeIconButton extends ConsumerWidget {
  final MatchSection section;
  final String lang;

  const _ModeIconButton({
    required this.section,
    required this.lang,
  });

  static const _gold = Color(0xFFF5C842);
  static const _rose = Color(0xFFF4436C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section == MatchSection.matches) return const SizedBox.shrink();

    final gymState = ref.watch(gymModeControllerProvider);
    final runState = ref.watch(runModeControllerProvider);
    final eventState = ref.watch(eventModeControllerProvider);

    final (icon, modeKind) = switch (section) {
      MatchSection.gym => (LucideIcons.dumbbell, RadarModeKind.gym),
      MatchSection.event => (LucideIcons.calendar, RadarModeKind.event),
      MatchSection.run => (LucideIcons.footprints, RadarModeKind.run),
      MatchSection.matches => (LucideIcons.users, RadarModeKind.gym),
    };

    final isActive = switch (section) {
      MatchSection.gym => gymState.isActive,
      MatchSection.run => runState.isActive,
      MatchSection.event => eventState.isActive,
      MatchSection.matches => false,
    };

    final activeColor = switch (section) {
      MatchSection.gym || MatchSection.event => _gold,
      MatchSection.run => _rose,
      MatchSection.matches => _gold,
    };

    final iconColor = isActive
        ? activeColor
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          // Active circular border around icon
          if (isActive)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
            ),
          Icon(icon, size: 20, color: iconColor),
          if (isActive)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A1A18)
                        : Colors.white,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        showModeInfoDialog(
          context: context,
          ref: ref,
          mode: modeKind,
          lang: lang,
          isActive: isActive,
          onActivate: () {
            switch (section) {
              case MatchSection.gym:
                GymModeSheet.show(context);
              case MatchSection.run:
                ref.read(runModeControllerProvider.notifier).activate();
              case MatchSection.event:
                ref.read(eventModeControllerProvider.notifier).activate(
                      eventId: 'default',
                      eventName: t('section_your_event', lang),
                    );
              case MatchSection.matches:
                break;
            }
          },
          onDeactivate: () {
            switch (section) {
              case MatchSection.gym:
                ref.read(gymModeControllerProvider.notifier).deactivate();
              case MatchSection.run:
                ref.read(runModeControllerProvider.notifier).deactivate();
              case MatchSection.event:
                ref.read(eventModeControllerProvider.notifier).deactivate();
              case MatchSection.matches:
                break;
            }
          },
        );
      },
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionPickerSheet — bottom sheet with 4 section options
// ─────────────────────────────────────────────────────────────────────────────
class _SectionPickerSheet extends ConsumerWidget {
  final String lang;
  final Color primary;
  final Color gymPillColor;
  final MatchSection activeSection;
  final ValueChanged<MatchSection> onSelect;
  final VoidCallback onOpenGymSheet;

  const _SectionPickerSheet({
    required this.lang,
    required this.primary,
    required this.gymPillColor,
    required this.activeSection,
    required this.onSelect,
    required this.onOpenGymSheet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymState = ref.watch(gymModeControllerProvider);
    final runState = ref.watch(runModeControllerProvider);
    final eventState = ref.watch(eventModeControllerProvider);

    final items = [
      (
        MatchSection.gym,
        LucideIcons.dumbbell,
        'section_your_gym',
        gymState.isActive
      ),
      (
        MatchSection.event,
        LucideIcons.calendar,
        'section_your_event',
        eventState.isActive
      ),
      (
        MatchSection.run,
        LucideIcons.footprints,
        'section_your_run',
        runState.isActive
      ),
      (MatchSection.matches, LucideIcons.users, 'section_your_matches', false),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A18).withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: EdgeInsets.fromLTRB(
              0, 12, 0, MediaQuery.of(context).padding.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              ...List.generate(items.length, (i) {
                final (section, icon, labelKey, modeActive) = items[i];
                final isSelected = section == activeSection;
                final isGym = section == MatchSection.gym;
                final isLast = i == items.length - 1;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => onSelect(section),
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            // Icon badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primary.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                size: 18,
                                color: isSelected ? primary : Colors.white38,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                t(labelKey, lang),
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ),
                            // Active green dot
                            if (modeActive)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            // Selected checkmark
                            if (isSelected)
                              Icon(LucideIcons.check, size: 16, color: primary),
                          ],
                        ),
                      ),
                    ),

                    // Gym sub-row: shown only under gym option
                    if (isGym)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(78, 0, 24, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: gymState.isActive
                                  ? _GymActivePill(
                                      gymName: gymState.activeGymName ?? '')
                                  : _GymEmptyPill(
                                      lang: lang,
                                      onTap: onOpenGymSheet,
                                      accentColor: gymPillColor,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onOpenGymSheet,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.10)),
                                ),
                                child: const Icon(LucideIcons.listFilter,
                                    size: 13, color: Colors.white38),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Divider (except last)
                    if (!isLast)
                      Divider(
                        height: 0,
                        thickness: 0.5,
                        color: Colors.white.withValues(alpha: 0.06),
                        indent: 24,
                        endIndent: 24,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionContextBar — pill + filter icon below header for gym/event/run
// ─────────────────────────────────────────────────────────────────────────────
class _SectionContextBar extends StatelessWidget {
  final MatchSection section;
  final GymModeState gymState;
  final String lang;
  final Color primary;
  final Color gymPillColor;
  final VoidCallback onChangeGym;

  const _SectionContextBar({
    required this.section,
    required this.gymState,
    required this.lang,
    required this.primary,
    required this.gymPillColor,
    required this.onChangeGym,
  });

  @override
  Widget build(BuildContext context) {
    if (section == MatchSection.gym) {
      return Row(
        children: [
          Expanded(
            child: gymState.isActive
                ? _GymActivePill(gymName: gymState.activeGymName ?? '')
                : _GymEmptyPill(
                    lang: lang,
                    onTap: onChangeGym,
                    accentColor: gymPillColor,
                  ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onChangeGym,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(LucideIcons.listFilter,
                  size: 14, color: Colors.white38),
            ),
          ),
        ],
      );
    }

    if (section == MatchSection.event || section == MatchSection.run) {
      return const SizedBox.shrink();
    }

    final (icon, labelKey) = switch (section) {
      _ => (LucideIcons.users, 'section_your_matches'),
    };

    return Row(
      children: [
        Icon(icon, size: 14, color: primary.withValues(alpha: 0.7)),
        const SizedBox(width: 7),
        Text(
          t(labelKey, lang),
          style: GoogleFonts.instrumentSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: primary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gym pills
// ─────────────────────────────────────────────────────────────────────────────
class _GymActivePill extends StatelessWidget {
  final String gymName;
  const _GymActivePill({required this.gymName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Colors.greenAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              gymName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymEmptyPill extends StatelessWidget {
  final String lang;
  final VoidCallback onTap;
  // When isGenderBasedColor is on, caller passes the resolved gender color.
  // Falls back to a neutral theme-aware appearance when null.
  final Color? accentColor;

  const _GymEmptyPill({
    required this.lang,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = accentColor;

    final bgColor = accent != null
        ? accent.withValues(alpha: 0.10)
        : cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final borderColor = accent != null
        ? accent.withValues(alpha: 0.35)
        : cs.onSurface.withValues(alpha: 0.15);
    final iconColor = accent != null
        ? accent.withValues(alpha: 0.8)
        : cs.onSurface.withValues(alpha: 0.5);
    final textColor =
        accent != null ? accent : cs.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPin, size: 11, color: iconColor),
            const SizedBox(width: 5),
            Text(
              t('no_gym_selected', lang),
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MatchTypeBadge
// ─────────────────────────────────────────────────────────────────────────────
class _MatchTypeBadge extends StatelessWidget {
  final String type;
  final Color primary;

  const _MatchTypeBadge({required this.type, required this.primary});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (type) {
      'event' => ('Event', LucideIcons.calendar),
      'activity' => ('Activity', LucideIcons.activitySquare),
      'gym' => ('Gym', LucideIcons.dumbbell),
      _ => ('Standard', LucideIcons.zap),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.instrumentSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MatchDisplayItem
// ─────────────────────────────────────────────────────────────────────────────
class _MatchDisplayItem {
  final MatchProfile profile;
  final bool isLocked;
  _MatchDisplayItem({required this.profile, required this.isLocked});
}
