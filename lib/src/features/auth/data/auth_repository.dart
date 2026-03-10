import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthUser — data model (password field REMOVED for security)
// ─────────────────────────────────────────────────────────────────────────────
class AuthUser {
  final String id;
  final String? name;
  final int? age;
  final bool isOnboarded;
  final DateTime? birthDate;
  final List<String> photoUrls;
  final String? gender;
  final String? interestedIn;
  final String? email;
  // REMOVED: final String? password; — never store passwords in app state
  final int? height;
  final int? heightRangeStart;
  final int? heightRangeEnd;
  final bool? isSmoker;
  final String? partnerSmokingPreference;
  final String? occupation;
  final String? drinkingHabit;
  final int? introvertScale;
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
  final List<String> lookingFor;
  final List<String> languages;
  final List<String> hobbies;
  final Map<String, String> prompts;
  final bool isEmailVerified;
  final bool isAdmin;
  final bool isPremium;
  final bool isDarkMode;
  final bool isPrideMode;
  final String appLanguage;
  final int ageRangeStart;
  final int ageRangeEnd;
  final bool showPingAnimation;
  final int maxDistance;

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
    this.interestedIn,
    this.isSmoker,
    this.partnerSmokingPreference,
    this.occupation,
    this.drinkingHabit,
    this.introvertScale,
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
    this.lookingFor = const [],
    this.languages = const [],
    this.hobbies = const [],
    this.prompts = const {},
    this.isOnboarded = false,
    this.isEmailVerified = false,
    this.isAdmin = false,
    this.isPremium = false,
    this.isDarkMode = false,
    this.isPrideMode = false,
    this.appLanguage = 'en',
    this.ageRangeStart = 18,
    this.ageRangeEnd = 100,
    this.showPingAnimation = true,
    this.maxDistance = 50,
  });

  // ── Serialization for Cloud Functions API ─────────────────────────────────
  // NOTE: isAdmin/isPremium are NEVER sent to the server — they are
  // server-managed fields. The Cloud Functions .strict() schema rejects them.
  Map<String, dynamic> toApiPayload() {
    return {
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
      if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      if (gender != null) 'gender': gender,
      if (interestedIn != null) 'interestedIn': interestedIn,
      if (height != null) 'height': height,
      if (heightRangeStart != null) 'heightRangeStart': heightRangeStart,
      if (heightRangeEnd != null) 'heightRangeEnd': heightRangeEnd,
      if (isSmoker != null) 'isSmoker': isSmoker,
      if (partnerSmokingPreference != null)
        'partnerSmokingPreference': partnerSmokingPreference,
      if (occupation != null) 'occupation': occupation,
      if (drinkingHabit != null) 'drinkingHabit': drinkingHabit,
      if (introvertScale != null) 'introvertScale': introvertScale,
      if (partnerIntrovertPreference != null)
        'partnerIntrovertPreference': partnerIntrovertPreference,
      if (exerciseHabit != null) 'exerciseHabit': exerciseHabit,
      if (sleepSchedule != null) 'sleepSchedule': sleepSchedule,
      if (petPreference != null) 'petPreference': petPreference,
      if (childrenPreference != null) 'childrenPreference': childrenPreference,
      if (location != null) 'location': location,
      if (religion != null) 'religion': religion,
      if (religionPreference != null) 'religionPreference': religionPreference,
      if (ethnicity != null) 'ethnicity': ethnicity,
      if (ethnicityPreference != null)
        'ethnicityPreference': ethnicityPreference,
      if (hairColor != null) 'hairColor': hairColor,
      if (hairColorPreference != null)
        'hairColorPreference': hairColorPreference,
      if (politicalAffiliation != null)
        'politicalAffiliation': politicalAffiliation,
      if (politicalAffiliationPreference != null)
        'politicalAffiliationPreference': politicalAffiliationPreference,
      'lookingFor': lookingFor,
      'languages': languages,
      'hobbies': hobbies,
      'prompts': prompts,
      'isDarkMode': isDarkMode,
      'isPrideMode': isPrideMode,
      'appLanguage': appLanguage,
      'ageRangeStart': ageRangeStart,
      'ageRangeEnd': ageRangeEnd,
      'showPingAnimation': showPingAnimation,
      'maxDistance': maxDistance,
    };
  }

  factory AuthUser.fromFirestore(String uid, Map<String, dynamic> data,
      {bool emailVerified = false}) {
    return AuthUser(
      id: uid,
      name: data['name'] as String?,
      age: data['age'] as int?,
      isOnboarded: data['isOnboarded'] as bool? ?? false,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      gender: data['gender'] as String?,
      interestedIn: data['interestedIn'] as String?,
      email: data['email'] as String?,
      height: data['height'] as int?,
      heightRangeStart: data['heightRangeStart'] as int?,
      heightRangeEnd: data['heightRangeEnd'] as int?,
      isSmoker: data['isSmoker'] as bool?,
      partnerSmokingPreference: data['partnerSmokingPreference'] as String?,
      occupation: data['occupation'] as String?,
      drinkingHabit: data['drinkingHabit'] as String?,
      introvertScale: data['introvertScale'] as int?,
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
      lookingFor: List<String>.from(data['lookingFor'] ?? []),
      languages: List<String>.from(data['languages'] ?? []),
      hobbies: List<String>.from(data['hobbies'] ?? []),
      prompts: Map<String, String>.from(data['prompts'] ?? {}),
      isAdmin: data['isAdmin'] as bool? ?? false,
      isPremium: data['isPremium'] as bool? ?? false,
      isDarkMode: data['isDarkMode'] as bool? ?? false,
      isPrideMode: data['isPrideMode'] as bool? ?? false,
      appLanguage: data['appLanguage'] as String? ?? 'en',
      ageRangeStart: data['ageRangeStart'] as int? ?? 18,
      ageRangeEnd: data['ageRangeEnd'] as int? ?? 100,
      showPingAnimation: data['showPingAnimation'] as bool? ?? true,
      maxDistance: data['maxDistance'] as int? ?? 50,
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
    String? interestedIn,
    bool? isSmoker,
    String? partnerSmokingPreference,
    String? occupation,
    String? drinkingHabit,
    int? introvertScale,
    String? partnerIntrovertPreference,
    String? exerciseHabit,
    String? sleepSchedule,
    String? petPreference,
    String? childrenPreference,
    String? location,
    String? religion,
    String? religionPreference,
    String? ethnicity,
    String? ethnicityPreference,
    String? hairColor,
    String? hairColorPreference,
    String? politicalAffiliation,
    String? politicalAffiliationPreference,
    List<String>? lookingFor,
    List<String>? languages,
    List<String>? hobbies,
    Map<String, String>? prompts,
    bool? isOnboarded,
    bool? isEmailVerified,
    bool? isAdmin,
    bool? isPremium,
    bool? isDarkMode,
    bool? isPrideMode,
    String? appLanguage,
    int? ageRangeStart,
    int? ageRangeEnd,
    bool? showPingAnimation,
    int? maxDistance,
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
      isSmoker: isSmoker ?? this.isSmoker,
      partnerSmokingPreference:
          partnerSmokingPreference ?? this.partnerSmokingPreference,
      occupation: occupation ?? this.occupation,
      drinkingHabit: drinkingHabit ?? this.drinkingHabit,
      introvertScale: introvertScale ?? this.introvertScale,
      partnerIntrovertPreference:
          partnerIntrovertPreference ?? this.partnerIntrovertPreference,
      exerciseHabit: exerciseHabit ?? this.exerciseHabit,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      petPreference: petPreference ?? this.petPreference,
      childrenPreference: childrenPreference ?? this.childrenPreference,
      location: location ?? this.location,
      religion: religion ?? this.religion,
      religionPreference: religionPreference ?? this.religionPreference,
      ethnicity: ethnicity ?? this.ethnicity,
      ethnicityPreference: ethnicityPreference ?? this.ethnicityPreference,
      hairColor: hairColor ?? this.hairColor,
      hairColorPreference: hairColorPreference ?? this.hairColorPreference,
      politicalAffiliation: politicalAffiliation ?? this.politicalAffiliation,
      politicalAffiliationPreference:
          politicalAffiliationPreference ?? this.politicalAffiliationPreference,
      lookingFor: lookingFor ?? this.lookingFor,
      languages: languages ?? this.languages,
      hobbies: hobbies ?? this.hobbies,
      prompts: prompts ?? this.prompts,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      isPremium: isPremium ?? this.isPremium,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isPrideMode: isPrideMode ?? this.isPrideMode,
      appLanguage: appLanguage ?? this.appLanguage,
      ageRangeStart: ageRangeStart ?? this.ageRangeStart,
      ageRangeEnd: ageRangeEnd ?? this.ageRangeEnd,
      showPingAnimation: showPingAnimation ?? this.showPingAnimation,
      maxDistance: maxDistance ?? this.maxDistance,
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
    // Send verification email
    await cred.user!.sendEmailVerification();
    // The Cloud Function `onUserCreated` trigger automatically creates
    // the Firestore user stub — no direct write needed here.
    return AuthUser(
      id: cred.user!.uid,
      email: email.trim(),
      isOnboarded: false,
      isEmailVerified: false,
    );
  }

  // ── Fetch user from Firestore (READ only — this is fine client-side) ────
  Future<AuthUser> _fetchUser(User firebaseUser) async {
    final doc = await _users.doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return AuthUser.fromFirestore(
        firebaseUser.uid,
        doc.data()!,
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

  // ── Update profile (via Cloud Functions) ─────────────────────────────────
  Future<void> updateProfile(AuthUser user) async {
    await _api.call('updateProfile', data: user.toApiPayload());
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
      return _fetchUser(firebaseUser);
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

// ─────────────────────────────────────────────────────────────────────────────
// AuthNotifier — Riverpod StateNotifier
// ─────────────────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthUser?> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(null) {
    // Listen to Firebase auth stream on startup
    _repository.authStateChanges().listen((user) {
      state = user;
    });
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

  Future<void> updateProfile(AuthUser user) async {
    await _repository.updateProfile(user);
    state = user;
  }

  Future<void> completeOnboarding(AuthUser user) async {
    await _repository.completeOnboarding(user);
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

  Future<bool> reloadVerification() async {
    final verified = await _repository.reloadAndCheckVerification();
    if (verified && state != null) {
      state = state!.copyWith(isEmailVerified: true);
    }
    return verified;
  }
}
