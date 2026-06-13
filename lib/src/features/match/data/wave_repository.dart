import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api_client.dart';

part 'wave_repository.g.dart';

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
      if (e.code == 'permission-denied') {
        throw TrembleApiException(
          code: e.code,
          message: "You can't wave at this person right now.",
          details: e.details,
        );
      }
      rethrow;
    }
  }

  /// Performs a gesture (Greet/Accept) on a match document.
  Future<void> sendGesture(String matchId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('matches').doc(matchId).update({
      'gestures.${currentUser.uid}': true,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
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
  Future<void> markMatchAsFound(String matchId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 1. Update match status
    await _firestore.collection('matches').doc(matchId).update({
      'status': 'found',
      'isFound': true,
      'foundAt': FieldValue.serverTimestamp(),
    });

    // 2. Update user last found timestamp to enforce 30m cooldown for free users
    await _firestore.collection('users').doc(currentUser.uid).update({
      'lastWaveFoundAt': FieldValue.serverTimestamp(),
    });
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
