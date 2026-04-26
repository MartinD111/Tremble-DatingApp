import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../dashboard/application/dev_mock_matches_provider.dart';
import '../../match/data/wave_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MatchProfile — data model for matched users
// ─────────────────────────────────────────────────────────────────────────────
class MatchProfile {
  final String id;
  final String name;
  final int age;
  final String imageUrl;
  final List<String> hobbies;
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
  final bool? isSmoker;
  final String? drinkingHabit;
  final int? introvertLevel;
  final List<String> photoUrls;
  final List<Map<String, String>> prompts;
  final String gender;

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
    this.isSmoker,
    this.drinkingHabit,
    this.introvertLevel,
    this.prompts = const [],
    this.gender = 'Female',
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
      hobbies: List<String>.from(data['hobbies'] ?? []),
      bio: '', // Bio not stored server-side; derived from prompts
      height: data['height'] as int?,
      politicalAffiliation: data['politicalAffiliation'] as String?,
      religion: data['religion'] as String?,
      ethnicity: data['ethnicity'] as String?,
      jobStatus: data['jobStatus'] as String?,
      occupation: data['occupation'] as String?,
      isSmoker: data['isSmoker'] as bool?,
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
      lookingFor: List<String>.from(data['lookingFor'] ?? []),
      birthDate: _parseDateTime(data['birthDate']),
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

  /// Stream that polls for new matches periodically.
  /// Replaces the old mock simulateMatches() with real polling.
  Stream<List<MatchProfile>> watchMatches({
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (true) {
      try {
        final matches = await getMatches();
        yield matches;
      } catch (e) {
        yield []; // Return empty on error, will retry
      }
      await Future.delayed(interval);
    }
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
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final matchRepositoryProvider = Provider((ref) => MatchRepository());

/// Stream of real matches from the server, merged with dev-mode mock matches
/// produced by completed proximity simulations. Dev mocks are appended to the
/// front of the list so they appear at the top of the People tab.
final matchesStreamProvider = StreamProvider<List<MatchProfile>>((ref) {
  final devMocks = ref.watch(devMockMatchesProvider);
  return ref.watch(matchRepositoryProvider).watchMatches().map((real) {
    if (devMocks.isEmpty) return real;
    final realIds = real.map((m) => m.id).toSet();
    final unique = devMocks.where((m) => !realIds.contains(m.id));
    return [...unique, ...real];
  });
});

/// Controller to handle user actions (Like/Pass/Greet)
class MatchController extends StateNotifier<MatchProfile?> {
  final WaveRepository _waveRepo;

  MatchController(this._waveRepo) : super(null);

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
}

final matchControllerProvider =
    StateNotifierProvider<MatchController, MatchProfile?>((ref) {
  return MatchController(ref.watch(waveRepositoryProvider));
});
