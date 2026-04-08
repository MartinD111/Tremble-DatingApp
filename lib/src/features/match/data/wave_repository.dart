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

  /// Označi match kot viden s strani trenutnega uporabnika.
  Future<void> markMatchAsSeen(String matchId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('matches').doc(matchId).update({
      'seenBy': FieldValue.arrayUnion([currentUser.uid]),
    });
  }
}

@Riverpod(keepAlive: true)
WaveRepository waveRepository(WaveRepositoryRef ref) {
  return WaveRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}
