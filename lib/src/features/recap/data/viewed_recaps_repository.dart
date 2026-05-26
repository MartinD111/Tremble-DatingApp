import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matches/data/match_repository.dart';

final viewedRecapsRepositoryProvider = Provider<ViewedRecapsRepository>((ref) {
  return ViewedRecapsRepository();
});

final viewedRecapIdsProvider =
    StreamProvider.family<Set<String>, String>((ref, uid) {
  if (uid.isEmpty) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('viewedRecaps')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
});

class ViewedRecapsRepository {
  static const Set<String> validTypes = {'run', 'event', 'gym'};

  Future<void> markViewedRecapOnClose({
    required String uid,
    required String recapId,
    required String type,
  }) async {
    if (uid.isEmpty || recapId.isEmpty) return;
    if (!validTypes.contains(type)) {
      throw ArgumentError.value(type, 'type', 'Must be run, event, or gym');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('viewedRecaps')
        .doc(recapId)
        .set({
      'closedAt': FieldValue.serverTimestamp(),
      'type': type,
    });
  }

  Future<void> markViewedRecapsOnClose({
    required String uid,
    required Iterable<String> recapIds,
    required String type,
  }) async {
    for (final recapId in recapIds.toSet()) {
      await markViewedRecapOnClose(
        uid: uid,
        recapId: recapId,
        type: type,
      );
    }
  }
}

bool shouldHideViewedMatchRecap({
  required bool isPremium,
  required MatchProfile profile,
  required Set<String> viewedRecapIds,
  String? matchId,
}) {
  if (isPremium || viewedRecapIds.isEmpty) return false;

  final recapIds = <String>{
    profile.id,
    if (matchId != null && matchId.isNotEmpty) matchId,
    if (profile.matchContext?.eventId != null) profile.matchContext!.eventId!,
    if (profile.matchContext?.gymPlaceId != null)
      profile.matchContext!.gymPlaceId!,
  };

  return recapIds.any(viewedRecapIds.contains);
}
