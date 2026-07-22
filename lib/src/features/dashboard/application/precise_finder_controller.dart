import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tremble/src/features/dashboard/data/finder_repository.dart';

part 'precise_finder_controller.g.dart';

const _pollCadence = Duration(seconds: 3);
const _finderDistanceFilterMeters = 2;

typedef FinderLocationStream = Stream<Position> Function(
  LocationSettings settings,
);
typedef FinderClock = DateTime Function();
typedef FinderDelay = Future<void> Function(Duration duration);

final finderLocationStreamProvider = Provider<FinderLocationStream>((ref) {
  return (settings) => Geolocator.getPositionStream(locationSettings: settings);
});

final finderClockProvider = Provider<FinderClock>((ref) => DateTime.now);
final finderDelayProvider =
    Provider<FinderDelay>((ref) => Future<void>.delayed);

/// Serializes teardown and replacement activation for the same match, even
/// across auto-dispose creating a new controller instance.
class FinderSessionCoordinator {
  final _cleanupByMatch = <String, Future<void>>{};

  Future<void> waitForCleanup(String matchId) async {
    final cleanup = _cleanupByMatch[matchId];
    if (cleanup != null) await cleanup;
  }

  void trackCleanup(String matchId, Future<void> cleanup) {
    _cleanupByMatch[matchId] = cleanup;
    unawaited(
      cleanup.then(
        (_) => _remove(matchId, cleanup),
        onError: (_, __) => _remove(matchId, cleanup),
      ),
    );
  }

  void _remove(String matchId, Future<void> cleanup) {
    if (identical(_cleanupByMatch[matchId], cleanup)) {
      _cleanupByMatch.remove(matchId);
    }
  }
}

final finderSessionCoordinatorProvider = Provider<FinderSessionCoordinator>(
  (ref) => FinderSessionCoordinator(),
);

enum FinderStatus { idle, waiting, active, fallback, stopped }

class FinderState {
  const FinderState._(this.status, this.reading);

  const FinderState.idle() : this._(FinderStatus.idle, null);

  const FinderState.waiting([FinderReading? reading])
      : this._(FinderStatus.waiting, reading);

  const FinderState.active(FinderReading reading)
      : this._(FinderStatus.active, reading);

  factory FinderState.fallback({String? reason}) => FinderState._(
        FinderStatus.fallback,
        FinderReading(partnerSharing: false, reason: reason),
      );

  factory FinderState.stopped({String? reason}) => FinderState._(
        FinderStatus.stopped,
        FinderReading(partnerSharing: false, reason: reason),
      );

  final FinderStatus status;
  final FinderReading? reading;

  @override
  bool operator ==(Object other) =>
      other is FinderState &&
      other.status == status &&
      other.reading == reading;

  @override
  int get hashCode => Object.hash(status, reading);

  @override
  String toString() => 'FinderState(status: $status, reading: $reading)';
}

/// Foreground-only, per-window precise finder session.
///
/// The current window identity is read once on the explicit opt-in tap and is
/// reused for the entire session. Polls are serialized so an older callable
/// response can never arrive after and overwrite a newer state.
@riverpod
class PreciseFinderController extends _$PreciseFinderController {
  StreamSubscription<Position>? _positionSubscription;
  Position? _latestPosition;
  Position? _pendingPosition;
  DateTime? _lastSentAt;
  Future<void>? _requestDone;
  Future<void>? _cadenceDelay;
  Future<void>? _stopFuture;
  String? _matchId;
  String? _windowId;
  bool _sessionActive = false;
  bool _requestInFlight = false;
  bool _locationAvailable = false;
  bool _disposed = false;
  int _generation = 0;
  int _cadenceDelayGeneration = 0;
  late FinderRepository _repository;
  late FinderLocationStream _locationStream;
  late FinderClock _clock;
  late FinderDelay _delay;
  late FinderSessionCoordinator _coordinator;

