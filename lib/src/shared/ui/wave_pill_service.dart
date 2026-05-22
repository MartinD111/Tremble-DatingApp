import 'package:flutter/material.dart';

import '../../features/match/presentation/widgets/match_notification_pill.dart';
import '../../features/match/presentation/widgets/match_reveal_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WavePillData
// ─────────────────────────────────────────────────────────────────────────────

class WavePillData {
  final String name;
  final int age;
  final String imageUrl;
  final String targetUid;
  final bool
      isIncomingWave; // true → PillState.waveReceived, false → waitingForAction
  final DateTime? birthDate;

  const WavePillData({
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.targetUid,
    required this.isIncomingWave,
    this.birthDate,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// WavePillService
// ─────────────────────────────────────────────────────────────────────────────

/// Global OverlayEntry manager for the foreground wave / proximity pill.
///
/// Usage (e.g. from NotificationService.initialize onForegroundWave callback):
/// ```dart
/// final overlay = Overlay.of(navigatorKey.currentContext!);
/// WavePillService.show(
///   overlay:  overlay,
///   data:     WavePillData(name: 'Ana', age: 23, imageUrl: '...', targetUid: '...', isIncomingWave: true),
///   onWave:   (uid) => waveRepository.sendWave(toUid: uid),
/// );
/// ```
///
/// The pill dismisses itself (and removes the OverlayEntry) automatically:
///   - After the 3-second success state on Wave tap.
///   - Immediately on swipe dismiss (after the slide animation).
class WavePillService {
  WavePillService._();

  static OverlayEntry? _entry;
  static OverlayEntry? _confettiEntry;

  // ── Public API ────────────────────────────────────────────────────────────

  static void show({
    required OverlayState overlay,
    required WavePillData data,
    required void Function(String targetUid) onWave,
    VoidCallback? onTap,
  }) {
    // Replace any existing pill instead of stacking.
    _forceDismiss();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final topPad = MediaQuery.of(ctx).padding.top;
        return Positioned(
          top: topPad + 14,
          left: 16,
          right: 16,
          child: Material(
            type: MaterialType.transparency,
            child: MatchNotificationPill(
              name: data.name,
              age: data.age,
              imageUrl: data.imageUrl,
              birthDate: data.birthDate,
              pillState: data.isIncomingWave
                  ? PillState.waveReceived
                  : PillState.waitingForAction,
              onWave: () => onWave(data.targetUid),
              onIgnore: () => _removeEntry(entry),
              // Match reveal handled by activeMatchesStream → MatchRevealScreen.
              onMatch: null,
              onTap: onTap,
            ),
          ),
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);
  }

  /// Programmatically dismiss the active pill (e.g. when the user navigates away).
  static void dismiss() => _forceDismiss();

  /// Show the match reveal overlay standalone — call this when a MUTUAL_WAVE
  /// FCM message arrives and there is no active pill to trigger onMatch.
  static void showConfetti(OverlayState overlay, {String? imageUrl}) =>
      _showConfetti(overlay, imageUrl: imageUrl);

  // ── Internal helpers ──────────────────────────────────────────────────────

  static void _showConfetti(OverlayState overlay, {String? imageUrl}) {
    // Remove any stale overlay before inserting a new one.
    _removeConfetti();

    late OverlayEntry confetti;
    confetti = OverlayEntry(
      builder: (_) => MatchRevealOverlay(
        matchImageUrl: imageUrl,
        onDone: () => _removeConfettiEntry(confetti),
      ),
    );

    _confettiEntry = confetti;
    overlay.insert(confetti);
  }

  static void _forceDismiss() {
    if (_entry != null && _entry!.mounted) _entry!.remove();
    _entry = null;
    _removeConfetti();
  }

  static void _removeConfetti() {
    if (_confettiEntry != null && _confettiEntry!.mounted) {
      _confettiEntry!.remove();
    }
    _confettiEntry = null;
  }

  static void _removeEntry(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
    if (_entry == entry) _entry = null;
  }

  static void _removeConfettiEntry(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
    if (_confettiEntry == entry) _confettiEntry = null;
  }
}
