// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'precise_finder_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$preciseFinderControllerHash() =>
    r'0ca095ea592b3dd4915d9ba7b64c07e08e3d2e38';

/// Foreground-only, per-window precise finder session.
///
/// The current window identity is read once on the explicit opt-in tap and is
/// reused for the entire session. Polls are serialized so an older callable
/// response can never arrive after and overwrite a newer state.
///
/// Copied from [PreciseFinderController].
@ProviderFor(PreciseFinderController)
final preciseFinderControllerProvider =
    AutoDisposeNotifierProvider<PreciseFinderController, FinderState>.internal(
  PreciseFinderController.new,
  name: r'preciseFinderControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$preciseFinderControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PreciseFinderController = AutoDisposeNotifier<FinderState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
