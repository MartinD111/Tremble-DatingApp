import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/match.dart';

part 'match_service.g.dart';

@riverpod
Stream<List<Match>> activeMatchesStream(ActiveMatchesStreamRef ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('matches')
      .where('userIds', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList());
}

@riverpod
Match? currentSearch(CurrentSearchRef ref) {
  final matches = ref.watch(activeMatchesStreamProvider).value ?? [];
  if (matches.isEmpty) return null;

  final now = DateTime.now();
  // Only one active search at a time per requirements
  return matches.where((m) => m.status == 'pending').where((m) {
    final expiry = m.createdAt.add(const Duration(minutes: 30));
    return expiry.isAfter(now);
  }).firstOrNull;
}

@riverpod
Match? getMatchByUserId(GetMatchByUserIdRef ref, String userId) {
  final matches = ref.watch(activeMatchesStreamProvider).value ?? [];
  return matches.where((m) => m.userIds.contains(userId)).firstOrNull;
}
