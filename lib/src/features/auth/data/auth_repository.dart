import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/api_client.dart';
import '../../../core/event_geofence_service.dart';
import '../../../core/hobby_utils.dart';
import '../../gym/domain/selected_gym.dart';

// Sentinel marking "argument not provided" — distinguishes from explicit null
// in copyWith. Use to allow callers to clear a nullable field by passing null.
const Object _unset = Object();

// ─────────────────────────────────────────────────────────────────────────────
// AuthUser — data model (password field REMOVED for security)
// ─────────────────────────────────────────────────────────────────────────────
class AuthUser {
  final String id;
  final String? name;
  final int? age;
  final bool isOnboarded;
  final int onboardingCheckpoint;
  final DateTime? birthDate;
  final List<String> photoUrls;
  final String? gender;
  final List<String> interestedIn;
  final String? email;
  // REMOVED: final String? password; — never store passwords in app state
  final int? height;
  final int? heightRangeStart;
  final int? heightRangeEnd;

  /// Nicotine products the user uses. Empty list = none.
  /// Valid values: 'cigarettes' | 'vape' | 'iqos' | 'zyn' | 'shisha' | 'cannabis'
  final List<String> nicotineUse;

  /// Partner nicotine filter. Values: 'any' | 'none_only' | 'no_preference'
  final String? nicotineFilter;
  final String? jobStatus; // 'student' or 'employed'
  final String? occupation; // Specific title (e.g. 'Computer Science')
  final String? drinkingHabit;
  final int? introvertScale;
  final int? selfIntrovertMin;
  final int? selfIntrovertMax;
  final String? partnerIntrovertPreference;
  final String? exerciseHabit;
  final String? sleepSchedule;
  final String? petPreference;
  final String? childrenPreference;
  final String? location;
  final String? religion;
  final String? religionPreference;
  final String? ethnicity;
  final String? ethnicityPreference;
  final String? hairColor;
  final String? hairColorPreference;
  final String? politicalAffiliation;
  final String? politicalAffiliationPreference;
  final String? partnerExerciseHabit;
  final String? partnerDrinkingHabit;
  final String? partnerSleepSchedule;
  final String? partnerPetPreference;
  final String? partnerChildrenPreference;
  final List<String> lookingFor;
  final List<String> languages;
  final List<Map<String, dynamic>> hobbies;
  final Map<String, String> prompts;
  final bool isEmailVerified;
  final bool isAdmin;
  final bool isPremium;
  final bool isDarkMode;
  final bool isPrideMode;
  final bool isClassicAppearance;
  final String? partnerHeightPreference;
  final String appLanguage;
  final int ageRangeStart;
  final int ageRangeEnd;
  final bool showPingAnimation;
  final int maxDistance;
  // Partner preference range sliders (new numeric fields replacing legacy strings)
  final int? partnerPoliticalMin; // 1..5 spectrum left→right
  final int? partnerPoliticalMax;
  final int? partnerIntrovertMin; // 0..100 introvert→extrovert
  final int? partnerIntrovertMax;
  final String? school;
  final String? company;
  final bool? hasChildren;
  final bool isPingVibrationEnabled;
  final bool isGenderBasedColor;
  final DateTime? lastWaveFoundAt;
  // null = user has not been asked yet; true/false = explicit choice
  final bool? gymNotificationsEnabled;
  final String? phoneNumber;
  final bool isTraveler;

  /// Gyms selected by the user via Google Places search.
  /// Written directly to Firestore — NOT sent via Cloud Function API (strict Zod schema).
  final List<SelectedGym> selectedGyms;

  /// Returns true if user has real Premium OR is inside an active event
  /// geofence (Taste of Premium). The [inEventGeofence] flag comes from
  /// EventGeofenceService — it is runtime-only and never persisted.
  bool effectiveIsPremium({bool inEventGeofence = false}) =>
      isPremium || inEventGeofence;

