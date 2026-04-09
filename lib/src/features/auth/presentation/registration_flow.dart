import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../../core/theme_provider.dart';
import '../../../shared/ui/tremble_back_button.dart';
import 'widgets/registration_steps/intro_slide_step.dart';
import 'widgets/registration_steps/name_step.dart';
import 'widgets/registration_steps/gender_step.dart';
import 'widgets/registration_steps/status_step.dart';
import 'widgets/registration_steps/exercise_step.dart';
import 'widgets/registration_steps/drinking_step.dart';
import 'widgets/registration_steps/smoking_step.dart';

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
    _selectedLanguage = ref.read(appLanguageProvider);

    final currentUser = FirebaseAuth.instance.currentUser;
    final isGoogleUser =
        currentUser?.providerData.any((p) => p.providerId == 'google.com') ??
            false;
    if (currentUser != null) {
      // Pre-fill known fields for any authenticated user resuming onboarding
      _emailController.text = currentUser.email ?? '';
      if (isGoogleUser) {
        _nameController.text = currentUser.displayName ?? '';
      }
    }
    _currentPage = 0;

    _pageController = PageController(initialPage: _currentPage);
  }

  // Email/password/location
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = Colors.red;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  // Name
  final TextEditingController _nameController = TextEditingController();

  // Gender
  String? _selectedGender; // 'male' | 'female' | 'non_binary'

  // Birthday
  int _pickerMonth = DateTime.now().month;
  int _pickerDay = DateTime.now().day;
  int _pickerYear = DateTime.now().year - 22;
  bool _birthdayConfirmed = false;
  DateTime? _birthDate;

  // Height
  int _heightCm = 170;
  bool _isMetric = true;

  // About you lifestyle
  String? _exerciseHabit; // 'active' | 'sometimes' | 'almost_never'
  String? _drinkingHabit; // 'socially' | 'never' | 'frequently' | 'sober'
  String? _smokingHabit; // 'yes' | 'no'
  String? _childrenPreference; // 'want_someday' | 'dont_want' | ...
  double _introversionLevel = 0.5; // 0.0 (Introvert) to 1.0 (Extrovert)
  String? _sleepHabit; // 'night_owl' | 'early_bird'
  String? _petPreference; // 'dog' | 'cat' | 'something_else' | 'nothing'
  final TextEditingController _customPetController = TextEditingController();
  final List<String> _selectedLanguages = [];
  final TextEditingController _customLanguageController =
      TextEditingController();
  bool _showCustomLanguage = false;

  // New fields
  String? _status; // 'student' | 'employed'
  final TextEditingController _customOccupationController =
      TextEditingController();

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
  final Map<String, ExpansibleController> _hobbyTileControllers = {};

  ExpansibleController _getHobbyTileController(String key) {
    if (!_hobbyTileControllers.containsKey(key)) {
      _hobbyTileControllers[key] = ExpansibleController();
    }
    return _hobbyTileControllers[key]!;
  }

  // Hobbies
  final List<String> _selectedHobbies = [];

  // Photos
  final List<File?> _photos = [null, null, null, null, null, null];
  final ImagePicker _picker = ImagePicker();

  // Prompt (Removed)

  // GDPR consent
  bool _consentTerms = false;
  bool _consentPrivacy = false;
  bool _consentDataProcessing =
      false; // GDPR Art.9 — explicit consent for sensitive data (religion, ethnicity, etc.)
  bool _consentLocation =
      false; // GDPR Art.6 / ZVOP-2 — explicit consent for live location tracking
  // ALL four must be true — no shortcuts (18+ is enforced on birthday page)
  bool get _consentGiven =>
      _consentTerms &&
      _consentPrivacy &&
      _consentDataProcessing &&
      _consentLocation;

  // helpers
  String tr(String key) => t(key, _selectedLanguage);

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
  }

  Future<void> _registerUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Already logged in (via Social or incomplete Email registration), just move to next page
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
      await ref.read(authStateProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
          );

      _showVerificationNotification();

      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
        _isRegistering = false;
      });
    } catch (e) {
      setState(() => _isRegistering = false);
      String errorMsg = e.toString().contains('email-already-in-use')
          ? tr('email_in_use')
          : tr('registration_error');

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

  void _updatePasswordStrength(String pw) {
    _hasMinLength = pw.length >= 8;
    _hasUppercase = pw.contains(RegExp(r'[A-Z]'));
    _hasDigit = pw.contains(RegExp(r'[0-9]'));
    _hasSpecialChar =
        pw.contains(RegExp(r'[!@#%^&*()_+\-=\[\]{};:,.<>?/\\|`~]'));
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecialChar) score++;
    if (pw.length >= 12) score++;
    if (pw.length >= 16) score++;
    if (pw.contains(RegExp(r'[a-z]'))) score++;
    double strength = math.min(score / 5.0, 1.0);
    if (pw.isEmpty) strength = 0.0;
    String label;
    Color color;
    if (strength == 0) {
      label = '';
      color = Colors.red;
    } else if (strength < 0.3) {
      label = tr('very_weak');
      color = Colors.red;
    } else if (strength < 0.5) {
      label = tr('weak');
      color = Colors.orange;
    } else if (strength < 0.7) {
      label = tr('medium');
      color = Colors.amber;
    } else if (strength < 0.9) {
      label = tr('strong');
      color = const Color(0xFF2D9B6F);
    } else {
      label = tr('very_strong');
      color = const Color(0xFF2D9B6F);
    }
    setState(() {
      _passwordStrength = strength;
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasDigit && _hasSpecialChar;

  // ────── ZODIAC ──────
  String _zodiacSign(DateTime d) {
    final m = d.month;
    final day = d.day;
    if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) return '♒ Aquarius';
    if ((m == 2 && day >= 19) || (m == 3 && day <= 20)) return '♓ Pisces';
    if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) return '♈ Aries';
    if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) return '♉ Taurus';
    if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) return '♊ Gemini';
    if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) return '♋ Cancer';
    if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) return '♌ Leo';
    if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) return '♍ Virgo';
    if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) return '♎ Libra';
    if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) return '♏ Scorpio';
    if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) {
      return '♐ Sagittarius';
    }
    return '♑ Capricorn';
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
    const _brandRose = Color(0xFFF4436C);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: enabled
              ? _brandRose
              : (isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: _brandRose.withValues(alpha: 0.3),
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

  // ────── BACK BUTTON ──────
  Widget _backButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: TrembleBackButton(
        label: tr('back'),
        onPressed: () async {
          if (_currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
            setState(() => _currentPage--);
          } else {
            // Sign out if leaving onboarding completely to allow fresh start
            if (FirebaseAuth.instance.currentUser != null) {
              await FirebaseAuth.instance.signOut();
            }
            if (mounted) context.pop();
          }
        },
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
        valueColor: const AlwaysStoppedAnimation(Color(0xFFF4436C)),
        minHeight: 3,
      ),
    );
  }

  // ────── STEP HEADER ──────
  Widget _stepHeader(String title, {String? subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black)),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
                height: 1.4)),
      ],
    ]);
  }

  Widget _optionPill(String label, bool selected, VoidCallback onTap,
      {IconData? icon}) {
    const _brandRose = Color(0xFFF4436C);
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
              ? _brandRose.withValues(alpha: 0.22)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: selected
                  ? _brandRose
                  : (isDark ? Colors.white38 : Colors.black26),
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: selected
                      ? _brandRose
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
            if (selected) Icon(Icons.check_circle, color: _brandRose, size: 20),
          ],
        ),
      ),
    );
  }

  void _showVerificationNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('verification_email')),
        backgroundColor: const Color(0xFFF4436C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildScrollableFormPage({required Widget child}) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine background brightness based on themeModeProvider
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    // Gender-specific gradient — intentional UI, not brand tokens. Do not replace with TrembleTheme colors.
    Color topColor = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF0F4F8);
    Color bottomColor =
        isDark ? const Color(0xFF2A2A3E) : const Color(0xFFD9E2EC);

    if (!_isClassicAppearance) {
      if (_selectedGender == 'male') {
        topColor = isDark ? const Color(0xFF0D253F) : const Color(0xFFE0F7FA);
        bottomColor =
            isDark ? const Color(0xFF005662) : const Color(0xFF80DEEA);
      } else if (_selectedGender == 'female') {
        topColor = isDark ? const Color(0xFF2A0845) : const Color(0xFFF3E5F5);
        bottomColor =
            isDark ? const Color(0xFF6441A5) : const Color(0xFFCE93D8);
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
                  IntroSlideStep(index: 0, onNext: _nextPage, tr: tr),
                  IntroSlideStep(index: 1, onNext: _nextPage, tr: tr),
                  IntroSlideStep(index: 2, onNext: _nextPage, tr: tr),
                  IntroSlideStep(index: 3, onNext: _nextPage, tr: tr),
                  // GDPR / ZVOP-2: Age verification FIRST — must confirm 18+
                  // before any personal data is collected or consent is given.
                  _buildPageBirthday(),
                  _buildPageEmailPassword(),
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
                  _buildPageHeight(),
                  StatusStep(
                    status: _status,
                    onStatusSelect: (k) => setState(() => _status = k),
                    occupationController: _customOccupationController,
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
                  _buildPageChildren(),
                  _buildPageIntroversion(),
                  _buildPageSleep(),
                  _buildPagePets(),
                  _buildPageReligion(),
                  _buildPageEthnicity(),
                  _buildPageHairColor(),
                  _buildPagePoliticalAffiliation(),
                  _buildPageLanguages(),
                  _buildPageDatingPreferences(),
                  _buildPageWhatToMeet(),
                  _buildPageHobbies(),
                  _buildPagePhotos(),
                  _buildPageConsent(),
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
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 5 – EMAIL / PASSWORD / LOCATION
  // ══════════════════════════════════════════════════════
  Widget _buildPageEmailPassword() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAlreadyLoggedIn = currentUser != null;
    final isSocialUser = currentUser?.providerData.any((p) =>
            p.providerId == 'google.com' || p.providerId == 'apple.com') ??
        false;
    final hasPassword =
        currentUser?.providerData.any((p) => p.providerId == 'password') ??
            false;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _backButton(),
            const SizedBox(height: 16),
            _stepHeader(tr('basic_info')),
            const SizedBox(height: 32),
            if (isAlreadyLoggedIn &&
                (isSocialUser || hasPassword) &&
                _emailController.text.isNotEmpty)
              _inputField(tr('email'), _emailController,
                  icon: LucideIcons.mail,
                  keyboard: TextInputType.emailAddress,
                  readOnly: true)
            else
              _inputField(tr('email'), _emailController,
                  icon: LucideIcons.mail,
                  keyboard: TextInputType.emailAddress,
                  readOnly: false),
            const SizedBox(height: 20),
            _locationAutocomplete(),
            // Show password fields if the user is not logged in OR if they haven't set a password yet (Social users)
            if (!hasPassword && !isSocialUser) ...[
              const SizedBox(height: 20),
              _passwordInputField(),
              const SizedBox(height: 20),
              _confirmPasswordInputField(),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _passwordStrengthBar(),
                const SizedBox(height: 8),
                _pwReq(tr('pw_min_length'), _hasMinLength),
                _pwReq(tr('pw_uppercase'), _hasUppercase),
                _pwReq(tr('pw_digit'), _hasDigit),
                _pwReq(tr('pw_special'), _hasSpecialChar),
                _pwReq(
                    tr('confirm_password'),
                    _passwordController.text ==
                            _confirmPasswordController.text &&
                        _confirmPasswordController.text.isNotEmpty),
              ],
            ],
            const SizedBox(height: 32),
            _buildPremiumPill(),
            const SizedBox(height: 32),
            _isRegistering
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF4436C)))
                : _continueButton(
                    enabled: _emailController.text.isNotEmpty &&
                        ((isAlreadyLoggedIn && (isSocialUser || hasPassword)) ||
                            (_isPasswordValid &&
                                _passwordController.text ==
                                    _confirmPasswordController.text)),
                    onTap: _nextPage,
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl,
      {IconData? icon, TextInputType? keyboard, bool readOnly = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      readOnly: readOnly,
      style: GoogleFonts.instrumentSans(color: textColor, fontSize: 17),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.instrumentSans(color: hintColor),
        prefixIcon:
            icon != null ? Icon(icon, color: iconColor, size: 20) : null,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderFocusColor, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  Widget _passwordInputField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.instrumentSans(color: textColor, fontSize: 17),
      onChanged: _updatePasswordStrength,
      decoration: InputDecoration(
        labelText: tr('password'),
        labelStyle: GoogleFonts.instrumentSans(color: hintColor),
        prefixIcon: Icon(LucideIcons.lock, color: iconColor, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderFocusColor, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
              color: iconColor, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  Widget _passwordStrengthBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? Colors.white12 : Colors.black12;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _passwordStrength),
      duration: const Duration(milliseconds: 400),
      builder: (ctx, val, _) => Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: val,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
              )),
        ),
        const SizedBox(height: 4),
        Align(
            alignment: Alignment.centerRight,
            child: Text(_passwordStrengthLabel,
                style: TextStyle(
                    color: _passwordStrengthColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _confirmPasswordInputField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: TextStyle(color: textColor, fontSize: 17),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: tr('confirm_password'),
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(LucideIcons.lock, color: iconColor, size: 20),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide(color: borderFocusColor, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: IconButton(
          icon: Icon(
              _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
              color: iconColor,
              size: 20),
          onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
    );
  }

  Widget _pwReq(String text, bool met) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unmetIconColor = isDark ? Colors.white30 : Colors.black26;
    final unmetTextColor = isDark ? Colors.white38 : Colors.black45;
    final successColor = isDark ? Colors.greenAccent : const Color(0xFF2D9B6F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(met ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: 14, color: met ? successColor : unmetIconColor),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: met ? successColor : unmetTextColor,
                decoration: met ? TextDecoration.lineThrough : null,
                decorationColor: successColor.withValues(alpha: 0.5))),
      ]),
    );
  }

  Widget _locationAutocomplete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final iconColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark ? Colors.white30 : Colors.black26;
    final borderFocusColor = isDark ? Colors.white : Colors.black;

    return Autocomplete<String>(
      optionsBuilder: (tv) {
        if (tv.text.isEmpty) return const Iterable<String>.empty();
        return locationSuggestions
            .where((c) => c.toLowerCase().contains(tv.text.toLowerCase()));
      },
      onSelected: (s) => setState(() => _locationController.text = s),
      fieldViewBuilder: (ctx, ctrl, fn, _) {
        if (_locationController.text.isNotEmpty && ctrl.text.isEmpty) {
          ctrl.text = _locationController.text;
        }
        return TextField(
          controller: ctrl,
          focusNode: fn,
          style: TextStyle(color: textColor, fontSize: 17),
          onChanged: (v) {
            _locationController.text = v;
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: tr('from_where'),
            labelStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(LucideIcons.mapPin, color: iconColor, size: 20),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(color: borderFocusColor, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180, maxWidth: 340),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: opts.length,
              itemBuilder: (ctx, i) {
                final o = opts.elementAt(i);
                return ListTile(
                    dense: true,
                    leading: Icon(LucideIcons.mapPin,
                        size: 14,
                        color: isDark ? Colors.white54 : Colors.black54),
                    title: Text(o, style: TextStyle(color: textColor)),
                    onTap: () => onSel(o));
              },
            ),
          ),
        ),
      ),
    );
  }

  // ────── PREMIUM PILL ──────
  Widget _buildPremiumPill() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.diamond,
                      color: Color(0xFFF4436C), size: 40),
                  const SizedBox(height: 16),
                  Text(
                    tr('premium_free_notice'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('current_users_count').replaceAll('{count}', '4.832'),
                    style: const TextStyle(
                        color: Color(0xFFF4436C),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4436C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4436C).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: const Color(0xFFF4436C).withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.diamond,
                  color: Color(0xFFF4436C), size: 16),
              const SizedBox(width: 8),
              Text(
                tr('premium_account_activated'),
                style: const TextStyle(
                    color: Color(0xFFF4436C),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
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
        color: const Color(0xFFF4436C).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFF4436C).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              color: Color(0xFFF4436C), size: 20),
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
                      backgroundColor: const Color(0xFFF4436C),
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
              style: const TextStyle(color: Color(0xFFF4436C), fontSize: 12),
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
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(LucideIcons.info, color: Color(0xFFF4436C), size: 40),
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
                    color: const Color(0xFFF4436C),
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

  // ══════════════════════════════════════════════════════
  // PAGE 4 – BIRTHDAY
  // ══════════════════════════════════════════════════════
  Widget _buildPageBirthday() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final now = DateTime.now();
    final maxYear = now.year - 18;
    final minYear = now.year - 100;
    final maxDays = DateTime(_pickerYear, _pickerMonth + 1, 0).day;
    final validDay = _pickerDay > maxDays ? maxDays : _pickerDay;
    final d = DateTime(_pickerYear, _pickerMonth, validDay);
    final age = _calcAge(d);
    final zodiac = _zodiacSign(d);

    return _buildScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 24),
          _stepHeader(tr('whats_your_birthday'),
              subtitle: tr('birthday_subtitle')),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(children: [
              Expanded(
                  child: _drumPicker(
                items: months,
                selectedIndex: _pickerMonth - 1,
                looping: true,
                onChanged: (i) => setState(() => _pickerMonth = i + 1),
              )),
              SizedBox(
                  width: 65,
                  child: _drumPicker(
                    items: List.generate(maxDays, (i) => '${i + 1}'),
                    selectedIndex: validDay - 1,
                    looping: true,
                    onChanged: (i) => setState(
                        () => _pickerDay = i + 1 > maxDays ? maxDays : i + 1),
                  )),
              SizedBox(
                  width: 90,
                  child: _drumPicker(
                    items: List.generate(
                        maxYear - minYear + 1, (i) => '${maxYear - i}'),
                    selectedIndex: maxYear - _pickerYear,
                    looping: false,
                    onChanged: (i) => setState(() => _pickerYear = maxYear - i),
                  )),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _chip('🎂 $age'),
            const SizedBox(width: 8),
            _chip(zodiac),
          ]),
          const SizedBox(height: 24),
          _continueButton(
            enabled: true,
            onTap: () => _showBirthdayConfirmation(),
            label: _birthdayConfirmed ? tr('continue_btn') : tr('continue_btn'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drumPicker(
      {required List<String> items,
      required int selectedIndex,
      required ValueChanged<int> onChanged,
      bool looping = false}) {
    final ctrl = FixedExtentScrollController(initialItem: selectedIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : Colors.black87;
    final inactiveColor = isDark ? Colors.white38 : Colors.black26;

    return ListWheelScrollView.useDelegate(
      controller: ctrl,
      itemExtent: 44,
      perspective: 0.004,
      diameterRatio: 1.8,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) {
        if (looping) {
          onChanged(i % items.length);
        } else {
          onChanged(i);
        }
      },
      childDelegate: looping
          ? ListWheelChildLoopingListDelegate(
              children: List.generate(items.length, (i) {
                final selected = i == (selectedIndex % items.length);
                return Center(
                    child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.instrumentSans(
                    fontSize: selected ? 20 : 16,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? activeColor : inactiveColor,
                  ),
                  child: Text(items[i]),
                ));
              }),
            )
          : ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (ctx, i) {
                final selected = i == selectedIndex;
                return Center(
                    child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.instrumentSans(
                    fontSize: selected ? 20 : 16,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? activeColor : inactiveColor,
                  ),
                  child: Text(items[i]),
                ));
              },
            ),
    );
  }

  Widget _chip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white38 : Colors.black26)),
      child: Text(label,
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
    );
  }

  void _showBirthdayConfirmation() {
    final maxDays = DateTime(_pickerYear, _pickerMonth + 1, 0).day;
    final validDay = _pickerDay > maxDays ? maxDays : _pickerDay;
    final d = DateTime(_pickerYear, _pickerMonth, validDay);
    final age = _calcAge(d);
    final dateStr = DateFormat('MMMM d, yyyy').format(d);
    const _brandRose = Color(0xFFF4436C);
    const red = Color(0xFFFF4C4C);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final bodyColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final handleColor = isDark ? Colors.white24 : Colors.black26;
    final buttonBg =
        isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);

    // ── ZVOP-2 čl. 14 / GDPR čl. 8 — HARD STOP FOR UNDER 18 ──────────
    // App is strictly 18+. Registration is impossible for minors.
    if (age < 18) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              decoration: BoxDecoration(
                color: sheetBg.withValues(alpha: 0.8),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 28),
                const Icon(Icons.block_rounded, color: red, size: 56),
                const SizedBox(height: 20),
                Text(
                  'Tremble is 18+ only',
                  style: GoogleFonts.instrumentSans(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: titleColor),
                ),
                const SizedBox(height: 12),
                Text(
                  'You must be at least 18 years old to use Tremble. '
                  'We are unable to create an account for you at this time.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSans(
                      color: bodyColor, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                        color: buttonBg,
                        borderRadius: BorderRadius.circular(30)),
                    child: Center(
                        child: Text('Go back',
                            style: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white70 : Colors.black87,
                                letterSpacing: 1.2))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
      return; // Stop — do not proceed to next page
    }
    // ──────────────────────────────────────────────────────────────────

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            decoration: BoxDecoration(
              color: sheetBg.withValues(alpha: 0.8),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 28),
              Text(
                tr('youre_age').replaceAll('{age}', '$age'),
                style: GoogleFonts.instrumentSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: titleColor),
              ),
              const SizedBox(height: 12),
              Text(
                tr('is_birthday_correct').replaceAll('{date}', dateStr),
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                    color: bodyColor, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _birthDate = d;
                    _birthdayConfirmed = true;
                  });
                  Navigator.pop(ctx);
                  _nextPage();
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                      color: _brandRose,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: _brandRose.withValues(alpha: 0.4),
                            blurRadius: 16)
                      ]),
                  child: Center(
                      child: Text(tr('confirm_btn').toUpperCase(),
                          style: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black,
                              letterSpacing: 1.2))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('edit_btn').toUpperCase(),
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        letterSpacing: 1.2,
                        fontSize: 13)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 5 – HEIGHT
  // ══════════════════════════════════════════════════════
  Widget _buildPageHeight() {
    // Generate height ranges
    final cmItems = List.generate(121, (i) => '${130 + i}'); // 130 to 250 cm
    final ftInItems = <String>[];
    for (int f = 4; f <= 8; f++) {
      for (int i = 0; i < 12; i++) {
        if (f == 8 && i > 2) break; // max ~8'2"
        ftInItems.add('$f\'$i"');
      }
    }

    // Convert current cm to ft/in index
    int ft = (_heightCm / 30.48).floor();
    int inc = ((_heightCm / 2.54) - (ft * 12)).round();
    if (inc == 12) {
      ft++;
      inc = 0;
    }
    int ftInIndex = ftInItems.indexOf('$ft\'$inc"');
    if (ftInIndex == -1) ftInIndex = ftInItems.indexOf('5\'7"');

    int cmIndex = cmItems.indexOf('$_heightCm');
    if (cmIndex == -1) cmIndex = cmItems.indexOf('170');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toggleBgColor =
        isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);

    return _buildScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 24),
          _stepHeader(tr('whats_your_height')),
          const SizedBox(height: 48),
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: toggleBgColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isMetric = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isMetric
                            ? const Color(0xFFF4436C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(tr('height_cm'),
                          style: TextStyle(
                              color: _isMetric
                                  ? Colors.black
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: _isMetric
                                  ? FontWeight.bold
                                  : FontWeight.w500)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isMetric = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isMetric
                            ? const Color(0xFFF4436C)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(tr('height_ft_in'),
                          style: TextStyle(
                              color: !_isMetric
                                  ? Colors.black
                                  : (isDark ? Colors.white70 : Colors.black54),
                              fontWeight: !_isMetric
                                  ? FontWeight.bold
                                  : FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            child: Center(
              child: _isMetric
                  ? _drumPicker(
                      items: cmItems,
                      selectedIndex: cmIndex,
                      onChanged: (i) {
                        setState(() => _heightCm = int.parse(cmItems[i]));
                      })
                  : _drumPicker(
                      items: ftInItems,
                      selectedIndex: ftInIndex,
                      onChanged: (i) {
                        final str = ftInItems[i];
                        final parts = str.split('\'');
                        final feet = int.parse(parts[0]);
                        final inches = int.parse(parts[1].replaceAll('"', ''));
                        final cm = ((feet * 12 + inches) * 2.54).round();
                        setState(() => _heightCm = cm);
                      }),
            ),
          ),
          _continueButton(
              enabled: true,
              onTap: () {
                _showPartnerRangeModal(
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
                );
              }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _currentPage = page);
  }

  // ══════════════════════════════════════════════════════
  // PAGE RELIGION
  // ══════════════════════════════════════════════════════
  Widget _buildPageReligion() {
    return _subScreen(
      title: tr('religion'),
      backTarget: _currentPage - 1,
      options: [
        {'key': 'christianity', 'label': tr('christianity')},
        {'key': 'islam', 'label': tr('islam')},
        {'key': 'hinduism', 'label': tr('hinduism')},
        {'key': 'buddhism', 'label': tr('buddhism')},
        {'key': 'judaism', 'label': tr('judaism')},
        {'key': 'agnostic', 'label': tr('agnostic')},
        {'key': 'atheist', 'label': tr('atheist')},
      ],
      selected: _religion,
      onSelect: (val) {
        setState(() => _religion = val);
      },
      onSavePartner: (val) => setState(() => _partnerReligion = val),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE ETHNICITY
  // ══════════════════════════════════════════════════════
  Widget _buildPageEthnicity() {
    return _subScreen(
      title: tr('ethnicity'),
      backTarget: _currentPage - 1,
      options: [
        {'key': 'white', 'label': tr('ethnicity_white')},
        {'key': 'black', 'label': tr('ethnicity_black')},
        {'key': 'mixed', 'label': tr('ethnicity_mixed')},
        {'key': 'asian', 'label': tr('ethnicity_asian')},
      ],
      selected: _ethnicity,
      onSelect: (val) {
        setState(() => _ethnicity = val);
      },
      onSavePartner: (val) => setState(() => _partnerEthnicity = val),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE HAIR COLOR
  // ══════════════════════════════════════════════════════
  Widget _buildPageHairColor() {
    return _subScreen(
      title: tr('hair_color'),
      backTarget: _currentPage - 1,
      options: [
        {'key': 'blonde', 'label': tr('hair_blonde')},
        {'key': 'brunette', 'label': tr('hair_brunette')},
        {'key': 'black', 'label': tr('hair_black')},
        {'key': 'red', 'label': tr('hair_red')},
        {'key': 'gray_white', 'label': tr('hair_gray_white')},
        {'key': 'other', 'label': tr('hair_other')},
      ],
      selected: _hairColor,
      onSelect: (val) {
        setState(() => _hairColor = val);
      },
      onSavePartner: (val) => setState(() => _partnerHairColor = val),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE POLITICAL AFFILIATION
  // ══════════════════════════════════════════════════════
  Widget _buildPagePoliticalAffiliation() {
    final labels = [
      tr('politics_left'),
      tr('politics_center_left'),
      tr('politics_center'),
      tr('politics_center_right'),
      tr('politics_right')
    ];
    return _buildScrollableFormPage(
      child: Column(
        children: [
          _backButton(),
          const SizedBox(height: 40),
          _stepHeader(tr('political_affiliation')),
          const SizedBox(height: 48),
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final labelColor = isDark ? Colors.white70 : Colors.black54;
            return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr('politics_left'),
                      style: GoogleFonts.instrumentSans(color: labelColor)),
                  Text(tr('politics_right'),
                      style: GoogleFonts.instrumentSans(color: labelColor)),
                ]);
          }),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: (_politicalAffiliationValue == 0 ||
                      _politicalAffiliationValue == -1)
                  ? const RoundSliderThumbShape(enabledThumbRadius: 0)
                  : const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: (_politicalAffiliationValue == 0 ||
                      _politicalAffiliationValue == -1)
                  ? 3
                  : _politicalAffiliationValue.clamp(1.0, 5.0),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) {
                if (_politicalAffiliationValue == 0 ||
                    _politicalAffiliationValue == -1) return;
                setState(() => _politicalAffiliationValue = v);
              },
              activeColor: const Color(0xFFF4436C),
              inactiveColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white12
                  : Colors.black12,
            ),
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final idx = _politicalAffiliationValue.toInt();
            // Guard against index -1 or 0 when "Don't care" or "Undisclosed" is selected
            final displayLabel = (idx >= 1 &&
                    idx <= labels.length &&
                    _politicalAffiliationValue > 0)
                ? labels[idx - 1]
                : '';
            return Text(displayLabel,
                style: GoogleFonts.instrumentSans(
                    color: const Color(0xFFF4436C),
                    fontSize: 18,
                    fontWeight: FontWeight.bold));
          }),
          const SizedBox(height: 32),
          _optionPill(tr('politics_dont_care'), _politicalAffiliationValue == 0,
              () {
            setState(() => _politicalAffiliationValue = 0);
          }),
          _optionPill(
              tr('politics_undisclosed'), _politicalAffiliationValue == -1, () {
            setState(() => _politicalAffiliationValue = -1);
          }),
          const SizedBox(height: 24),
          _continueButton(
              enabled: true,
              onTap: () {
                _showPartnerRangeModal(
                  title: tr('political_affiliation'),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  labels: [tr('politics_left'), tr('politics_right')],
                  onSave: (val) {
                    if (val == null) {
                      setState(
                          () => _partnerPoliticalAffiliationPreference = null);
                    } else {
                      setState(() => _partnerPoliticalAffiliationPreference =
                          '${val.start.toInt()}-${val.end.toInt()}');
                    }
                  },
                );
              }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 6 – EXERCISE
  // ══════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════
  // PAGE 7 – DRINKING
  // ══════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════
  // PAGE 10 – SMOKING (Updated with partner pref)
  // ══════════════════════════════════════════════════════

  Widget _subScreen({
    required String title,
    required int backTarget,
    required List<Map<String, Object>> options,
    required String? selected,
    required ValueChanged<String> onSelect,
    bool showCustomPartnerPref = true,
    ValueChanged<List<String>?>? onSavePartner,
    VoidCallback? overrideContinue,
  }) {
    return _buildScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: TrembleBackButton(
              onPressed: () => _goToPage(backTarget),
              label: tr('back'),
            ),
          ),
          const SizedBox(height: 24),
          _stepHeader(title),
          const SizedBox(height: 40),
          ...options.map((o) => _optionPill(
                o['label'] as String,
                selected == o['key'],
                () => onSelect(o['key'] as String),
                icon: o['icon'] as IconData?,
              )),
          const SizedBox(height: 24),
          _continueButton(
            enabled: selected != null,
            onTap: overrideContinue ??
                () {
                  if (onSavePartner != null && selected != null) {
                    _showPartnerPreferenceModal(
                      title: title,
                      options: options,
                      userSelection: selected,
                      showCustom: showCustomPartnerPref,
                      onSave: onSavePartner,
                    );
                  } else {
                    _nextPage();
                  }
                },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
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
                            ? const Color(0xFFF4436C)
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
                                    ? '${(tempRange.start * 100).toInt()}%'
                                    : '${tempRange.start.toInt()}',
                                title == tr('introversion')
                                    ? '${(tempRange.end * 100).toInt()}%'
                                    : '${tempRange.end.toInt()}',
                              ),
                              activeColor: const Color(0xFFF4436C),
                              inactiveColor:
                                  isDark ? Colors.white12 : Colors.black12,
                              onChanged: (v) =>
                                  setModalState(() => tempRange = v),
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
                                    backgroundColor: const Color(0xFFF4436C),
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
  // PAGE 9 – CHILDREN PREFERENCE
  // ══════════════════════════════════════════════════════
  Widget _buildPageChildren() {
    return _subScreen(
      title: tr('do_you_want_children'),
      backTarget: _currentPage - 1,
      options: [
        {
          'key': 'want_someday',
          'label': tr('children_want_someday'),
          'icon': LucideIcons.heart
        },
        {
          'key': 'dont_want',
          'label': tr('children_dont_want'),
          'icon': LucideIcons.ban
        },
        {
          'key': 'have_and_want_more',
          'label': tr('children_have_and_want_more'),
          'icon': LucideIcons.users
        },
        {
          'key': 'have_and_dont_want_more',
          'label': tr('children_have_and_dont_want_more'),
          'icon': LucideIcons.userCheck
        },
        {
          'key': 'not_sure',
          'label': tr('children_not_sure'),
          'icon': LucideIcons.helpCircle
        },
      ],
      selected: _childrenPreference,
      onSelect: (k) {
        setState(() => _childrenPreference = k);
      },
      onSavePartner: (val) => setState(() => _partnerChildrenPreference = val),
    );
  }

  // ══════════════════════════════════════════════════════
  // NEW LIFESTYLE SCREENS
  // ══════════════════════════════════════════════════════
  Widget _buildPageIntroversion() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildScrollableFormPage(
      child: Column(
        children: [
          _backButton(),
          const SizedBox(height: 40),
          _stepHeader(tr('introversion')),
          const SizedBox(height: 48),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(tr('introvert'),
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            Text(tr('extrovert'),
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          ]),
          Slider(
            value: _introversionLevel,
            onChanged: (v) {
              setState(() => _introversionLevel = v);
            },
            activeColor: const Color(0xFFF4436C),
            inactiveColor:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _introversionLevel <= 0.5
                  ? '${((1.0 - _introversionLevel) * 100).toInt()}% ${tr('introvert').toLowerCase()}'
                  : '${(_introversionLevel * 100).toInt()}% ${tr('extrovert').toLowerCase()}',
              style: const TextStyle(
                  color: Color(0xFFF4436C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          _continueButton(
              enabled: true,
              onTap: () {
                _showPartnerRangeModal(
                  title: tr('introversion'),
                  min: 0,
                  max: 1,
                  divisions: 100,
                  labels: [tr('introvert'), tr('extrovert')],
                  onSave: (val) {
                    if (val == null) {
                      setState(() => _partnerIntroversionRange = null);
                    } else {
                      setState(() => _partnerIntroversionRange =
                          '${(val.start * 100).toInt()}-${(val.end * 100).toInt()}');
                    }
                  },
                );
              }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPageSleep() {
    return _subScreen(
      title: tr('sleep'),
      backTarget: _currentPage - 1,
      options: [
        {
          'key': 'night_owl',
          'label': tr('night_owl'),
          'icon': LucideIcons.moon
        },
        {
          'key': 'early_bird',
          'label': tr('early_bird'),
          'icon': LucideIcons.sun
        },
      ],
      selected: _sleepHabit,
      onSelect: (k) {
        setState(() => _sleepHabit = k);
      },
      showCustomPartnerPref: false,
      onSavePartner: (val) => setState(() => _partnerSleepHabit = val),
    );
  }

  Widget _buildPagePets() {
    return _buildScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 24),
          _stepHeader(tr('pets')),
          const SizedBox(height: 24),
          _optionPill(tr('dog_person'), _petPreference == 'dog',
              () => setState(() => _petPreference = 'dog')),
          _optionPill(tr('cat_person'), _petPreference == 'cat',
              () => setState(() => _petPreference = 'cat')),
          _optionPill(tr('something_else'), _petPreference == 'something_else',
              () => setState(() => _petPreference = 'something_else')),
          if (_petPreference == 'something_else')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return TextField(
                  controller: _customPetController,
                  style: GoogleFonts.instrumentSans(
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: tr('write_answer'),
                    hintStyle: GoogleFonts.instrumentSans(
                        color: isDark ? Colors.white30 : Colors.black38),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white30 : Colors.black26)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(100),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                );
              }),
            ),
          _optionPill(tr('nothing'), _petPreference == 'nothing',
              () => setState(() => _petPreference = 'nothing')),
          const SizedBox(height: 24),
          _continueButton(
              enabled: _petPreference != null,
              onTap: () {
                _showPartnerPreferenceModal(
                  title: tr('pets'),
                  options: [
                    {'key': 'dog', 'label': tr('dog_person')},
                    {'key': 'cat', 'label': tr('cat_person')},
                    {'key': 'something_else', 'label': tr('something_else')},
                    {'key': 'nothing', 'label': tr('nothing')},
                  ],
                  userSelection: _petPreference!,
                  onSave: (val) => setState(() => _partnerPetPreference = val),
                );
              }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPageLanguages() {
    final opts = [
      'Angleščina 🇬🇧',
      'Slovenščina 🇸🇮',
      'Nemščina 🇩🇪',
      'Italijanščina 🇮🇹',
      'Hrvaščina 🇭🇷',
      'Španščina 🇪🇸',
      'Francoščina 🇫🇷',
    ];
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _backButton(),
            const SizedBox(height: 16),
            _stepHeader(tr('how_many_languages')),
            const SizedBox(height: 24),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              ...opts.map((lang) {
                final sel = _selectedLanguages.contains(lang);
                return _optionPill(lang, sel, () {
                  setState(() {
                    if (sel) {
                      _selectedLanguages.remove(lang);
                    } else {
                      _selectedLanguages.add(lang);
                    }
                  });
                });
              }),
              _optionPill('Custom', _showCustomLanguage, () {
                setState(() => _showCustomLanguage = !_showCustomLanguage);
              }),
              if (_showCustomLanguage)
                Builder(builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return TextField(
                    controller: _customLanguageController,
                    style: GoogleFonts.instrumentSans(
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: tr('write_answer'),
                      hintStyle: GoogleFonts.instrumentSans(
                          color: isDark ? Colors.white30 : Colors.black38),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(
                              color: isDark ? Colors.white30 : Colors.black26)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(
                              color: isDark ? Colors.white : Colors.black,
                              width: 2)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    onChanged: (v) => setState(() {}),
                  );
                }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _continueButton(
              enabled: _selectedLanguages.isNotEmpty ||
                  (_showCustomLanguage &&
                      _customLanguageController.text.isNotEmpty),
              onTap: _nextPage),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 16 – DATING PREFERENCES (Updated)
  // ══════════════════════════════════════════════════════
  Widget _buildPageDatingPreferences() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opts = [
      {'key': 'short_term_fun', 'label': tr('short_term_fun')},
      {'key': 'long_term_partner', 'label': tr('long_term_partner')},
      {'key': 'short_open_long', 'label': tr('short_open_long')},
      {'key': 'long_open_short', 'label': tr('long_open_short')},
      {'key': 'undecided', 'label': tr('undecided')},
    ];
    return _buildScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 24),
          _stepHeader(tr('who_looking_for')),
          const SizedBox(height: 24),
          ...opts.map((o) => _optionPill(
              o['label']!,
              _datingPreference == o['key'],
              () => setState(() => _datingPreference = o['key']))),
          const SizedBox(height: 32),
          _stepHeader(tr('age_range')),
          const SizedBox(height: 16),
          RangeSlider(
            values: _ageRangePref,
            min: 18,
            max: 65,
            divisions: 47,
            labels: RangeLabels('${_ageRangePref.start.round()}',
                '${_ageRangePref.end.round()}'),
            onChanged: (v) => setState(() => _ageRangePref = v),
            activeColor: const Color(0xFFF4436C),
            inactiveColor:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          _continueButton(enabled: _datingPreference != null, onTap: _nextPage),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 11 – WHAT TO MEET
  // ══════════════════════════════════════════════════════
  Widget _buildPageWhatToMeet() {
    final opts = [
      {'key': 'male', 'label': tr('gender_male'), 'icon': Icons.male},
      {'key': 'female', 'label': tr('gender_female'), 'icon': Icons.female},
      {
        'key': 'non_binary',
        'label': tr('non_binary'),
        'icon': LucideIcons.userX
      },
    ];
    return _buildScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 24),
          _stepHeader(tr('what_to_meet_title')),
          const SizedBox(height: 36),
          ...opts.map((o) {
            final k = o['key'] as String;
            final sel = _wantToMeet.contains(k);
            return _optionPill(o['label'] as String, sel, () {
              setState(() {
                if (sel) {
                  _wantToMeet.remove(k);
                } else {
                  _wantToMeet.add(k);
                }
              });
            }, icon: o['icon'] as IconData);
          }),
          const SizedBox(height: 24),
          _continueButton(enabled: _wantToMeet.isNotEmpty, onTap: _nextPage),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE 18 – HOBBIES (Improved)
  // ══════════════════════════════════════════════════════
  Widget _buildPageHobbies() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Map<String, List<String>> cats = {
      'Active 🏋️': [
        'Fitnes',
        'Pilates',
        'Sprehodi',
        'Tek',
        'Smučanje',
        'Snowboarding',
        'Plezanje',
        'Plavanje'
      ],
      'Prosti čas ☕': [
        'Branje',
        'Kava',
        'Čaj',
        'Kuhanje',
        'Filmi',
        'Serije',
        'Videoigre',
        'Glasba'
      ],
      'Umetnost 🎨': [
        'Slikanje',
        'Fotografija',
        'Pisanje',
        'Muzeji',
        'Gledališče'
      ],
      'Potovanja ✈️': ['Roadtrips', 'Camping', 'City breaks', 'Backpacking'],
    };

    final predefinedHobbies = cats.values.expand((element) => element).toSet();
    final customHobbies =
        _selectedHobbies.where((h) => !predefinedHobbies.contains(h)).toList();

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _backButton(),
            const SizedBox(height: 16),
            _stepHeader(tr('hobbies'),
                subtitle:
                    '${_selectedHobbies.length} ${tr('hobbies_selected').replaceAll('{count}', '')}'),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (customHobbies.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(tr('my_hobbies_custom'),
                      style: GoogleFonts.instrumentSans(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: customHobbies.map((hobby) {
                    return FilterChip(
                      label: Text(
                        hobby,
                        style: GoogleFonts.instrumentSans(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: true,
                      onSelected: (_) =>
                          setState(() => _selectedHobbies.remove(hobby)),
                      selectedColor: const Color(0xFFF4436C),
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.05),
                      shape: StadiumBorder(
                        side: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : Colors.black.withValues(alpha: 0.1)),
                      ),
                      checkmarkColor: Colors.black,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              ...cats.entries.map((e) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    // Ta del zagotovi, da so vse animacije znotraj ExpansionTile gladke
                    expansionTileTheme: ExpansionTileThemeData(
                      iconColor: const Color(0xFFF4436C),
                      collapsedIconColor:
                          isDark ? Colors.white : Colors.black54,
                    ),
                  ),
                  child: ExpansionTile(
                    controller: _getHobbyTileController(e.key),
                    expansionAnimationStyle: AnimationStyle(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    ),
                    onExpansionChanged: (expanded) {
                      if (expanded) {
                        for (var key in cats.keys) {
                          if (key != e.key) {
                            _getHobbyTileController(key).collapse();
                          }
                        }
                      }
                    },
                    title: Text(
                        '${e.key} (${e.value.where((h) => _selectedHobbies.contains(h)).length})',
                        style: GoogleFonts.instrumentSans(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold)),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...e.value.map((hobby) {
                            final sel = _selectedHobbies.contains(hobby);
                            return FilterChip(
                              label: Text(
                                hobby,
                                style: GoogleFonts.instrumentSans(
                                  color: sel
                                      ? Colors.black
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                  fontWeight:
                                      sel ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              selected: sel,
                              onSelected: (s) => setState(() => s
                                  ? _selectedHobbies.add(hobby)
                                  : _selectedHobbies.remove(hobby)),
                              selectedColor: const Color(0xFFF4436C),
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white12
                                  : Colors.black12,
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: sel
                                      ? const Color(0xFFF4436C)
                                      : (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white24
                                          : Colors.black26),
                                ),
                              ),
                              checkmarkColor: Colors.black,
                            );
                          }),
                          ActionChip(
                            label: Text(tr('add_own'),
                                style: GoogleFonts.instrumentSans(
                                    color: Colors.black)),
                            backgroundColor: const Color(0xFFF4436C),
                            shape: const StadiumBorder(),
                            onPressed: () => _showAddHobbyDialog(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              }),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _continueButton(enabled: true, onTap: _nextPage),
        ),
      ]),
    );
  }

  void _showAddHobbyDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              title: Text(tr('add_hobby'),
                  style: GoogleFonts.instrumentSans(
                      color: isDark ? Colors.white : Colors.black)),
              content: TextField(
                  controller: ctrl,
                  style: GoogleFonts.instrumentSans(
                      color: isDark ? Colors.white : Colors.black),
                  autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(tr('cancel'))),
                TextButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        setState(() => _selectedHobbies.add(ctrl.text));
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(tr('add'),
                        style: GoogleFonts.instrumentSans(
                            color: const Color(0xFFF4436C)))),
              ],
            ));
  }

  // ══════════════════════════════════════════════════════
  // PAGE 13 – PHOTOS
  // ══════════════════════════════════════════════════════
  Widget _buildPagePhotos() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const _isDev =
        String.fromEnvironment('FLAVOR', defaultValue: 'dev') != 'prod';
    final hasAtLeastOne = _isDev || _photos.any((p) => p != null);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _backButton(),
          const SizedBox(height: 24),
          _stepHeader(tr('select_photo_title')),
          const SizedBox(height: 8),
          Text(tr('photos_hint'),
              style: GoogleFonts.instrumentSans(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 13)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: 6,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => _pickImage(i),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _photos[i] != null
                              ? const Color(0xFFF4436C)
                              : (isDark ? Colors.white24 : Colors.black12)),
                      image: _photos[i] != null
                          ? DecorationImage(
                              image: FileImage(_photos[i]!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _photos[i] == null
                        ? Center(
                            child: Icon(LucideIcons.plus,
                                color: isDark ? Colors.white38 : Colors.black26,
                                size: 28))
                        : null,
                  ),
                  if (i == 0)
                    Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.amber, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.star,
                              size: 10, color: Colors.black),
                        )),
                  if (_photos[i] != null)
                    Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos[i] = null),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.x,
                                size: 12, color: Colors.white),
                          ),
                        )),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _continueButton(enabled: hasAtLeastOne, onTap: _nextPage),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // PAGE — GDPR CONSENT
  // ══════════════════════════════════════════════════════
  Widget _buildPageConsent() {
    return _buildScrollableFormPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backButton(),
          const SizedBox(height: 24),
          _stepHeader(
            'Privacy and GDPR',
            subtitle: tr('consent_subtitle'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    final newVal = !_consentGiven;
                    _consentTerms = newVal;
                    _consentPrivacy = newVal;
                    _consentDataProcessing = newVal;
                    _consentLocation = newVal;
                  });
                },
                icon: Icon(
                  _consentGiven
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: const Color(0xFFF4436C),
                ),
                label: Text(
                  'Izberi Vse',
                  style: GoogleFonts.instrumentSans(
                    color: const Color(0xFFF4436C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _consentTile(
            value: _consentTerms,
            onChanged: (v) => setState(() => _consentTerms = v),
            richText: TextSpan(
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                  fontSize: 14,
                  height: 1.5),
              children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Terms of Service',
                        style: TextStyle(
                            color: Color(0xFFF4436C),
                            fontSize: 14,
                            decoration: TextDecoration.underline)),
                  ),
                ),
                const TextSpan(text: ' of Tremble.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentPrivacy,
            onChanged: (v) => setState(() => _consentPrivacy = v),
            richText: TextSpan(
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                  fontSize: 14,
                  height: 1.5),
              children: [
                const TextSpan(text: 'I have read and accept the '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Privacy Policy',
                        style: TextStyle(
                            color: Color(0xFFF4436C),
                            fontSize: 14,
                            decoration: TextDecoration.underline)),
                  ),
                ),
                const TextSpan(text: ', including GDPR data processing.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentDataProcessing,
            onChanged: (v) => setState(() => _consentDataProcessing = v),
            richText: TextSpan(
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                  fontSize: 14,
                  height: 1.5),
              children: const [
                TextSpan(
                    text:
                        'I explicitly consent to the processing of my sensitive personal data '
                        '(interests, preferences, religion, ethnicity) for the purpose of matchmaking. '
                        'I understand this data is encrypted, never sold, and I can withdraw consent '
                        'at any time from Settings.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _consentTile(
            value: _consentLocation,
            onChanged: (v) => setState(() => _consentLocation = v),
            richText: TextSpan(
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                  fontSize: 14,
                  height: 1.5),
              children: const [
                TextSpan(
                    text:
                        'I consent to live location tracking for the Radar feature. '
                        'Only an approximate grid position (~38m accuracy) is stored — '
                        'never my exact coordinates. Location data auto-deletes after 2 hours of inactivity. '
                        'I can disable Radar at any time from Settings.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : Colors.black12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    color: Color(0xFFF4436C), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your data is stored securely, never sold to third parties, '
                    'and can be exported or deleted at any time from Settings.',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black54,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _continueButton(
            enabled: _consentGiven,
            onTap: completeRegistration,
            label: 'Continue',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _consentTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required InlineSpan richText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const _brandRose = Color(0xFFF4436C);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? _brandRose : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: value
                      ? _brandRose
                      : (isDark ? Colors.white38 : Colors.black38),
                  width: 2),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.black, size: 16)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(text: richText),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // COMPLETE REGISTRATION
  // ══════════════════════════════════════════════════════
  void completeRegistration() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid =
        currentUser?.uid ?? 'generated_id'; // Fallback only if somehow null

    // Safety guard — consent page enforces all 4 checkboxes, but double-check
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please accept all consent checkboxes to continue.',
                style: GoogleFonts.instrumentSans())),
      );
      return;
    }
    final photoUrls =
        _photos.where((p) => p != null).map((p) => p!.path).toList();

    final datingMap = {
      'short_term_fun': 'Kratkoročna zabava',
      'long_term_partner': 'Dolgoročni partner',
      'short_open_long': 'Kratkoročno, odprto za dolgo',
      'long_open_short': 'Dolgoročno, odprto za kratko',
      'undecided': 'Neodločen',
    };

    final user = AuthUser(
      id: uid,
      name: _nameController.text,
      email: _emailController.text,
      // password removed — never stored in app state
      photoUrls: photoUrls,
      age: _birthDate != null ? _calcAge(_birthDate!) : 20,
      birthDate: _birthDate,
      height: _heightCm, // Included height in cm
      gender: _selectedGender ?? 'male',
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
      interestedIn: _wantToMeet.join(', '),
      isSmoker: _smokingHabit == 'yes',
      occupation: _status != null
          ? (_customOccupationController.text.isNotEmpty
              ? _customOccupationController.text
              : (_status == 'student' ? 'Študent' : 'Zaposlen'))
          : 'Študent', // Fallback
      drinkingHabit: _drinkingHabit ?? 'never',
      introvertScale: (_introversionLevel * 100).toInt(),
      exerciseHabit: _exerciseHabit ?? 'sometimes',
      sleepSchedule: 'Nočna ptica',
      petPreference: 'Dog person',
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
    );

    try {
      setState(() => _isRegistering = true);

      // Step 1: Firebase Auth user is ALREADY created on page 5 (_registerUser)
      // We skip register() here to avoid 'email-already-in-use' exception.

      // Step 2: Save profile via Cloud Function.
      // In debug mode, API failures are bypassed inside the notifier and
      // isOnboarded is still set to true locally.
      await ref.read(authStateProvider.notifier).completeOnboarding(user);

      if (mounted) context.go('/');
    } catch (e) {
      if (kDebugMode) {
        // Dev mode: show error but force local state and navigate through.
        debugPrint('[DEV] Registration error (bypassed): $e');
        ref.read(authStateProvider.notifier).setUser(
              user.copyWith(isOnboarded: true),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('[DEV] Error bypassed: $e',
                  style: GoogleFonts.instrumentSans()),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 5),
            ),
          );
          context.go('/');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e')),
          );
        }
      }
    }
  }
}
