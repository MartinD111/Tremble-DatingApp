import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

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
      imageUrl: urls.isNotEmpty ? urls.first : 'https://via.placeholder.com/150',
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

  /// Send a greeting to another user.
  /// Returns true if it resulted in an instant match (mutual interest).
  /// No message parameter — Tremble waves are silent signals, not text.
  Future<bool> sendGreeting(String toUserId) async {
    final result = await _api.call('sendGreeting', data: {
      'toUserId': toUserId,
    });
    return result['matched'] as bool? ?? false;
  }

  /// Respond to a greeting (accept or decline).
  Future<void> respondToGreeting(String greetingId,
      {required bool accept}) async {
    await _api.call('respondToGreeting', data: {
      'greetingId': greetingId,
      'accept': accept,
    });
  }

  /// Get all accepted matches for the current user.
  Future<List<MatchProfile>> getMatches() async {
    final result = await _api.call('getMatches');
    final matchesList = result['matches'] as List<dynamic>? ?? [];
    return matchesList
        .map((m) => MatchProfile.fromApi(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Get pending greetings (received and sent).
  Future<Map<String, List<Map<String, dynamic>>>> getPendingGreetings() async {
    final result = await _api.call('getPendingGreetings');
    return {
      'received': List<Map<String, dynamic>>.from(
          (result['received'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              []),
      'sent': List<Map<String, dynamic>>.from((result['sent'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          []),
    };
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
  /// Users with gender 'Ne želim povedati' only match with those
  /// whose interestedIn == 'Oba'.
  static bool isMatchCompatible({
    required String? userGender,
    required String? userInterestedIn,
    required String matchGender,
    required String? matchInterestedIn,
  }) {
    // If user chose 'Ne želim povedati', they can only be found
    // by people searching for 'Oba'
    if (userGender == 'Ne želim povedati') {
      if (matchInterestedIn != 'Oba') return false;
    }

    // If match chose 'Ne želim povedati', user must be searching 'Oba'
    if (matchGender == 'Ne želim povedati') {
      if (userInterestedIn != 'Oba') return false;
    }

    // Standard gender filtering
    if (userGender != 'Ne želim povedati' && matchInterestedIn != null) {
      if (matchInterestedIn != 'Oba' && matchInterestedIn != userGender) {
        return false;
      }
    }
    if (matchGender != 'Ne želim povedati' && userInterestedIn != null) {
      if (userInterestedIn != 'Oba' && userInterestedIn != matchGender) {
        return false;
      }
    }

    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final matchRepositoryProvider = Provider((ref) => MatchRepository());

/// Stream of real matches from the server.
final matchesStreamProvider = StreamProvider<List<MatchProfile>>((ref) {
  return ref.watch(matchRepositoryProvider).watchMatches();
});

/// Controller to handle user actions (Like/Pass/Greet)
class MatchController extends StateNotifier<MatchProfile?> {
  final MatchRepository _repo;

  MatchController(this._repo) : super(null);

  void setMatch(MatchProfile? match) => state = match;
  void dismiss() => state = null;

  /// Send a greeting to the currently displayed match.
  /// Silent — no text, no message. One tap. That's it.
  Future<bool> greet() async {
    if (state == null) return false;
    final matched = await _repo.sendGreeting(state!.id);
    state = null;
    return matched;
  }
}

final matchControllerProvider =
    StateNotifierProvider<MatchController, MatchProfile?>((ref) {
  return MatchController(ref.watch(matchRepositoryProvider));
});
