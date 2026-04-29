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

  /// Fetches current device location, then calls the backend to validate
  /// proximity and activate gym mode.
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

  /// Manually deactivates gym mode.
  Future<void> deactivate() async {
    state = state.copyWith(status: GymModeStatus.loading);

    try {
      await _repo.deactivateGymMode();
      state = const GymModeState();
    } on Exception catch (e) {
      state = GymModeState(
        status: GymModeStatus.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  /// Ensures location permission is granted and returns the current position.
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
      // Surface the distance message from the backend
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
