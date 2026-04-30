import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Stream of active run encounters targeted at the current user.
// Returns a list of documents from 'active_run_crosses' where userIds contains myId and status == 'pending'.
final activeRunCrossesProvider =
    StreamProvider.family<List<QueryDocumentSnapshot>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('active_run_crosses')
      .where('userIds', arrayContains: userId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    final docs = snapshot.docs.where((doc) {
      final data = doc.data();
      // Filter out expired documents just in case local clock vs server clock
      if (data['expiresAt'] != null) {
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();
        if (expiresAt.isBefore(DateTime.now())) {
          return false;
        }
      }
      // Filter out if user dismissed it
      final dismissedBy = data['dismissedBy'] as List<dynamic>? ?? [];
      if (dismissedBy.contains(userId)) {
        return false;
      }

      // We also only want crosses where the OTHER person hasn't waved yet?
      // Actually, if we both waved, status becomes 'matched'.
      // So pending means one or none waved. We'll show the card to the user if they HAVEN'T waved yet.
      final signals = data['signals'] as Map<String, dynamic>? ?? {};
      final iWaved = signals[userId] == true;
      return !iWaved;
    }).toList();

    return docs;
  });
});

class RunClubRepository {
  RunClubRepository();

  /// User taps [Send Wave] on the LiveRunCard
  Future<void> sendWave(String crossId, String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('active_run_crosses')
        .doc(crossId);

    // We update the `signals` map.
    // The Cloud Function will listen to this update, and if both waved, will transition to match.
    await docRef.set({
      'signals': {
        userId: true,
      }
    }, SetOptions(merge: true));
  }

  Future<void> dismissEncounter(String crossId, String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('active_run_crosses')
        .doc(crossId);

    await docRef.set({
      'dismissedBy': FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));
  }
}

final runClubRepositoryProvider = Provider((ref) => RunClubRepository());

// Stream of ALL run encounters for the current user — including ones already
// waved — filtered only by expiresAt > now and not dismissed.
// Used by RunRecapScreen to show the full list of who the user crossed paths with.
final recentRunCrossesProvider =
    StreamProvider.family<List<QueryDocumentSnapshot>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('active_run_crosses')
      .where('userIds', arrayContains: userId)
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();
    final docs = snapshot.docs.where((doc) {
      final data = doc.data();
      if (data['expiresAt'] != null) {
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();
        if (expiresAt.isBefore(now)) return false;
      }
      final dismissedBy = data['dismissedBy'] as List<dynamic>? ?? [];
      if (dismissedBy.contains(userId)) return false;
      return true;
    }).toList();

    // Most recent first
    docs.sort((a, b) {
      final aTs = (a.data()['timestamp'] as Timestamp?)?.toDate();
      final bTs = (b.data()['timestamp'] as Timestamp?)?.toDate();
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });

    return docs;
  });
});

// Stream of permanent run encounters (History) for the current user.
// These are logged by Cloud Functions and do not expire.
final runHistoryProvider =
    StreamProvider.family<List<QueryDocumentSnapshot>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('run_encounters')
      .doc(userId)
      .collection('encounters')
      .orderBy('timestamp', descending: true)
      .limit(20) // Show last 20 for the history
      .snapshots()
      .map((snapshot) => snapshot.docs);
});