  const AuthUser({
    required this.id,
    this.name,
    this.age,
    this.birthDate,
    this.email,
    this.height,
    this.heightRangeStart,
    this.heightRangeEnd,
    this.photoUrls = const [],
    this.gender,
    this.interestedIn = const [],
    this.nicotineUse = const [],
    this.nicotineFilter,
    this.jobStatus,
    this.occupation,
    this.drinkingHabit,
    this.introvertScale,
    this.selfIntrovertMin,
    this.selfIntrovertMax,
    this.partnerIntrovertPreference,
    this.exerciseHabit,
    this.sleepSchedule,
    this.petPreference,
    this.childrenPreference,
    this.location,
    this.religion,
    this.religionPreference,
    this.ethnicity,
    this.ethnicityPreference,
    this.hairColor,
    this.hairColorPreference,
    this.politicalAffiliation,
    this.politicalAffiliationPreference,
    this.partnerExerciseHabit,
    this.partnerDrinkingHabit,
    this.partnerSleepSchedule,
    this.partnerPetPreference,
    this.partnerChildrenPreference,
    this.lookingFor = const [],
    this.languages = const [],
    this.hobbies = const [],
    this.prompts = const {},
    this.isOnboarded = false,
    this.onboardingCheckpoint = 0,
    this.isEmailVerified = false,
    this.isAdmin = false,
    this.isPremium = false,
    this.isDarkMode = false,
    this.isPrideMode = false,
    this.isClassicAppearance = true,
    this.partnerHeightPreference,
    this.appLanguage = 'en',
    this.ageRangeStart = 18,
    this.ageRangeEnd = 100,
    this.showPingAnimation = true,
    this.maxDistance = 50,
    this.partnerPoliticalMin,
    this.partnerPoliticalMax,
    this.partnerIntrovertMin,
    this.partnerIntrovertMax,
    this.school,
    this.company,
    this.hasChildren,
    this.isPingVibrationEnabled = true,
    this.isGenderBasedColor = false,
    this.lastWaveFoundAt,
    this.gymNotificationsEnabled,
    this.phoneNumber,
    this.isTraveler = false,
    this.selectedGyms = const [],
  });

  // ── Serialization for Cloud Functions API ─────────────────────────────────
  // NOTE: isAdmin/isPremium are NEVER sent to the server — they are
  // server-managed fields. The Cloud Functions .strict() schema rejects them.
  Map<String, dynamic> toApiPayload() {
    return {
      if (name != null) 'name': name,
      'onboardingCheckpoint': onboardingCheckpoint,
      if (age != null) 'age': age,
      if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
      if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      if (gender != null) 'gender': gender!.toLowerCase(),
      if (interestedIn.isNotEmpty) 'interestedIn': interestedIn,
      'height': height,
      'heightRangeStart': heightRangeStart,
      'heightRangeEnd': heightRangeEnd,
      'nicotineUse': nicotineUse,
      'nicotineFilter': nicotineFilter,
      'jobStatus': jobStatus,
      'occupation': occupation,
      'drinkingHabit': drinkingHabit,
      'introvertScale': introvertScale,
      if (selfIntrovertMin != null) 'selfIntrovertMin': selfIntrovertMin,
      if (selfIntrovertMax != null) 'selfIntrovertMax': selfIntrovertMax,
      'partnerIntrovertPreference': partnerIntrovertPreference,
      'exerciseHabit': exerciseHabit,
      'sleepSchedule': sleepSchedule,
      'petPreference': petPreference,
      'childrenPreference': childrenPreference,
      'location': location,
      'religion': religion,
      'religionPreference': religionPreference,
      'ethnicity': ethnicity,
      'ethnicityPreference': ethnicityPreference,
      'hairColor': hairColor,
      'hairColorPreference': hairColorPreference,
      'politicalAffiliation': politicalAffiliation,
      'politicalAffiliationPreference': politicalAffiliationPreference,
      'partnerExerciseHabit': partnerExerciseHabit,
      'partnerDrinkingHabit': partnerDrinkingHabit,
      'partnerSleepSchedule': partnerSleepSchedule,
      if (partnerPetPreference != null)
        'partnerPetPreference': partnerPetPreference,
      if (partnerChildrenPreference != null)
        'partnerChildrenPreference': partnerChildrenPreference,
      'lookingFor': lookingFor,
      'languages': languages,
      'hobbies': hobbies,
      'prompts': prompts,
      'isDarkMode': isDarkMode,
      'isPrideMode': isPrideMode,
      'isClassicAppearance': isClassicAppearance,
      if (partnerHeightPreference != null)
        'partnerHeightPreference': partnerHeightPreference,
      'appLanguage': appLanguage,
      'ageRangeStart': ageRangeStart,
      'ageRangeEnd': ageRangeEnd,
      'showPingAnimation': showPingAnimation,
      'maxDistance': maxDistance,
      if (partnerPoliticalMin != null)
        'partnerPoliticalMin': partnerPoliticalMin,
      if (partnerPoliticalMax != null)
        'partnerPoliticalMax': partnerPoliticalMax,
      if (partnerIntrovertMin != null)
        'partnerIntrovertMin': partnerIntrovertMin,
      if (partnerIntrovertMax != null)
        'partnerIntrovertMax': partnerIntrovertMax,
      'isGenderBasedColor': isGenderBasedColor,
      'school': school,
      'company': company,
      'isPingVibrationEnabled': isPingVibrationEnabled,
      'hasChildren': hasChildren,
      if (gymNotificationsEnabled != null)
        'gymNotificationsEnabled': gymNotificationsEnabled,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'isTraveler': isTraveler,
    };
  }

