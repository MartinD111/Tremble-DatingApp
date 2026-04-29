import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tremble/src/shared/ui/glass_card.dart';
import 'package:tremble/src/shared/ui/tremble_circle_button.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:tremble/src/features/auth/data/auth_repository.dart';
import 'package:tremble/src/features/match/application/match_service.dart';
import 'package:tremble/src/features/match/domain/match.dart' as wave_match;
import 'package:tremble/src/features/safety/presentation/widgets/ugc_action_sheet.dart';
import 'package:tremble/src/core/theme.dart';
import 'package:tremble/src/core/translations.dart';
import 'package:tremble/src/core/utils/icon_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: maps HistoryFilter → display label translation key
// ─────────────────────────────────────────────────────────────────────────────
String _historyKey(wave_match.HistoryFilter filter) => switch (filter) {
      wave_match.HistoryFilter.lastWeek => 'history_last_week',
      wave_match.HistoryFilter.lastMonth => 'history_last_month',
      wave_match.HistoryFilter.last3Months => 'history_last_3months',
      wave_match.HistoryFilter.last12Months => 'history_last_12months',
      wave_match.HistoryFilter.all => 'history_all',
    };

// ─────────────────────────────────────────────────────────────────────────────
// Helper: maps MatchType → display label translation key
// ─────────────────────────────────────────────────────────────────────────────
String _tabKey(wave_match.MatchType? type) => switch (type) {
      null => 'match_tab_all',
      wave_match.MatchType.standard => 'match_tab_standard',
      wave_match.MatchType.event => 'match_tab_event',
      wave_match.MatchType.activity => 'match_tab_activity',
      wave_match.MatchType.gym => 'match_tab_gym',
    };

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  final Set<String> _removedIds = {};

  // F3 — Tab + Filter State
  late final TabController _tabController;
  wave_match.HistoryFilter _historyFilter = wave_match.HistoryFilter.all;

  // Tab index → MatchType (null = All)
  static const List<wave_match.MatchType?> _tabs = [
    null,
    wave_match.MatchType.standard,
    wave_match.MatchType.event,
    wave_match.MatchType.activity,
    wave_match.MatchType.gym,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
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

  void _showHelpDialog() {
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.helpCircle,
                  color: Theme.of(context).primaryColor, size: 40),
              const SizedBox(height: 16),
              Text(
                t('matches_help_title', lang),
                style: GoogleFonts.instrumentSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t('matches_help_body', lang),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  t('ok', lang),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryFilterSheet(String lang, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('history_filter_label', lang),
              style: GoogleFonts.instrumentSans(
                  color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...wave_match.HistoryFilter.values.map((filter) {
              final selected = filter == _historyFilter;
              return GestureDetector(
                onTap: () {
                  setState(() => _historyFilter = filter);
                  Navigator.pop(ctx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? primary
                          : Colors.white.withValues(alpha: 0.08),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t(_historyKey(filter), lang),
                          style: GoogleFonts.instrumentSans(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle, color: primary, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesStreamProvider);
    final activeMatchesAsync = ref.watch(activeMatchesStreamProvider);
    final user = ref.watch(authStateProvider);
    final isPremium = user?.isPremium == true;
    final lang = ref.watch(appLanguageProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final dimColor = isDark ? Colors.white24 : Colors.black26;
    final primary = Theme.of(context).primaryColor;

    final activeType = _tabs[_tabController.index];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t('matches_title', lang),
                    style: TrembleTheme.displayFont(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                // History filter pill
                GestureDetector(
                  onTap: () => _showHistoryFilterSheet(lang, primary),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _historyFilter == wave_match.HistoryFilter.all
                          ? Colors.white.withValues(alpha: 0.08)
                          : primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _historyFilter == wave_match.HistoryFilter.all
                            ? Colors.white.withValues(alpha: 0.15)
                            : primary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendarDays,
                            size: 13,
                            color:
                                _historyFilter == wave_match.HistoryFilter.all
                                    ? subtextColor
                                    : primary),
                        const SizedBox(width: 5),
                        Text(
                          t(_historyKey(_historyFilter), lang),
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                _historyFilter == wave_match.HistoryFilter.all
                                    ? subtextColor
                                    : primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TrembleCircleButton(
                  icon: LucideIcons.helpCircle,
                  onPressed: _showHelpDialog,
                  size: 40,
                ),
                const SizedBox(width: 8),
                TrembleCircleButton(
                  icon: _isEditMode ? LucideIcons.check : LucideIcons.pencil,
                  onPressed: () => setState(() => _isEditMode = !_isEditMode),
                  color: _isEditMode ? primary : null,
                  size: 40,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Category Tabs ──────────────────────────────────────────
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
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.instrumentSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: _tabs
                  .map((type) => Tab(text: t(_tabKey(type), lang)))
                  .toList(),
            ),
          ),

          const SizedBox(height: 4),

          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: matchesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: primary,
                    strokeWidth: 2,
                  ),
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
                data: (allProfiles) {
                  final activeMatches = activeMatchesAsync.value ?? [];
                  final cutoff = _historyFilter.cutoffDate;

                  // Build display items
                  final matchesToDisplay = <_MatchDisplayItem>[];
                  for (final profile in allProfiles) {
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

                    // Apply time filter
                    if (matchData.createdAt.isBefore(cutoff)) continue;

                    // Apply category filter
                    if (activeType != null && matchData.matchType != activeType)
                      continue;

                    if (isPremium || matchData.isFound) {
                      matchesToDisplay.add(_MatchDisplayItem(
                        profile: profile,
                        match: matchData,
                        isLocked: false,
                      ));
                    } else if (!matchData.isFound) {
                      matchesToDisplay.add(_MatchDisplayItem(
                        profile: profile,
                        match: matchData,
                        isLocked: true,
                      ));
                    }
                  }

                  final filteredItems = matchesToDisplay
                      .where((item) => !_removedIds.contains(item.profile.id))
                      .toList();

                  if (filteredItems.isEmpty) {
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
                    itemCount: filteredItems.length,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
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
                                              // F3 — Match type badge
                                              if (item.match.matchType !=
                                                  wave_match
                                                      .MatchType.standard) ...[
                                                const SizedBox(width: 8),
                                                _MatchTypeBadge(
                                                  type: item.match.matchType,
                                                  primary: primary,
                                                ),
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
// _MatchTypeBadge — small inline badge for non-standard match types
// ─────────────────────────────────────────────────────────────────────────────
class _MatchTypeBadge extends StatelessWidget {
  final wave_match.MatchType type;
  final Color primary;

  const _MatchTypeBadge({required this.type, required this.primary});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (type) {
      wave_match.MatchType.event => ('Event', LucideIcons.calendar),
      wave_match.MatchType.activity => ('Activity', LucideIcons.activitySquare),
      wave_match.MatchType.gym => ('Gym', LucideIcons.dumbbell),
      wave_match.MatchType.standard => ('Standard', LucideIcons.zap),
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
  final wave_match.Match match;
  final bool isLocked;

  _MatchDisplayItem({
    required this.profile,
    required this.match,
    required this.isLocked,
  });
}
