import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/ui/glass_card.dart';
import '../data/match_repository.dart';

class MatchDialog extends ConsumerStatefulWidget {
  final MatchProfile match;

  const MatchDialog({super.key, required this.match});

  @override
  ConsumerState<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends ConsumerState<MatchDialog> {
  bool _isGreeting = false;

  IconData _getHobbyIcon(String hobby) {
    switch (hobby.toLowerCase()) {
      case 'music':
      case 'glasba':
        return LucideIcons.music;
      case 'art':
      case 'umetnost':
      case 'slikanje':
        return LucideIcons.palette;
      case 'travel':
      case 'potovanja':
        return LucideIcons.plane;
      case 'sport':
      case 'šport':
      case 'fitnes':
        return LucideIcons.dumbbell;
      case 'reading':
      case 'branje':
        return LucideIcons.book;
      case 'movies':
      case 'filmi':
        return LucideIcons.film;
      case 'gaming':
      case 'videoigre':
        return LucideIcons.gamepad2;
      default:
        return LucideIcons.star;
    }
  }

  Future<void> _sendGreet() async {
    if (_isGreeting) return;
    setState(() => _isGreeting = true);
    try {
      // Calls sendGreeting CF → returns true if both users greeted (mutual match)
      final matched = await ref.read(matchControllerProvider.notifier).greet();

      if (!mounted) return;
      if (context.canPop()) context.pop();

      if (matched) {
        // Mutual match — show celebration
        _showMutualMatchBanner();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Text('👋  '),
              Text('Pozdrav poslan — čakamo na ${widget.match.name}!'),
            ]),
            backgroundColor: const Color(0xFF00D9A6).withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGreeting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Napaka: ${e.toString()}'),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        ),
      );
    }
  }

  void _showMutualMatchBanner() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GlassCard(
            opacity: 0.15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Match!',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00D9A6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ti in ${widget.match.name}\nsta si poslala pozdrav.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9A6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Super!',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(matchControllerProvider.notifier).dismiss();
                  if (context.canPop()) context.pop();
                  context.push('/profile', extra: match);
                },
                child: GlassCard(
                  opacity: 0.9,
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Photo
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          image: DecorationImage(
                            image: NetworkImage(match.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('${match.name}, ${match.age}',
                                style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: match.hobbies.take(3).map((h) {
                                return Chip(
                                  avatar: Icon(_getHobbyIcon(h),
                                      size: 16, color: Colors.white),
                                  label: Text(h,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  backgroundColor:
                                      Colors.black.withValues(alpha: 0.6),
                                  padding: const EdgeInsets.all(4),
                                  labelPadding: const EdgeInsets.only(right: 8),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dismiss
                  GestureDetector(
                    onTap: _isGreeting
                        ? null
                        : () {
                            ref
                                .read(matchControllerProvider.notifier)
                                .dismiss();
                            if (context.canPop()) context.pop();
                          },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Greet — now calls sendGreeting CF
                  GestureDetector(
                    onTap: _isGreeting ? null : _sendGreet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isGreeting
                            ? const Color(0xFF00D9A6).withValues(alpha: 0.5)
                            : const Color(0xFF00D9A6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00D9A6).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isGreeting
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('👋', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
