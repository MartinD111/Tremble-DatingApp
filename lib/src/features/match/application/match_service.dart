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
Stream<Match?> currentSearch(CurrentSearchRef ref) {
  return ref.watch(activeMatchesStreamProvider.stream).map((matches) {
    if (matches.isEmpty) return null;

    final now = DateTime.now();
    // Only one active search at a time per requirements
    return matches.where((m) => m.status == 'pending').where((m) {
      final expiry = m.createdAt.add(const Duration(minutes: 30));
      return expiry.isAfter(now);
    }).firstOrNull;
  });
}
