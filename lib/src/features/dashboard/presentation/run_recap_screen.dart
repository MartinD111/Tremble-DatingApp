import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/skeleton.dart';
import '../../../shared/ui/warmth_empty_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../matches/data/match_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/public_profile.dart';
import '../../recap/data/viewed_recaps_repository.dart';
import '../../recap/providers/recap_ttl_provider.dart';
import '../data/run_club_repository.dart';
import '../../../core/translations.dart';
import '../../safety/screen_protection_service.dart';

@visibleForTesting
MatchProfile runRecapMatchProfileFromPublicProfile(PublicProfile profile) {
  return MatchProfile(
    id: profile.id,
    name: profile.name,
    age: profile.age,
    imageUrl: profile.primaryPhotoUrl,
    photoUrls: profile.photoUrls,
    hobbies: profile.hobbies,
    bio: '',
    matchType: 'activity',
    lookingFor: profile.lookingFor == null ? const [] : [profile.lookingFor!],
    isTraveler: profile.isTraveler,
  );
}

@visibleForTesting
List<String> safeRecapUserIdsFromData(Map<String, dynamic> data) {
  final rawUserIds = data['userIds'];
  if (rawUserIds is! List) return const [];
  return rawUserIds.whereType<String>().toList(growable: false);
}

@visibleForTesting
Widget recapProviderErrorContent(Object error, StackTrace stackTrace) {
  debugPrint('RecapProvider error: $error\n$stackTrace');
  return Center(
    child: Text(
      'Something went wrong.',
      style: GoogleFonts.lora(
        color: const Color(0xFF6B6B63),
      ),
    ),
  );
}

SliverToBoxAdapter _recapProviderErrorSliver(
  Object error,
  StackTrace stackTrace,
) {
  return SliverToBoxAdapter(
    child: SizedBox(
      height: 120,
      child: recapProviderErrorContent(error, stackTrace),
    ),
  );
}

class RunRecapScreen extends ConsumerStatefulWidget {
  const RunRecapScreen({super.key});

  @override
  ConsumerState<RunRecapScreen> createState() => _RunRecapScreenState();
}

class _RunRecapScreenState extends ConsumerState<RunRecapScreen> {
  bool _isRecording = false;
  late final void Function(bool) _recordingListener;

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
    _markViewedRecapsOnClose();
    ScreenProtectionService.removeRecordingListener();
    ScreenProtectionService.disable();
    super.dispose();
  }

  void _markViewedRecapsOnClose() {
    final user = ref.read(authStateProvider);
    if (user == null || ref.read(effectiveIsPremiumProvider)) return;

    final activeDocs =
        ref.read(recentRunCrossesProvider(user.id)).valueOrNull ?? const [];
    final recapIds = activeDocs.map((doc) => doc.id);

    unawaited(
      ref
          .read(viewedRecapsRepositoryProvider)
          .markViewedRecapsOnClose(
            uid: user.id,
            recapIds: recapIds,
            type: 'run',
          )
          .catchError(
        (Object e, StackTrace st) {
          debugPrint('viewedRecaps write failed: $e\n$st');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) return const RecordingShield();

    final user = ref.watch(authStateProvider);
    final lang = ref.watch(appLanguageProvider);
    final effectivePremium = ref.watch(effectiveIsPremiumProvider);
    if (user == null) return const SizedBox.shrink();

    final activeAsync = ref.watch(recentRunCrossesProvider(user.id));
    final historyAsync = ref.watch(runHistoryProvider(user.id));
    final viewedRecapIds = effectivePremium
        ? const <String>{}
        : ref.watch(viewedRecapIdsProvider(user.id)).valueOrNull ??
            const <String>{};

    return Scaffold(
      backgroundColor: TrembleTheme.textColor,
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
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: WarmthEmptyState(
                          title: t('run_active_empty_title', lang),
                          subtitle: t('run_active_empty_sub', lang),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final userIds = safeRecapUserIdsFromData(data);
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
                                isPremium: effectivePremium,
                                isActive: true,
                                onWave: () {
                                  return ref
                                      .read(runClubRepositoryProvider)
                                      .sendWave(doc.id, user.id);
                                },
                              ),
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: _recapProviderErrorSliver,
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
                        ?.expand((doc) => safeRecapUserIdsFromData(
                              doc.data() as Map<String, dynamic>,
                            ))
                        .where((id) => id != user.id)
                        .toSet() ??
                    {};

                final historyDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userIds = safeRecapUserIdsFromData(data);
                  final partnerId = userIds.firstWhere((id) => id != user.id,
                      orElse: () => '');
                  return !activeIds.contains(partnerId) &&
                      !viewedRecapIds.contains(doc.id);
                }).toList();

                if (historyDocs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: WarmthEmptyState(
                        title: t('recaps_history_empty_title', lang),
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
                        final userIds = safeRecapUserIdsFromData(data);
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
                            isPremium: effectivePremium,
                            isActive: false,
                          ),
                        );
                      },
                      childCount: historyDocs.length,
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: DelayedChild(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const _RecapItemSkeleton(),
                        const SizedBox(height: 10),
                        const _RecapItemSkeleton(),
                      ],
                    ),
                  ),
                ),
              ),
              error: _recapProviderErrorSliver,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _RecapItem extends ConsumerStatefulWidget {
  final String partnerId;
  final bool iWaved;
  final Future<void> Function()? onWave;
  final bool isHistory;
  final bool isPremium;
  final bool isActive;

  const _RecapItem({
    required this.partnerId,
    required this.iWaved,
    required this.isPremium,
    required this.isActive,
    this.onWave,
    this.isHistory = false,
  });

  @override
  ConsumerState<_RecapItem> createState() => _RecapItemState();
}