  /// Parses interestedIn from Firestore — handles legacy String values and
  /// current List<String> format. Migrates legacy compound string values:
  ///   "both" → ['male', 'female']
  ///   "male, female" → ['male', 'female']
  ///   "male" → ['male']
  static List<String> _parseInterestedIn(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String && value.isNotEmpty) {
      if (value == 'both' || value == 'Vse' || value == 'Oba') {
        return ['male', 'female'];
      }
      return value
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Safely parses a Firestore field that may be a [Timestamp], an ISO-8601
  /// [String], or null. Documents written by older app versions or admin tools
  /// may store dates as strings, so a hard cast would throw.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory AuthUser.fromFirestore(String uid, Map<String, dynamic> data,
      {bool emailVerified = false}) {
    return AuthUser(
      id: uid,
      name: data['name'] as String?,
      age: data['age'] as int?,
      isOnboarded: data['isOnboarded'] as bool? ?? false,
      onboardingCheckpoint: data['onboardingCheckpoint'] as int? ?? 0,
      birthDate: _parseDateTime(data['birthDate']),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      gender: data['gender'] as String?,
      interestedIn: _parseInterestedIn(data['interestedIn']),
      email: data['email'] as String?,
      height: data['height'] as int?,
      heightRangeStart: data['heightRangeStart'] as int?,
      heightRangeEnd: data['heightRangeEnd'] as int?,
      nicotineUse: List<String>.from(data['nicotineUse'] ?? []),
      nicotineFilter: data['nicotineFilter'] as String?,
      jobStatus: data['jobStatus'] as String?,
      occupation: data['occupation'] as String?,
      drinkingHabit: data['drinkingHabit'] as String?,
      introvertScale: data['introvertScale'] as int?,
      selfIntrovertMin: data['selfIntrovertMin'] as int?,
      selfIntrovertMax: data['selfIntrovertMax'] as int?,
      partnerIntrovertPreference: data['partnerIntrovertPreference'] as String?,
      exerciseHabit: data['exerciseHabit'] as String?,
      sleepSchedule: data['sleepSchedule'] as String?,
      petPreference: data['petPreference'] as String?,
      childrenPreference: data['childrenPreference'] as String?,
      location: data['location'] as String?,
      religion: data['religion'] as String?,
      religionPreference: data['religionPreference'] as String?,
      ethnicity: data['ethnicity'] as String?,
      ethnicityPreference: data['ethnicityPreference'] as String?,
      hairColor: data['hairColor'] as String?,
      hairColorPreference: data['hairColorPreference'] as String?,
      politicalAffiliation: data['politicalAffiliation'] as String?,
      politicalAffiliationPreference:
          data['politicalAffiliationPreference'] as String?,
      partnerExerciseHabit: data['partnerExerciseHabit'] as String?,
      partnerDrinkingHabit: data['partnerDrinkingHabit'] as String?,
      partnerSleepSchedule: data['partnerSleepSchedule'] as String?,
      partnerPetPreference: data['partnerPetPreference'] as String?,
      partnerChildrenPreference: data['partnerChildrenPreference'] as String?,
      lookingFor: List<String>.from(data['lookingFor'] ?? []),
      languages: List<String>.from(data['languages'] ?? []),
      hobbies: HobbyUtils.parseHobbies(data['hobbies']),
      prompts: Map<String, String>.from(data['prompts'] ?? {}),
      isAdmin: data['isAdmin'] as bool? ?? false,
      isPremium: data['isPremium'] as bool? ?? false,
      isDarkMode: data['isDarkMode'] as bool? ?? false,
      isPrideMode: data['isPrideMode'] as bool? ?? false,
      isClassicAppearance: data['isClassicAppearance'] as bool? ?? true,
      partnerHeightPreference: data['partnerHeightPreference'] as String?,
      appLanguage: data['appLanguage'] as String? ?? 'en',
      ageRangeStart: data['ageRangeStart'] as int? ?? 18,
      ageRangeEnd: data['ageRangeEnd'] as int? ?? 100,
      showPingAnimation: data['showPingAnimation'] as bool? ?? true,
      maxDistance: data['maxDistance'] as int? ?? 50,
      partnerPoliticalMin: data['partnerPoliticalMin'] as int?,
      partnerPoliticalMax: data['partnerPoliticalMax'] as int?,
      partnerIntrovertMin: data['partnerIntrovertMin'] as int?,
      partnerIntrovertMax: data['partnerIntrovertMax'] as int?,
      isGenderBasedColor: data['isGenderBasedColor'] as bool? ?? false,
      school: data['school'] as String?,
      company: data['company'] as String?,
      isPingVibrationEnabled: data['isPingVibrationEnabled'] as bool? ?? true,
      hasChildren: data['hasChildren'] as bool?,
      lastWaveFoundAt: _parseDateTime(data['lastWaveFoundAt']),
      gymNotificationsEnabled: data['gymNotificationsEnabled'] as bool?,
      phoneNumber: data['phoneNumber'] as String?,
      isTraveler: data['isTraveler'] as bool? ?? false,
      selectedGyms: (data['selectedGyms'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SelectedGym.fromMap)
          .toList(),
      isEmailVerified: emailVerified,
    );
  }

  AuthUser copyWith({
    String? id,
    String? name,
    int? age,
    DateTime? birthDate,
    String? email,
    int? height,
    int? heightRangeStart,
    int? heightRangeEnd,
    List<String>? photoUrls,
    String? gender,
    List<String>? interestedIn,
    List<String>? nicotineUse,
    Object? nicotineFilter = _unset,
    String? jobStatus,
    String? occupation,
    Object? drinkingHabit = _unset,
    int? introvertScale,
    int? selfIntrovertMin,
    int? selfIntrovertMax,
    Object? partnerIntrovertPreference = _unset,
    Object? exerciseHabit = _unset,
    Object? sleepSchedule = _unset,
    Object? petPreference = _unset,
    Object? childrenPreference = _unset,
    String? location,
    String? religion,
    Object? religionPreference = _unset,
    String? ethnicity,
    Object? ethnicityPreference = _unset,
    String? hairColor,
    Object? hairColorPreference = _unset,
    String? politicalAffiliation,
    Object? politicalAffiliationPreference = _unset,
    Object? partnerExerciseHabit = _unset,
    Object? partnerDrinkingHabit = _unset,
    Object? partnerSleepSchedule = _unset,
    Object? partnerPetPreference = _unset,
    Object? partnerChildrenPreference = _unset,
    List<String>? lookingFor,
    List<String>? languages,
    List<Map<String, dynamic>>? hobbies,
    Map<String, String>? prompts,
    bool? isOnboarded,
    int? onboardingCheckpoint,
    bool? isEmailVerified,
    bool? isAdmin,
    bool? isPremium,
    bool? isDarkMode,
    bool? isPrideMode,
    bool? isClassicAppearance,
    String? partnerHeightPreference,
    String? appLanguage,
    int? ageRangeStart,
    int? ageRangeEnd,
    bool? showPingAnimation,
    int? maxDistance,
    int? partnerPoliticalMin,
    int? partnerPoliticalMax,
    int? partnerIntrovertMin,
    int? partnerIntrovertMax,
    bool? isGenderBasedColor,
    String? school,
    String? company,
    bool? isPingVibrationEnabled,
    bool? hasChildren,
    DateTime? lastWaveFoundAt,
    bool? gymNotificationsEnabled,
    String? phoneNumber,
    bool? isTraveler,
    List<SelectedGym>? selectedGyms,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      height: height ?? this.height,
      heightRangeStart: heightRangeStart ?? this.heightRangeStart,
      heightRangeEnd: heightRangeEnd ?? this.heightRangeEnd,
      photoUrls: photoUrls ?? this.photoUrls,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      nicotineUse: nicotineUse ?? this.nicotineUse,
      nicotineFilter: identical(nicotineFilter, _unset)
          ? this.nicotineFilter
          : nicotineFilter as String?,
      jobStatus: jobStatus ?? this.jobStatus,
      occupation: occupation ?? this.occupation,
      drinkingHabit: identical(drinkingHabit, _unset)
          ? this.drinkingHabit
          : drinkingHabit as String?,
      introvertScale: introvertScale ?? this.introvertScale,
      selfIntrovertMin: selfIntrovertMin ?? this.selfIntrovertMin,
      selfIntrovertMax: selfIntrovertMax ?? this.selfIntrovertMax,
      partnerIntrovertPreference: identical(partnerIntrovertPreference, _unset)
          ? this.partnerIntrovertPreference
          : partnerIntrovertPreference as String?,
      exerciseHabit: identical(exerciseHabit, _unset)
          ? this.exerciseHabit
          : exerciseHabit as String?,
      sleepSchedule: identical(sleepSchedule, _unset)
          ? this.sleepSchedule
          : sleepSchedule as String?,
      petPreference: identical(petPreference, _unset)
          ? this.petPreference
          : petPreference as String?,
      childrenPreference: identical(childrenPreference, _unset)
          ? this.childrenPreference
          : childrenPreference as String?,
      location: location ?? this.location,
      religion: religion ?? this.religion,
      religionPreference: identical(religionPreference, _unset)
          ? this.religionPreference
          : religionPreference as String?,
      ethnicity: ethnicity ?? this.ethnicity,
      ethnicityPreference: identical(ethnicityPreference, _unset)
          ? this.ethnicityPreference
          : ethnicityPreference as String?,
      hairColor: hairColor ?? this.hairColor,
      hairColorPreference: identical(hairColorPreference, _unset)
          ? this.hairColorPreference
          : hairColorPreference as String?,
      politicalAffiliation: politicalAffiliation ?? this.politicalAffiliation,
      politicalAffiliationPreference:
          identical(politicalAffiliationPreference, _unset)
              ? this.politicalAffiliationPreference
              : politicalAffiliationPreference as String?,
      partnerExerciseHabit: identical(partnerExerciseHabit, _unset)
          ? this.partnerExerciseHabit
          : partnerExerciseHabit as String?,
      partnerDrinkingHabit: identical(partnerDrinkingHabit, _unset)
          ? this.partnerDrinkingHabit
          : partnerDrinkingHabit as String?,
      partnerSleepSchedule: identical(partnerSleepSchedule, _unset)
          ? this.partnerSleepSchedule
          : partnerSleepSchedule as String?,
      partnerPetPreference: identical(partnerPetPreference, _unset)
          ? this.partnerPetPreference
          : partnerPetPreference as String?,
      partnerChildrenPreference: identical(partnerChildrenPreference, _unset)
          ? this.partnerChildrenPreference
          : partnerChildrenPreference as String?,
      lookingFor: lookingFor ?? this.lookingFor,
      languages: languages ?? this.languages,
      hobbies: hobbies ?? this.hobbies,
      prompts: prompts ?? this.prompts,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      onboardingCheckpoint: onboardingCheckpoint ?? this.onboardingCheckpoint,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      isPremium: isPremium ?? this.isPremium,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isPrideMode: isPrideMode ?? this.isPrideMode,
      isClassicAppearance: isClassicAppearance ?? this.isClassicAppearance,
      partnerHeightPreference:
          partnerHeightPreference ?? this.partnerHeightPreference,
      appLanguage: appLanguage ?? this.appLanguage,
      ageRangeStart: ageRangeStart ?? this.ageRangeStart,
      ageRangeEnd: ageRangeEnd ?? this.ageRangeEnd,
      showPingAnimation: showPingAnimation ?? this.showPingAnimation,
      maxDistance: maxDistance ?? this.maxDistance,
      partnerPoliticalMin: partnerPoliticalMin ?? this.partnerPoliticalMin,
      partnerPoliticalMax: partnerPoliticalMax ?? this.partnerPoliticalMax,
      partnerIntrovertMin: partnerIntrovertMin ?? this.partnerIntrovertMin,
      partnerIntrovertMax: partnerIntrovertMax ?? this.partnerIntrovertMax,
      isGenderBasedColor: isGenderBasedColor ?? this.isGenderBasedColor,
      school: school ?? this.school,
      company: company ?? this.company,
      isPingVibrationEnabled:
          isPingVibrationEnabled ?? this.isPingVibrationEnabled,
      hasChildren: hasChildren ?? this.hasChildren,
      lastWaveFoundAt: lastWaveFoundAt ?? this.lastWaveFoundAt,
      gymNotificationsEnabled:
          gymNotificationsEnabled ?? this.gymNotificationsEnabled,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isTraveler: isTraveler ?? this.isTraveler,
      selectedGyms: selectedGyms ?? this.selectedGyms,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// Real-time auth state — null = logged out, AuthUser = logged in
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthUser?>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Convenience: expose current Firebase UID
final currentUidProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

// ─────────────────────────────────────────────────────────────────────────────
// ProfileStatus — sealed class for the router's profile existence + onboarding
// state machine.
//
// loading   → Firestore snapshot not yet received (show full-screen splash)
// notFound  → doc does not exist or user is signed out → route to /onboarding
// ready     → doc exists; isOnboarded drives the final routing decision
// ─────────────────────────────────────────────────────────────────────────────
sealed class ProfileStatus {
  const ProfileStatus();

  const factory ProfileStatus.loading() = ProfileStatusLoading;
  const factory ProfileStatus.notFound() = ProfileStatusNotFound;
  const factory ProfileStatus.ready({required bool isOnboarded}) =
      ProfileStatusReady;

  T map<T>({
    required T Function(ProfileStatusLoading) loading,
    required T Function(ProfileStatusNotFound) notFound,
    required T Function(ProfileStatusReady) ready,
  }) {
    if (this is ProfileStatusLoading)
      return loading(this as ProfileStatusLoading);
    if (this is ProfileStatusNotFound)
      return notFound(this as ProfileStatusNotFound);
    return ready(this as ProfileStatusReady);
  }
}

final class ProfileStatusLoading extends ProfileStatus {
  const ProfileStatusLoading();

  @override
  bool operator ==(Object other) => other is ProfileStatusLoading;

  @override
  int get hashCode => (ProfileStatusLoading).hashCode;
}

final class ProfileStatusNotFound extends ProfileStatus {
  const ProfileStatusNotFound();

  @override
  bool operator ==(Object other) => other is ProfileStatusNotFound;

  @override
  int get hashCode => (ProfileStatusNotFound).hashCode;
}

final class ProfileStatusReady extends ProfileStatus {
  final bool isOnboarded;
  const ProfileStatusReady({required this.isOnboarded});

  @override
  bool operator ==(Object other) =>
      other is ProfileStatusReady && other.isOnboarded == isOnboarded;

  @override
  int get hashCode => Object.hash(ProfileStatusReady, isOnboarded);
}

/// Real-time stream of the authenticated user's Firestore profile status.
///
/// Emits:
///   - [ProfileStatusNotFound] immediately if auth is null (signed out)
///   - A Firestore [snapshots()] stream mapped to [ProfileStatusReady]
///     (isOnboarded derived from the doc field)
///   - [ProfileStatusNotFound] if the doc is absent in Firestore
///
/// The router listens to this provider to drive the Auth→Home state machine.
/// Because this is a StreamProvider, it stays [AsyncLoading] until the first
/// snapshot arrives — the router returns null during that window, keeping the
/// user on a full-screen loading indicator rather than routing prematurely.
final profileStatusProvider = StreamProvider<ProfileStatus>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState == null) {
    return Stream.value(const ProfileStatus.notFound());
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authState.id)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return const ProfileStatus.notFound();
    final data = snap.data()!;
    final isOnboarded = data['isOnboarded'] as bool? ?? false;
    return ProfileStatus.ready(isOnboarded: isOnboarded);
  }).handleError((Object e) {
    debugPrint('[PROFILE] Firestore snapshot error: $e');
    // On error fail-safe to notFound so router sends user to /onboarding
    // rather than showing the Home screen with a broken profile.
    return const ProfileStatus.notFound();
  });
});

