// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proximity_ping_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sonarPingControllerHash() =>
    r'e4540e04d2fabfd812fdd90b9dbc1ccafd52ee09';

/// Sonar data source for the trembling-window radar dot.
///
/// Sources the partner's smoothed BLE RSSI from [BleService.proximityStream]
/// (the same signal behind the warmth mechanic) and emits a [SonarPing] the
/// production writer pipes into `pingDistanceProvider` / `pingAngleProvider`.
///
/// Phase A: distance drives the dot radius (near → center) and the ping loop
/// rate; the angle is a slow orbit (no bearing yet). Signal loss fades the dot
/// to a "searching" state. Phase B replaces the orbit with a real bearing.
///
/// Also drives the existing haptic ping loop (closer → faster/stronger).
///
/// Copied from [SonarPingController].
@ProviderFor(SonarPingController)
final sonarPingControllerProvider =
    AutoDisposeNotifierProvider<SonarPingController, SonarPing>.internal(
  SonarPingController.new,
  name: r'sonarPingControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sonarPingControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SonarPingController = AutoDisposeNotifier<SonarPing>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
