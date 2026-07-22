import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api_client.dart';

part 'wave_repository.g.dart';

/// Maps sendWave failures to user-facing messages. Returns the SAME instance
/// when no mapping applies so callers can rethrow the original.
@visibleForTesting
TrembleApiException mapSendWaveException(TrembleApiException e) {
  if (e.code == 'permission-denied') {
    return TrembleApiException(
      code: e.code,
      message: "You can't wave at this person right now.",
      details: e.details,
    );
  }
  // Rule #105: server rejects waves at radar-off targets (defense-in-depth).
  final details = e.details;
  final reason = details is Map ? details['reason'] : null;
  if (e.code == 'failed-precondition' && reason == 'target_radar_off') {
    return TrembleApiException(
      code: e.code,
      message: "They're not on the radar right now.",
      details: e.details,
    );
  }
  return e;
}

class WaveRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TrembleApiClient _api;

  WaveRepository(this._firestore, this._auth, {TrembleApiClient? api})
      : _api = api ?? TrembleApiClient();

  /// Pošlje wave prek Cloud Function (rate-limited za free userje: 5/30 dni).
  Future<void> sendWave(String targetUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Uporabnik ni prijavljen.');

    try {
      await _api.call('sendWave', data: {'targetUid': targetUid});
    } on AccountSuspendedException {
      rethrow;
    } on TrembleApiException catch (e) {
      final mapped = mapSendWaveException(e);
      if (identical(mapped, e)) rethrow;
      throw mapped;
    }
  }

  /// Performs a gesture (Greet/Accept) on a match document.
  ///
  /// Routed through a Cloud Function because firestore.rules only permits a
  /// client to change `seenBy` on /matches; a direct gesture-field write is
  /// denied.
  Future<void> sendGesture(String matchId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _api.call('sendMatchGesture', data: {'matchId': matchId});
  }

  /// Označi match kot viden s strani trenutnega uporabnika.
  Future<void> markMatchAsSeen(String matchId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('matches').doc(matchId).update({
      'seenBy': FieldValue.arrayUnion([currentUser.uid]),
    });
  }

  /// Označi, da sta se osebi našli.
  ///
  /// Routed through a Cloud Function: the match status write and the
  /// `lastWaveFoundAt` cooldown stamp are both backend-authoritative. A direct
  /// client write to /matches (status/isFound/foundAt) is denied by
  /// firestore.rules and previously crashed the trembling window.
  Future<void> markMatchAsFound(String matchId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _api.call('markMatchFound', data: {'matchId': matchId});
  }

  /// Označi, da je čas za iskanje potekel.
  Future<void> markMatchAsExpired(String matchId) async {
    await _firestore.collection('matches').doc(matchId).update({
      'status': 'expired',
    });
  }
}

@Riverpod(keepAlive: true)
WaveRepository waveRepository(WaveRepositoryRef ref) {
  return WaveRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}