/// @deprecated Use [profileStatusProvider] instead.
/// Kept for any remaining callsites during migration; will be removed.
final profileExistsProvider = FutureProvider<bool>((ref) async {
  final status = await ref.watch(profileStatusProvider.future);
  return status is ProfileStatusReady;
});

/// Resolves as soon as Firebase Auth has emitted its first auth state event.
/// Returns true if a session exists, false if no user is logged in.
///
/// This is a raw Firebase stream listener — it does NOT go through asyncMap
/// or the Firestore fetch in [authStateChanges]. Its sole purpose is to
/// signal [_RouterNotifier] that Firebase has settled, so the router can
/// unblock the signed-out cold-start case where [authStateProvider] stays
/// null→null and Riverpod's listener never fires (no state change).
final authInitializedProvider = FutureProvider<bool>((ref) async {
  // Guard against Firebase/Google Play Services failures (e.g. DEVELOPER_ERROR)
  // that prevent authStateChanges() from ever emitting. Without this timeout
  // the router's _initialized flag stays false forever and the app hangs on
  // the loading screen indefinitely.
  try {
    final user = await ref
        .read(firebaseAuthProvider)
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 5));
    return user != null;
  } on TimeoutException {
    debugPrint('[AUTH] authStateChanges() timed out after 5 s — '
        'forcing no-session state. Check SHA-1 / google-services.json.');
    return false;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// AuthRepository — wraps FirebaseAuth + Cloud Functions API
// ─────────────────────────────────────────────────────────────────────────────
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn =
      GoogleSignIn(scopes: <String>['email', 'profile']);
  final TrembleApiClient _api = TrembleApiClient();

  AuthRepository(
      {required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _db = firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Registration Draft (Checkpointing) ───────────────────────────────────
  Future<void> updateRegistrationDraft(
      String uid, Map<String, dynamic> draftData) async {
    try {
      await _users.doc(uid).set(
            draftData,
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint("[AUTH] Failed to update draft for $uid: $e");
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────
  Future<AuthUser> loginWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _fetchUser(cred.user!);
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────
  Future<AuthUser> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In canceled');

      // In google_sign_in v6, authentication is a Future<GoogleSignInAuthentication>
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return _fetchUser(userCredential.user!);
    } catch (e) {
      debugPrint("[Google Sign-In] Error: $e");
      rethrow;
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<AuthUser> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    // Create initial user doc immediately to trigger onUserDocCreated Cloud Function.
    // This eliminates the race condition where router checks auth state before Firestore doc exists.
    try {
      await _users.doc(uid).set(
        {
          'email': email.trim(),
          'isOnboarded': false,
          'isPremium': true,
          'isAdmin': false,
          // onUserDocCreated trigger will add createdAt/updatedAt server timestamps
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("[AUTH] Failed to create initial user doc for $uid: $e");
      // Don't fail the signup — the trigger may still create it
    }

    // Send verification email
    await cred.user!.sendEmailVerification();

    return AuthUser(
      id: uid,
      email: email.trim(),
      isOnboarded: false,
      isEmailVerified: false,
    );
  }

  // ── Fetch user from Firestore (READ only — this is fine client-side) ────
  Future<AuthUser> _fetchUser(User firebaseUser) async {
    final doc = await _users.doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      // isOnboarded is the authoritative source of truth — read it directly.
      // The self-healing heuristic that overrode this based on profile field
      // presence has been removed: profileStatusProvider's real-time stream
      // now handles the isOnboarded=false case reactively, so the heuristic
      // only introduced false positives (e.g. partially-filled profiles
      // incorrectly treated as complete).
      return AuthUser.fromFirestore(
        firebaseUser.uid,
        data,
        emailVerified: firebaseUser.emailVerified,
      );
    }
    // User doc not yet created by Cloud Function — return minimal stub.
    // The `onUserCreated` trigger will create the doc shortly.
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      isOnboarded: false,
      isEmailVerified: firebaseUser.emailVerified,
    );
  }

  // ── Complete onboarding (via Cloud Functions) ────────────────────────────
  Future<void> completeOnboarding(AuthUser user) async {
    final payload = user.toApiPayload();
    payload['consentGiven'] = true; // GDPR consent
    await _api.call('completeOnboarding', data: payload);
  }

  // ── Dev-mode fallback: write isOnboarded + full profile to Firestore ────────
  // Called only when completeOnboarding Cloud Function fails in debug mode.
  // Writes the full payload so the ghost-onboarded safety net in computeRedirect
  // (name==null && photoUrls.isEmpty → /onboarding) does not re-trigger on the
  // next cold start.
  Future<void> markOnboardedDirectly(AuthUser user) async {
    final payload = user.toApiPayload()..['isOnboarded'] = true;
    await _users
        .doc(user.id)
        .set(payload, SetOptions(merge: true))
        .catchError((e) {
      debugPrint('[AUTH] markOnboardedDirectly failed for ${user.id}: $e');
    });
  }

  // ── Update profile (via Cloud Functions) ─────────────────────────────────
  Future<void> updateProfile(AuthUser user) async {
    await _api.call('updateProfile', data: user.toApiPayload());
  }

  // ── Update selected gyms (direct Firestore — bypasses strict CF schema) ──
  Future<void> updateSelectedGyms(String uid, List<SelectedGym> gyms) async {
    await _users.doc(uid).update({
      'selectedGyms': gyms.map((g) => g.toMap()).toList(),
    });
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Password reset email ──────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Change password (requires recent sign-in) ────────────────────────────
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('Not logged in');
    // Re-authenticate first
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  // ── Stream: listen to Firebase auth changes ──────────────────────────────
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      // Timeout + fallback: if Firestore is slow or the read is denied
      // (e.g. App Check token rejected), emit a minimal signed-in stub so
      // the router can make progress instead of hanging on the splash.
      try {
        return await _fetchUser(firebaseUser)
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint(
            '[AUTH] _fetchUser failed ($e) — emitting minimal stub so router unblocks');
        return AuthUser(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          isOnboarded: false,
          isEmailVerified: firebaseUser.emailVerified,
        );
      }
    });
  }

  // ── Reload email verified status ─────────────────────────────────────────
  Future<bool> reloadAndCheckVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }
}

/// Derived provider that combines [authStateProvider] and
/// [eventGeofenceServiceProvider] into a single boolean. Widgets that need
/// effective-premium status can watch this instead of computing it inline.
///
/// Returns true when the user has real Premium OR is inside an active event
/// geofence (Taste of Premium). Updates reactively on both auth and geofence
/// state changes — no app restart required.
final effectiveIsPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  final geofence = ref.watch(eventGeofenceServiceProvider);
  return user?.effectiveIsPremium(inEventGeofence: geofence.inEventGeofence) ??
      false;
});

