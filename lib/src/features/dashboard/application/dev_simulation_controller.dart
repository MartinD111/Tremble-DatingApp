import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dev_mock_users.dart';
import '../../../core/notification_service.dart';
import '../../matches/data/match_repository.dart';
import 'dev_mock_matches_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DevSimulationController
//
// Drives the dev-mode proximity simulation as a strict state machine. Replaces
// the legacy "ping-first then dialog" behavior with a passive notification
// flow:
//
//   idle ──start()──▶ countdownToDiscovery
//                       │ (10s)
//                       ▼
//                    waitingForAction (pill: "Sarah, 24" + Wave/Ignore)
//                       │
//        userTapsWave ──┴── 10s no-action
//             │              │
//             ▼              ▼
//         waveSent       waveReceived (pill: "Sarah sent you a wave!")
//             │              │
//          (2.5s)      userTapsWaveBack
//             │              │
//             └──┬───────────┘
//                ▼
//        mutualWaveActive (radar ping unlocks, 30m timer, organic tracking)
//                │
//   stop / timeout / found
//                ▼
//             completed (mock profile persisted to People tab)
//
// Ignore at any state → idle. Profile is NOT persisted on Ignore.
// ─────────────────────────────────────────────────────────────────────────────

enum DevSimPhase {
  idle,
  countdownToDiscovery,
  waitingForAction,
  waveSent,
  waveReceived,
  mutualWaveActive,
  completed,
}

@immutable
class DevSimulationState {
  final DevSimPhase phase;
  final MatchProfile? profile;
  final DateTime? mutualWaveExpiresAt;
  final double pingDistance; // 0.0 (center) → 1.0 (edge); only meaningful in mutualWaveActive
  final double pingAngle; // radians
  final bool showMutualFlash; // brief "Mutual Wave! Find them." flash

  const DevSimulationState({
    required this.phase,
    this.profile,
    this.mutualWaveExpiresAt,
    this.pingDistance = 0.9,
    this.pingAngle = 0.8,
    this.showMutualFlash = false,
  });

  const DevSimulationState.idle() : this(phase: DevSimPhase.idle);

  DevSimulationState copyWith({
    DevSimPhase? phase,
    MatchProfile? profile,
    DateTime? mutualWaveExpiresAt,
    double? pingDistance,
    double? pingAngle,
    bool? showMutualFlash,
  }) {
    return DevSimulationState(
      phase: phase ?? this.phase,
      profile: profile ?? this.profile,
      mutualWaveExpiresAt: mutualWaveExpiresAt ?? this.mutualWaveExpiresAt,
      pingDistance: pingDistance ?? this.pingDistance,
      pingAngle: pingAngle ?? this.pingAngle,
      showMutualFlash: showMutualFlash ?? this.showMutualFlash,
    );
  }

  bool get isMutualWaveActive => phase == DevSimPhase.mutualWaveActive;
  bool get hasPillVisible =>
      phase == DevSimPhase.waitingForAction ||
      phase == DevSimPhase.waveSent ||
      phase == DevSimPhase.waveReceived;
}

class DevSimulationController extends StateNotifier<DevSimulationState> {
  DevSimulationController(this._ref) : super(const DevSimulationState.idle());

  final Ref _ref;
  final Random _rng = Random();

  // Stable IDs so a follow-up notification (waveReceived) replaces the previous
  // one in the shade rather than stacking.
  // Reuses the singleton plugin already initialized by NotificationService —
  // calling .show() on a fresh instance throws because init() was never run on
  // it, which previously masked legitimate failures and risked breaking the
  // state-update chain when callers forget the try/catch.
  static const int _kHeadsUpNotificationId = 7710;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Timing constants (single source of truth — keeps tests honest).
  static const Duration kDiscoveryDelay = Duration(seconds: 10);
  static const Duration kUserActionWindow = Duration(seconds: 10);
  static const Duration kWaveSentToMutual = Duration(milliseconds: 2500);
  static const Duration kMutualWaveDuration = Duration(minutes: 30);
  static const Duration kTrackingTick = Duration(milliseconds: 500);
  static const Duration kFlashDuration = Duration(milliseconds: 1800);

