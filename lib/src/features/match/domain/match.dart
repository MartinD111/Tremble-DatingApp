import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MatchType — F3 Match Categories
// ─────────────────────────────────────────────────────────────────────────────
enum MatchType {
  standard,
  event,
  activity,
  gym;

  static MatchType fromString(String? value) {
    return MatchType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchType.standard,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HistoryFilter — F3 Time-based filters
// ─────────────────────────────────────────────────────────────────────────────
enum HistoryFilter {
  lastWeek,
  lastMonth,
  last3Months,
  last12Months,
  all;

  DateTime get cutoffDate {
    final now = DateTime.now();
    return switch (this) {
      HistoryFilter.lastWeek => now.subtract(const Duration(days: 7)),
      HistoryFilter.lastMonth => now.subtract(const Duration(days: 30)),
      HistoryFilter.last3Months => now.subtract(const Duration(days: 90)),
      HistoryFilter.last12Months => now.subtract(const Duration(days: 365)),
      HistoryFilter.all => DateTime(2020),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MatchContext — additional data per match type
// ─────────────────────────────────────────────────────────────────────────────
class MatchContext {
  final String? eventId;
  final String? activityType; // 'running' | null
  final String? gymPlaceId; // Google Place ID

  const MatchContext({
    this.eventId,
    this.activityType,
    this.gymPlaceId,
  });

  factory MatchContext.fromMap(Map<String, dynamic> map) => MatchContext(
        eventId: map['eventId'] as String?,
        activityType: map['activityType'] as String?,
        gymPlaceId: map['gymPlaceId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (eventId != null) 'eventId': eventId,
        if (activityType != null) 'activityType': activityType,
        if (gymPlaceId != null) 'gymPlaceId': gymPlaceId,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Match domain model
// ─────────────────────────────────────────────────────────────────────────────
class Match {
  final String id;
  final List<String> userIds;
  final DateTime createdAt;
  final List<String> seenBy;
  final String status; // 'pending', 'found', 'expired'
  final bool isFound;
  final Map<String, bool> gestures;
  final DateTime? expiresAt;

  // F3 — Match Categories
  final MatchType matchType;
  final MatchContext? matchContext;

  Match({
    required this.id,
    required this.userIds,
    required this.createdAt,
    required this.seenBy,
    this.status = 'pending',
    this.isFound = false,
    this.gestures = const {},
    this.expiresAt,
    this.matchType = MatchType.standard,
    this.matchContext,
  });

  bool get isMutual => gestures.length >= 2;
  bool hasWaved(String uid) => gestures.containsKey(uid);

  factory Match.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // serverTimestamp() resolves null in the local cache before the write
    // round-trips. Fall back to "now" so the stream doesn't error mid-rebuild
    // and paint Flutter's red ErrorWidget.
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Match(
      id: doc.id,
      userIds: List<String>.from(data['userIds'] ?? []),
      createdAt: createdAt,
      seenBy: List<String>.from(data['seenBy'] ?? []),
      status: data['status'] ?? 'pending',
      isFound: data['isFound'] ?? false,
      gestures: Map<String, bool>.from(data['gestures'] ?? {}),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          createdAt.add(const Duration(minutes: 30)),
      matchType: MatchType.fromString(data['matchType'] as String?),
      matchContext: data['matchContext'] != null
          ? MatchContext.fromMap(
              Map<String, dynamic>.from(data['matchContext'] as Map))
          : null,
    );
  }

  /// Vrne ID osebe, s katero smo se povezali.
  String getPartnerId(String myUid) {
    return userIds.firstWhere((id) => id != myUid, orElse: () => '');
  }
}