// ─────────────────────────────────────────────────────────────────────────────
// AuthNotifier — Riverpod StateNotifier
// ─────────────────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthUser?> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(null) {
    // Listen to Firebase auth stream on startup.
    // onError guard: if the upstream stream errors (should no longer happen
    // now that authStateChanges() catches internally, but defend in depth),
    // fall back to signed-out state so the router unblocks the splash.
    _repository.authStateChanges().listen(
      (user) {
        debugPrint('[AUTH] authStateChanges emitted: ${user?.id ?? 'null'}');
        state = user;
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[AUTH] authStateChanges stream error: $e — forcing null');
        state = null;
      },
    );
  }

  Future<void> login(String email, String password) async {
    state = await _repository.loginWithEmail(email, password);
  }

  Future<void> signInWithGoogle() async {
    state = await _repository.signInWithGoogle();
  }

  Future<void> register(String email, String password) async {
    state = await _repository.registerWithEmail(email, password);
  }

  /// Dev-only: force local auth state without backend calls.
  void setUser(AuthUser user) {
    state = user;
  }

  Future<void> updateProfile(AuthUser user) async {
    // Optimistic update: apply locally first so the UI reflects changes
    // immediately regardless of API latency or transient failures.
    state = user;
    try {
      await _repository.updateProfile(user);
    } catch (e) {
      debugPrint('[AUTH] updateProfile API error (state already applied): $e');
      // Keep optimistic state — next cold start will reconcile from Firestore.
    }
  }

  Future<void> completeOnboarding(AuthUser user) async {
    try {
      await _repository.completeOnboarding(user);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DEV] completeOnboarding API error (bypassed): $e');
        // Dev fallback: write isOnboarded directly to Firestore so that the
        // next cold-start reads the correct value. Without this, the Cloud
        // Function failure leaves isOnboarded=false in Firestore, causing the
        // router to route back to /onboarding on every subsequent app open.
        await _repository.markOnboardedDirectly(user);
      } else {
        rethrow;
      }
    }
    // Always update local state — in debug mode this runs even after API failure.
    state = user.copyWith(isOnboarded: true);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = null;
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _repository.changePassword(oldPassword, newPassword);
  }

  Future<void> updateSelectedGyms(List<SelectedGym> gyms) async {
    final uid = state?.id;
    if (uid == null) return;
    // Optimistic update
    state = state?.copyWith(selectedGyms: gyms);
    await _repository.updateSelectedGyms(uid, gyms);
  }

  Future<bool> reloadVerification() async {
    final verified = await _repository.reloadAndCheckVerification();
    if (verified && state != null) {
      state = state!.copyWith(isEmailVerified: true);
    }
    return verified;
  }
}