  // Tracking — distance progresses 0.9 → 0.1 over ~50s with organic wobble.
  static const double _trackingStartDistance = 0.9;
  static const double _trackingEndDistance = 0.1;
  static const Duration _trackingApproachWindow = Duration(seconds: 50);

  Timer? _discoveryTimer;
  Timer? _userActionTimer;
  Timer? _waveSentTimer;
  Timer? _trackingTimer;
  Timer? _expiryTimer;
  Timer? _flashTimer;

  DateTime? _mutualWaveStartedAt;
  double _baseAngle = 0.8;

  /// Begin Phase 1. Caller must guard with kDebugMode + bypass flag.
  void start({MatchProfile? profile}) {
    if (state.phase != DevSimPhase.idle) return;
    final pick = profile ?? _pickMockProfile();
    state = state.copyWith(
      phase: DevSimPhase.countdownToDiscovery,
      profile: pick,
    );
    _discoveryTimer = Timer(kDiscoveryDelay, _enterWaitingForAction);
  }

  void _enterWaitingForAction() {
    if (state.phase != DevSimPhase.countdownToDiscovery) return;
    state = state.copyWith(phase: DevSimPhase.waitingForAction);
    _userActionTimer = Timer(kUserActionWindow, _enterWaveReceived);
    final p = state.profile;
    if (p != null) {
      _showHeadsUpNotification(
        title: '${p.name} is nearby',
        body: 'Tap to wave or open Tremble to respond.',
      );
    }
  }

  /// Phase 2 / Scenario A — user initiates the wave.
  void onUserWave() {
    if (state.phase != DevSimPhase.waitingForAction) return;
    _userActionTimer?.cancel();
    _dismissHeadsUpNotification();
    state = state.copyWith(phase: DevSimPhase.waveSent);
    _waveSentTimer = Timer(kWaveSentToMutual, _enterMutualWaveActive);
  }

  /// Phase 2 / Scenario B — mock user waves first after timeout.
  void _enterWaveReceived() {
    if (state.phase != DevSimPhase.waitingForAction) return;
    state = state.copyWith(phase: DevSimPhase.waveReceived);
    final p = state.profile;
    if (p != null) {
      _showHeadsUpNotification(
        title: '${p.name} sent you a wave!',
        body: 'Open Tremble to wave back.',
      );
    }
  }

  /// Phase 2 / Scenario B — user taps Wave Back.
  void onUserWaveBack() {
    if (state.phase != DevSimPhase.waveReceived) return;
    _enterMutualWaveActive();
  }

  /// Ignore at any pill state → abort, do NOT persist.
  void onIgnore() {
    if (!state.hasPillVisible) return;
    _resetTimers();
    _dismissHeadsUpNotification();
    state = const DevSimulationState.idle();
  }

  void _enterMutualWaveActive() {
    _waveSentTimer?.cancel();
    _userActionTimer?.cancel();
    _dismissHeadsUpNotification();
    _mutualWaveStartedAt = DateTime.now();
    _baseAngle = _rng.nextDouble() * 2 * pi;
    state = state.copyWith(
      phase: DevSimPhase.mutualWaveActive,
      mutualWaveExpiresAt: DateTime.now().add(kMutualWaveDuration),
      pingDistance: _trackingStartDistance,
      pingAngle: _baseAngle,
      showMutualFlash: true,
    );
    _flashTimer = Timer(kFlashDuration, () {
      if (state.phase == DevSimPhase.mutualWaveActive) {
        state = state.copyWith(showMutualFlash: false);
      }
    });
    _trackingTimer = Timer.periodic(kTrackingTick, (_) => _tickTracking());
    _expiryTimer = Timer(kMutualWaveDuration, () => _terminate(persist: true));
  }

