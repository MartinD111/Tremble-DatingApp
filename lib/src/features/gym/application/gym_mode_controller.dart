import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/gym_repository.dart';

enum GymModeStatus { inactive, loading, active, error }

class GymModeState {
  final GymModeStatus status;
  final String? activeGymId;
  final String? activeGymName;
  final String? errorMessage;

  const GymModeState({
    this.status = GymModeStatus.inactive,
    this.activeGymId,
    this.activeGymName,
    this.errorMessage,
  });

  bool get isActive => status == GymModeStatus.active;
  bool get isLoading => status == GymModeStatus.loading;

  GymModeState copyWith({
    GymModeStatus? status,
    String? activeGymId,
    String? activeGymName,
    String? errorMessage,
  }) {
    return GymModeState(
      status: status ?? this.status,
      activeGymId: activeGymId ?? this.activeGymId,
      activeGymName: activeGymName ?? this.activeGymName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class GymModeController extends StateNotifier<GymModeState> {
  final GymRepository _repo;

  GymModeController(this._repo) : super(const GymModeState());

  /// Fetches current device location, calls onGymModeActivate, then updates
  /// both local gym state and the auth user profile atomically.
  Future<void> activate({
    required String gymId,
    required String gymName,
  }) async {
    state = state.copyWith(status: GymModeStatus.loading, errorMessage: null);

    try {
      final position = await _requireLocation();

      await _repo.activateGymMode(
        gymId: gymId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      state = GymModeState(
        status: GymModeStatus.active,
        activeGymId: gymId,
        activeGymName: gymName,
      );
    } on Exception catch (e) {
      state = GymModeState(
        status: GymModeStatus.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  /// Calls onGymModeDeactivate, then immediately clears local Riverpod state
  /// so the UI reverts to "No gym selected" without needing a full refresh.
  Future<void> deactivate() async {
    // Optimistic: clear state immediately so UI is instant.
    state = const GymModeState();

    try {
      await _repo.deactivateGymMode();
    } on Exception catch (e) {
      // Revert on failure so the user knows deactivation didn't land.
      state = GymModeState(
        status: GymModeStatus.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  Future<Position> _requireLocation() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is required to verify you are at the gym.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  String _friendlyError(Exception e) {
    final msg = e.toString();
    if (msg.contains('failed-precondition') || msg.contains('away from')) {
      final match = RegExp(r'You are .+').firstMatch(msg);
      return match?.group(0) ?? 'You are not at this gym location.';
    }
    if (msg.contains('Location permission'))
      return msg.replaceFirst('Exception: ', '');
    if (msg.contains('not-found')) return 'Gym not found.';
    return 'Something went wrong. Please try again.';
  }
}

final gymModeControllerProvider =
    StateNotifierProvider<GymModeController, GymModeState>(
  (ref) => GymModeController(ref.watch(gymRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// RadarModeKind-agnostic activation state — shared by Event and Run controllers.
// ─────────────────────────────────────────────────────────────────────────────
enum SimpleModeStatus { inactive, loading, active, error }

class SimpleModeState {
  final SimpleModeStatus status;
  final String? activeName;
  final String? activeId;
  final String? errorMessage;

  const SimpleModeState({
    this.status = SimpleModeStatus.inactive,
    this.activeName,
    this.activeId,
    this.errorMessage,
  });

  bool get isActive => status == SimpleModeStatus.active;
  bool get isLoading => status == SimpleModeStatus.loading;

  SimpleModeState copyWith({
    SimpleModeStatus? status,
    String? activeName,
    String? activeId,
    String? errorMessage,
  }) =>
      SimpleModeState(
        status: status ?? this.status,
        activeName: activeName ?? this.activeName,
        activeId: activeId ?? this.activeId,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EventModeController — calls onEventModeActivate / onEventModeDeactivate
// ─────────────────────────────────────────────────────────────────────────────
class EventModeController extends StateNotifier<SimpleModeState> {
  final GymRepository _repo;

  EventModeController(this._repo) : super(const SimpleModeState());

  Future<void> activate({
    required String eventId,
    required String eventName,
  }) async {
    state = state.copyWith(
        status: SimpleModeStatus.loading, errorMessage: null);

    try {
      await _repo.activateEventMode(eventId: eventId, eventName: eventName);
      state = SimpleModeState(
        status: SimpleModeStatus.active,
        activeId: eventId,
        activeName: eventName,
      );
    } on Exception catch (e) {
      state = SimpleModeState(
        status: SimpleModeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deactivate() async {
    // Optimistic clear.
    state = const SimpleModeState();
    try {
      await _repo.deactivateEventMode();
    } on Exception catch (e) {
      state = SimpleModeState(
        status: SimpleModeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final eventModeControllerProvider =
    StateNotifierProvider<EventModeController, SimpleModeState>(
  (ref) => EventModeController(ref.watch(gymRepositoryProvider)),
);

// ─────────────────────────────────────────────────────────────────────────────
// RunModeController — calls onRunModeActivate / onRunModeDeactivate
// No gym/event selection UI; activation is immediate (no args needed).
// ─────────────────────────────────────────────────────────────────────────────
class RunModeController extends StateNotifier<SimpleModeState> {
  final GymRepository _repo;

  RunModeController(this._repo) : super(const SimpleModeState());

  Future<void> activate() async {
    state = state.copyWith(
        status: SimpleModeStatus.loading, errorMessage: null);

    try {
      await _repo.activateRunMode();
      state = const SimpleModeState(status: SimpleModeStatus.active);
    } on Exception catch (e) {
      state = SimpleModeState(
        status: SimpleModeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deactivate() async {
    state = const SimpleModeState();
    try {
      await _repo.deactivateRunMode();
    } on Exception catch (e) {
      state = SimpleModeState(
        status: SimpleModeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final runModeControllerProvider =
    StateNotifierProvider<RunModeController, SimpleModeState>(
  (ref) => RunModeController(ref.watch(gymRepositoryProvider)),
);
