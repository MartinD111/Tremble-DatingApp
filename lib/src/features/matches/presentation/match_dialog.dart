import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/match_repository.dart';
import '../../../core/api_client.dart';
import '../../../core/translations.dart';

class MatchDialog extends ConsumerStatefulWidget {
  final MatchProfile match;

  const MatchDialog({super.key, required this.match});

  @override
  ConsumerState<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends ConsumerState<MatchDialog>
    with SingleTickerProviderStateMixin {
  bool _isGreeting = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _sendGreet() async {
    if (_isGreeting) return;
    setState(() => _isGreeting = true);
    try {
      // Calls WaveRepository.sendWave() through MatchController
      final matched = await ref.read(matchControllerProvider.notifier).greet();

      if (!mounted) return;
      if (context.canPop()) context.pop();

      if (matched) {
        _showMutualMatchBanner();
      } else {
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Text('👋  '),
              Text(t('wave_sent_to', lang)
                  .replaceAll('{name}', widget.match.name)),
            ]),
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on AccountSuspendedException {
      if (!mounted) return;
      context.go('/account-suspended');
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
    final lang = ref.read(appLanguageProvider);
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A18).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFF4436C).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rose signal dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4436C),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fade(duration: 800.ms, begin: 0.3, end: 1.0),
                    const SizedBox(height: 20),
                    Text(
                      'Match.',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.03 * 42,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ti in ${widget.match.name} sta si poslala pozdrav.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4436C),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF4436C)
                                  .withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t('continue', lang).toUpperCase(),
                          style: GoogleFonts.instrumentSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final lang = ref.watch(appLanguageProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Card ──────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  ref.read(matchControllerProvider.notifier).dismiss();
                  if (context.canPop()) context.pop();
                  context.push('/profile?showActions=false', extra: match);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A18).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Photo
                          Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              Container(
                                height: 260,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                  image: DecorationImage(
                                    image: NetworkImage(match.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Gradient scrim over photo
                              Container(
                                height: 260,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF1A1A18)
                                          .withValues(alpha: 0.7),
                                    ],
                                    stops: const [0.45, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Name + Hobbies
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${match.name}, ${match.age}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.03 * 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: match.hobbies.take(3).map((h) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A28),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.10),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(h['emoji'] as String,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(
                                            h['name'] as String,
                                            style: GoogleFonts.instrumentSans(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
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
                ),
              ),

              const SizedBox(height: 20),

              // ── Action Buttons ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dismiss — subtle outlined
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
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Wave — triple-ring pulse
                  GestureDetector(
                    onTap: _isGreeting ? null : _sendGreet,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ring
                            Container(
                              width: 84 +
                                  (28 * _waveController.value).clamp(0.0, 28.0),
                              height: 84 +
                                  (28 * _waveController.value).clamp(0.0, 28.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                      alpha: (1.0 - _waveController.value)
                                          .clamp(0.0, 0.25)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Middle ring
                            Container(
                              width: 84 +
                                  (14 * _waveController.value).clamp(0.0, 14.0),
                              height: 84 +
                                  (14 * _waveController.value).clamp(0.0, 14.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                      alpha: (1.0 - _waveController.value)
                                          .clamp(0.0, 0.35)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            // Core button
                            child!,
                          ],
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: _isGreeting
                              ? LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.5),
                                    colorScheme.primary.withValues(alpha: 0.5),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    const Color(0xFFC02048), // rose-dark
                                  ],
                                ),
                          shape: BoxShape.circle,
                          boxShadow: _isGreeting
                              ? []
                              : [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.45),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                        ),
                        child: Center(
                          child: _isGreeting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('👋',
                                  style: TextStyle(fontSize: 34)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Dismiss later — text link
              GestureDetector(
                onTap: _isGreeting
                    ? null
                    : () {
                        ref.read(matchControllerProvider.notifier).dismiss();
                        if (context.canPop()) context.pop();
                      },
                child: Text(
                  t('decide_later', lang).toUpperCase(),
                  style: GoogleFonts.instrumentSans(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