  void _tickTracking() {
    if (state.phase != DevSimPhase.mutualWaveActive ||
        _mutualWaveStartedAt == null) {
      return;
    }
    final elapsed = DateTime.now().difference(_mutualWaveStartedAt!);
    final progress =
        (elapsed.inMilliseconds / _trackingApproachWindow.inMilliseconds)
            .clamp(0.0, 1.0);
    final base = _trackingStartDistance +
        (_trackingEndDistance - _trackingStartDistance) * progress;

    // Organic wobble — small random walk so it doesn't read as robotic.
    final distanceWobble = (_rng.nextDouble() - 0.5) * 0.06;
    final angleWobble = (_rng.nextDouble() - 0.5) * 0.18;

    final nextDistance = (base + distanceWobble).clamp(0.05, 1.0);
    final nextAngle = state.pingAngle + angleWobble;

    state = state.copyWith(
      pingDistance: nextDistance.toDouble(),
      pingAngle: nextAngle,
    );
  }

  /// User pressed "Stop Search" or "Found each other" — persist and reset.
  void stopAndPersist() {
    if (state.phase != DevSimPhase.mutualWaveActive) return;
    _terminate(persist: true);
  }

  /// External cancellation (e.g., radar toggled off) — does NOT persist.
  void cancelWithoutPersist() {
    _resetTimers();
    _dismissHeadsUpNotification();
    state = const DevSimulationState.idle();
  }

  void _terminate({required bool persist}) {
    final profile = state.profile;
    _resetTimers();
    _dismissHeadsUpNotification();
    if (persist && profile != null) {
      _ref.read(devMockMatchesProvider.notifier).add(profile);
    }
    state = const DevSimulationState.idle();
  }

  void _resetTimers() {
    _discoveryTimer?.cancel();
    _userActionTimer?.cancel();
    _waveSentTimer?.cancel();
    _trackingTimer?.cancel();
    _expiryTimer?.cancel();
    _flashTimer?.cancel();
    _discoveryTimer = null;
    _userActionTimer = null;
    _waveSentTimer = null;
    _trackingTimer = null;
    _expiryTimer = null;
    _flashTimer = null;
    _mutualWaveStartedAt = null;
  }

  MatchProfile _pickMockProfile() {
    return kMockNearbyUsers[_rng.nextInt(kMockNearbyUsers.length)];
  }

  // ── Heads-up system notification ────────────────────────────────────────
  // Fired when entering pill-visible phases so the user is alerted even when
  // the app is backgrounded or the screen is locked. Uses the existing
  // `tremble_match` channel (Importance.max / Priority.max) so Android renders
  // it as a heads-up banner. Tapping the notification routes through the OS's
  // default activity launcher → brings the app to the foreground, where the
  // global MatchNotificationPill in HomeScreen is already rendered.
  Future<void> _showHeadsUpNotification({
    required String title,
    required String body,
  }) async {
    // Foreground suppression: when the app is resumed (visible + interactive),
    // the global MatchNotificationPill is already on-screen — firing a system
    // heads-up on top is redundant and feels noisy. Only fire when the app is
    // backgrounded, inactive (call/control-center overlay), hidden, or
    // detached. Lifecycle is null very briefly during the first frame; treat
    // null as "not foreground" so we don't drop the very first wave.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == AppLifecycleState.resumed) {
      return;
    }
    try {
      const androidDetails = AndroidNotificationDetails(
        TrembleNotificationChannels.match,
        'Tremble — Wave',
        channelDescription: 'Alerts when someone is nearby or sends a wave.',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.message,
        fullScreenIntent: false,
        playSound: true,
        enableVibration: true,
        ticker: 'Tremble',
        visibility: NotificationVisibility.public,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'WAVE_CATEGORY',
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      await _localNotifications.show(
        _kHeadsUpNotificationId,
        title,
        body,
        details,
        payload: jsonEncode({
          'type': TrembleNotificationType.incomingWave,
          'source': 'dev_simulation',
        }),
      );
    } catch (e) {
      debugPrint('[DevSim] heads-up notification failed: $e');
    }
  }

  Future<void> _dismissHeadsUpNotification() async {
    try {
      await _localNotifications.cancel(_kHeadsUpNotificationId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _resetTimers();
    super.dispose();
  }
}

final devSimulationControllerProvider =
    StateNotifierProvider<DevSimulationController, DevSimulationState>((ref) {
  return DevSimulationController(ref);
});
