import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/match.dart';
import 'widgets/match_background_animation.dart';
import '../../../shared/ui/glass_card.dart';

class MatchRevealScreen extends ConsumerWidget {
  final Match match;
  const MatchRevealScreen({super.key, required this.match});

  static const Color _rose = Color(0xFFF4436C);
  static const Color _deepGraphite = Color(0xFF1A1A18);
  static const Color _warmCream = Color(0xFFFAFAF7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(
        backgroundColor: _deepGraphite,
        body: Center(
          child:
              Text('Napaka avtentikacije', style: TextStyle(color: _warmCream)),
        ),
      );
    }

    final partnerId = match.getPartnerId(myUid);
    final partnerProfileAsync = ref.watch(publicProfileProvider(partnerId));

    return Scaffold(
      backgroundColor: _deepGraphite,
      body: Stack(
        children: [
          // Animated Rose radar pulse background
          const Positioned.fill(child: MatchBackgroundAnimation()),

          // Subtle deep graphite gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _deepGraphite.withValues(alpha: 0.3),
                    _deepGraphite.withValues(alpha: 0.7),
                    _deepGraphite.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: partnerProfileAsync.when(
              data: (profile) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Brand headline
                    Text(
                      'MUTUAL WAVE',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _rose,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Oba sta si poslala val',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        color: _warmCream.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Partner avatar with rose glow
                    GlassCard(
                      opacity: 0.1,
                      borderRadius: 100,
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _rose.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _rose.withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.grey[850],
                          backgroundImage: profile.primaryPhotoUrl.isNotEmpty
                              ? NetworkImage(profile.primaryPhotoUrl)
                              : null,
                          child: profile.primaryPhotoUrl.isEmpty
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.white54)
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Partner name
                    Text(
                      profile.name.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _warmCream,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.age} let',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 16,
                        color: _warmCream.withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 64),

                    // Primary CTA — odpri radar, poišči jih v živo
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => context.pop(), // Nazaj na radar
                        child: Text(
                          'ODPRI RADAR',
                          style: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Secondary action — dismiss
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'NE ZDAJ',
                        style: GoogleFonts.instrumentSans(
                          color: _warmCream.withValues(alpha: 0.5),
                          fontSize: 13,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              loading: () => const CircularProgressIndicator(
                color: _rose,
                strokeWidth: 2,
              ),
              error: (err, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: _rose, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Napaka pri nalaganju profila',
                    style: GoogleFonts.instrumentSans(
                      color: _warmCream.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Zapri',
                      style: TextStyle(color: _rose.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
