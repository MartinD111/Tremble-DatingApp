// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeMatchesStreamHash() =>
    r'13552ec99639e8ad646c3441aedfe8445dcded8a';

/// See also [activeMatchesStream].
@ProviderFor(activeMatchesStream)
final activeMatchesStreamProvider =
    AutoDisposeStreamProvider<List<Match>>.internal(
  activeMatchesStream,
  name: r'activeMatchesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeMatchesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveMatchesStreamRef = AutoDisposeStreamProviderRef<List<Match>>;
String _$currentSearchHash() => r'8a43c94c25831928b9aa13a17332fde13bdcb9c2';

/// See also [currentSearch].
@ProviderFor(currentSearch)
final currentSearchProvider = AutoDisposeProvider<Match?>.internal(
  currentSearch,
  name: r'currentSearchProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSearchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentSearchRef = AutoDisposeProviderRef<Match?>;
String _$getMatchByUserIdHash() => r'991fd8382d21fdfb6c3b542bdc531537ef487cfb';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [getMatchByUserId].
@ProviderFor(getMatchByUserId)
const getMatchByUserIdProvider = GetMatchByUserIdFamily();

/// See also [getMatchByUserId].
class GetMatchByUserIdFamily extends Family<Match?> {
  /// See also [getMatchByUserId].
  const GetMatchByUserIdFamily();

  /// See also [getMatchByUserId].
  GetMatchByUserIdProvider call(
    String userId,
  ) {
    return GetMatchByUserIdProvider(
      userId,
    );
  }

  @override
  GetMatchByUserIdProvider getProviderOverride(
    covariant GetMatchByUserIdProvider provider,
  ) {
    return call(
      provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'getMatchByUserIdProvider';
}

/// See also [getMatchByUserId].
class GetMatchByUserIdProvider extends AutoDisposeProvider<Match?> {
  /// See also [getMatchByUserId].
  GetMatchByUserIdProvider(
    String userId,
  ) : this._internal(
          (ref) => getMatchByUserId(
            ref as GetMatchByUserIdRef,
            userId,
          ),
          from: getMatchByUserIdProvider,
          name: r'getMatchByUserIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getMatchByUserIdHash,
          dependencies: GetMatchByUserIdFamily._dependencies,
          allTransitiveDependencies:
              GetMatchByUserIdFamily._allTransitiveDependencies,
          userId: userId,
        );

  GetMatchByUserIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Match? Function(GetMatchByUserIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetMatchByUserIdProvider._internal(
        (ref) => create(ref as GetMatchByUserIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<Match?> createElement() {
    return _GetMatchByUserIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetMatchByUserIdProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetMatchByUserIdRef on AutoDisposeProviderRef<Match?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _GetMatchByUserIdProviderElement
    extends AutoDisposeProviderElement<Match?> with GetMatchByUserIdRef {
  _GetMatchByUserIdProviderElement(super.provider);

  @override
  String get userId => (origin as GetMatchByUserIdProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