  @override
  FinderState build() {
    // Capture dependencies while Ref is valid. Auto-dispose cleanup may await
    // an in-flight request before revoking, at which point Ref is disposed.
    _repository = ref.read(finderRepositoryProvider);
    _locationStream = ref.read(finderLocationStreamProvider);
    _clock = ref.read(finderClockProvider);
    _delay = ref.read(finderDelayProvider);
    _coordinator = ref.read(finderSessionCoordinatorProvider);
    ref.onDispose(() {
      _disposed = true;
      unawaited(stop());
    });
    return const FinderState.idle();
  }

  Future<void> optInAndStart(String matchId) async {
    final previousStop = _stopFuture;
    if (previousStop != null) await previousStop;
    if (_disposed) return;
    if (_sessionActive) return;

    final generation = ++_generation;
    state = const FinderState.waiting();
    await _coordinator.waitForCleanup(matchId);
    if (_disposed || generation != _generation || _sessionActive) return;

    _stopFuture = null;
    _matchId = matchId;
    _windowId = null;
    _latestPosition = null;
    _pendingPosition = null;
    _lastSentAt = null;
    _locationAvailable = false;
    _sessionActive = true;

    try {
      // This is deliberately the only match-window read in the session. A
      // deterministic restart must invalidate old sessions server-side rather
      // than silently rebinding them to the new window on a later poll.
      final windowId = await _repository.readWindowId(matchId);
      if (!_isCurrent(generation)) return;
      _windowId = windowId;

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _finderDistanceFilterMeters,
      );
      _locationAvailable = true;
      _positionSubscription = _locationStream(settings).listen(
        _acceptPosition,
        onError: _handleLocationError,
        onDone: _handleLocationDone,
      );
    } on Object {
      if (!_isCurrent(generation)) return;
      _sessionActive = false;
      _locationAvailable = false;
      state = FinderState.fallback(reason: 'location');
    }
  }

  void _acceptPosition(Position position) {
    if (!_sessionActive) return;
    _locationAvailable = true;
    _latestPosition = position;

    if (_requestInFlight || !_cadenceElapsed) {
      _pendingPosition = position;
      if (!_requestInFlight) _schedulePending();
      return;
    }

    _pendingPosition = null;
    _startRequest(position);
  }

  bool get _cadenceElapsed {
    final lastSentAt = _lastSentAt;
    if (lastSentAt == null) return true;
    final elapsed = _clock().difference(lastSentAt);
    return !elapsed.isNegative && elapsed >= _pollCadence;
  }

  void _startRequest(Position position) {
    if (!_sessionActive || _requestInFlight) return;
    _cadenceDelayGeneration++;
    _cadenceDelay = null;
    _requestInFlight = true;
    _lastSentAt = _clock();
    unawaited(_sendPosition(position, _generation));
  }

  Future<void> _sendPosition(Position position, int generation) async {
    final done = Completer<void>();
    _requestDone = done.future;
    FinderReading? reading;
    Object? requestError;

    try {
      reading = await _repository.updateLocation(
        matchId: _matchId!,
        windowId: _windowId!,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        optIn: true,
      );
    } on Object catch (error) {
      requestError = error;
    } finally {
      _requestInFlight = false;
      _requestDone = null;
      done.complete();
    }

    if (!_isCurrent(generation)) return;

    if (requestError != null) {
      state = FinderState.fallback(reason: 'callable');
    } else if (reading?.reason == 'window_over') {
      await stop();
      return;
    } else {
      _applyReading(reading!);
    }

    if (_locationAvailable) _pendingPosition ??= _latestPosition;
    final pending = _pendingPosition;
    if (pending != null && _sessionActive) {
      if (_cadenceElapsed) {
        _pendingPosition = null;
        _startRequest(pending);
      } else {
        _schedulePending();
      }
    }
  }

  void _schedulePending() {
    if (!_sessionActive ||
        !_locationAvailable ||
        _cadenceDelay != null ||
        _lastSentAt == null) {
      return;
    }
    final elapsed = _clock().difference(_lastSentAt!);
    final remaining = elapsed.isNegative
        ? _pollCadence
        : elapsed >= _pollCadence
            ? Duration.zero
            : _pollCadence - elapsed;
    final sessionGeneration = _generation;
    final delayGeneration = ++_cadenceDelayGeneration;
    final delay = _delay(remaining);
    _cadenceDelay = delay;
    unawaited(
      delay.then((_) {
        if (delayGeneration != _cadenceDelayGeneration) return;
        _cadenceDelay = null;
        if (!_isCurrent(sessionGeneration) || _requestInFlight) return;
        final pending = _pendingPosition;
        if (pending == null) return;
        if (!_cadenceElapsed) {
          _schedulePending();
          return;
        }
        _pendingPosition = null;
        _startRequest(pending);
      }, onError: (_) {
        if (delayGeneration == _cadenceDelayGeneration) {
          _cadenceDelay = null;
        }
      }),
    );
  }

  void _applyReading(FinderReading reading) {
    if (reading.hasPreciseData) {
      state = FinderState.active(reading);
      return;
    }

    if (reading.partnerSharing) {
      state = FinderState.fallback(reason: 'callable');
      return;
    }

    if (reading.reason == 'partner_not_opted') {
      state = FinderState.waiting(reading);
      return;
    }

    state = FinderState.fallback(reason: reading.reason ?? 'callable');
  }

  void _handleLocationError(Object _) {
    if (!_sessionActive) return;
    _locationAvailable = false;
    _pendingPosition = null;
    _cancelCadenceDelay();
    state = FinderState.fallback(reason: 'location');
  }

  void _handleLocationDone() {
    if (!_sessionActive) return;
    _locationAvailable = false;
    _pendingPosition = null;
    _cancelCadenceDelay();
    state = FinderState.fallback(reason: 'location');
  }

  void _cancelCadenceDelay() {
    _cadenceDelayGeneration++;
    _cadenceDelay = null;
  }

  Future<void> stop() {
    final existing = _stopFuture;
    if (existing != null) return existing;
    final completer = Completer<void>();
    final future = completer.future;
    _stopFuture = future;
    final matchId = _matchId;
    if (matchId != null) _coordinator.trackCleanup(matchId, future);
    unawaited(_completeStop(completer));
    return future;
  }

  Future<void> _completeStop(Completer<void> completer) async {
    try {
      await _performStop();
    } on Object {
      if (!_disposed) state = FinderState.stopped(reason: 'cleanup_failed');
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

  Future<void> _performStop() async {
    _sessionActive = false;
    _locationAvailable = false;
    _generation++;
    _cancelCadenceDelay();
    _pendingPosition = null;

    final subscription = _positionSubscription;
    _positionSubscription = null;
    String? stopReason;
    try {
      await subscription?.cancel();
    } on Object {
      stopReason = 'location';
    }

    final requestDone = _requestDone;
    if (requestDone != null) await requestDone;

    final matchId = _matchId;
    final windowId = _windowId;
    final lastPosition = _latestPosition;
    if (matchId != null && windowId != null) {
      try {
        await _repository.updateLocation(
          matchId: matchId,
          windowId: windowId,
          latitude: lastPosition?.latitude ?? 0,
          longitude: lastPosition?.longitude ?? 0,
          accuracy: lastPosition?.accuracy ?? 0,
          optIn: false,
        );
      } on Object {
        stopReason = 'revocation_failed';
      }
    }

    _matchId = null;
    _windowId = null;
    _latestPosition = null;
    _lastSentAt = null;
    if (!_disposed) state = FinderState.stopped(reason: stopReason);
  }

  bool _isCurrent(int generation) =>
      !_disposed && _sessionActive && generation == _generation;
}
