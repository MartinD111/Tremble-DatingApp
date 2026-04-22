import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// The final activation screen shown after onboarding consent.
/// "SIGNAL LOCKED" — confirms radar is live and instructs the user
/// to put their phone down. Haptic feedback on entry.
class RitualStep extends StatefulWidget {
  const RitualStep({super.key, required this.tr});

  final String Function(String) tr;

  @override
  State<RitualStep> createState() => _RitualStepState();
}

class _RitualStepState extends State<RitualStep> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1A1A18); // Deep Graphite
    const rose = Color(0xFFF4436C); // Tremble Rose

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Header
              Text(
                widget.tr('ritual_header'),
                style: GoogleFonts.jetBrainsMono(
                  color: rose,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 32),
              // Body
              Text(
                widget.tr('ritual_body'),
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              const Spacer(),
              // CTA
              GestureDetector(
                onTap: () => context.go('/'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: rose, width: 1.0),
                  ),
                  child: Text(
                    widget.tr('ritual_button'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      color: rose,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
