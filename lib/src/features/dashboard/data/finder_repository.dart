import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _finderRegion = 'europe-west1';
const _updateFinderLocation = 'updateFinderLocation';
const _allowedResponseKeys = <String>{
  'partnerSharing',
  'bearing',
  'distanceM',
  'reason',
};
const _fallbackReasons = <String>{
  'window_over',
  'partner_not_opted',
  'partner_stale',
  'poor_accuracy',
};
final _windowIdPattern = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');

/// Derived finder data safe to expose to presentation code.
///
/// Raw coordinates and GPS accuracy deliberately never appear in this model.
class FinderReading {
  const FinderReading({
    required this.partnerSharing,
    this.bearing,
    this.distanceM,
    this.reason,
  });

  final bool partnerSharing;
  final double? bearing;
  final double? distanceM;
  final String? reason;

  bool get hasPreciseData {
    final currentBearing = bearing;
    final currentDistance = distanceM;
    return partnerSharing &&
        currentBearing != null &&
        currentBearing.isFinite &&
        currentBearing >= 0 &&
        currentBearing < 360 &&
        currentDistance != null &&
        currentDistance.isFinite &&
        currentDistance >= 0;
  }

  @override
  bool operator ==(Object other) =>
      other is FinderReading &&
      other.partnerSharing == partnerSharing &&
      other.bearing == bearing &&
      other.distanceM == distanceM &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(partnerSharing, bearing, distanceM, reason);

  @override
  String toString() =>
      'FinderReading(partnerSharing: $partnerSharing, bearing: $bearing, '
      'distanceM: $distanceM, reason: $reason)';
}

abstract interface class FinderRepository {
  /// Reads the current deterministic trembling-window identity once at opt-in.
  Future<String> readWindowId(String matchId);

  Future<FinderReading> updateLocation({
    required String matchId,
    required String windowId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool optIn,
  });
}

abstract interface class FinderCallableClient {
  Future<Object?> call({
    required String region,
    required String name,
    required Map<String, dynamic> data,
  });
}

class FirebaseFinderCallableClient implements FinderCallableClient {
  const FirebaseFinderCallableClient();

  @override
  Future<Object?> call({
    required String region,
    required String name,
    required Map<String, dynamic> data,
  }) async {
    final functions = FirebaseFunctions.instanceFor(region: region);
    final callable = functions.httpsCallable(name);
    final result = await callable.call<Object?>(data);
    return result.data;
  }
}

typedef FinderWindowIdReader = Future<Object?> Function(String matchId);

class FirebaseFinderRepository implements FinderRepository {
  FirebaseFinderRepository({
    FinderCallableClient? callableClient,
    FinderWindowIdReader? windowIdReader,
  })  : _callableClient =
            callableClient ?? const FirebaseFinderCallableClient(),
        _windowIdReader = windowIdReader ?? _readWindowIdFromFirestore;

  final FinderCallableClient _callableClient;
  final FinderWindowIdReader _windowIdReader;

  static Future<Object?> _readWindowIdFromFirestore(String matchId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .get();
    return snapshot.data()?['notificationOwnerWaveId'];
  }

  @override
  Future<String> readWindowId(String matchId) async {
    final value = await _windowIdReader(matchId);
    if (value is! String || !_windowIdPattern.hasMatch(value)) {
      throw const FormatException('Finder window is unavailable.');
    }
    return value;
  }

  @override
  Future<FinderReading> updateLocation({
    required String matchId,
    required String windowId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool optIn,
  }) async {
    final response = await _callableClient.call(
      region: _finderRegion,
      name: _updateFinderLocation,
      data: <String, dynamic>{
        'matchId': matchId,
        'windowId': windowId,
        'lat': latitude,
        'lng': longitude,
        'accuracy': accuracy,
        'optIn': optIn,
      },
    );
    return _parseResponse(response);
  }

  static FinderReading _parseResponse(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('Invalid finder response.');
    }

    final response = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String || !_allowedResponseKeys.contains(key)) {
        throw const FormatException('Unexpected finder response field.');
      }
      response[key] = entry.value;
    }

    final partnerSharing = response['partnerSharing'];
    if (partnerSharing is! bool) {
      throw const FormatException('Invalid partnerSharing value.');
    }

    if (partnerSharing) {
      if (response.containsKey('reason')) {
        throw const FormatException('Precise response cannot contain reason.');
      }
      final bearing = _finiteDouble(response['bearing']);
      final distanceM = _finiteDouble(response['distanceM']);
      if (bearing == null ||
          bearing < 0 ||
          bearing >= 360 ||
          distanceM == null ||
          distanceM < 0) {
        throw const FormatException('Invalid precise finder response.');
      }
      return FinderReading(
        partnerSharing: true,
        bearing: bearing,
        distanceM: distanceM,
      );
    }

    if (response.containsKey('bearing') || response.containsKey('distanceM')) {
      throw const FormatException('Fallback response contains precise data.');
    }
    final reason = response['reason'];
    if (reason != null &&
        (reason is! String || !_fallbackReasons.contains(reason))) {
      throw const FormatException('Invalid finder fallback reason.');
    }
    return FinderReading(
      partnerSharing: false,
      reason: reason as String?,
    );
  }

  static double? _finiteDouble(Object? value) {
    if (value is! num) return null;
    final result = value.toDouble();
    return result.isFinite ? result : null;
  }
}

final finderRepositoryProvider = Provider<FinderRepository>((ref) {
  return FirebaseFinderRepository();
});
