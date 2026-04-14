import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/ui/glass_card.dart';
import '../../../shared/ui/tremble_circle_button.dart';
import '../../matches/data/match_repository.dart';
import '../../safety/presentation/widgets/ugc_action_sheet.dart';
import '../../../core/theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final dimColor = isDark ? Colors.white24 : Colors.black26;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                // Centered Title
                Text(
                  'Ljudje',
                  style: TrembleTheme.displayFont(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                // Action Buttons (Right Aligned)
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
                        icon:
                            _isEditMode ? LucideIcons.check : LucideIcons.pencil,
                        onPressed: () =>
                            setState(() => _isEditMode = !_isEditMode),
                        color: _isEditMode ? Theme.of(context).primaryColor : null,
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
                    Icon(LucideIcons.wifiOff,
                        size: 48, color: dimColor),
                    const SizedBox(height: 12),
                    Text('Napaka pri nalaganju',
                        style: GoogleFonts.instrumentSans(
                            color: subtextColor, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(matchesStreamProvider),
                      child: Text('Poskusi znova',
                          style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                  ],
                ),
              ),
              data: (allMatches) {
                // Filter out locally removed matches
                final matches = allMatches
                    .where((m) => !_removedIds.contains(m.id))
                    .toList();

                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users,
                            size: 48, color: dimColor),
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
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: _isEditMode ? null : () => _openProfile(match),
                        child: GlassCard(
                          opacity: 0.15,
                          borderRadius: 50,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(match.imageUrl),
                                backgroundColor: Colors.white12,
                              ),
                              const SizedBox(width: 15),

                              // Name & Age
                              Expanded(
                                child: Text('${match.name}, ${match.age}',
                                    style: GoogleFonts.instrumentSans(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontSize: 18)),
                              ),

                              // Edit mode: delete | Normal: match-again toggle
                              if (_isEditMode)
                                GestureDetector(
                                  onTap: () =>
                                      _removeMatch(match.id, match.name),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
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
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(LucideIcons.moreVertical,
                                          color: subtextColor),
                                      onPressed: () {
                                        UgcActionSheet.show(
                                          context,
                                          targetUid: match.id,
                                          targetName: match.name,
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
