import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/ui/glass_card.dart';
import '../../matches/data/match_repository.dart';

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
          textColor: Colors.pinkAccent,
          onPressed: () => setState(() => _removedIds.remove(matchId)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesStreamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text('Ljudje',
                    style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              GestureDetector(
                onTap: () => setState(() => _isEditMode = !_isEditMode),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isEditMode
                        ? Colors.pinkAccent.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isEditMode ? Colors.pinkAccent : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEditMode ? LucideIcons.check : LucideIcons.pencil,
                        size: 14,
                        color: _isEditMode ? Colors.pinkAccent : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isEditMode ? 'Končaj' : 'Uredi',
                        style: TextStyle(
                          color:
                              _isEditMode ? Colors.pinkAccent : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text('Upravljaj svoje pretekle stike',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 5),
          Text(
            _isEditMode
                ? 'Klikni X za odstranitev osebe'
                : 'Ali želiš še kdaj jih srečati ali ne',
            style: TextStyle(
                color: _isEditMode
                    ? Colors.pinkAccent.withValues(alpha: 0.7)
                    : Colors.white70,
                fontSize: 14),
          ),
          const SizedBox(height: 20),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: matchesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00D9A6),
                  strokeWidth: 2,
                ),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.wifiOff,
                        size: 48, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text('Napaka pri nalaganju',
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(matchesStreamProvider),
                      child: const Text('Poskusi znova',
                          style: TextStyle(color: Color(0xFF00D9A6))),
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
                        const Icon(LucideIcons.users,
                            size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text('Ni matchev',
                            style: GoogleFonts.outfit(
                                color: Colors.white38, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text(
                          'Ko srečaš nekoga v bližini in si oba pošljete pozdrav,\npridejo tukaj.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white24, fontSize: 13),
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
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                                const Icon(LucideIcons.chevronRight,
                                    color: Colors.white30, size: 20),
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
