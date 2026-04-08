import 'package:cloud_firestore/cloud_firestore.dart';

class Wave {
  final String? id;
  final String fromUid;
  final String toUid;
  final DateTime createdAt;

  Wave({
    this.id,
    required this.fromUid,
    required this.toUid,
    required this.createdAt,
  });

  factory Wave.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wave(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      toUid: data['toUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