class _RecapItemState extends ConsumerState<_RecapItem> {
  bool _ttlStarted = false;
  bool _isSendingWave = false;
  bool _optimisticWaveSent = false;
  String? _waveErrorMessage;

  @override
  void initState() {
    super.initState();
    _startTTLIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _RecapItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnerId != widget.partnerId ||
        oldWidget.isPremium != widget.isPremium ||
        oldWidget.isActive != widget.isActive ||
        oldWidget.isHistory != widget.isHistory) {
      _ttlStarted = false;
      _startTTLIfNeeded();
    }
  }

  void _startTTLIfNeeded() {
    if (_ttlStarted ||
        !widget.isPremium ||
        !widget.isActive ||
        widget.isHistory) {
      return;
    }

    ref.read(recapTTLProvider(widget.partnerId).notifier).start();
    _ttlStarted = true;
  }

  String _formatRemaining(int remainingSeconds) {
    return '${remainingSeconds ~/ 60}:'
        '${(remainingSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _handleWaveTap() async {
    unawaited(HapticFeedback.lightImpact());
    final onWave = widget.onWave;
    if (onWave == null) return;

    try {
      setState(() {
        _isSendingWave = true;
        _optimisticWaveSent = true;
        _waveErrorMessage = null;
      });
      await onWave();
      if (!mounted) return;
      setState(() => _isSendingWave = false);
    } catch (e, st) {
      debugPrint('sendWave error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isSendingWave = false;
        _optimisticWaveSent = false;
        _waveErrorMessage = 'Ni uspelo. Poskusi znova.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicProfileProvider(widget.partnerId));
    final lang = ref.watch(appLanguageProvider);
    final shouldTrackTTL =
        widget.isPremium && widget.isActive && !widget.isHistory;
    final ttlState = shouldTrackTTL
        ? ref.watch(recapTTLProvider(widget.partnerId))
        : const RecapTTLState();
    if (shouldTrackTTL) {
      ref.listen<RecapTTLState>(
        recapTTLProvider(widget.partnerId),
        (previous, next) {
          if (previous != null && !previous.isExpired && next.isExpired) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('pulse_expired', lang))),
              );
            }
          }
        },
      );
    }
    final isExpired = shouldTrackTTL && ttlState.isExpired;
    final isReadOnly = !widget.isPremium || widget.isHistory || isExpired;
    final effectiveIWaved = widget.iWaved || _optimisticWaveSent;
    final showWaveButton = shouldTrackTTL &&
        !effectiveIWaved &&
        !isExpired &&
        widget.onWave != null;

    return profileAsync.when(
      data: (profile) => GestureDetector(
        onTap: isReadOnly
            ? null
            : () => context.push(
                  '/profile',
                  extra: runRecapMatchProfileFromPublicProfile(profile),
                ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          borderColor:
              Colors.white.withValues(alpha: widget.isHistory ? 0.03 : 0.08),
          child: Builder(
            builder: (context) {
              final content = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: TrembleTheme.rose.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isHistory ? LucideIcons.ghost : LucideIcons.zap,
                      color: TrembleTheme.rose
                          .withValues(alpha: widget.isPremium ? 1.0 : 0.4),
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
                            .withValues(alpha: widget.isPremium ? 1.0 : 0.4),
                      ),
                    ),
                  ),
                  if (shouldTrackTTL)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        _formatRemaining(ttlState.remainingSeconds),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: TrembleTheme.rose.withValues(
                            alpha: isExpired ? 0.35 : 0.75,
                          ),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  if (widget.isHistory)
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
                  else if (effectiveIWaved)
                    Text(
                      t('run_wave_sent', lang).toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: TrembleTheme.rose.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    )
                  else if (showWaveButton)
                    GestureDetector(
                      onTap: _isSendingWave
                          ? null
                          : () => unawaited(_handleWaveTap()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: TrembleTheme.rose
                              .withValues(alpha: _isSendingWave ? 0.45 : 0.9),
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
                    )
                  else
                    const SizedBox.shrink(),
                ],
              );

              final contentWithError = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  content,
                  if (_waveErrorMessage != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _waveErrorMessage!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.instrumentSans(
                          color: TrembleTheme.rose,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              );

              if (widget.isPremium) return contentWithError;

              return ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: contentWithError,
              );
            },
          ),
        ),
      ),
      loading: () => const SizedBox(height: 60),
      error: (e, st) => SizedBox(
        height: 80,
        child: recapProviderErrorContent(e, st),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RecapItemSkeleton — placeholder that mirrors the _RecapItem layout
// ─────────────────────────────────────────────────────────────────────────────
class _RecapItemSkeleton extends StatelessWidget {
  const _RecapItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: const [
          SkeletonBox(width: 34, height: 34, borderRadius: 17),
          SizedBox(width: 14),
          Expanded(child: SkeletonBox(height: 17)),
          SizedBox(width: 10),
          SkeletonBox(width: 40, height: 14),
        ],
      ),
    );
  }
}
