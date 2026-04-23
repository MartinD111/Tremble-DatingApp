import 'dart:async';
import 'dart:math';
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
  bool _canEnter = false;

  @override
  void initState() {
    super.initState();
    // Initial feedback
    HapticFeedback.lightImpact();

    // Enforce a 2.5 second delay before the CTA becomes active
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _canEnter = true);
      }
    });
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
              // Header with decryption animation
              _DecryptedText(
                text: widget.tr('ritual_header'),
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
                onTap: _canEnter ? () => context.go('/') : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _canEnter ? rose : rose.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    widget.tr('ritual_button'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      color: _canEnter ? rose : rose.withValues(alpha: 0.15),
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

class _DecryptedText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _DecryptedText({required this.text, required this.style});

  @override
  State<_DecryptedText> createState() => _DecryptedTextState();
}

class _DecryptedTextState extends State<_DecryptedText> {
  String _currentText = "";
  late Timer _timer;
  final Random _random = Random();
  final String _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()";
  int _ticks = 0;
  final int _maxTicks = 16; // Approx 800ms at 50ms per tick

  @override
  void initState() {
    super.initState();
    _currentText = _scramble(widget.text.length);

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      _ticks++;

      if (_ticks >= _maxTicks) {
        _timer.cancel();
        setState(() {
          _currentText = widget.text;
        });
        // The satisfying hard lock when the text finishes decrypting
        HapticFeedback.heavyImpact();
      } else {
        setState(() {
          // Progressively reveal the true text
          int revealCount = (widget.text.length * (_ticks / _maxTicks)).floor();
          String revealed = widget.text.substring(0, revealCount);
          String scrambled = _scramble(widget.text.length - revealCount);
          _currentText = revealed + scrambled;
        });
        
        // Subtle mechanical ticking sound/haptic
        if (_ticks % 3 == 0) {
          HapticFeedback.selectionClick();
        }
      }
    });
  }

  String _scramble(int length) {
    if (length <= 0) return "";
    return List.generate(length, (index) => _chars[_random.nextInt(_chars.length)]).join();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentText,
      style: widget.style,
    );
  }
}
