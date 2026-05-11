import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/application/dev_mock_matches_provider.dart';
import '../../match/data/wave_repository.dart';
import '../../../core/hobby_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MatchContext — context that created the match (event, gym, activity, etc.)
// ─────────────────────────────────────────────────────────────────────────────
class MatchContext {
  final String? eventId;
  final String? activityType;
  final String? gymPlaceId;

  const MatchContext({
    this.eventId,
    this.activityType,
    this.gymPlaceId,
  });

  factory MatchContext.fromMap(Map<String, dynamic> map) {
    return MatchContext(
      eventId: map['eventId'] as String?,
      activityType: map['activityType'] as String?,
      gymPlaceId: map['gymPlaceId'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MatchProfile — data model for matched users
// ─────────────────────────────────────────────────────────────────────────────
class MatchProfile {
  final String id;
  final String name;
  final int age;
  final String imageUrl;
  final List<Map<String, dynamic>> hobbies;
  final String bio;

  // Extended fields
  final int? height;
  final String? politicalAffiliation;
  final String? religion;
  final String? ethnicity;
  final String? jobStatus;
  final String? occupation;
  final String? company;
  final String? school;
  final String? graduatedUniversity;
  final bool? lookingForNewJob;
  final List<String> nicotineUse;
  final String? drinkingHabit;
  final int? introvertLevel;
  final List<String> photoUrls;
  final List<Map<String, String>> prompts;
  final String gender;

  // Match categorisation
  final String matchType;
  final MatchContext? matchContext;

  // Lifestyle
  final String? exerciseHabit;
  final String? sleepSchedule;
  final String? petPreference;
  final String? childrenPreference;
  final String? hairColor;
  final List<String> languages;
  final String? location;
  final bool? hasChildren;
  final List<String> lookingFor;
  final DateTime? birthDate;
  final DateTime? matchedAt;
  final bool isTraveler;

  const MatchProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.hobbies,
    required this.bio,
    this.photoUrls = const [],
    this.height,
    this.politicalAffiliation,
    this.religion,
    this.ethnicity,
    this.jobStatus,
    this.occupation,
    this.company,
    this.school,
    this.graduatedUniversity,
    this.lookingForNewJob,
    this.nicotineUse = const [],
    this.drinkingHabit,
    this.introvertLevel,
    this.prompts = const [],
    this.gender = 'Female',
    this.matchType = 'standard',
    this.matchContext,
    this.exerciseHabit,
    this.sleepSchedule,
    this.petPreference,
    this.childrenPreference,
    this.hairColor,
    this.languages = const [],
    this.location,
    this.hasChildren,
    this.lookingFor = const [],
    this.birthDate,
    this.matchedAt,
    this.isTraveler = false,
  });

  /// Create a MatchProfile from Cloud Functions response data.
  factory MatchProfile.fromApi(Map<String, dynamic> data) {
    final urls = List<String>.from(data['photoUrls'] ?? []);
    return MatchProfile(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Unknown',
      age: data['age'] as int? ?? 0,
      imageUrl:
          urls.isNotEmpty ? urls.first : 'https://via.placeholder.com/150',
      photoUrls: urls,
      hobbies: HobbyUtils.parseHobbies(data['hobbies']),
      bio: '', // Bio not stored server-side; derived from prompts
      height: data['height'] as int?,
      politicalAffiliation: data['politicalAffiliation'] as String?,
      religion: data['religion'] as String?,
      ethnicity: data['ethnicity'] as String?,
      jobStatus: data['jobStatus'] as String?,
      occupation: data['occupation'] as String?,
      nicotineUse: List<String>.from(data['nicotineUse'] ?? []),
      drinkingHabit: data['drinkingHabit'] as String?,
      introvertLevel: data['introvertScale'] as int?,
      gender: data['gender'] as String? ?? 'Female',
      exerciseHabit: data['exerciseHabit'] as String?,
      sleepSchedule: data['sleepSchedule'] as String?,
      petPreference: data['petPreference'] as String?,
      childrenPreference: data['childrenPreference'] as String?,
      hairColor: data['hairColor'] as String?,
      languages: List<String>.from(data['languages'] ?? []),
      location: data['location'] as String?,
      hasChildren: data['hasChildren'] as bool?,
      company: data['company'] as String?,
      school: data['school'] as String?,
      graduatedUniversity: data['graduatedUniversity'] as String?,
      lookingForNewJob: data['lookingForNewJob'] as bool?,
      lookingFor: List<String>.from(data['lookingFor'] ?? []),
      birthDate: _parseDateTime(data['birthDate']),
      matchType: data['matchType'] as String? ?? 'standard',
      matchContext: data['matchContext'] is Map
          ? MatchContext.fromMap(
              Map<String, dynamic>.from(data['matchContext'] as Map),
            )
          : null,
      matchedAt: _parseDateTime(data['matchedAt']),
      isTraveler: data['isTraveler'] as bool? ?? false,
    );
  }

  /// Safely parses a Firestore field that may be a [Timestamp], an ISO-8601
  /// [String], or null.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MatchRepository — real backend via Cloud Functions
// ─────────────────────────────────────────────────────────────────────────────
class MatchRepository {
  final TrembleApiClient _api = TrembleApiClient();

  /// Get all accepted matches for the current user.
  Future<List<MatchProfile>> getMatches() async {
    final result = await _api.call('getMatches');
    final matchesList = result['matches'] as List<dynamic>? ?? [];
    return matchesList
        .map((m) => MatchProfile.fromApi(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Activate event mode for the current user.
  Future<void> activateEventMode({
    required String eventId,
    required double latitude,
    required double longitude,
  }) async {
    await _api.call('onEventModeActivate', data: {
      'eventId': eventId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  /// Request a Pulse Intercept (Phone or Photo).
  Future<Map<String, dynamic>> requestPulseIntercept({
    required String targetUid,
    required String type,
    String? data,
  }) async {
    return await _api.call('requestPulseIntercept', data: {
      'targetUid': targetUid,
      'type': type,
      'data': data,
    });
  }

  /// Retrieve a Pulse Intercept sent by a match.
  Future<Map<String, dynamic>> getPulseIntercept(String senderUid) async {
    return await _api.call('getPulseIntercept', data: {
      'senderUid': senderUid,
    });
  }

  /// Real-time match stream backed by a Firestore listener.
  ///
  /// Fires immediately on first subscription and again whenever the matches
  /// collection changes for [uid]. Full profile hydration is delegated to
  /// [getMatches] (Cloud Function) so no additional Firestore reads are needed.
  Stream<List<MatchProfile>> watchMatches(String uid) {
    return FirebaseFirestore.instance
        .collection('matches')
        .where('userIds', arrayContains: uid)
        .snapshots()
        .asyncMap((_) => getMatches());
  }

  /// Filters [matches] in-memory according to [filter].
  ///
  /// - [filter.historyFilter] restricts by [MatchProfile.matchedAt].
  ///   Matches without a [matchedAt] are kept when [HistoryFilter.all] is
  ///   selected and excluded otherwise (unknown timestamp = cannot confirm
  ///   recency).
  /// - [filter.matchType] restricts by [MatchProfile.matchType].
  ///   Null means "no restriction".
  static List<MatchProfile> filterMatches(
    List<MatchProfile> matches,
    MatchFilterState filter,
  ) {
    final cutoff = filter.historyFilter.cutoff;
    return matches.where((m) {
      // ── time-window gate ──────────────────────────────────────────────────
      if (cutoff != null) {
        final matchedAt = m.matchedAt;
        if (matchedAt == null) return false; // unknown → exclude
        if (matchedAt.isBefore(cutoff)) return false;
      }

      // ── match-type gate ───────────────────────────────────────────────────
      if (filter.matchType != null && m.matchType != filter.matchType) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Check if a match is compatible based on gender preferences.
  /// [userInterestedIn] and [matchInterestedIn] are lists of gender keys
  /// (e.g. ['male', 'female', 'non_binary']).
  static bool isMatchCompatible({
    required String? userGender,
    required List<String> userInterestedIn,
    required String matchGender,
    required List<String> matchInterestedIn,
  }) {
    // If either party has no stated preference, allow the match.
    if (userInterestedIn.isEmpty || matchInterestedIn.isEmpty) return true;

    // User must be interested in the match's gender.
    if (!userInterestedIn.contains(matchGender)) return false;

    // Match must be interested in the user's gender.
    if (userGender != null && !matchInterestedIn.contains(userGender)) {
      return false;
    }

    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HistoryFilter — time-window filter applied in-memory on the matches list
// ─────────────────────────────────────────────────────────────────────────────
enum HistoryFilter {
  lastWeek,
  lastMonth,
  last3Months,
  last12Months,
  all;

  /// Returns the earliest [DateTime] that qualifies for this filter,
  /// or null when the filter is [all] (no cutoff applied).
  DateTime? get cutoff {
    final now = DateTime.now();
    return switch (this) {
      HistoryFilter.lastWeek => now.subtract(const Duration(days: 7)),
      HistoryFilter.lastMonth => DateTime(now.year, now.month - 1, now.day),
      HistoryFilter.last3Months => DateTime(now.year, now.month - 3, now.day),
      HistoryFilter.last12Months => DateTime(now.year - 1, now.month, now.day),
      HistoryFilter.all => null,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MatchFilterState — combined filter applied by filteredMatchesProvider
// ─────────────────────────────────────────────────────────────────────────────
class MatchFilterState {
  /// Time-window filter. Defaults to [HistoryFilter.all].
  final HistoryFilter historyFilter;

  /// When non-null, only matches with this [MatchProfile.matchType] are shown.
  /// Null means "show all types".
  final String? matchType;

  const MatchFilterState({
    this.historyFilter = HistoryFilter.all,
    this.matchType,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final matchRepositoryProvider = Provider((ref) => MatchRepository());

/// Real-time stream of matches from Firestore, merged with dev-mode mock
/// matches produced by completed proximity simulations.
/// Dev mocks are prepended so they appear at the top of the People tab.
/// In release builds the dev mock merge is skipped entirely.
final matchesStreamProvider = StreamProvider<List<MatchProfile>>((ref) {
  final uid = ref.watch(authStateProvider)?.id;
  if (uid == null) return const Stream.empty();

  // In release mode skip the dev-mock merge so the provider has no dependency
  // on devMockMatchesProvider at all (avoids unnecessary rebuilds in prod).
  if (kReleaseMode) {
    return ref.watch(matchRepositoryProvider).watchMatches(uid);
  }

  final devMocks = ref.watch(devMockMatchesProvider);
  return ref.watch(matchRepositoryProvider).watchMatches(uid).map((real) {
    if (devMocks.isEmpty) return real;
    final realIds = real.map((m) => m.id).toSet();
    final unique = devMocks.where((m) => !realIds.contains(m.id));
    return [...unique, ...real];
  });
});

/// Controller to handle user actions (Like/Pass/Greet)
class MatchController extends StateNotifier<MatchProfile?> {
  final WaveRepository _waveRepo;
  final MatchRepository _matchRepo;

  MatchController(this._waveRepo, this._matchRepo) : super(null);

  void setMatch(MatchProfile? match) => state = match;
  void dismiss() => state = null;

  /// Send a wave to the currently displayed match.
  /// Writes directly to the waves collection — mutual match detection is server-side.
  Future<bool> greet() async {
    if (state == null) return false;
    await _waveRepo.sendWave(state!.id);
    state = null;
    return false;
  }

  /// Request Pulse Intercept for a specific match partner.
  Future<void> requestIntercept({
    required String targetUid,
    required String type,
    String? data,
  }) async {
    await _matchRepo.requestPulseIntercept(
      targetUid: targetUid,
      type: type,
      data: data,
    );
  }

  /// Retrieve a Pulse Intercept sent by a match.
  Future<Map<String, dynamic>> fetchIntercept(String senderUid) async {
    return await _matchRepo.getPulseIntercept(senderUid);
  }
}

final matchControllerProvider =
    StateNotifierProvider<MatchController, MatchProfile?>((ref) {
  return MatchController(
    ref.watch(waveRepositoryProvider),
    ref.watch(matchRepositoryProvider),
  );
});

/// Holds the active [MatchFilterState] — UI writes here to drive filtering.
final matchFilterProvider = StateProvider<MatchFilterState>(
  (_) => const MatchFilterState(),
);

/// Filtered view of [matchesStreamProvider].
///
/// Applies the active [MatchFilterState] in-memory via
/// [MatchRepository.filterMatches]. Rebuilds whenever the upstream stream
/// emits a new list or the filter state changes.
final filteredMatchesProvider = Provider<AsyncValue<List<MatchProfile>>>((ref) {
  final allMatches = ref.watch(matchesStreamProvider);
  final filter = ref.watch(matchFilterProvider);

  return allMatches.whenData(
    (matches) => MatchRepository.filterMatches(matches, filter),
  );
});
