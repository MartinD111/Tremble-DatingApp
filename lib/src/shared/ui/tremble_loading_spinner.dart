import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

enum LoadingStyle { simple, dynamic }

class TrembleLoadingSpinner extends StatefulWidget {
  const TrembleLoadingSpinner({
    super.key,
    this.style = LoadingStyle.simple,
    this.messages = const [
      'Scanning for nearby matches...',
      'Connecting to the radar...',
      'Looking for signals...',
    ],
    this.duration = const Duration(milliseconds: 2500),
    this.accentColor = TrembleTheme.rose,
  });

  final LoadingStyle style;
  final List<String> messages;
  final Duration duration;
  final Color accentColor;

  @override
  State<TrembleLoadingSpinner> createState() => _TrembleLoadingSpinnerState();
}

class _TrembleLoadingSpinnerState extends State<TrembleLoadingSpinner> {
  Timer? _messageTimer;
  Timer? _fallbackTimer;
  int _messageIndex = 0;
  bool _showLinearFallback = false;

  @override
  void initState() {
    super.initState();
    _configureTimers();
  }

  @override
  void didUpdateWidget(TrembleLoadingSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style ||
        oldWidget.duration != widget.duration ||
        oldWidget.messages != widget.messages) {
      _messageIndex = 0;
      _showLinearFallback = false;
      _configureTimers();
    }
  }

  void _configureTimers() {
    _messageTimer?.cancel();
    _fallbackTimer?.cancel();

    if (widget.style == LoadingStyle.dynamic && widget.messages.length > 1) {
      _messageTimer = Timer.periodic(widget.duration, (_) {
        if (!mounted) return;
        setState(() {
          _messageIndex = (_messageIndex + 1) % widget.messages.length;
        });
      });
    }

    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() => _showLinearFallback = true);
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDynamic = widget.style == LoadingStyle.dynamic;
    final message = widget.messages.isEmpty
        ? ''
        : widget.messages[_messageIndex.clamp(0, widget.messages.length - 1)];

    return Semantics(
      liveRegion: isDynamic,
      label: isDynamic && message.isNotEmpty ? message : 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: widget.accentColor,
            ),
          ),
          if (isDynamic && message.isNotEmpty) ...[
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.16),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                message,
                key: ValueKey<String>(message),
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: _showLinearFallback
                ? Padding(
                    key: const ValueKey('linear-fallback'),
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      width: 160,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: widget.accentColor,
                        backgroundColor:
                            widget.accentColor.withValues(alpha: 0.16),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-fallback')),
          ),
        ],
      ),
    );
  }
}
