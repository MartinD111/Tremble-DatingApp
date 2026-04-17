import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final List<String> userIds;
  final DateTime createdAt;
  final List<String> seenBy;
  final String status; // 'pending', 'found', 'expired'
  final bool isFound;
  final Map<String, bool> gestures;

  Match({
    required this.id,
    required this.userIds,
    required this.createdAt,
    required this.seenBy,
    this.status = 'pending',
    this.isFound = false,
    this.gestures = const {},
  });

  bool get isMutual => gestures.length >= 2;
  bool hasWaved(String uid) => gestures.containsKey(uid);

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Match(
      id: doc.id,
      userIds: List<String>.from(data['userIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
      status: data['status'] ?? 'pending',
      isFound: data['isFound'] ?? false,
      gestures: Map<String, bool>.from(data['gestures'] ?? {}),
    );
  }

  /// Vrne ID osebe, s katero smo se povezali.
  String getPartnerId(String myUid) {
    return userIds.firstWhere((id) => id != myUid, orElse: () => '');
  }
}
