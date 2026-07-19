import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/api_client.dart';
import '../../../../core/theme.dart';

typedef PulseInterceptRequester = Future<void> Function({
  required String targetUid,
  required String type,
});

/// "Pulse Intercept" — Send Phone / Send Photo. This is meetup *assistance*
/// shown DURING the trembling window (the active mutual-wave radar search),
/// not on the celebratory match reveal. It lets a user share their number or a
/// "here's what I'm wearing" photo so the two can find each other in person.
///
/// Kept injectable ([requestPulseIntercept]) for tests; defaults to the real
/// `requestPulseIntercept` callable.
class PulseInterceptBar extends ConsumerStatefulWidget {
  final String targetUid;
  final PulseInterceptRequester? requestPulseIntercept;

  const PulseInterceptBar({
    super.key,
    required this.targetUid,
    this.requestPulseIntercept,
  });

  @override
  ConsumerState<PulseInterceptBar> createState() => _PulseInterceptBarState();
}

class _PulseInterceptBarState extends ConsumerState<PulseInterceptBar> {
  String? _pulseSendingType;
  String? _pulseInterceptError;
  final Set<String> _sentPulseTypes = <String>{};

  Future<void> _sendPulseIntercept(String type) async {
    if (_sentPulseTypes.contains(type) || _pulseSendingType != null) return;

    setState(() {
      _pulseSendingType = type;
      _pulseInterceptError = null;
    });

    try {
      final requester =
          widget.requestPulseIntercept ?? _requestPulseInterceptViaApiClient;
      await requester(targetUid: widget.targetUid, type: type);
      if (!mounted) return;
      setState(() => _sentPulseTypes.add(type));
    } catch (error) {
      if (!mounted) return;
      setState(() => _pulseInterceptError = _mapPulseInterceptError(error));
    } finally {
      if (!mounted) return;
      setState(() => _pulseSendingType = null);
    }
  }

  Future<void> _requestPulseInterceptViaApiClient({
    required String targetUid,
    required String type,
  }) async {
    await TrembleApiClient().call(
      'requestPulseIntercept',
      data: {
        'targetUid': targetUid,
        'type': type,
      },
    );
  }

  String _mapPulseInterceptError(Object error) {
    if (error is TrembleApiException) return error.message;
    return 'Could not send this right now. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _PulseInterceptButton(
                label: 'Send Photo',
                sentLabel: 'Photo Sent',
                icon: Icons.photo_camera_outlined,
                isSending: _pulseSendingType == 'photo',
                isSent: _sentPulseTypes.contains('photo'),
                isBlocked: _pulseSendingType != null,
                onPressed: () => unawaited(_sendPulseIntercept('photo')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PulseInterceptButton(
                label: 'Send Phone',
                sentLabel: 'Phone Sent',
                icon: Icons.call_outlined,
                isSending: _pulseSendingType == 'phone',
                isSent: _sentPulseTypes.contains('phone'),
                isBlocked: _pulseSendingType != null,
                onPressed: () => unawaited(_sendPulseIntercept('phone')),
              ),
            ),
          ],
        ),
        if (_pulseInterceptError != null) ...[
          const SizedBox(height: 8),
          Text(
            _pulseInterceptError!,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF8A9D),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _PulseInterceptButton extends StatelessWidget {
  const _PulseInterceptButton({
    required this.label,
    required this.sentLabel,
    required this.icon,
    required this.isSending,
    required this.isSent,
    required this.isBlocked,
    required this.onPressed,
  });

  static const _greenDark = TrembleTheme.successGreen;
  static const _greenLight = Color(0xFF5BBF93);
  static const _cream = TrembleTheme.backgroundColor;

  final String label;
  final String sentLabel;
  final IconData icon;
  final bool isSending;
  final bool isSent;
  final bool isBlocked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled = isSent || isBlocked;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isDisabled ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSent
                  ? [
                      _greenDark.withValues(alpha: 0.46),
                      _greenLight.withValues(alpha: 0.34),
                    ]
                  : const [_greenLight, _greenDark],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isSent ? 0.16 : 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: _greenLight.withValues(alpha: isSent ? 0.12 : 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: isSending
                ? const SizedBox(
                    key: ValueKey('sending'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_cream),
                    ),
                  )
                : Row(
                    key: ValueKey(isSent ? sentLabel : label),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isSent ? Icons.check : icon,
                          size: 15, color: _cream),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isSent ? sentLabel : label,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _cream,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
