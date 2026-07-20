import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // The partner the currently-visible pill is about. Lets callers dismiss the
  // "{name} is nearby" pill for a specific person (e.g. once a wave is sent to
  // them) without tearing down a pill that belongs to someone else.
  static String? _currentTargetUid;

  // ── Auto-dismiss ──────────────────────────────────────────────────────────
  // An unanswered pill covers the UI, and the proximity claim behind it goes
  // stale, so it self-closes after a quiet period. Any user reaction cancels
  // the timer — without that, a Wave tapped just before the deadline would be
  // torn down mid-request.
  static const Duration defaultAutoDismissAfter = Duration(minutes: 3);
  static Timer? _autoDismissTimer;

  static void _cancelAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
  }

  // ── Swipe-hint counter ────────────────────────────────────────────────────
  // Show "Swipe away to ignore" hint for the first 3 pills ever shown.
  static const _hintKey = 'wave_pill_hint_count';
  static int _hintCount = 0;
  static bool _hintLoaded = false;

  /// Pre-warm the counter from SharedPreferences (call once at app start).
  static Future<void> preloadHintCount() async {
    if (_hintLoaded) return;
    _hintLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    _hintCount = prefs.getInt(_hintKey) ?? 0;
  }

  static bool get shouldShowHint => _hintCount < 3;

  /// Call this when showing the dev-sim pill (which bypasses [show]).
  static Future<void> recordPillShown() async => _recordPillShown();

  static Future<void> _recordPillShown() async {
    _hintCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hintKey, _hintCount);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  static void show({
    required OverlayState overlay,
    required WavePillData data,
    required FutureOr<void> Function(String targetUid) onWave,
    VoidCallback? onTap,
    Duration autoDismissAfter = defaultAutoDismissAfter,
  }) {
    // Replace any existing pill instead of stacking. Also cancels the outgoing
    // pill's timer, so it cannot dismiss the replacement.
    _forceDismiss();

    _currentTargetUid = data.targetUid;

    final showHint = shouldShowHint;
    if (showHint) _recordPillShown();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final topPad = MediaQuery.of(ctx).padding.top;
        return Positioned(
          // Sit below the top control bar (mode selector + Tremble title +
          // schedule button live at padding.top + 20, height 50 → bottom at
          // +70). +80 matches the in-app _MatchNotificationPillOverlay so the
          // two pill paths align and neither covers the radar-mode / schedule
          // controls (UI-POSTMATCH-PILLS).
          top: topPad + 80,
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
              // The user reacted — stop the clock before the send starts, so a
              // slow network cannot let the timer fire mid-request.
              onWave: () {
                _cancelAutoDismiss();
                return onWave(data.targetUid);
              },
              onIgnore: () => _removeEntry(entry),
              // Match reveal handled by activeMatchesStream → MatchRevealScreen.
              onMatch: null,
              onTap: onTap,
              showSwipeHint: showHint,
            ),
          ),
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);
    _autoDismissTimer = Timer(autoDismissAfter, () => _removeEntry(entry));
  }

  /// Programmatically dismiss the active pill (e.g. when the user navigates away
  /// or enters the match / trembling-window page).
  static void dismiss() => _forceDismiss();

  /// Dismiss the active pill only if it is the "{name} is nearby" pill for
  /// [targetUid] — e.g. once a wave has been sent to that person, the nearby
  /// prompt for them is stale. A no-op if no pill is showing, or the visible
  /// pill is about someone else.
  static void dismissForTarget(String targetUid) {
    if (_entry != null && _currentTargetUid == targetUid) {
      _forceDismiss();
    }
  }

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
    _cancelAutoDismiss();
    if (_entry != null && _entry!.mounted) _entry!.remove();
    _entry = null;
    _currentTargetUid = null;
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
    if (_entry == entry) {
      _entry = null;
      _currentTargetUid = null;
      _cancelAutoDismiss();
    }
  }

  static void _removeConfettiEntry(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
    if (_confettiEntry == entry) _confettiEntry = null;
  }
}
