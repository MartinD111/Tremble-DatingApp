import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final List<String> userIds;
  final DateTime createdAt;
  final List<String> seenBy;
  // lastMessage removed — Tremble has no in-app chat.
  // After mutual wave, users find each other in the real world.

  Match({
    required this.id,
    required this.userIds,
    required this.createdAt,
    required this.seenBy,
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      userIds: List<String>.from(data['userIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
    );
  }

  /// Vrne ID osebe, s katero smo se povezali.
  String getPartnerId(String myUid) {
    return userIds.firstWhere((id) => id != myUid, orElse: () => '');
  }
}
