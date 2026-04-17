import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wave_repository.g.dart';

class WaveRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WaveRepository(this._firestore, this._auth);

  /// Zapiše nov wave dokument v Firestore.
  Future<void> sendWave(String targetUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Uporabnik ni prijavljen.');

    await _firestore.collection('waves').add({
      'fromUid': currentUser.uid,
      'toUid': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
