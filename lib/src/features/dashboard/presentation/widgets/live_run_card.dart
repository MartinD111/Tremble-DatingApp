import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme.dart';
import '../../../../core/translations.dart';
import '../../../../shared/ui/glass_card.dart';

class LiveRunCard extends ConsumerStatefulWidget {
  final String name;
  final int age;
  final FutureOr<void> Function() onWave;
  final VoidCallback onDismiss;

  const LiveRunCard({
    super.key,
    required this.name,
    required this.age,
    required this.onWave,
    required this.onDismiss,
  });

  @override
  ConsumerState<LiveRunCard> createState() => _LiveRunCardState();
}

class _LiveRunCardState extends ConsumerState<LiveRunCard> {
  bool _isSending = false;
  bool _isSent = false;
  String? _errorMessage;

  Future<void> _handleWaveTap() async {
    if (_isSending || _isSent) return;
    setState(() {
      _isSending = true;
      _isSent = true;
      _errorMessage = null;
    });

    try {
      await Future<void>.sync(widget.onWave);
      if (!mounted) return;
      setState(() => _isSending = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isSent = false;
        _errorMessage = 'Ni uspelo. Poskusi znova.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDisabled = _isSending || _isSent;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          borderColor: Colors.white.withValues(alpha: 0.10),
          child: Row(
            children: [
              // Signal icon — minimal, technical
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TrembleTheme.rose.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.zap,
                  color: TrembleTheme.rose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('signal_detected', lang).toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: TrembleTheme.rose.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.name}, ${widget.age}',
                      style: TrembleTheme.displayFont(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Wave Action
              GestureDetector(
                onTap: isDisabled ? null : () => unawaited(_handleWaveTap()),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: TrembleTheme.rose
                            .withValues(alpha: isDisabled ? 0.45 : 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSent ? LucideIcons.check : LucideIcons.hand,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isSent
                                ? t('run_wave_sent', lang)
                                : t('wave', lang),
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.instrumentSans(
                          color: TrembleTheme.rose,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Dismiss button
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                Icons.close,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
