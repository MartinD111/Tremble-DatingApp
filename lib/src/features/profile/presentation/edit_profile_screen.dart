import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../settings/presentation/widgets/preference_edit_modal.dart';
import '../../settings/presentation/widgets/preference_pill_row.dart';
import '../../auth/presentation/widgets/registration_steps/hobbies_step.dart';
import '../../auth/presentation/widgets/registration_steps/step_shared.dart'
    show DrumPicker;
import '../../../shared/ui/top_notification.dart';
import '../../../shared/ui/discard_changes_modal.dart';
import '../../../core/upload_service.dart';
import '../../../core/utils/icon_utils.dart';
import '../../../core/theme.dart';

import '../../../shared/ui/tremble_circle_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _hasChanges = false;
  double _distancePreference = 50.0;
  bool _isPremium = false;
  bool _isUploading = false;

  List<String> _photoUrls = [];
  final ValueNotifier<double> _buttonsOpacity = ValueNotifier(1.0);
  String? _gender;
  List<String> _interestedIn = [];
  String? _jobStatus;
  String? _religion;
  String? _hairColor;
  String? _ethnicity;
  String? _occupation;
  final _occupationController = TextEditingController();
  bool? _isSmoker;
  String? _drinkingHabit;
  String? _exerciseHabit;
  String? _sleepSchedule;
  String? _petPreference;
  String? _childrenPreference;
  double _introversionLevel = 0.5;
  final _schoolController = TextEditingController();
  final _companyController = TextEditingController();
  bool? _hasChildren;
  List<String> _hobbies = [];
  List<String> _lookingFor = [];
  List<String> _languages = [];
  double _politicalAffiliationValue = 3.0; // 1-5 spectrum left→right
  DateTime? _birthDate;
  double _lastScrollOffset = 0;

  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider);
    if (user != null) {
      _lang = user.appLanguage;
      _nameController.text = user.name ?? '';
      _locationController.text = user.location ?? '';
      _photoUrls = List.from(user.photoUrls);
      _gender = _normalizeLegacyValue(user.gender, {
        'Moški': 'male',
        'Ženska': 'female',
      });
      _interestedIn = List.from(user.interestedIn);
      _jobStatus = _normalizeLegacyValue(user.jobStatus, {
        'Študent': 'student',
        'Študent/-ka': 'student',
        'Zaposlen': 'employed',
        'Zaposlen/-a': 'employed',
      });
      _religion = _normalizeLegacyValue(user.religion, {
        'Krščanstvo': 'christianity',
        'Islam': 'islam',
        'Hinduizem': 'hinduism',
        'Budizem': 'buddhism',
        'Judaizem': 'judaism',
        'Agnostik': 'agnostic',
        'Ateist': 'atheist',
      });
      _hairColor = _normalizeLegacyValue(user.hairColor, {
        'Blond': 'hair_blonde',
        'Rjavi': 'hair_brunette',
        'Črni': 'hair_black',
        'Rdeči': 'hair_red',
        'Sivi/Beli': 'hair_gray_white',
        'Drugo': 'hair_other',
      });
      _ethnicity = _normalizeLegacyValue(user.ethnicity, {
        'Bela': 'ethnicity_white',
        'Črna': 'ethnicity_black',
        'Mešana': 'ethnicity_mixed',
        'Azijska': 'ethnicity_asian',
      });
      _isSmoker = user.isSmoker;
      _occupation = user.occupation;
      _occupationController.text = user.occupation ?? '';
      _schoolController.text = user.school ?? '';
      _companyController.text = user.company ?? '';
      _hasChildren = user.hasChildren;

      // Backward compatibility: if jobStatus is missing, infer it from occupation
      if (_jobStatus == null && _occupation != null) {
        if (_occupation == 'Študent' || _occupation == 'Student') {
          _jobStatus = 'student';
          _occupation = null;
          _occupationController.text = '';
        } else if (_occupation == 'Zaposlen' || _occupation == 'Employed') {
          _jobStatus = 'employed';
          _occupation = null;
          _occupationController.text = '';
        }
      }

      _drinkingHabit = _normalizeLegacyValue(user.drinkingHabit, {
        'Nikoli': 'never',
        'Družabno': 'socially',
        'Ob priliki': 'occasionally',
      });
      _exerciseHabit = _normalizeLegacyValue(user.exerciseHabit, {
        'Aktivno': 'active',
        'Včasih': 'sometimes',
        'Skoraj nikoli': 'almost_never',
      });
      _sleepSchedule = _normalizeLegacyValue(user.sleepSchedule, {
        'Nočna ptica': 'night_owl',
        'Jutranja ptica': 'early_bird',
      });
      _petPreference = _normalizeLegacyValue(user.petPreference, {
        'Pes dog person 🐶': 'dog',
        'Mačka cat person 🐱': 'cat',
        'Nekaj drugega': 'something_else',
        'Nič': 'nothing',
      });
      _childrenPreference = _normalizeLegacyValue(user.childrenPreference, {
        'Nekoč ja': 'want_someday',
        'Ne želim': 'dont_want',
        'Imam in bi rad/-a še': 'have_and_want_more',
        'Imam, ne bi več': 'have_and_dont_want_more',
        'Še nisem odločen/-a': 'not_sure',
      });
      _lookingFor = user.lookingFor
          .map((e) => _normalizeLegacyValue(e, {
                'Kratkoročna zabava': 'short_term_fun',
                'Dolgoročni partner': 'long_term_partner',
                'Kratkotrajno, odprto za dolgo': 'short_open_long',
                'Dolgoročno, odprto za kratko': 'long_open_short',
                'Neodločen/-a': 'undecided',
              }))
          .whereType<String>()
          .toList();

      // Registration saves 0-100 (int); legacy edit profile saved 1-5.
      final rawIntrovert = user.introvertScale ?? 50;
      _introversionLevel = rawIntrovert > 5
          ? (rawIntrovert / 100.0).clamp(0.0, 1.0)
          : ((rawIntrovert - 1) / 4.0).clamp(0.0, 1.0);
      _hobbies = user.hobbies
          .map((h) => _normalizeLegacyValue(h, {
                'Fitnes': 'hobby_fitness',
                'Pilates': 'hobby_pilates',
                'Sprehodi': 'hobby_walking',
                'Tek': 'hobby_running',
                'Smučanje': 'hobby_skiing',
                'Snowboarding': 'hobby_snowboarding',
                'Plezanje': 'hobby_climbing',
                'Plavanje': 'hobby_swimming',
                'Branje': 'hobby_reading',
                'Kava': 'hobby_coffee',
                'Čaj': 'hobby_tea',
                'Kuhanje': 'hobby_cooking',
                'Filmi': 'hobby_movies',
                'Serije': 'hobby_series',
                'Videoigre': 'hobby_video_games',
                'Glasba': 'hobby_music',
                'Slikanje': 'hobby_painting',
                'Fotografija': 'hobby_photography',
                'Pisanje': 'hobby_writing',
                'Muzeji': 'hobby_museums',
                'Gledališče': 'hobby_theater',
                'Izleti': 'hobby_trips',
                'Narava': 'hobby_nature',
                'Gore': 'hobby_mountains',
                'Morje': 'hobby_sea',
                'Mestna potepanja': 'hobby_city_walks',
                'Kampiranje': 'hobby_camping',
              }))
          .whereType<String>()
          .toList();
      _languages = List.from(user.languages);
      _distancePreference = user.maxDistance.toDouble();
      _isPremium = user.isPremium;
      _birthDate = user.birthDate;

      // Political affiliation mapping: String -> Double
      final polString = user.politicalAffiliation;
      if (polString == 'politics_left')
        _politicalAffiliationValue = 1.0;
      else if (polString == 'politics_center_left')
        _politicalAffiliationValue = 2.0;
      else if (polString == 'politics_center')
        _politicalAffiliationValue = 3.0;
      else if (polString == 'politics_center_right')
        _politicalAffiliationValue = 4.0;
      else if (polString == 'politics_right')
        _politicalAffiliationValue = 5.0;
      else if (polString == 'politics_dont_care')
        _politicalAffiliationValue = 0.0;
      else if (polString == 'politics_undisclosed')
        _politicalAffiliationValue = -1.0;
      else
        _politicalAffiliationValue = 3.0; // Default to center
    }
    _nameController.addListener(_markChanged);
    _locationController.addListener(_markChanged);
    _occupationController.addListener(_markChanged);
    _schoolController.addListener(_markChanged);
    _companyController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _schoolController.dispose();
    _companyController.dispose();
    _buttonsOpacity.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    final offset = notification.metrics.pixels;
    final delta = offset - _lastScrollOffset;

    if (offset <= 0) {
      _buttonsOpacity.value = 1.0;
    } else if (delta > 2) {
      // Scrolling down -> fade out
      _buttonsOpacity.value = 0.0;
    } else if (delta < -2) {
      // Scrolling up -> fade in
      _buttonsOpacity.value = 1.0;
    }

    _lastScrollOffset = offset;
    return false;
  }

  String _formatValue(String? raw, String lang) {
    if (raw == null) return '';
    // Check if the raw value is a legacy Slovenian string
    final normalized = _normalizeLegacyValue(raw, {
      'Moški': 'male',
      'Ženska': 'female',
      'Nikoli': 'never',
      'Družabno': 'socially',
      'Ob priliki': 'occasionally',
      'Aktivno': 'active',
      'Včasih': 'sometimes',
      'Skoraj nikoli': 'almost_never',
      'Nočna ptica': 'night_owl',
      'Jutranja ptica': 'early_bird',
      'Kratkotrajna zabava': 'short_term_fun',
      'Dolgoročni partner': 'long_term_partner',
      'Kratkotrajno, odprto za dolgo': 'short_open_long',
      'Dolgoročno, odprto za kratko': 'long_open_short',
      'Neodločen/-a': 'undecided',
      'Pes dog person 🐶': 'dog',
      'Mačka cat person 🐱': 'cat',
      'Nekoč ja': 'want_someday',
      'Ne želim': 'dont_want',
      'Imam in bi rad/-a še': 'have_and_want_more',
      'Imam, ne bi več': 'have_and_dont_want_more',
      'Še nisem odločen/-a': 'not_sure',
      // Religion
      'Krščanstvo': 'christianity',
      'Islam': 'islam',
      'Hinduizem': 'hinduism',
      'Budizem': 'buddhism',
      'Judaizem': 'judaism',
      'Agnostik': 'agnostic',
      'Ateist': 'atheist',
      // Ethnicity
      'Bela': 'ethnicity_white',
      'Črna': 'ethnicity_black',
      'Mešana': 'ethnicity_mixed',
      'Azijska': 'ethnicity_asian',
      // Hair
      'Blond': 'hair_blonde',
      'Rjavi': 'hair_brunette',
      'Črni': 'hair_black',
      'Rdeči': 'hair_red',
      'Sivi/Beli': 'hair_gray_white',
      'Drugo': 'hair_other',
      // Other
      'Nekaj drugega': 'something_else',
      'Nič': 'nothing',
    });

    if (normalized == null) return '';
    final translated = t(normalized, lang);
    if (translated != normalized) return _titleCase(translated);
    return _titleCase(normalized.replaceAll('_', ' '));
  }

  String? _normalizeLegacyValue(String? value, Map<String, String> mapping) {
    if (value == null || value.isEmpty) return null;
    return mapping[value] ?? value;
  }

  String _formatHobby(String hobby, String lang) {
    // If it's already a key (starts with hobby_), translate it
    if (hobby.startsWith('hobby_')) {
      final translated = t(hobby, lang);
      return translated == hobby
          ? _titleCase(hobby.replaceAll('hobby_', '').replaceAll('_', ' '))
          : translated;
    }

    // Otherwise, it might be a legacy Slovenian string
    final mapping = {
      'Fitnes': 'hobby_fitness',
      'Pilates': 'hobby_pilates',
      'Sprehodi': 'hobby_walking',
      'Tek': 'hobby_running',
      'Smučanje': 'hobby_skiing',
      'Snowboarding': 'hobby_snowboarding',
      'Plezanje': 'hobby_climbing',
      'Plavanje': 'hobby_swimming',
      'Branje': 'hobby_reading',
      'Kava': 'hobby_coffee',
      'Čaj': 'hobby_tea',
      'Kuhanje': 'hobby_cooking',
      'Filmi': 'hobby_movies',
      'Serije': 'hobby_series',
      'Videoigre': 'hobby_video_games',
      'Glasba': 'hobby_music',
      'Slikanje': 'hobby_painting',
      'Fotografija': 'hobby_photography',
      'Pisanje': 'hobby_writing',
      'Muzeji': 'hobby_museums',
      'Gledališče': 'hobby_theater',
      'Izleti': 'hobby_trips',
      'Narava': 'hobby_nature',
      'Gore': 'hobby_mountains',
      'Morje': 'hobby_sea',
      'Mestna potepanja': 'hobby_city_walks',
      'Kampiranje': 'hobby_camping',
    };

    final key = mapping[hobby];
    if (key != null) {
      return t(key, lang);
    }

    // Fallback for custom hobbies
    return hobby;
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    String saveText = t('save_changes', _lang);

    // Default translation value fallback
    String discardTitle = t('discard_unsaved_changes', _lang);
    if (discardTitle.isEmpty || discardTitle == 'discard_unsaved_changes')
      discardTitle = 'Discard unsaved changes';

    if (saveText.isEmpty || saveText == 'save_changes') {
      saveText = 'Save changes';
    }

    final res = await showDiscardChangesModal(context, ref);

    if (res == 'save') {
      _saveChanges();
      return false; // _saveChanges will pop the screen
    } else if (res == 'discard') {
      return true;
    }
    return false;
  }

  void _saveChanges() {
    final user = ref.read(authStateProvider);
    if (user == null) return;
    ref.read(authStateProvider.notifier).updateProfile(user.copyWith(
          name: _nameController.text,
          location: _locationController.text,
          photoUrls: _photoUrls,
          gender: _gender,
          interestedIn: _interestedIn,
          jobStatus: _jobStatus,
          religion: _religion,
          hairColor: _hairColor,
          ethnicity: _ethnicity,
          occupation: _occupationController.text.isNotEmpty
              ? _occupationController.text
              : null,
          school:
              _schoolController.text.isNotEmpty ? _schoolController.text : null,
          company: _companyController.text.isNotEmpty
              ? _companyController.text
              : null,
          hasChildren: _hasChildren,
          isSmoker: _isSmoker,
          drinkingHabit: _drinkingHabit,
          exerciseHabit: _exerciseHabit,
          sleepSchedule: _sleepSchedule,
          petPreference: _petPreference,
          childrenPreference: _childrenPreference,
          introvertScale: (_introversionLevel * 100).round(),
          hobbies: _hobbies,
          lookingFor: _lookingFor,
          languages: _languages,
          birthDate: _birthDate,
          age: _birthDate != null ? ZodiacUtils.calcAge(_birthDate!) : user.age,
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
          maxDistance: _distancePreference.round(),
        ));
    TopNotification.show(
      context: context,
      message: t('profile_updated', _lang),
      icon: LucideIcons.checkCircle,
    );
    setState(() => _hasChanges = false);
    context.pop();
  }

  Future<void> _pickImage() async {
    if (_isUploading) return;

    final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _isUploading = true);

      try {
        final publicUrl = await ref
            .read(uploadServiceProvider)
            .uploadPhotoFromPath(picked.path);
        setState(() {
          _photoUrls.add(publicUrl);
          _isUploading = false;
          _hasChanges = true;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t('upload_failed', _lang)}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
      _hasChanges = true;
    });
  }

  /// Opens the full hobbies selector as a bottom sheet — identical to the
  /// registration flow. Changes are committed only when the user taps Continue.
  void _showHobbiesModal() {
    final tempHobbies = List<String>.from(_hobbies);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            builder: (context, scrollController) => HobbiesStep(
              isModal: true,
              selectedHobbies: tempHobbies,
              onAddHobby: (h) => setModalState(() => tempHobbies.add(h)),
              onRemoveHobby: (h) => setModalState(() => tempHobbies.remove(h)),
              onBack: () => Navigator.pop(ctx),
              onContinue: () {
                setState(() {
                  _hobbies = List.from(tempHobbies);
                  _hasChanges = true;
                });
                Navigator.pop(ctx);
              },
              tr: (key) => t(key, _lang),
            ),
          ),
        );
      },
    );
  }

  void _showDistanceHelp(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(LucideIcons.mapPin, color: primaryColor, size: 20),
            const SizedBox(width: 10),
            Text(t('distance', _lang),
                style: GoogleFonts.instrumentSans(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
        content: Text(
          t('distance_help', _lang),
          style: GoogleFonts.lora(
              color: colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: GoogleFonts.instrumentSans(
                    color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final iconColor = isDark ? Colors.white70 : Colors.black45;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final brandRose = Theme.of(context).primaryColor;
    final lang = _lang;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) context.pop();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: GradientScaffold(
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24,
                            MediaQuery.of(context).padding.top + 25, 24, 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                t('edit_profile', lang),
                                style: TrembleTheme.displayFont(
                                  color: textColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Photos ────────────────────────────────────────────
                            _sectionLabel(t('photos', lang), LucideIcons.camera,
                                textColor, iconColor),
                            const SizedBox(height: 10),
                            _buildPhotoGrid(isDark, textColor, borderColor),
                            const SizedBox(height: 24),

                            // ── Name ──────────────────────────────────────────────
                            _sectionLabel(t('name', lang), LucideIcons.user,
                                textColor, iconColor),
                            const SizedBox(height: 8),
                            _buildTextField(_nameController, t('name', lang),
                                textColor, fillColor),
                            const SizedBox(height: 24),

                            // ── Location ──────────────────────────────────────────
                            _sectionLabel(t('location', lang),
                                LucideIcons.mapPin, textColor, iconColor),
                            const SizedBox(height: 8),
                            _buildLocationField(
                                lang, textColor, fillColor, iconColor, isDark),
                            const SizedBox(height: 12),
                            // ── Age / Birth Date ───────────────────────────────────
                            GestureDetector(
                              onTap: _showAgePickerModal,
                              child: Row(
                                children: [
                                  if (_birthDate != null) ...[
                                    _AgePill(
                                      '${ZodiacUtils.calcAge(_birthDate!)}',
                                      icon: LucideIcons.cake,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(width: 8),
                                    _AgePill(
                                      t('zodiac_${ZodiacUtils.getZodiacSign(_birthDate!)}',
                                          lang),
                                      icon: ZodiacUtils.getZodiacIcon(
                                        ZodiacUtils.getZodiacSign(_birthDate!),
                                      ),
                                      isDark: isDark,
                                    ),
                                  ] else
                                    _AgePill(
                                      t('set_birthday', lang).isNotEmpty &&
                                              t('set_birthday', lang) !=
                                                  'set_birthday'
                                          ? t('set_birthday', lang)
                                          : 'Set birthday',
                                      icon: LucideIcons.calendar,
                                      isDark: isDark,
                                    ),
                                  const SizedBox(width: 8),
                                  Icon(LucideIcons.pencil,
                                      color: iconColor, size: 14),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Gender ────────────────────────────────────────────
                            _sectionLabel(t('gender', lang), LucideIcons.users,
                                textColor, iconColor),
                            const SizedBox(height: 8),
                            _buildGenderChips(lang, isDark, textColor),
                            const SizedBox(height: 24),

                            // ── Interested In ──────────────────────────────────────
                            _sectionLabel(t('want_to_meet', lang),
                                LucideIcons.heart, textColor, iconColor),
                            const SizedBox(height: 8),
                            _buildInterestChips(lang, isDark, textColor),
                            const SizedBox(height: 24),

                            // ── Status ────────────────────────────────────────────
                            _sectionLabel(t('status', lang),
                                LucideIcons.briefcase, textColor, iconColor),
                            const SizedBox(height: 8),
                            _buildOccupationChips(lang, isDark, textColor),
                            if (_jobStatus != null) ...[
                              const SizedBox(height: 12),
                              _buildTextField(
                                _occupationController,
                                t(
                                    _jobStatus == 'student'
                                        ? 'course_of_study'
                                        : 'job_title',
                                    lang),
                                textColor,
                                fillColor,
                              ),
                            ],
                            const SizedBox(height: 16),
                            // ── Details ───────────────────────────────────────────
                            PreferencePillRow(
                              icon: LucideIcons.book,
                              label: t('religion', lang),
                              values: [_religion],
                              formatter: (v) => _formatValue(v, lang),
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('religion', lang),
                                rowIcon: LucideIcons.book,
                                options: [
                                  {
                                    'label': t('christianity', lang),
                                    'value': 'christianity',
                                    'icon': IconUtils.getReligionIcon(
                                        'christianity')
                                  },
                                  {
                                    'label': t('islam', lang),
                                    'value': 'islam',
                                    'icon': IconUtils.getReligionIcon('islam')
                                  },
                                  {
                                    'label': t('hinduism', lang),
                                    'value': 'hinduism',
                                    'icon':
                                        IconUtils.getReligionIcon('hinduism')
                                  },
                                  {
                                    'label': t('buddhism', lang),
                                    'value': 'buddhism',
                                    'icon':
                                        IconUtils.getReligionIcon('buddhism')
                                  },
                                  {
                                    'label': t('judaism', lang),
                                    'value': 'judaism',
                                    'icon': IconUtils.getReligionIcon('judaism')
                                  },
                                  {
                                    'label': t('agnostic', lang),
                                    'value': 'agnostic',
                                    'icon':
                                        IconUtils.getReligionIcon('agnostic')
                                  },
                                  {
                                    'label': t('atheist', lang),
                                    'value': 'atheist',
                                    'icon': IconUtils.getReligionIcon('atheist')
                                  },
                                ],
                                currentValue: _religion,
                                onUpdate: (v) => setState(() {
                                  _religion = v;
                                  _hasChanges = true;
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),

                            PreferencePillRow(
                              icon: LucideIcons.user,
                              label: t('ethnicity', lang),
                              values: [_ethnicity],
                              formatter: (v) => _formatValue(v, lang),
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('ethnicity', lang),
                                rowIcon: LucideIcons.user,
                                options: [
                                  {
                                    'label': t('ethnicity_white', lang),
                                    'value': 'ethnicity_white'
                                  },
                                  {
                                    'label': t('ethnicity_black', lang),
                                    'value': 'ethnicity_black'
                                  },
                                  {
                                    'label': t('ethnicity_mixed', lang),
                                    'value': 'ethnicity_mixed'
                                  },
                                  {
                                    'label': t('ethnicity_asian', lang),
                                    'value': 'ethnicity_asian'
                                  },
                                ],
                                currentValue: _ethnicity,
                                onUpdate: (v) => setState(() {
                                  _ethnicity = v;
                                  _hasChanges = true;
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),

                            PreferencePillRow(
                              icon: LucideIcons.scissors,
                              label: t('hair_color', lang),
                              values: [_hairColor],
                              formatter: (v) => _formatValue(v, lang),
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('hair_color', lang),
                                rowIcon: LucideIcons.scissors,
                                options: [
                                  {
                                    'label': t('hair_blonde', lang),
                                    'value': 'hair_blonde',
                                    'icon': Icons.circle,
                                    'iconColor':
                                        IconUtils.getHairColor('hair_blonde')
                                  },
                                  {
                                    'label': t('hair_brunette', lang),
                                    'value': 'hair_brunette',
                                    'icon': Icons.circle,
                                    'iconColor':
                                        IconUtils.getHairColor('hair_brunette')
                                  },
                                  {
                                    'label': t('hair_black', lang),
                                    'value': 'hair_black',
                                    'icon': Icons.circle,
                                    'iconColor':
                                        IconUtils.getHairColor('hair_black')
                                  },
                                  {
                                    'label': t('hair_red', lang),
                                    'value': 'hair_red',
                                    'icon': Icons.circle,
                                    'iconColor':
                                        IconUtils.getHairColor('hair_red')
                                  },
                                  {
                                    'label': t('hair_gray_white', lang),
                                    'value': 'hair_gray_white',
                                    'icon': Icons.circle,
                                    'iconColor': IconUtils.getHairColor(
                                        'hair_gray_white')
                                  },
                                  {
                                    'label': t('hair_other', lang),
                                    'value': 'hair_other',
                                    'icon': Icons.circle,
                                    'iconColor':
                                        IconUtils.getHairColor('hair_other')
                                  },
                                ],
                                currentValue: _hairColor,
                                onUpdate: (v) => setState(() {
                                  _hairColor = v;
                                  _hasChanges = true;
                                }),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Smoker & Children ─────────────────────────────────
                            _buildSmokerSwitch(lang, isDark, textColor),
                            _buildChildrenSwitch(lang, isDark, textColor),

                            Divider(color: borderColor, height: 24),

                            // ── Lifestyle Header (Centered, no icon) ──────────────
                            Center(
                              child: Text(
                                t('lifestyle', lang),
                                style: GoogleFonts.instrumentSans(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Lifestyle: pill rows + modals ─────────────────────
                            PreferencePillRow(
                              icon: LucideIcons.zap,
                              label: t('exercise', lang),
                              values: [_exerciseHabit],
                              formatter: (v) => _formatValue(v, lang),
                              iconMapper: IconUtils.getLifestyleIcon,
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('exercise', lang),
                                rowIcon: LucideIcons.zap,
                                options: [
                                  {
                                    'label': t('exercise_active', lang),
                                    'value': 'active',
                                    'icon': LucideIcons.zap,
                                  },
                                  {
                                    'label': t('exercise_sometimes', lang),
                                    'value': 'sometimes',
                                    'icon': LucideIcons.activity,
                                  },
                                  {
                                    'label': t('almost_never', lang),
                                    'value': 'almost_never',
                                    'icon': LucideIcons.moon,
                                  },
                                ],
                                currentValue: _exerciseHabit,
                                onUpdate: (val) => setState(() {
                                  _exerciseHabit = val;
                                  _hasChanges = true;
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),

                            PreferencePillRow(
                              icon: LucideIcons.wine,
                              label: t('alcohol', lang),
                              values: [_drinkingHabit],
                              formatter: (v) => _formatValue(v, lang),
                              iconMapper: IconUtils.getLifestyleIcon,
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('alcohol', lang),
                                rowIcon: LucideIcons.wine,
                                options: [
                                  {
                                    'label': t('drink_never', lang),
                                    'value': 'never',
                                    'icon': LucideIcons.ban,
                                  },
                                  {
                                    'label': t('drink_socially', lang),
                                    'value': 'socially',
                                    'icon': LucideIcons.users,
                                  },
                                  {
                                    'label': t('drink_frequently', lang),
                                    'value': 'frequently',
                                    'icon': LucideIcons.trendingUp,
                                  },
                                ],
                                currentValue: _drinkingHabit,
                                onUpdate: (val) => setState(() {
                                  _drinkingHabit = val;
                                  _hasChanges = true;
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),

                            PreferencePillRow(
                              icon: LucideIcons.moon,
                              label: t('sleep', lang),
                              values: [_sleepSchedule],
                              formatter: (v) => _formatValue(v, lang),
                              iconMapper: IconUtils.getLifestyleIcon,
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('sleep', lang),
                                rowIcon: LucideIcons.moon,
                                options: [
                                  {
                                    'label': t('night_owl', lang),
                                    'value': 'night_owl',
                                    'icon': LucideIcons.moon,
                                  },
                                  {
                                    'label': t('early_bird', lang),
                                    'value': 'early_bird',
                                    'icon': LucideIcons.sun,
                                  },
                                ],
                                currentValue: _sleepSchedule,
                                onUpdate: (val) => setState(() {
                                  _sleepSchedule = val;
                                  _hasChanges = true;
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),

                            PreferencePillRow(
                              icon: _petPreference == 'cat'
                                  ? LucideIcons.cat
                                  : LucideIcons.dog,
                              label: t('pets', lang),
                              values: [_petPreference],
                              formatter: (v) => _formatValue(v, lang),
                              iconMapper: IconUtils.getLifestyleIcon,
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('pets', lang),
                                rowIcon: LucideIcons.dog,
                                options: [
                                  {
                                    'label': t('dog_person', lang),
                                    'value': 'dog',
                                    'icon': LucideIcons.dog
                                  },
                                  {
                                    'label': t('cat_person', lang),
                                    'value': 'cat',
                                    'icon': LucideIcons.cat
                                  },
                                ],
                                currentValue: _petPreference,
                                onUpdate: (val) => setState(() {
                                  _petPreference = val;
                                  _hasChanges = true;
                                }),
                                allowOther: true,
                              ),
                            ),
                            const SizedBox(height: 12),

                            PreferencePillRow(
                              icon: LucideIcons.baby,
                              label: t('children', lang),
                              values: [_childrenPreference],
                              formatter: (v) => _formatValue(v, lang),
                              iconMapper: IconUtils.getLifestyleIcon,
                              onEdit: () => showPreferenceEditModal(
                                context: context,
                                title: t('children', lang),
                                rowIcon: LucideIcons.baby,
                                options: [
                                  {
                                    'label': t('children_want_someday', lang),
                                    'value': 'want_someday',
                                    'icon': LucideIcons.heart,
                                  },
                                  {
                                    'label': t('children_dont_want', lang),
                                    'value': 'dont_want',
                                    'icon': LucideIcons.ban,
                                  },
                                  {
                                    'label':
                                        t('children_have_and_want_more', lang),
                                    'value': 'have_and_want_more',
                                    'icon': LucideIcons.users,
                                  },
                                  {
                                    'label': t(
                                        'children_have_and_dont_want_more',
                                        lang),
                                    'value': 'have_and_dont_want_more',
                                    'icon': LucideIcons.userCheck,
                                  },
                                  {
                                    'label': t('children_not_sure', lang),
                                    'value': 'not_sure',
                                    'icon': LucideIcons.helpCircle,
                                  },
                                ],
                                currentValue: _childrenPreference,
                                onUpdate: (val) => setState(() {
                                  _childrenPreference = val;
                                  _hasChanges = true;
                                }),
                              ),
                            ),

                            Divider(color: borderColor, height: 28),

                            // ── Introvert / Extrovert ─────────────────────────────
                            Center(
                              child: _sectionLabel(
                                  t('introvert_extrovert', lang),
                                  LucideIcons.brain,
                                  textColor,
                                  iconColor,
                                  centered: true),
                            ),
                            const SizedBox(height: 12),
                            _buildIntrovertSlider(lang, isDark, subColor),
                            const SizedBox(height: 20),
                            _sectionLabel(t('political_affiliation', lang),
                                LucideIcons.flag, textColor, iconColor,
                                centered: true),
                            const SizedBox(height: 8),
                            _buildPoliticalSlider(lang, isDark, subColor),
                            const SizedBox(height: 32),

                            // ── Distance ──────────────────────────────────────────
                            Center(
                              child: _sectionLabel(t('distance', lang),
                                  LucideIcons.map, textColor, iconColor,
                                  centered: true,
                                  onHelp: () => _showDistanceHelp(context)),
                            ),
                            const SizedBox(height: 12),
                            _buildDistanceSlider(lang, isDark, subColor),

                            Divider(color: borderColor, height: 28),

                            // ── Looking for ───────────────────────────────────────
                            Row(
                              children: [
                                Icon(LucideIcons.heart,
                                    size: 18, color: iconColor),
                                const SizedBox(width: 10),
                                Text(t('looking_for', lang),
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                _multiPill(_lookingFor, lang, isDark, subColor,
                                    iconMapper: IconUtils.getLookingForIcon),
                                const SizedBox(width: 8),
                                _editCircle(isDark, borderColor, fillColor,
                                    onTap: () => showMultiSelectModal(
                                          context: context,
                                          title: t('looking_for', lang),
                                          options: [
                                            {
                                              'label':
                                                  t('short_term_fun', lang),
                                              'value': 'short_term_fun',
                                              'icon':
                                                  IconUtils.getLookingForIcon(
                                                      'short_term_fun'),
                                            },
                                            {
                                              'label':
                                                  t('long_term_partner', lang),
                                              'value': 'long_term_partner',
                                              'icon':
                                                  IconUtils.getLookingForIcon(
                                                      'long_term_partner'),
                                            },
                                            {
                                              'label':
                                                  t('short_open_long', lang),
                                              'value': 'short_open_long',
                                              'icon':
                                                  IconUtils.getLookingForIcon(
                                                      'short_open_long'),
                                            },
                                            {
                                              'label':
                                                  t('long_open_short', lang),
                                              'value': 'long_open_short',
                                              'icon':
                                                  IconUtils.getLookingForIcon(
                                                      'long_open_short'),
                                            },
                                            {
                                              'label': t('undecided', lang),
                                              'value': 'undecided',
                                              'icon':
                                                  IconUtils.getLookingForIcon(
                                                      'undecided'),
                                            },
                                          ],
                                          currentValues: _lookingFor,
                                          onSave: (vals) => setState(() {
                                            _lookingFor = vals;
                                            _hasChanges = true;
                                          }),
                                        )),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Languages ─────────────────────────────────────────
                            Row(
                              children: [
                                Icon(LucideIcons.languages,
                                    size: 18, color: iconColor),
                                const SizedBox(width: 10),
                                Text(t('i_speak', lang),
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                const Spacer(),
                                _multiPill(_languages, lang, isDark, subColor),
                                const SizedBox(width: 8),
                                _editCircle(isDark, borderColor, fillColor,
                                    onTap: () => showMultiSelectModal(
                                          context: context,
                                          title: t('i_speak', lang),
                                          options: [
                                            {
                                              'label':
                                                  t('lang_slovenian', lang),
                                              'value': 'Slovenščina'
                                            },
                                            {
                                              'label': t('lang_english', lang),
                                              'value': 'Angleščina'
                                            },
                                            {
                                              'label': t('lang_german', lang),
                                              'value': 'Nemščina'
                                            },
                                            {
                                              'label': t('lang_italian', lang),
                                              'value': 'Italijanščina'
                                            },
                                            {
                                              'label': t('lang_french', lang),
                                              'value': 'Francoščina'
                                            },
                                            {
                                              'label': t('lang_spanish', lang),
                                              'value': 'Španščina'
                                            },
                                            {
                                              'label': t('lang_croatian', lang),
                                              'value': 'Hrvaščina'
                                            },
                                            {
                                              'label': t('lang_serbian', lang),
                                              'value': 'Srbščina'
                                            },
                                            {
                                              'label':
                                                  t('lang_hungarian', lang),
                                              'value': 'Madžarščina'
                                            },
                                          ],
                                          currentValues: _languages,
                                          onSave: (vals) => setState(() {
                                            _languages = vals.length <= 5
                                                ? vals
                                                : vals.sublist(0, 5);
                                            _hasChanges = true;
                                          }),
                                        )),
                              ],
                            ),

                            Divider(color: borderColor, height: 28),

                            // ── Hobbies ───────────────────────────────────────────
                            Center(
                              child: Text(
                                t('hobbies', lang),
                                style: GoogleFonts.instrumentSans(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCategorizedHobbies(lang, isDark, textColor,
                                fillColor, borderColor),
                            const SizedBox(height: 16),
                            Center(
                              child: _editCircle(isDark, borderColor, fillColor,
                                  onTap: _showHobbiesModal),
                            ),

                            const SizedBox(height: 30),

                            // ── Save button ───────────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _hasChanges ? _saveChanges : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _hasChanges ? brandRose : fillColor,
                                  foregroundColor:
                                      _hasChanges ? Colors.white : subColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text(t('save_changes', lang),
                                    style: GoogleFonts.instrumentSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _buttonsOpacity,
                builder: (context, opacity, child) {
                  return TrembleHeader(
                    title: '', // Title is in scrollable content
                    titleOpacity: 0.0,
                    buttonsOpacity: opacity,
                    onBack: () async {
                      if (_hasChanges) {
                        final should = await _onWillPop();
                        if (should && context.mounted) context.pop();
                      } else {
                        context.pop();
                      }
                    },
                    actions: [
                      if (_hasChanges)
                        TrembleCircleButton(
                          icon: LucideIcons.check,
                          color: brandRose,
                          onPressed: _saveChanges,
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _sectionLabel(
      String label, IconData icon, Color textColor, Color iconColor,
      {bool centered = false, VoidCallback? onHelp}) {
    return Row(
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.instrumentSans(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onHelp != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onHelp,
            child: Icon(LucideIcons.helpCircle, size: 16, color: iconColor),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint,
      Color textColor, Color fillColor) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPhotoGrid(bool isDark, Color textColor, Color borderColor) {
    final addBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._photoUrls.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 90,
                      height: 110,
                      child: url.startsWith('http')
                          ? Image.network(url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[800]))
                          : Image.file(File(url),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[800])),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(t('main', _lang),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_photoUrls.length < 4)
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                width: 90,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  color: addBg,
                ),
                child: Center(
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white38),
                        )
                      : Icon(LucideIcons.plus,
                          size: 30,
                          color: isDark ? Colors.white38 : Colors.black26),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationField(String lang, Color textColor, Color fillColor,
      Color iconColor, bool isDark) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _locationController.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return locationSuggestions.where((city) =>
            city.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _locationController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(color: textColor),
          onChanged: (val) => _locationController.text = val,
          decoration: InputDecoration(
            hintText: t('location_hint', lang),
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
            filled: true,
            fillColor: fillColor,
            prefixIcon: Icon(LucideIcons.mapPin, size: 18, color: iconColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 340),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(LucideIcons.mapPin,
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.black45),
                    title: Text(option,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderChips(String lang, bool isDark, Color textColor) {
    final options = [
      {'label': t('gender_male', lang), 'value': 'male', 'icon': Icons.male},
      {
        'label': t('gender_female', lang),
        'value': 'female',
        'icon': Icons.female
      },
      {
        'label': t('non_binary', lang),
        'value': 'non_binary',
        'icon': LucideIcons.userX
      },
    ];
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          ChoiceChip(
            avatar: Icon(options[i]['icon'] as IconData,
                size: 16,
                color: _gender == options[i]['value']
                    ? Colors.black
                    : (isDark ? Colors.white70 : Colors.black54)),
            label: Text(options[i]['label'] as String),
            selected: _gender == options[i]['value'],
            onSelected: (s) {
              if (s) {
                final value = options[i]['value'] as String;
                setState(() => _gender = value);
                _markChanged();

                if (value == 'non_binary') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(t('gender_nonbinary_popup_title', lang)),
                      content: Text(t('gender_nonbinary_popup_body', lang)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(t('ok', lang)),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            selectedColor: Theme.of(context).primaryColor,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            labelStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold),
            shape: StadiumBorder(
                side: BorderSide(
                    color: _gender == options[i]['value']
                        ? Theme.of(context).primaryColor
                        : (isDark ? Colors.white24 : Colors.black12))),
            showCheckmark: false,
          ),
          if (i < options.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildInterestChips(String lang, bool isDark, Color textColor) {
    final options = [
      {'label': t('male', lang), 'value': 'male', 'icon': Icons.male},
      {'label': t('female', lang), 'value': 'female', 'icon': Icons.female},
      {
        'label': t('non_binary', lang),
        'value': 'non_binary',
        'icon': LucideIcons.userX
      },
    ];
    return Wrap(
      spacing: 10,
      children: options.map((opt) {
        final label = opt['label'] as String;
        final value = opt['value'] as String;
        final icon = opt['icon'] as IconData;
        final sel = _interestedIn.contains(value);
        return ChoiceChip(
          avatar: Icon(icon,
              size: 16,
              color: sel
                  ? Colors.black
                  : (isDark ? Colors.white70 : Colors.black54)),
          label: Text(label),
          selected: sel,
          onSelected: (s) {
            setState(() {
              if (s) {
                if (!_interestedIn.contains(value)) {
                  _interestedIn = [..._interestedIn, value];
                }
              } else {
                _interestedIn = _interestedIn.where((v) => v != value).toList();
              }
            });
            _markChanged();
          },
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          labelStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold),
          shape: StadiumBorder(
              side: BorderSide(
                  color: sel
                      ? Theme.of(context).primaryColor
                      : (isDark ? Colors.white24 : Colors.black12))),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildOccupationChips(String lang, bool isDark, Color textColor) {
    final options = [
      {'label': t('student', lang), 'value': 'student'},
      {'label': t('employed', lang), 'value': 'employed'},
    ];
    return Wrap(
      spacing: 10,
      children: options.map((opt) {
        final label = opt['label']!;
        final value = opt['value']!;
        final sel = _jobStatus == value;
        return ChoiceChip(
          label: Text(label),
          selected: sel,
          onSelected: (s) {
            setState(() {
              _jobStatus = s ? value : null;
              _hasChanges = true;
            });
          },
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          labelStyle: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold),
          shape: StadiumBorder(
              side: BorderSide(
                  color: sel
                      ? Theme.of(context).primaryColor
                      : (isDark ? Colors.white24 : Colors.black12))),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildSmokerSwitch(String lang, bool isDark, Color textColor) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t('smoking', lang), style: TextStyle(color: textColor)),
      value: _isSmoker ?? false,
      activeThumbColor: Theme.of(context).primaryColor,
      activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
      inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
      onChanged: (val) => setState(() {
        _isSmoker = val;
        _hasChanges = true;
      }),
    );
  }

  Widget _buildChildrenSwitch(String lang, bool isDark, Color textColor) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t('has_children', lang), style: TextStyle(color: textColor)),
      value: _hasChildren ?? false,
      activeThumbColor: Theme.of(context).primaryColor,
      activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
      inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
      onChanged: (val) => setState(() {
        _hasChildren = val;
        _hasChanges = true;
      }),
    );
  }

  Widget _buildIntrovertSlider(String lang, bool isDark, Color subColor) {
    final percentLabel = _introversionLevel <= 0.5
        ? '${((1.0 - _introversionLevel) * 100).toInt()}% ${t('introvert', lang).toLowerCase()}'
        : '${(_introversionLevel * 100).toInt()}% ${t('extrovert', lang).toLowerCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('introvert', lang),
                style: TextStyle(color: subColor, fontSize: 12)),
            Text(t('extrovert', lang),
                style: TextStyle(color: subColor, fontSize: 12)),
          ],
        ),
        Slider(
          value: _introversionLevel,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: isDark ? Colors.white24 : Colors.black12,
          onChanged: (val) => setState(() {
            _introversionLevel = val;
            _hasChanges = true;
          }),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            percentLabel,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider(String lang, bool isDark, Color subColor) {
    final maxDist = _isPremium ? 100.0 : 50.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('10m', style: TextStyle(color: subColor, fontSize: 12)),
            Text('${_distancePreference.round()}m',
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('${maxDist.round()}m',
                style: TextStyle(color: subColor, fontSize: 12)),
          ],
        ),
        Slider(
          value: _distancePreference.clamp(10, maxDist),
          min: 10,
          max: maxDist,
          divisions: (maxDist - 10) ~/ 10,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: isDark ? Colors.white24 : Colors.black12,
          onChanged: (v) => setState(() {
            _distancePreference = v;
            _hasChanges = true;
          }),
        ),
        if (_distancePreference > 50)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              t('battery_warning', lang).replaceFirst('{percent}', '25'),
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// Pill showing count/value for multi-select rows.
  Widget _multiPill(
      List<String> values, String lang, bool isDark, Color subColor,
      {IconData? Function(String)? iconMapper}) {
    final String display;
    IconData? icon;
    if (values.isEmpty) {
      display = '—';
    } else if (values.length == 1) {
      display = _formatValue(values.first, lang);
      icon = iconMapper?.call(values.first);
    } else {
      display = 'Selected ${values.length}';
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: subColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: subColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editCircle(bool isDark, Color borderColor, Color fillColor,
      {required VoidCallback onTap}) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? primary.withValues(alpha: 0.2) : fillColor,
          border: Border.all(
              color: isDark ? primary.withValues(alpha: 0.3) : borderColor),
        ),
        child: Icon(LucideIcons.pencil,
            size: 14, color: isDark ? primary : Colors.black38),
      ),
    );
  }

  Widget _buildPoliticalSlider(String lang, bool isDark, Color subColor) {
    final labels = [
      '',
      t('politics_left', lang),
      t('politics_center_left', lang),
      t('politics_center', lang),
      t('politics_center_right', lang),
      t('politics_right', lang),
    ];

    // Scale for display: 1.0 to 5.0
    // If 0 (Don't care) or -1 (Undisclosed), we show it as Center (3) on slider for now
    // or we could handle it better. For edit profile, we'll keep it simple.
    double displayValue = _politicalAffiliationValue;
    if (displayValue <= 0) displayValue = 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('politics_left', lang),
                style: TextStyle(color: subColor, fontSize: 12)),
            Text(t('politics_right', lang),
                style: TextStyle(color: subColor, fontSize: 12)),
          ],
        ),
        Slider(
          value: displayValue,
          min: 1.0,
          max: 5.0,
          divisions: 4,
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: isDark ? Colors.white24 : Colors.black12,
          onChanged: (val) => setState(() {
            _politicalAffiliationValue = val;
            _hasChanges = true;
          }),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            labels[displayValue.round()],
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Local _calcAge removed in favor of ZodiacUtils.calcAge

  // ── DOB drum-picker — identical UX to registration BirthdayStep ──────────
  void _showAgePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final maxYear = now.year - 18;
    final minYear = now.year - 100;

    final initial = _birthDate ?? DateTime(2000, 1, 1);
    int month = initial.month;
    int day = initial.day;
    int year = initial.year.clamp(minYear, maxYear).toInt();

    const months = [
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

    final sheetBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final handleColor = isDark ? Colors.white24 : Colors.black26;
    final brandRose = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final maxDays = DateTime(year, month + 1, 0).day;
            final validDay = day > maxDays ? maxDays : day;

            // ── Main picker sheet ──────────────────────────────────────────────
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t('date_of_birth', _lang).isNotEmpty &&
                            t('date_of_birth', _lang) != 'date_of_birth'
                        ? t('date_of_birth', _lang)
                        : 'Date of Birth',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Drum pickers (Month / Day / Year) ─────────────────────
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        // Month
                        Expanded(
                          child: DrumPicker(
                            items: months,
                            selectedIndex: month - 1,
                            looping: true,
                            onChanged: (i) => setSheet(() => month = i + 1),
                          ),
                        ),
                        // Day
                        SizedBox(
                          width: 65,
                          child: DrumPicker(
                            items: List.generate(maxDays, (i) => '${i + 1}'),
                            selectedIndex: (validDay - 1).clamp(0, maxDays - 1),
                            looping: true,
                            onChanged: (i) {
                              final d2 = i + 1;
                              setSheet(() => day = d2 > maxDays ? maxDays : d2);
                            },
                          ),
                        ),
                        // Year
                        SizedBox(
                          width: 90,
                          child: DrumPicker(
                            items: List.generate(
                                maxYear - minYear + 1, (i) => '${maxYear - i}'),
                            selectedIndex: maxYear - year,
                            looping: false,
                            onChanged: (i) =>
                                setSheet(() => year = (maxYear - i).toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Age + Zodiac chips ─────────────────────────────────────
                  Row(
                    children: [
                      _AgePill(
                        '${ZodiacUtils.calcAge(DateTime(year, month, validDay))}',
                        icon: LucideIcons.cake,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _AgePill(
                        t('zodiac_${ZodiacUtils.getZodiacSign(DateTime(year, month, validDay))}',
                            _lang),
                        icon: ZodiacUtils.getZodiacIcon(
                          ZodiacUtils.getZodiacSign(
                            DateTime(year, month, validDay),
                          ),
                        ),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // ── Save / Cancel buttons at bottom ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        final d = DateTime(year, month, validDay);
                        final age = ZodiacUtils.calcAge(d);
                        if (age < 18) return;
                        setState(() {
                          _birthDate = d;
                          _hasChanges = true;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRose,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        t('save', _lang).isNotEmpty &&
                                t('save', _lang) != 'save'
                            ? t('save', _lang).toUpperCase()
                            : 'SAVE',
                        style: GoogleFonts.instrumentSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      t('cancel', _lang).isNotEmpty &&
                              t('cancel', _lang) != 'cancel'
                          ? t('cancel', _lang).toUpperCase()
                          : 'CANCEL',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static const Map<String, List<String>> _hobbyCategories = {
    'hobby_cat_active': [
      'hobby_fitness',
      'hobby_pilates',
      'hobby_walking',
      'hobby_running',
      'hobby_skiing',
      'hobby_snowboarding',
      'hobby_climbing',
      'hobby_swimming'
    ],
    'hobby_cat_leisure': [
      'hobby_reading',
      'hobby_coffee',
      'hobby_tea',
      'hobby_cooking',
      'hobby_movies',
      'hobby_series',
      'hobby_video_games'
    ],
    'hobby_cat_art': [
      'hobby_painting',
      'hobby_photography',
      'hobby_writing',
      'hobby_museums',
      'hobby_theater',
      'hobby_music'
    ],
    'hobby_cat_travel': [
      'hobby_trips',
      'hobby_nature',
      'hobby_mountains',
      'hobby_sea',
      'hobby_city_walks',
      'hobby_camping'
    ],
  };

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'hobby_cat_active':
        return LucideIcons.zap;
      case 'hobby_cat_leisure':
        return LucideIcons.coffee;
      case 'hobby_cat_art':
        return LucideIcons.palette;
      case 'hobby_cat_travel':
        return LucideIcons.map;
      default:
        return LucideIcons.sparkles;
    }
  }

  String _getHobbyKey(String hobby) {
    if (hobby.startsWith('hobby_')) return hobby;
    final mapping = {
      'Fitnes': 'hobby_fitness',
      'Pilates': 'hobby_pilates',
      'Sprehodi': 'hobby_walking',
      'Tek': 'hobby_running',
      'Smučanje': 'hobby_skiing',
      'Snowboarding': 'hobby_snowboarding',
      'Plezanje': 'hobby_climbing',
      'Plavanje': 'hobby_swimming',
      'Branje': 'hobby_reading',
      'Kava': 'hobby_coffee',
      'Čaj': 'hobby_tea',
      'Kuhanje': 'hobby_cooking',
      'Filmi': 'hobby_movies',
      'Serije': 'hobby_series',
      'Video igre': 'hobby_video_games',
      'Slikanje': 'hobby_painting',
      'Fotografija': 'hobby_photography',
      'Pisanje': 'hobby_writing',
      'Muzeji': 'hobby_museums',
      'Gledališče': 'hobby_theater',
      'Glasba': 'hobby_music',
      'Izleti': 'hobby_trips',
      'Narava': 'hobby_nature',
      'Gore': 'hobby_mountains',
      'Morje': 'hobby_sea',
      'Sprehodi po mestu': 'hobby_city_walks',
      'Kampiranje': 'hobby_camping',
    };
    return mapping[hobby] ?? hobby;
  }

  Widget _buildCategorizedHobbies(String lang, bool isDark, Color textColor,
      Color fillColor, Color borderColor) {
    if (_hobbies.isEmpty) return const SizedBox.shrink();

    // Normalize hobbies to keys for categorization
    final normalizedHobbies = _hobbies.map((h) => _getHobbyKey(h)).toList();

    final categorizedHobbies = <String>{};
    for (var group in _hobbyCategories.values) {
      categorizedHobbies.addAll(group);
    }

    final customHobbies = normalizedHobbies
        .where((h) => !categorizedHobbies.contains(h))
        .toList();

    return Column(
      children: [
        for (final entry in _hobbyCategories.entries)
          if (normalizedHobbies.any((h) => entry.value.contains(h))) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(entry.key),
                    size: 12,
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t(entry.key, lang).toUpperCase(),
                    style: GoogleFonts.instrumentSans(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: normalizedHobbies
                  .where((h) => entry.value.contains(h))
                  .map((h) => _smallHobbyChip(
                      h, lang, isDark, textColor, fillColor, borderColor))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        if (customHobbies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 12,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  t('hobby_other', lang).toUpperCase(),
                  style: GoogleFonts.instrumentSans(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: customHobbies
                .map((h) => _smallHobbyChip(
                    h, lang, isDark, textColor, fillColor, borderColor))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _smallHobbyChip(String hobby, String lang, bool isDark,
      Color textColor, Color fillColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatHobby(hobby, lang),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() {
              _hobbies.remove(hobby);
              _hasChanges = true;
            }),
            child: Icon(LucideIcons.x,
                size: 10, color: textColor.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ── Small age/zodiac pill ─────────────────────────────────────────────────────
class _AgePill extends StatelessWidget {
  const _AgePill(this.label, {required this.isDark, this.icon});
  final String label;
  final bool isDark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isDark ? Colors.white30 : Colors.black.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 13, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
