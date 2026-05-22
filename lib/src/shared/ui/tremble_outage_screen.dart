import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme.dart';
import 'glass_card.dart';
import 'primary_button.dart';

class TrembleServiceStatus {
  const TrembleServiceStatus({
    required this.label,
    required this.isActive,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final bool isActive;
  final String? actionLabel;
  final VoidCallback? onAction;
}

class TrembleOutageScreen extends StatefulWidget {
  const TrembleOutageScreen({
    super.key,
    required this.bluetoothStatus,
    required this.locationStatus,
    required this.networkStatus,
    required this.onRetry,
    this.retryInterval = const Duration(seconds: 10),
    this.title = 'Connection Interrupted',
    this.subtitle =
        'Your profile, matches, and logs are completely safe. We are reconnecting...',
    this.activeLabel = 'Active',
    this.inactiveLabel = 'Inactive',
    this.tryNowLabel = 'Try Now',
    this.openSettingsLabel = 'Open Settings',
    this.retryInPattern = 'Retrying in {seconds}s...',
  });

  factory TrembleOutageScreen.fromAvailability({
    Key? key,
    required bool isBluetoothActive,
    required bool isLocationActive,
    required bool isNetworkActive,
    required VoidCallback onRetry,
    Duration retryInterval = const Duration(seconds: 10),
    String title = 'Connection Interrupted',
    String subtitle =
        'Your profile, matches, and logs are completely safe. We are reconnecting...',
    String bluetoothLabel = 'Bluetooth',
    String locationLabel = 'Location',
    String networkLabel = 'Network',
    String activeLabel = 'Active',
    String inactiveLabel = 'Inactive',
    String tryNowLabel = 'Try Now',
    String openSettingsLabel = 'Open Settings',
    String retryInPattern = 'Retrying in {seconds}s...',
  }) {
    return TrembleOutageScreen(
      key: key,
      bluetoothStatus: TrembleServiceStatus(
        label: bluetoothLabel,
        isActive: isBluetoothActive,
        actionLabel: isBluetoothActive ? null : openSettingsLabel,
        onAction: isBluetoothActive ? null : openAppSettings,
      ),
      locationStatus: TrembleServiceStatus(
        label: locationLabel,
        isActive: isLocationActive,
        actionLabel: isLocationActive ? null : openSettingsLabel,
        onAction: isLocationActive ? null : openAppSettings,
      ),
      networkStatus: TrembleServiceStatus(
        label: networkLabel,
        isActive: isNetworkActive,
      ),
      retryInterval: retryInterval,
      onRetry: onRetry,
      title: title,
      subtitle: subtitle,
      activeLabel: activeLabel,
      inactiveLabel: inactiveLabel,
      tryNowLabel: tryNowLabel,
      openSettingsLabel: openSettingsLabel,
      retryInPattern: retryInPattern,
    );
  }

  final TrembleServiceStatus bluetoothStatus;
  final TrembleServiceStatus locationStatus;
  final TrembleServiceStatus networkStatus;
  final VoidCallback onRetry;
  final Duration retryInterval;
  final String title;
  final String subtitle;
  final String activeLabel;
  final String inactiveLabel;
  final String tryNowLabel;
  final String openSettingsLabel;
  final String retryInPattern;

  @override
  State<TrembleOutageScreen> createState() => _TrembleOutageScreenState();
}

class _TrembleOutageScreenState extends State<TrembleOutageScreen> {
  Timer? _timer;
  late int _secondsRemaining;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _initialSeconds;
    _startCountdown();
  }

  @override
  void didUpdateWidget(TrembleOutageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.retryInterval != widget.retryInterval) {
      _secondsRemaining = _initialSeconds;
      _startCountdown();
    }
  }

  int get _initialSeconds => math.max(1, widget.retryInterval.inSeconds);

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        HapticFeedback.lightImpact();
        widget.onRetry();
        setState(() => _secondsRemaining = _initialSeconds);
        return;
      }

      setState(() => _secondsRemaining -= 1);
      if (_secondsRemaining <= 3) {
        HapticFeedback.lightImpact();
      }
    });
  }

  void _retryNow() {
    HapticFeedback.mediumImpact();
    widget.onRetry();
    setState(() => _secondsRemaining = _initialSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statuses = [
      widget.bluetoothStatus,
      widget.locationStatus,
      widget.networkStatus,
    ];
    final retryText = widget.retryInPattern
        .replaceAll('{seconds}', _secondsRemaining.toString());

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A18),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                useGlassEffect: false,
                solidDarkBg: const Color(0xFF222220),
                borderRadius: 24,
                borderColor: TrembleTheme.rose.withValues(alpha: 0.28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TrembleTheme.rose.withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        LucideIcons.wifiOff,
                        color: TrembleTheme.rose,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.instrumentSans(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.35,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...statuses.map(_buildStatusRow),
                    const SizedBox(height: 24),
                    _CountdownRing(
                      progress: _secondsRemaining / _initialSeconds,
                      text: retryText,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: widget.tryNowLabel,
                      onPressed: _retryNow,
                      width: 180,
                      height: 48,
                    ),
                    if (statuses.any((status) => status.onAction != null)) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.openSettingsLabel,
                        style: GoogleFonts.instrumentSans(
                          color: colorScheme.primary.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(TrembleServiceStatus status) {
    final statusColor =
        status.isActive ? TrembleTheme.successGreen : TrembleTheme.accentYellow;
    final statusText =
        status.isActive ? widget.activeLabel : widget.inactiveLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            status.isActive
                ? LucideIcons.checkCircle2
                : LucideIcons.circleAlert,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.label,
              style: GoogleFonts.instrumentSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            statusText,
            style: GoogleFonts.instrumentSans(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (status.onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: status.onAction,
              style: TextButton.styleFrom(
                foregroundColor: TrembleTheme.accentYellow,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(status.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.progress,
    required this.text,
  });

  final double progress;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 4,
                color: TrembleTheme.rose,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
