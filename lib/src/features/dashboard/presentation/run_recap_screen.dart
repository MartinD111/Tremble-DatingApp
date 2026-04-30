import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme.dart';
import '../../../shared/ui/glass_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../data/run_club_repository.dart';
import '../../../core/translations.dart';

class RunRecapScreen extends ConsumerWidget {
  const RunRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final lang = ref.watch(appLanguageProvider);
    if (user == null) return const SizedBox.shrink();

    final activeAsync = ref.watch(recentRunCrossesProvider(user.id));
    final historyAsync = ref.watch(runHistoryProvider(user.id));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A18),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Icon(
                            LucideIcons.arrowLeft,
                            size: 22,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          t('run_recap', lang).toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: TrembleTheme.rose,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t('active_signals', lang).toUpperCase()}: ${activeAsync.valueOrNull?.length ?? 0}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t('momentum_rule', lang)}: ${t('momentum_desc', lang)}',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            color: TrembleTheme.rose.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Active Section ──────────────────────────────────────
            activeAsync.when(
              data: (docs) => docs.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final userIds =
                                List<String>.from(data['userIds'] ?? []);
                            final partnerId = userIds.firstWhere(
                              (id) => id != user.id,
                              orElse: () => '',
                            );
                            if (partnerId.isEmpty)
                              return const SizedBox.shrink();
                            final signals =
                                data['signals'] as Map<String, dynamic>? ?? {};
                            final iWaved = signals[user.id] == true;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecapItem(
                                partnerId: partnerId,
                                iWaved: iWaved,
                                onWave: () => ref
                                    .read(runClubRepositoryProvider)
                                    .sendWave(doc.id, user.id),
                              ),
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── History Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('history', lang).toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('history_subtitle', lang),
                      style: GoogleFonts.instrumentSans(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── History Section ──────────────────────────────────────
            historyAsync.when(
              data: (docs) {
                // Filter out those who are currently active to avoid duplicates
                final activeIds = activeAsync.valueOrNull
                        ?.map((d) => (d.data()
                            as Map<String, dynamic>)['userIds'] as List)
                        .expand((ids) => ids)
                        .where((id) => id != user.id)
                        .toSet() ??
                    {};

                final historyDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userIds = List<String>.from(data['userIds'] ?? []);
                  final partnerId = userIds.firstWhere((id) => id != user.id,
                      orElse: () => '');
                  return !activeIds.contains(partnerId);
                }).toList();

                if (historyDocs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        t('no_encounters_history', lang),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = historyDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final userIds =
                            List<String>.from(data['userIds'] ?? []);
                        final partnerId = userIds.firstWhere(
                            (id) => id != user.id,
                            orElse: () => '');
                        if (partnerId.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecapItem(
                            partnerId: partnerId,
                            iWaved: false,
                            onWave: null, // Disabled in history
                            isHistory: true,
                          ),
                        );
                      },
                      childCount: historyDocs.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        color: TrembleTheme.rose, strokeWidth: 1),
                  ),
                ),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _RecapItem extends ConsumerWidget {
  final String partnerId;
  final bool iWaved;
  final VoidCallback? onWave;
  final bool isHistory;

  const _RecapItem({
    required this.partnerId,
    required this.iWaved,
    this.onWave,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(partnerId));
    final lang = ref.watch(appLanguageProvider);

    return profileAsync.when(
      data: (profile) => GestureDetector(
        onTap: () => context.push('/profile/${partnerId}'),
        child: ColorFiltered(
          colorFilter: isHistory
              ? const ColorFilter.matrix([
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            borderColor:
                Colors.white.withValues(alpha: isHistory ? 0.03 : 0.08),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: TrembleTheme.rose.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHistory ? LucideIcons.ghost : LucideIcons.zap,
                    color: TrembleTheme.rose
                        .withValues(alpha: isHistory ? 0.4 : 1.0),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${profile.name}, ${profile.age}',
                    style: TrembleTheme.displayFont(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: isHistory ? 0.4 : 1.0),
                    ),
                  ),
                ),
                if (isHistory)
                  Text(
                    t('missed', lang).toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  )
                else if (iWaved)
                  Text(
                    t('run_wave_sent', lang).toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: TrembleTheme.rose.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onWave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: TrembleTheme.rose.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.hand,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            t('wave', lang),
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
      ),
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
