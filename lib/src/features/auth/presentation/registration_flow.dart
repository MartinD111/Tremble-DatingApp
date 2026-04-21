import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../../core/theme_provider.dart';
import '../../../core/consent_service.dart';
import 'widgets/registration_steps/intro_slide_step.dart';
import 'widgets/registration_steps/name_step.dart';
import 'widgets/registration_steps/gender_step.dart';
import 'widgets/registration_steps/status_step.dart';
import 'widgets/registration_steps/exercise_step.dart';
import 'widgets/registration_steps/drinking_step.dart';
import 'widgets/registration_steps/smoking_step.dart';
import 'widgets/registration_steps/children_step.dart';
import 'widgets/registration_steps/introversion_step.dart';
import 'widgets/registration_steps/sleep_step.dart';
import 'widgets/registration_steps/pets_step.dart';
import 'widgets/registration_steps/religion_step.dart';
import 'widgets/registration_steps/ethnicity_step.dart';
import 'widgets/registration_steps/hair_color_step.dart';
import 'widgets/registration_steps/political_affiliation_step.dart';
import 'widgets/registration_steps/birthday_step.dart';
import 'widgets/registration_steps/height_step.dart';
import 'widgets/registration_steps/languages_step.dart';
import 'widgets/registration_steps/dating_preferences_step.dart';
import 'widgets/registration_steps/what_to_meet_step.dart';
import 'widgets/registration_steps/email_location_step.dart';
import 'widgets/registration_steps/hobbies_step.dart';
import 'widgets/registration_steps/photos_step.dart';
import 'widgets/registration_steps/consent_step.dart';
import '../../../core/upload_service.dart';
import '../../../shared/ui/tremble_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE INDICES (actual PageView order)
// ─────────────────────────────────────────────────────────────────────────────
// 0  : Intro slide 0
// 1  : Intro slide 1
// 2  : Intro slide 2
// 3  : Intro slide 3
// 4  : Birthday
// 5  : Email / Password / Location  (skipped for Google users)
// 6  : Name
// 7  : Gender
// 8  : Height
// 9  : Status
// 10 : Exercise
// 11 : Drinking
// 12 : Smoking
// 13 : Children
// 14 : Introversion
// 15 : Sleep
// 16 : Pets
// 17 : Religion
// 18 : Ethnicity
// 19 : Hair colour
// 20 : Political affiliation
// 21 : Languages
// 22 : Dating preferences
// 23 : What to meet
// 24 : Hobbies
// 25 : Photos
// 26 : Consent
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationFlow extends ConsumerStatefulWidget {
  const RegistrationFlow({super.key});

  @override
  ConsumerState<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends ConsumerState<RegistrationFlow> {
  late PageController _pageController;
  late int _currentPage;
  bool _isRegistering = false; // Added for loading state

  // Language - initialize from global provider
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final lang = ref.read(appLanguageProvider);
    _selectedLanguage = lang.isNotEmpty ? lang : 'sl';

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGoogleUser =
        currentUser?.providerData.any((p) => p.providerId == 'google.com') ??
            false;
    if (currentUser != null) {
      final appUser = ref.read(authStateProvider);
      if (appUser != null && appUser.onboardingCheckpoint > 0) {
        _currentPage = appUser.onboardingCheckpoint;
        _restoreStateFromUser(appUser);
      } else {
        _emailController.text = currentUser.email ?? '';
        if (isGoogleUser) {
          _nameController.text = currentUser.displayName ?? '';
        }
        _currentPage = 0;
      }
    } else {
      _currentPage = 0;
    }

    _pageController = PageController(initialPage: _currentPage);
  }

  // Email/password/location (controllers kept here; they are read by _registerUser and completeRegistration)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Name
  final TextEditingController _nameController = TextEditingController();

  // Gender
  String? _selectedGender; // 'male' | 'female' | 'non_binary'

  // Birthday
  int _pickerMonth = DateTime.now().month;
  int _pickerDay = DateTime.now().day;
  int _pickerYear = DateTime.now().year - 22;
  DateTime? _birthDate;

  // Height
  int _heightCm = 170;
  bool _isMetric = true;
  bool _isHardLocking = false;

  // About you lifestyle
  String? _exerciseHabit; // 'active' | 'sometimes' | 'almost_never'
  String? _drinkingHabit; // 'socially' | 'never' | 'frequently' | 'sober'
  String? _smokingHabit; // 'yes' | 'no'
  String? _childrenPreference; // 'want_someday' | 'dont_want' | ...
  RangeValues _introversionRange = const RangeValues(0.3, 0.7); // 30% to 70%
  String? _sleepHabit; // 'night_owl' | 'early_bird'
  String? _petPreference; // 'dog' | 'cat' | 'nothing'
  final List<String> _selectedLanguages = [];
  final TextEditingController _customLanguageController =
      TextEditingController();
  bool _showCustomLanguage = false;

  // New fields
  String? _status; // 'student' | 'employed'

  // Appearance toggles
  bool _isClassicAppearance = true;

  String? _religion;
  String? _ethnicity;
  String? _hairColor;
  double _politicalAffiliationValue = 3.0; // 1 to 5 mapping (Left to Right)

  // Partner preferences
  List<String>? _partnerReligion;
  List<String>? _partnerEthnicity;
  List<String>? _partnerHairColor;
  List<String>? _partnerExerciseHabit;
  List<String>? _partnerDrinkingHabit;
  List<String>? _partnerChildrenPreference;
  List<String>? _partnerSleepHabit;
  List<String>? _partnerPetPreference;
  List<String>? _partnerSmokingHabit;
  String? _partnerPoliticalAffiliationPreference;
  String? _partnerIntroversionRange;
  String? _partnerHeightRange;

  // Dating pref
  String? _datingPreference;
  RangeValues _ageRangePref = const RangeValues(18, 50);

  // What to meet
  final List<String> _wantToMeet = [];
  // Hobbies
  final List<String> _selectedHobbies = [];

  // Photos
  final List<File?> _photos = [null, null, null, null, null, null];
  final ImagePicker _picker = ImagePicker();

  // Prompt (Removed)

  // helpers
  String tr(String key) {
    final lang = _selectedLanguage.isNotEmpty ? _selectedLanguage : 'sl';
    final result = t(key, lang);
    // Fallback: if no translation in selected language, return English
    if (result == key) return t(key, 'en');
    return result;
  }

  void _restoreStateFromUser(AuthUser appUser) {
    _emailController.text = appUser.email ?? '';
    _nameController.text = appUser.name ?? '';
    if (appUser.birthDate != null) {
      _birthDate = appUser.birthDate;
      _pickerMonth = _birthDate!.month;
      _pickerDay = _birthDate!.day;
      _pickerYear = _birthDate!.year;
    }
    _selectedGender = appUser.gender;
    _heightCm = appUser.height ?? 170;
    _isClassicAppearance = appUser.isClassicAppearance;
    _status = appUser.jobStatus;
    if (appUser.occupation != null) {}
    _exerciseHabit = appUser.exerciseHabit;
    _drinkingHabit = appUser.drinkingHabit;
    _smokingHabit = appUser.isSmoker == true
        ? 'yes'
        : (appUser.isSmoker == false ? 'no' : null);
    _childrenPreference = appUser.childrenPreference;
    if (appUser.selfIntrovertMin != null && appUser.selfIntrovertMax != null) {
      _introversionRange = RangeValues(
        appUser.selfIntrovertMin! / 100.0,
        appUser.selfIntrovertMax! / 100.0,
      );
    } else if (appUser.introvertScale != null) {
      final center = appUser.introvertScale! / 100.0;
      _introversionRange = RangeValues(
        (center - 0.2).clamp(0.0, 1.0),
        (center + 0.2).clamp(0.0, 1.0),
      );
    }
    _sleepHabit = appUser.sleepSchedule;
    _petPreference = appUser.petPreference;
    _religion = appUser.religion;
    _ethnicity = appUser.ethnicity;
    _hairColor = appUser.hairColor;
    if (appUser.lookingFor.isNotEmpty)
      _datingPreference = appUser.lookingFor.first;
    if (appUser.interestedIn.isNotEmpty)
      _wantToMeet.addAll(appUser.interestedIn);
    if (appUser.hobbies.isNotEmpty) _selectedHobbies.addAll(appUser.hobbies);
    if (appUser.politicalAffiliation != null) {
      final map = {
        'politics_dont_care': 0.0,
        'politics_undisclosed': -1.0,
        'politics_left': 1.0,
        'politics_center_left': 2.0,
        'politics_center': 3.0,
        'politics_center_right': 4.0,
        'politics_right': 5.0,
      };
      _politicalAffiliationValue = map[appUser.politicalAffiliation] ?? 3.0;
    }
  }

  void _nextPage() {
    // Notify user about verification email when leaving the email/password page
    if (_currentPage == 5) {
      _registerUser();
      return; // Handled asynchronously by _registerUser
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
    _saveCheckpoint(_currentPage);
  }

  Future<void> _saveCheckpoint(int index) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final dump = AuthUser(
        id: currentUser.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        age: _birthDate != null
            ? (DateTime.now().difference(_birthDate!).inDays ~/ 365)
            : 20,
        birthDate: _birthDate,
        height: _heightCm,
        gender: _selectedGender ?? 'male',
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        interestedIn: _wantToMeet,
        isSmoker: _smokingHabit == 'yes',
        jobStatus: _status ?? 'student',
        occupation: null,
        drinkingHabit: _drinkingHabit ?? 'never',
        introvertScale:
            ((_introversionRange.start + _introversionRange.end) / 2 * 100)
                .toInt(),
        selfIntrovertMin: (_introversionRange.start * 100).toInt(),
        selfIntrovertMax: (_introversionRange.end * 100).toInt(),
        exerciseHabit: _exerciseHabit ?? 'sometimes',
        sleepSchedule: _sleepHabit ?? 'night_owl',
        petPreference: _petPreference ?? 'dog',
        childrenPreference: _childrenPreference ?? 'not_sure',
        religion: _religion,
        ethnicity: _ethnicity,
        hairColor: _hairColor,
        politicalAffiliation: _politicalAffiliationValue == 0
            ? 'politics_dont_care'
            : _politicalAffiliationValue == -1
                ? 'politics_undisclosed'
                : [
                    'politics_left',
                    'politics_center_left',
                    'politics_center',
                    'politics_center_right',
                    'politics_right'
                  ][(_politicalAffiliationValue - 1).toInt()],
        onboardingCheckpoint: index,
        isOnboarded: false,
      ).toApiPayload();

      await ref
          .read(authRepositoryProvider)
          .updateRegistrationDraft(currentUser.uid, dump);
    } catch (e) {
      debugPrint("Failed to save checkpoint: $e");
    }
  }

  Future<void> _registerUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (kDebugMode) {
      debugPrint(
        '[TREMBLE_AUTH_FLOW] _registerUser() called. currentUser=${currentUser?.email}, currentPage=$_currentPage',
      );
    }

    if (currentUser != null) {
      // Already logged in (via Social or incomplete Email registration), just move to next page
      if (kDebugMode) {
        debugPrint(
            '[TREMBLE_AUTH_FLOW] currentUser already exists, advancing page');
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
      return;
    }

    // New Email/Password registration
    setState(() => _isRegistering = true);

    try {
      if (kDebugMode) {
        debugPrint(
            '[TREMBLE_AUTH_FLOW] Registering via repository (bypasses premature authStateProvider update)');
      }

      // Call registerWithEmail() directly instead of authStateProvider.notifier.register().
      //
      // Why: notifier.register() updates Riverpod state (authStateProvider) synchronously
      // before this await returns, which immediately triggers _RouterNotifier.notifyListeners()
      // and a GoRouter redirect re-evaluation. On some GoRouter/Riverpod timing paths this
      // can cause RegistrationFlow to be rebuilt or replaced before _pageController.nextPage()
      // is called, resetting the PageController to page 0.
      //
      // By calling the repository directly, the page advances first. The Firebase auth stream
      // listener in AuthNotifier will update authStateProvider asynchronously (after the
      // frame has rendered page 6), which is the correct ordering.
      await ref.read(authRepositoryProvider).registerWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      if (kDebugMode) {
        debugPrint(
          '[TREMBLE_AUTH_FLOW] Register succeeded. Firebase currentUser=${FirebaseAuth.instance.currentUser?.email}',
        );
      }

      _showVerificationNotification();

      if (kDebugMode) {
        debugPrint(
            '[TREMBLE_AUTH_FLOW] Advancing page from $_currentPage to ${_currentPage + 1}');
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
        _isRegistering = false;
      });

      if (kDebugMode) {
        debugPrint(
            '[TREMBLE_AUTH_FLOW] Page advanced. currentPage=$_currentPage');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRegistering = false);
      String errorMsg = e.toString().contains('email-already-in-use')
          ? tr('email_in_use')
          : tr('registration_error');

      if (kDebugMode) {
        debugPrint('[TREMBLE_AUTH_FLOW] Register failed: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg, style: GoogleFonts.instrumentSans())),
      );
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _photos[index] = File(image.path));
    }
  }

  int _calcAge(DateTime d) {
    final now = DateTime.now();
    int age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age;
  }

  // ────── CONTINUE PILL ──────
  Widget _continueButton(
      {required bool enabled, required VoidCallback onTap, String? label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label ?? tr('continue_btn'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? Colors.black
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.black38),
                ),
          ),
        ),
      ),
    );
  }

  // ────── PROGRESS BAR ──────
  Widget _buildProgressBar() {
    const totalSteps = 26;
    final progress = (_currentPage + 1) / totalSteps;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (ctx, val, _) => LinearProgressIndicator(
        value: val,
        backgroundColor:
            isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        valueColor:
            AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
        minHeight: 3,
      ),
    );
  }

  Widget _optionPill(String label, bool selected, VoidCallback onTap,
      {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.22)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.white38 : Colors.black26),
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? Colors.white70 : Colors.black54),
                  size: 20),
              const SizedBox(width: 12)
            ],
            Text(label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xDDFFFFFF) : Colors.black87),
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showVerificationNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('verification_email')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine background brightness based on themeModeProvider
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    // Default dark gradient — Deep Graphite brand tokens
    Color topColor = isDark ? const Color(0xFF1A1A18) : const Color(0xFFFAFAF7);
    Color bottomColor =
        isDark ? const Color(0xFF1F1F1D) : const Color(0xFFF0F0EB);

    if (!_isClassicAppearance) {
      if (_selectedGender == 'male') {
        topColor = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFE0F7FA);
        bottomColor =
            isDark ? const Color(0xFF0D1B2A) : const Color(0xFF80DEEA);
      } else if (_selectedGender == 'female') {
        topColor = isDark ? const Color(0xFF1F1018) : const Color(0xFFF3E5F5);
        bottomColor =
            isDark ? const Color(0xFF1F1018) : const Color(0xFFCE93D8);
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [topColor, bottomColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: DefaultTextStyle(
              style: GoogleFonts.instrumentSans(
                color: Colors.white,
                fontSize: 14,
              ),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  IntroSlideStep(
                    index: 0,
                    onNext: _nextPage,
                    onBack: () => _goToPage(_currentPage - 1),
                    tr: tr,
                  ),
                  IntroSlideStep(
                    index: 1,
                    onNext: _nextPage,
                    onBack: () => _goToPage(_currentPage - 1),
                    tr: tr,
                  ),
                  IntroSlideStep(
                    index: 2,
                    onNext: _nextPage,
                    onBack: () => _goToPage(_currentPage - 1),
                    tr: tr,
                  ),
                  IntroSlideStep(
                    index: 3,
                    onNext: _nextPage,
                    onBack: () => _goToPage(_currentPage - 1),
                    tr: tr,
                  ),
                  // GDPR / ZVOP-2: Age verification FIRST — must confirm 18+
                  // before any personal data is collected or consent is given.
                  BirthdayStep(
                    pickerMonth: _pickerMonth,
                    pickerDay: _pickerDay,
                    pickerYear: _pickerYear,
                    onMonthChanged: (v) => setState(() => _pickerMonth = v),
                    onDayChanged: (v) => setState(() => _pickerDay = v),
                    onYearChanged: (v) => setState(() => _pickerYear = v),
                    onConfirm: (date) {
                      setState(() => _birthDate = date);
                      _nextPage();
                    },
                    onBack: () => _goToPage(_currentPage - 1),
                    tr: tr,
                  ),
                  EmailLocationStep(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    locationController: _locationController,
                    isRegistering: _isRegistering,
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinue: _nextPage,
                    tr: tr,
                  ),
                  NameStep(
                    nameController: _nameController,
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    tr: tr,
                    verificationBanner: (!(FirebaseAuth
                                    .instance.currentUser?.emailVerified ??
                                true) &&
                            (FirebaseAuth.instance.currentUser?.providerData
                                    .any((p) => p.providerId == 'password') ??
                                false))
                        ? _buildEmailVerificationBanner()
                        : null,
                  ),
                  GenderStep(
                    selectedGender: _selectedGender,
                    onGenderSelect: (g) => setState(() => _selectedGender = g),
                    isClassicAppearance: _isClassicAppearance,
                    onAppearanceToggle: (v) =>
                        setState(() => _isClassicAppearance = v),
                    isDark: ref.watch(themeModeProvider) == ThemeMode.dark,
                    onDarkModeToggle: (val) => ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(val ? ThemeMode.dark : ThemeMode.light),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onNonBinaryTap: _showNonBinaryPopup,
                    tr: tr,
                  ),
                  HeightStep(
                    heightCm: _heightCm,
                    isMetric: _isMetric,
                    onHeightChanged: (v) => setState(() => _heightCm = v),
                    onMetricToggle: (v) => setState(() => _isMetric = v),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinueTap: () => _showPartnerRangeModal(
                      title: tr('whats_your_height'),
                      min: 130,
                      max: 250,
                      divisions: 120,
                      labels: ['130 cm', '250 cm'],
                      onSave: (val) {
                        if (val == null) {
                          setState(() => _partnerHeightRange = null);
                        } else {
                          setState(() => _partnerHeightRange =
                              '${val.start.toInt()}-${val.end.toInt()}');
                        }
                      },
                    ),
                    tr: tr,
                  ),
                  StatusStep(
                    status: _status,
                    onStatusSelect: (k) => setState(() => _status = k),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    tr: tr,
                  ),
                  ExerciseStep(
                    selected: _exerciseHabit,
                    onSelect: (k) => setState(() => _exerciseHabit = k),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) =>
                        setState(() => _partnerExerciseHabit = v),
                    tr: tr,
                  ),
                  DrinkingStep(
                    selected: _drinkingHabit,
                    onSelect: (k) => setState(() => _drinkingHabit = k),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) =>
                        setState(() => _partnerDrinkingHabit = v),
                    tr: tr,
                  ),
                  SmokingStep(
                    selected: _smokingHabit,
                    onSelect: (k) => setState(() => _smokingHabit = k),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) =>
                        setState(() => _partnerSmokingHabit = v),
                    tr: tr,
                  ),
                  ChildrenStep(
                    selected: _childrenPreference,
                    onSelect: (k) => setState(() => _childrenPreference = k),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) =>
                        setState(() => _partnerChildrenPreference = v),
                    tr: tr,
                  ),
                  IntroversionStep(
                    values: _introversionRange,
                    onChanged: (v) => setState(() => _introversionRange = v),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinueTap: () => _showPartnerRangeModal(
                      title: tr('introversion'),
                      min: 0,
                      max: 1,
                      divisions: 4,
                      labels: [tr('introvert'), tr('extrovert')],
                      onSave: (val) {
                        if (val == null) {
                          setState(() => _partnerIntroversionRange = null);
                        } else {
                          setState(() => _partnerIntroversionRange =
                              '${(val.start * 100).toInt()}-${(val.end * 100).toInt()}');
                        }
                      },
                    ),
                    tr: tr,
                  ),
                  SleepStep(
                    selected: _sleepHabit,
                    onSelect: (k) => setState(() => _sleepHabit = k),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) =>
                        setState(() => _partnerSleepHabit = v),
                    tr: tr,
                  ),
                  PetsStep(
                    selected: _petPreference,
                    onSelect: (k) => setState(() => _petPreference = k),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinueTap: () {
                      final pref = _petPreference;
                      if (pref == null)
                        return; // defensive — button should already be disabled
                      _showPartnerPreferenceModal(
                        title: tr('pets'),
                        options: [
                          {'key': 'dog', 'label': tr('dog_person')},
                          {'key': 'cat', 'label': tr('cat_person')},
                          {'key': 'nothing', 'label': tr('nothing')},
                        ],
                        userSelection: pref,
                        onSave: (v) =>
                            setState(() => _partnerPetPreference = v),
                      );
                    },
                    tr: tr,
                  ),
                  ReligionStep(
                    selected: _religion,
                    onSelect: (v) => setState(() => _religion = v),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) => setState(() => _partnerReligion = v),
                    tr: tr,
                  ),
                  EthnicityStep(
                    selected: _ethnicity,
                    onSelect: (v) => setState(() => _ethnicity = v),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) => setState(() => _partnerEthnicity = v),
                    tr: tr,
                  ),
                  HairColorStep(
                    selected: _hairColor,
                    onSelect: (v) => setState(() => _hairColor = v),
                    onBack: () => _goToPage(_currentPage - 1),
                    onNext: _nextPage,
                    onSavePartner: (v) => setState(() => _partnerHairColor = v),
                    tr: tr,
                  ),
                  PoliticalAffiliationStep(
                    value: _politicalAffiliationValue,
                    onChanged: (v) =>
                        setState(() => _politicalAffiliationValue = v),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinueTap: () => _showPartnerRangeModal(
                      title: tr('political_affiliation'),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      labels: [tr('politics_left'), tr('politics_right')],
                      onSave: (val) {
                        if (val == null) {
                          setState(() =>
                              _partnerPoliticalAffiliationPreference = null);
                        } else {
                          setState(() =>
                              _partnerPoliticalAffiliationPreference =
                                  '${val.start.toInt()}-${val.end.toInt()}');
                        }
                      },
                    ),
                    tr: tr,
                  ),
                  LanguagesStep(
                    selectedLanguages: _selectedLanguages,
                    showCustom: _showCustomLanguage,
                    customLanguageController: _customLanguageController,
                    onToggleLanguage: (lang) => setState(() {
                      if (_selectedLanguages.contains(lang)) {
                        _selectedLanguages.remove(lang);
                      } else {
                        _selectedLanguages.add(lang);
                      }
                    }),
                    onToggleCustom: () => setState(
                        () => _showCustomLanguage = !_showCustomLanguage),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinue: _nextPage,
                    tr: tr,
                  ),
                  DatingPreferencesStep(
                    datingPreference: _datingPreference,
                    ageRangePref: _ageRangePref,
                    onPreferenceChanged: (v) =>
                        setState(() => _datingPreference = v),
                    onAgeRangeChanged: (v) => setState(() => _ageRangePref = v),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinue: _nextPage,
                    tr: tr,
                  ),
                  WhatToMeetStep(
                    wantToMeet: _wantToMeet,
                    onToggle: (k) => setState(() {
                      if (_wantToMeet.contains(k)) {
                        _wantToMeet.remove(k);
                      } else {
                        _wantToMeet.add(k);
                      }
                    }),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinue: _nextPage,
                    tr: tr,
                  ),
                  HobbiesStep(
                    selectedHobbies: _selectedHobbies,
                    onAddHobby: (h) => setState(() => _selectedHobbies.add(h)),
                    onRemoveHobby: (h) =>
                        setState(() => _selectedHobbies.remove(h)),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinue: _nextPage,
                    tr: tr,
                  ),
                  PhotosStep(
                    photos: _photos,
                    onPickImage: _pickImage,
                    onRemovePhoto: (i) => setState(() => _photos[i] = null),
                    onBack: () => _goToPage(_currentPage - 1),
                    onContinue: _nextPage,
                    tr: tr,
                  ),
                  ConsentStep(
                    onBack: () => _goToPage(_currentPage - 1),
                    onComplete: completeRegistration,
                    tr: tr,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildProgressBar(),
          ),
          if (_isHardLocking)
            Positioned.fill(
              child: _buildHardLockOverlay(),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 2 – NAME
  // ══════════════════════════════════════════════════════
  Widget _buildEmailVerificationBanner() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_unread_outlined,
              color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('verify_email_title'),
                  style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.instrumentSans(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await user?.sendEmailVerification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr('verification_email')),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } catch (_) {}
            },
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(
              tr('resend'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 3 – GENDER
  // ══════════════════════════════════════════════════════

  void _showNonBinaryPopup() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(LucideIcons.info,
                color: Theme.of(context).colorScheme.primary, size: 40),
            const SizedBox(height: 16),
            Text(tr('gender_nonbinary_popup_title'),
                style: GoogleFonts.instrumentSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(tr('gender_nonbinary_popup_body'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(30)),
                child: Center(
                    child: Text('OK',
                        style: GoogleFonts.instrumentSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 16))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _currentPage = page);
  }

  void _showPartnerPreferenceModal({
    required String title,
    required List<Map<String, Object>> options,
    required String userSelection,
    required ValueChanged<List<String>?> onSave,
    bool showCustom = true,
  }) {
    String? tempSelection;
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 28),
              Text(
                'Ali želiš, da ima tvoj partner enake preference?',
                style: GoogleFonts.instrumentSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E1E2E)),
              ),
              const SizedBox(height: 24),
              _optionPill('Enako kot jaz', tempSelection == 'same', () {
                setModalState(() => tempSelection = 'same');
              }),
              _optionPill('Vseeno mi je', tempSelection == 'idc', () {
                setModalState(() => tempSelection = 'idc');
              }),
              if (showCustom)
                _optionPill('Po meri', tempSelection == 'custom', () {
                  setModalState(() => tempSelection = 'custom');
                }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: isDark ? Colors.white38 : Colors.black26),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Nazaj',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tempSelection != null
                            ? Theme.of(context).colorScheme.primary
                            : (isDark ? Colors.white12 : Colors.black12),
                        foregroundColor: tempSelection != null
                            ? Colors.black
                            : (isDark ? Colors.white38 : Colors.black38),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                        elevation: tempSelection != null ? 2 : 0,
                      ),
                      onPressed: tempSelection == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              if (tempSelection == 'same') {
                                onSave([userSelection]);
                                _nextPage();
                              } else if (tempSelection == 'idc') {
                                onSave(null);
                                _nextPage();
                              } else if (tempSelection == 'custom') {
                                _showCustomPartnerPreferenceModal(
                                    title, options, onSave);
                              }
                            },
                      child: const Text('Nadaljuj',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Maps a 1–5 political value to its labeled descriptor.
  String _politicsLabelReg(double v) {
    final idx = v.round().clamp(1, 5) - 1;
    return [
      tr('politics_left'),
      tr('politics_center_left'),
      tr('politics_center'),
      tr('politics_center_right'),
      tr('politics_right'),
    ][idx];
  }

  /// Maps a 0.0–1.0 introvert value to a percentage label with personality descriptor.
  String _introvertLabelReg(double v) {
    final pct = (v * 100).toInt();
    if (pct <= 30) return '$pct% ${tr('introvert')}';
    if (pct >= 70) return '$pct% ${tr('extrovert')}';
    return '$pct% Ambivert';
  }

  void _showPartnerRangeModal({
    required String title,
    required double min,
    required double max,
    required int divisions,
    required List<String> labels,
    required ValueChanged<RangeValues?> onSave,
  }) {
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    RangeValues tempRange = RangeValues(min, max);
    bool dontCare = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return SafeArea(
            child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1A1A2E) : Colors.white)
                            .withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        border: Border(
                            top: BorderSide(
                                color:
                                    isDark ? Colors.white12 : Colors.black12)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26,
                                    borderRadius: BorderRadius.circular(2))),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Kakšen naj bo tvoj partner?',
                            style: GoogleFonts.instrumentSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E1E2E)),
                          ),
                          const SizedBox(height: 24),
                          if (!dontCare) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(labels.first,
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54)),
                                Text(labels.last,
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54)),
                              ],
                            ),
                            RangeSlider(
                              values: tempRange,
                              min: min,
                              max: max,
                              divisions: divisions > 0 ? divisions : null,
                              labels: RangeLabels(
                                title == tr('introversion')
                                    ? _introvertLabelReg(tempRange.start)
                                    : title == tr('political_affiliation')
                                        ? _politicsLabelReg(tempRange.start)
                                        : '${tempRange.start.toInt()}',
                                title == tr('introversion')
                                    ? _introvertLabelReg(tempRange.end)
                                    : title == tr('political_affiliation')
                                        ? _politicsLabelReg(tempRange.end)
                                        : '${tempRange.end.toInt()}',
                              ),
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                              inactiveColor:
                                  isDark ? Colors.white12 : Colors.black12,
                              onChanged: (v) =>
                                  setModalState(() => tempRange = v),
                            ),
                            if (title == tr('introversion'))
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${_introvertLabelReg(tempRange.start)} – ${_introvertLabelReg(tempRange.end)}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (title == tr('political_affiliation'))
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${_politicsLabelReg(tempRange.start)} – ${_politicsLabelReg(tempRange.end)}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                          _optionPill('Vseeno mi je', dontCare, () {
                            setModalState(() => dontCare = !dontCare);
                          }),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    'Nazaj',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    if (dontCare) {
                                      onSave(null);
                                    } else {
                                      onSave(tempRange);
                                    }
                                    _nextPage();
                                  },
                                  child: const Text('Nadaljuj',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ))));
      }),
    );
  }

  void _showCustomPartnerPreferenceModal(String title,
      List<Map<String, Object>> options, ValueChanged<List<String>?> onSave) {
    List<String> tempSelected = [];
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
              child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1A1A2E) : Colors.white)
                            .withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        border: Border(
                            top: BorderSide(
                                color:
                                    isDark ? Colors.white12 : Colors.black12)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26,
                                    borderRadius: BorderRadius.circular(2))),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            title,
                            style: GoogleFonts.instrumentSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E1E2E)),
                          ),
                          const SizedBox(height: 16),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: options.map((o) {
                                final val = o['key'] as String;
                                final isSelected = tempSelected.contains(val);
                                return _optionPill(
                                    o['label'] as String, isSelected, () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelected.remove(val);
                                    } else {
                                      tempSelected.add(val);
                                    }
                                  });
                                }, icon: o['icon'] as IconData?);
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black26),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                  },
                                  child: Text(
                                    'Nazaj',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _continueButton(
                                  enabled: tempSelected.isNotEmpty,
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onSave(tempSelected);
                                    _nextPage();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )));
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 18 – HOBBIES (Improved)
  // ══════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════
  // COMPLETE REGISTRATION
  // ══════════════════════════════════════════════════════
  void completeRegistration() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid =
        currentUser?.uid ?? 'generated_id'; // Fallback only if somehow null

    AuthUser? user;
    try {
      setState(() => _isRegistering = true);

      // Step 0: Upload photos in parallel to Cloudflare R2
      final validPhotos = _photos.whereType<File>().toList();

      if (kDebugMode) {
        debugPrint(
            '[RegistrationFlow] Starting upload of ${validPhotos.length} photos...');
      }

      final photoUrls = await Future.wait(
        validPhotos.map((file) =>
            ref.read(uploadServiceProvider).uploadPhotoFromPath(file.path)),
      );

      if (kDebugMode) {
        debugPrint('[RegistrationFlow] Uploads complete. URLs: $photoUrls');
      }

      final datingMap = {
        'short_term_fun': 'Kratkoročna zabava',
        'long_term_partner': 'Dolgoročni partner',
        'short_open_long': 'Kratkoročno, odprto za dolgo',
        'long_open_short': 'Dolgoročno, odprto za kratko',
        'undecided': 'Neodločen',
      };

      user = AuthUser(
        id: uid,
        name: _nameController.text,
        email: _emailController.text,
        // password removed — never stored in app state
        photoUrls: photoUrls,
        age: _birthDate != null ? _calcAge(_birthDate!) : 20,
        birthDate: _birthDate,
        height: _heightCm, // Included height in cm
        gender: _selectedGender ?? 'male',
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
        interestedIn: _wantToMeet,
        isSmoker: _smokingHabit == 'yes',
        jobStatus: _status ?? 'student',
        occupation: null,
        drinkingHabit: _drinkingHabit ?? 'never',
        introvertScale:
            ((_introversionRange.start + _introversionRange.end) / 2 * 100)
                .toInt(),
        selfIntrovertMin: (_introversionRange.start * 100).toInt(),
        selfIntrovertMax: (_introversionRange.end * 100).toInt(),
        exerciseHabit: _exerciseHabit ?? 'sometimes',
        sleepSchedule: _sleepHabit ?? 'night_owl',
        petPreference: _petPreference ?? 'dog',
        childrenPreference: _childrenPreference ?? 'not_sure',
        religion: _religion,
        ethnicity: _ethnicity,
        hairColor: _hairColor,
        politicalAffiliation: _politicalAffiliationValue == 0
            ? 'politics_dont_care'
            : _politicalAffiliationValue == -1
                ? 'politics_undisclosed'
                : [
                    'politics_left',
                    'politics_center_left',
                    'politics_center',
                    'politics_center_right',
                    'politics_right'
                  ][_politicalAffiliationValue.toInt() - 1],
        religionPreference: _partnerReligion?.join(', '),
        ethnicityPreference: _partnerEthnicity?.join(', '),
        hairColorPreference: _partnerHairColor?.join(', '),
        partnerExerciseHabit: _partnerExerciseHabit?.join(', '),
        partnerDrinkingHabit: _partnerDrinkingHabit?.join(', '),
        partnerSleepSchedule: _partnerSleepHabit?.join(', '),
        partnerPetPreference: _partnerPetPreference?.join(', '),
        partnerChildrenPreference: _partnerChildrenPreference?.join(', '),
        partnerSmokingPreference: _partnerSmokingHabit?.join(', '),
        politicalAffiliationPreference: _partnerPoliticalAffiliationPreference,
        partnerIntrovertPreference: _partnerIntroversionRange,
        partnerHeightPreference: _partnerHeightRange,
        lookingFor: _datingPreference != null
            ? [datingMap[_datingPreference!] ?? _datingPreference!]
            : [],
        languages: [
          ..._selectedLanguages,
          if (_showCustomLanguage && _customLanguageController.text.isNotEmpty)
            _customLanguageController.text
        ],
        hobbies: _selectedHobbies,
        prompts: const {},
        isOnboarded: true,
        isEmailVerified: false,
        ageRangeStart: 18,
        ageRangeEnd: 45,
        appLanguage: _selectedLanguage,
        isPremium: true, // Auto-premium in development mode as per request
        isClassicAppearance: _isClassicAppearance,
        isGenderBasedColor: !_isClassicAppearance,
      );

      // Step 1: Firebase Auth user is ALREADY created on page 5 (_registerUser)
      // We skip register() here to avoid 'email-already-in-use' exception.

      // Step 2: Save profile via Cloud Function.
      // In debug mode, API failures are bypassed inside the notifier and
      // isOnboarded is still set to true locally.
      await ref.read(authStateProvider.notifier).completeOnboarding(user);

      // Reset GDPR consent so the permission gate always shows after fresh registration.
      await ref.read(gdprConsentProvider.notifier).resetConsent();

      if (mounted) {
        setState(() => _isHardLocking = true);
        await Future.delayed(const Duration(milliseconds: 2500));
        context.go('/');
      }
    } catch (e) {
      if (kDebugMode && user != null) {
        // Dev mode: show error but force local state and navigate through.
        debugPrint('[DEV] Registration error (bypassed): $e');
        ref.read(authStateProvider.notifier).setUser(
              user.copyWith(isOnboarded: true),
            );
        await ref.read(gdprConsentProvider.notifier).resetConsent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('[DEV] Error bypassed: $e',
                  style: GoogleFonts.instrumentSans()),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() => _isHardLocking = true);
          await Future.delayed(const Duration(milliseconds: 2500));
          context.go('/');
        }
      } else {
        setState(() => _isRegistering = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e')),
          );
        }
      }
    }
  }

  Widget _buildHardLockOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.08, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInQuint,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: const TrembleLogo(size: 80),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Synchronizing Signal...',
              style: GoogleFonts.instrumentSans(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
              builder: (context, val, child) {
                return Opacity(
                  opacity: val > 0.8 ? 1.0 : 0.0,
                  child: child,
                );
              },
              child: Text(
                'SIGNAL LOCKED',
                style: GoogleFonts.instrumentSans(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
