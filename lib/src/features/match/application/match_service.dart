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
