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

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  bool _isEditMode = false;

  // Tracks locally removed match IDs (optimistic UI)
  final Set<String> _removedIds = {};

  void _openProfile(MatchProfile match) {
    context.push('/profile', extra: match);
  }

  void _removeMatch(String matchId, String name) {
    setState(() => _removedIds.add(matchId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name odstranjen/-a'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Razveljavi',
          textColor: Theme.of(context).primaryColor,
          onPressed: () => setState(() => _removedIds.remove(matchId)),
        ),
      ),
    );
  }

  void _showHelpDialog() {
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
                'O strani Ljudje',
                style: GoogleFonts.instrumentSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tukaj vidiš vse ljudi, ki si jih srečal/-a v resničnem življenju (preko radarja) in s katerimi sta si oba pomahala oz. si bila všeč.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Razumem',
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

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesStreamProvider);
    final activeMatchesAsync = ref.watch(activeMatchesStreamProvider);
    final user = ref.watch(authStateProvider);
    final isPremium = user?.isPremium == true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final dimColor = isDark ? Colors.white24 : Colors.black26;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            SizedBox(
              height: 50,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Ljudje',
                    style: TrembleTheme.displayFont(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TrembleCircleButton(
                          icon: LucideIcons.helpCircle,
                          onPressed: _showHelpDialog,
                          size: 40,
                        ),
                        const SizedBox(width: 8),
                        TrembleCircleButton(
                          icon: _isEditMode
                              ? LucideIcons.check
                              : LucideIcons.pencil,
                          onPressed: () =>
                              setState(() => _isEditMode = !_isEditMode),
                          color: _isEditMode
                              ? Theme.of(context).primaryColor
                              : null,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── List ─────────────────────────────────────────────
            Expanded(
              child: matchesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 2,
                  ),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.wifiOff, size: 48, color: dimColor),
                      const SizedBox(height: 12),
                      Text('Napaka pri nalaganju',
                          style: GoogleFonts.instrumentSans(
                              color: subtextColor, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(matchesStreamProvider),
                        child: Text('Poskusi znova',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor)),
                      ),
                    ],
                  ),
                ),
                data: (allProfiles) {
                  final activeMatches = activeMatchesAsync.value ?? [];
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
                          Text('Ni matchev',
                              style: GoogleFonts.instrumentSans(
                                  color: subtextColor, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(
                            'Ko srečaš nekoga v bližini in si oba pošljete pozdrav,\npridejo tukaj.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: dimColor, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredItems.length,
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
                              borderRadius: isLocked ? 20 : 50,
                              padding: EdgeInsets.symmetric(
                                horizontal: isLocked ? 16 : 8,
                                vertical: isLocked ? 12 : 8,
                              ),
                              child: Row(
                                children: [
                                  if (!isLocked)
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          NetworkImage(profile.imageUrl),
                                      backgroundColor: Colors.white12,
                                    )
                                  else
                                    const Icon(LucideIcons.user,
                                        color: Colors.white24, size: 24),

                                  const SizedBox(width: 15),

                                  Expanded(
                                    child: Text(
                                      isLocked ? 'Skrita oseba' : '${profile.name}, ${profile.age}',
                                      style: GoogleFonts.instrumentSans(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontSize: isLocked ? 16 : 18,
                                      ),
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
                                              color: Colors.red.withValues(
                                                  alpha: 0.4)),
                                        ),
                                        child: const Icon(LucideIcons.x,
                                            color: Colors.red, size: 18),
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
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
                                        Icon(LucideIcons.chevronRight,
                                            color: dimColor, size: 20),
                                      ],
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
          ],
        ),
      ),
    );
  }
}

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
