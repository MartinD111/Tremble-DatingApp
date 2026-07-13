import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../shared/ui/tremble_alert_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/ui/gradient_scaffold.dart';
import '../../../shared/ui/tremble_header.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/translations.dart';
import '../../../core/hobby_data.dart';
import '../../settings/presentation/widgets/preference_edit_modal.dart';
import '../../settings/presentation/widgets/preference_pill_row.dart';
import '../../auth/presentation/widgets/registration_steps/hobbies_step.dart';
import '../../auth/presentation/widgets/registration_steps/step_shared.dart'
    show DrumPicker, profileLocationOptions;
import '../../../shared/ui/center_notification.dart';
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
  bool _isUploading = false;

  List<String> _photoUrls = [];
  final ValueNotifier<double> _titleOpacity = ValueNotifier(1.0);
  final ValueNotifier<double> _buttonsOpacity = ValueNotifier(1.0);
  String? _gender;
  List<String> _interestedIn = [];
  String? _jobStatus;
  String? _religion;
  String? _hairColor;
  String? _ethnicity;
  String? _occupation;
  final _occupationController = TextEditingController();
  final List<String> _nicotineUse = [];
  bool _nicotineUseToggle = false;
  String? _drinkingHabit;
  String? _exerciseHabit;
  String? _sleepSchedule;
  String? _petPreference;
  String? _childrenPreference;
  double _introversionLevel = 0.5;
  final _schoolController = TextEditingController();
  final _companyController = TextEditingController();
  final _graduatedUniversityController = TextEditingController();
  bool? _lookingForNewJob;
  bool? _hasChildren;
  List<Map<String, dynamic>> _hobbies = [];
  List<String> _lookingFor = [];
  List<String> _languages = [];
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
      _locationController.text = profileLocationOptions.contains(user.location)
          ? user.location!
          : 'Other';
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
      _nicotineUse
        ..clear()
        ..addAll(user.nicotineUse.where((v) => v != 'cannabis'));
      _nicotineUseToggle = _nicotineUse.isNotEmpty;
      _occupation = user.occupation;
      _occupationController.text = user.occupation ?? '';
      _schoolController.text = user.school ?? '';
      _companyController.text = user.company ?? '';
      _graduatedUniversityController.text = user.graduatedUniversity ?? '';
      _lookingForNewJob = user.lookingForNewJob;
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
      _hobbies = List.from(user.hobbies);
      _languages = List.from(user.languages);
      _birthDate = user.birthDate;
    }
    _nameController.addListener(_markChanged);
    _locationController.addListener(_markChanged);
    _occupationController.addListener(_markChanged);
    _schoolController.addListener(_markChanged);
    _companyController.addListener(_markChanged);
    _graduatedUniversityController.addListener(_markChanged);
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
    _graduatedUniversityController.dispose();
    _titleOpacity.dispose();
    _buttonsOpacity.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    final offset = notification.metrics.pixels;
    final delta = offset - _lastScrollOffset;

    if (offset <= 0) {
      _titleOpacity.value = 1.0;
      _buttonsOpacity.value = 1.0;
    } else if (delta > 2) {
      _titleOpacity.value = 0.0;
      _buttonsOpacity.value = 0.0;
    } else if (delta < -2) {
      _titleOpacity.value = 0.0;
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
      _saveChanges(navigateToProfile: true);
      return false; // Don't pop, navigation handled in _saveChanges
    } else if (res == 'discard') {
      return true;
    }
    return false;
  }

  void _saveChanges({bool navigateToProfile = false}) {
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
          graduatedUniversity: _graduatedUniversityController.text.isNotEmpty
              ? _graduatedUniversityController.text
              : null,
          lookingForNewJob: _lookingForNewJob,
          hasChildren: _hasChildren,
          nicotineUse: _nicotineUse,
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
        ));
    CenterNotification.show(
      context: context,
      message: t('Profile updated', _lang),
    );
    setState(() => _hasChanges = false);
    if (context.mounted) {
      if (navigateToProfile) {
        // Pop back to My Profile — context.go would wipe navigation history
        if (context.canPop()) context.pop();
      } else {
        // When clicking save button directly, just stay on edit profile
        // (no navigation needed)
      }
    }
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
              content: Text(
                '${t('upload_failed', _lang)}. Povezava ali dovoljenje ni uspelo. Poskusi znova.',
              ),
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
    final tempHobbies = List<Map<String, dynamic>>.from(_hobbies);
    final user = ref.read(authStateProvider);
    final isGenderBasedColor = user?.isGenderBasedColor ?? false;
    final gender = user?.gender ?? 'default';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) => HobbiesStep(
              isModal: true,
              isGenderBased: isGenderBasedColor,
              gender: gender,
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
              lang: _lang,
              scrollController: scrollController,
            ),
          ),
        );
      },
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
    final user = ref.read(authStateProvider);
    final isPremium = ref.watch(effectiveIsPremiumProvider);
    final isGenderBasedColor = user?.isGenderBasedColor ?? false;
    final gender = user?.gender ?? 'default';
    final pillBg = TrembleTheme.getPillColor(
      isDark: isDark,
      isGenderBased: isGenderBasedColor,
      gender: gender,
    );

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
                            const SizedBox(height: 32),

                            _PhotosSection(
                              photoUrls: _photoUrls,
                              isDark: isDark,
                              textColor: textColor,
                              iconColor: iconColor,
                              borderColor: borderColor,
                              isUploading: _isUploading,
                              onRemove: _removePhoto,
                              onAdd: _pickImage,
                              lang: lang,
                            ),

                            _BasicInfoSection(
                              nameController: _nameController,
                              locationController: _locationController,
                              lang: lang,
                              textColor: textColor,
                              fillColor: fillColor,
                              isDark: isDark,
                              iconColor: iconColor,
                              subColor: subColor,
                              onLocationSelected: (val) {
                                _locationController.text = val;
                                _markChanged();
                                setState(() {});
                              },
                              birthDate: _birthDate,
                              onBirthDateTap: _showAgePickerModal,
                              pillBg: pillBg,
                            ),

                            _IdentitySection(
                              selectedGender: _gender,
                              interestedIn: _interestedIn,
                              jobStatus: _jobStatus,
                              religion: _religion,
                              hairColor: _hairColor,
                              ethnicity: _ethnicity,
                              occupationController: _occupationController,
                              schoolController: _schoolController,
                              companyController: _companyController,
                              graduatedUniversityController:
                                  _graduatedUniversityController,
                              lookingForNewJob: _lookingForNewJob,
                              lang: lang,
                              isDark: isDark,
                              textColor: textColor,
                              subColor: subColor,
                              fillColor: fillColor,
                              pillBg: pillBg,
                              user: user,
                              isGenderBasedColor: isGenderBasedColor,
                              themeGender: gender,
                              onGenderChanged: (v) => setState(() {
                                _gender = v;
                                _hasChanges = true;
                              }),
                              onInterestedInChanged: (v) => setState(() {
                                _interestedIn = v;
                                _hasChanges = true;
                              }),
                              onJobStatusChanged: (v) => setState(() {
                                _jobStatus = v;
                                _hasChanges = true;
                              }),
                              onReligionChanged: (v) => setState(() {
                                _religion = v;
                                _hasChanges = true;
                              }),
                              onEthnicityChanged: (v) => setState(() {
                                _ethnicity = v;
                                _hasChanges = true;
                              }),
                              onHairColorChanged: (v) => setState(() {
                                _hairColor = v;
                                _hasChanges = true;
                              }),
                              onLookingForNewJobChanged: (v) => setState(() {
                                _lookingForNewJob = v;
                                _hasChanges = true;
                              }),
                            ),

                            _LifestyleSection(
                              nicotineUse: _nicotineUse,
                              nicotineUseToggle: _nicotineUseToggle,
                              hasChildren: _hasChildren,
                              drinkingHabit: _drinkingHabit,
                              exerciseHabit: _exerciseHabit,
                              sleepSchedule: _sleepSchedule,
                              petPreference: _petPreference,
                              childrenPreference: _childrenPreference,
                              lang: lang,
                              isDark: isDark,
                              textColor: textColor,
                              pillBg: pillBg,
                              borderColor: borderColor,
                              user: user,
                              isGenderBasedColor: isGenderBasedColor,
                              themeGender: gender,
                              formatValue: (v) => _formatValue(v, lang),
                              onNicotineUseToggleChanged: (val) => setState(() {
                                _nicotineUseToggle = val;
                                if (!val) {
                                  _nicotineUse.clear();
                                }
                                _hasChanges = true;
                              }),
                              onNicotineUseChanged: (values) => setState(() {
                                _nicotineUse
                                  ..clear()
                                  ..addAll(values);
                                _hasChanges = true;
                              }),
                              onHasChildrenChanged: (val) => setState(() {
                                _hasChildren = val;
                                _hasChanges = true;
                              }),
                              onExerciseHabitChanged: (val) => setState(() {
                                _exerciseHabit = val;
                                _hasChanges = true;
                              }),
                              onDrinkingHabitChanged: (val) => setState(() {
                                _drinkingHabit = val;
                                _hasChanges = true;
                              }),
                              onSleepScheduleChanged: (val) => setState(() {
                                _sleepSchedule = val;
                                _hasChanges = true;
                              }),
                              onPetPreferenceChanged: (val) => setState(() {
                                _petPreference = val;
                                _hasChanges = true;
                              }),
                              onChildrenPreferenceChanged: (val) =>
                                  setState(() {
                                _childrenPreference = val;
                                _hasChanges = true;
                              }),
                            ),

                            _MetricsSection(
                              introversionLevel: _introversionLevel,
                              isPremium: isPremium,
                              lang: lang,
                              isDark: isDark,
                              textColor: textColor,
                              subColor: subColor,
                              iconColor: iconColor,
                              borderColor: borderColor,
                              onIntroversionChanged: (val) => setState(() {
                                _introversionLevel = val;
                                _hasChanges = true;
                              }),
                            ),

                            _PreferencesSection(
                              lookingFor: _lookingFor,
                              languages: _languages,
                              lang: lang,
                              isDark: isDark,
                              textColor: textColor,
                              subColor: subColor,
                              iconColor: iconColor,
                              borderColor: borderColor,
                              pillBg: pillBg,
                              isGenderBasedColor: isGenderBasedColor,
                              themeGender: gender,
                              languageOptions: _buildLanguageOptions(lang),
                              formatValue: (v) => _formatValue(v, lang),
                              onLookingForChanged: (vals) => setState(() {
                                _lookingFor = vals;
                                _hasChanges = true;
                              }),
                              onLanguagesChanged: (vals) => setState(() {
                                _languages = vals.length <= 5
                                    ? vals
                                    : vals.sublist(0, 5);
                                _hasChanges = true;
                              }),
                            ),

                            Divider(color: borderColor, height: 28),

                            _HobbiesSection(
                              hobbies: _hobbies,
                              lang: lang,
                              isDark: isDark,
                              textColor: textColor,
                              pillBg: pillBg,
                              borderColor: borderColor,
                              onEdit: _showHobbiesModal,
                              onRemoveHobby: (hobby) => setState(() {
                                bool sameHobby(Map<String, dynamic> a,
                                    Map<String, dynamic> b) {
                                  final aId = a['id'] as String? ?? '';
                                  final bId = b['id'] as String? ?? '';
                                  if (aId.isNotEmpty && bId.isNotEmpty) {
                                    return aId == bId;
                                  }
                                  return a['name'] == b['name'];
                                }

                                _hobbies
                                    .removeWhere((h) => sameHobby(h, hobby));
                                _hasChanges = true;
                              }),
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
              ListenableBuilder(
                listenable: Listenable.merge([_titleOpacity, _buttonsOpacity]),
                builder: (context, child) {
                  return TrembleHeader(
                    title: t('edit_profile', lang),
                    titleOpacity: _titleOpacity.value,
                    buttonsOpacity: _buttonsOpacity.value,
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

  static const Map<String, String> _languageFlags = {
    'lang_english': '🇬🇧',
    'lang_german': '🇩🇪',
    'lang_french': '🇫🇷',
    'lang_spanish': '🇪🇸',
    'lang_italian': '🇮🇹',
    'lang_portuguese': '🇵🇹',
    'lang_dutch': '🇳🇱',
    'lang_polish': '🇵🇱',
    'lang_czech': '🇨🇿',
    'lang_slovak': '🇸🇰',
    'lang_hungarian': '🇭🇺',
    'lang_romanian': '🇷🇴',
    'lang_bulgarian': '🇧🇬',
    'lang_greek': '🇬🇷',
    'lang_swedish': '🇸🇪',
    'lang_norwegian': '🇳🇴',
    'lang_danish': '🇩🇰',
    'lang_finnish': '🇫🇮',
    'lang_estonian': '🇪🇪',
    'lang_latvian': '🇱🇻',
    'lang_lithuanian': '🇱🇹',
    'lang_slovenian': '🇸🇮',
    'lang_croatian': '🇭🇷',
    'lang_serbian': '🇷🇸',
    'lang_bosnian': '🇧🇦',
    'lang_montenegrin': '🇲🇪',
    'lang_albanian': '🇦🇱',
    'lang_macedonian': '🇲🇰',
    'lang_ukrainian': '🇺🇦',
    'lang_russian': '🇷🇺',
    'lang_turkish': '🇹🇷',
    'lang_arabic': '🇸🇦',
    'lang_chinese': '🇨🇳',
    'lang_japanese': '🇯🇵',
    'lang_korean': '🇰🇷',
    'lang_hindi': '🇮🇳',
  };

  // Persisted value uses the canonical translation key (e.g. 'lang_english'),
  // matching what the onboarding flow writes. Legacy profiles may still hold
  // Slovenian display strings — those simply won't match here, which is the
  // same behaviour the old edit modal had when its 9-language list didn't
  // contain the saved value.
  List<Map<String, dynamic>> _buildLanguageOptions(String lang) {
    final entries = _languageFlags.entries.toList()
      ..sort((a, b) => t(a.key, lang).compareTo(t(b.key, lang)));
    return entries
        .map((e) => <String, dynamic>{
              'label': '${e.value} ${t(e.key, lang)}',
              'value': e.key,
            })
        .toList();
  }

  // Local _calcAge removed in favor of ZodiacUtils.calcAge

  // ── DOB drum-picker — identical UX to registration BirthdayStep ──────────
  void _showAgePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final maxYear = now.year - 18;
    final minYear = now.year - 100;
    final user = ref.read(authStateProvider);
    final isGenderBased = user?.isGenderBasedColor ?? false;
    final gender = user?.gender;

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

    final sheetBg = isDark
        ? TrembleTheme.getPillColor(
            isDark: true,
            isGenderBased: isGenderBased,
            gender: gender,
          )
        : Colors.white;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.cake,
                          size: 20, color: titleColor.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
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
                    ],
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
                  _AgePill(
                    '${ZodiacUtils.calcAge(DateTime(year, month, validDay))}  ${ZodiacUtils.getZodiacEmoji(DateTime(year, month, validDay)) ?? ''} ${t('zodiac_${ZodiacUtils.getZodiacSign(DateTime(year, month, validDay))}', _lang)}',
                    icon: LucideIcons.cake,
                    isDark: isDark,
                    pillBg: TrembleTheme.getPillColor(
                      isDark: isDark,
                      isGenderBased:
                          ref.watch(authStateProvider)?.isGenderBasedColor ??
                              false,
                      gender: ref.watch(authStateProvider)?.gender,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ── Save / Cancel — standard two-button row ────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                    isDark ? Colors.white38 : Colors.black26),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            t('cancel', _lang),
                            style: GoogleFonts.instrumentSans(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandRose,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
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
                          child: Text(
                            t('save', _lang),
                            style: GoogleFonts.instrumentSans(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Photos section ────────────────────────────────────────────────────────────
class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.photoUrls,
    required this.isDark,
    required this.textColor,
    required this.iconColor,
    required this.borderColor,
    required this.isUploading,
    required this.onRemove,
    required this.onAdd,
    required this.lang,
  });

  final List<String> photoUrls;
  final bool isDark;
  final Color textColor;
  final Color iconColor;
  final Color borderColor;
  final bool isUploading;
  final void Function(int) onRemove;
  final void Function() onAdd;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final addBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.camera, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              t('photos', lang),
              style: GoogleFonts.instrumentSans(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...photoUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 90,
                          height: 110,
                          child: url.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      Container(color: Colors.grey[800]))
                              : Image.file(File(url),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey[800])),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.amber, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.star,
                                size: 10, color: Colors.black),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => onRemove(index),
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
              if (photoUrls.length < 4)
                GestureDetector(
                  onTap: isUploading ? null : onAdd,
                  child: Container(
                    width: 90,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                      color: addBg,
                    ),
                    child: Center(
                      child: isUploading
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
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Basic info section ────────────────────────────────────────────────────────
class _BasicInfoSection extends StatelessWidget {
  const _BasicInfoSection({
    required this.nameController,
    required this.locationController,
    required this.lang,
    required this.textColor,
    required this.fillColor,
    required this.isDark,
    required this.iconColor,
    required this.subColor,
    required this.onLocationSelected,
    required this.birthDate,
    required this.onBirthDateTap,
    required this.pillBg,
  });

  static const int _nameMaxLength = 50;

  final TextEditingController nameController;
  final TextEditingController locationController;
  final String lang;
  final Color textColor;
  final Color fillColor;
  final bool isDark;
  final Color iconColor;
  final Color subColor;
  final void Function(String) onLocationSelected;
  final DateTime? birthDate;
  final void Function() onBirthDateTap;
  final Color pillBg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Name ──────────────────────────────────────────────────────────────
        Row(
          children: [
            Icon(LucideIcons.user, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              t('name', lang),
              style: GoogleFonts.instrumentSans(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(
          nameController,
          t('name', lang),
          maxLength: _nameMaxLength,
        ),
        const SizedBox(height: 6),
        ListenableBuilder(
          listenable: nameController,
          builder: (context, _) {
            final remaining = _nameMaxLength - nameController.text.length;
            final counterColor = remaining < 10
                ? TrembleTheme.rose
                : (isDark ? Colors.white54 : Colors.black45);
            final counterText = t('name_chars_remaining', lang).replaceAll(
              '{count}',
              remaining.toString(),
            );
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                counterText,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: counterColor),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // ── Location ──────────────────────────────────────────────────────────
        Row(
          children: [
            Icon(LucideIcons.mapPin, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              t('location', lang),
              style: GoogleFonts.instrumentSans(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...profileLocationOptions.map(
              (location) => GestureDetector(
                onTap: () => onLocationSelected(location),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: locationController.text == location
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15)
                        : pillBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: locationController.text == location
                          ? Theme.of(context).colorScheme.primary
                          : (isDark
                              ? const Color(0xFF3A3A3E)
                              : const Color(0xFFD8DCE0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: locationController.text == location
                            ? Theme.of(context).colorScheme.primary
                            : iconColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.instrumentSans(
                            color: locationController.text == location
                                ? Theme.of(context).colorScheme.primary
                                : textColor,
                            fontWeight: locationController.text == location
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (locationController.text == location)
                        Icon(
                          LucideIcons.checkCircle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Age / Birth Date ──────────────────────────────────────────────────
        GestureDetector(
          onTap: onBirthDateTap,
          child: Row(
            children: [
              if (birthDate != null) ...[
                _AgePill(
                  '${ZodiacUtils.calcAge(birthDate!)}  ${ZodiacUtils.getZodiacEmoji(birthDate) ?? ''} ${t('zodiac_${ZodiacUtils.getZodiacSign(birthDate!)}', lang)}',
                  icon: LucideIcons.cake,
                  isDark: isDark,
                  pillBg: pillBg,
                ),
              ] else
                _AgePill(
                  t('set_birthday', lang).isNotEmpty &&
                          t('set_birthday', lang) != 'set_birthday'
                      ? t('set_birthday', lang)
                      : 'Set birthday',
                  icon: LucideIcons.calendar,
                  isDark: isDark,
                  pillBg: pillBg,
                ),
              const SizedBox(width: 8),
              Icon(LucideIcons.pencil, color: iconColor, size: 14),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint,
      {int? maxLength}) {
    return TextField(
      controller: ctrl,
      maxLength: maxLength,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        counterText: maxLength == null ? null : '',
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
}

// ── Identity section ──────────────────────────────────────────────────────────
class _IdentitySection extends StatelessWidget {
  const _IdentitySection({
    required this.selectedGender,
    required this.interestedIn,
    required this.jobStatus,
    required this.religion,
    required this.hairColor,
    required this.ethnicity,
    required this.occupationController,
    required this.schoolController,
    required this.companyController,
    required this.graduatedUniversityController,
    required this.lookingForNewJob,
    required this.lang,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.fillColor,
    required this.pillBg,
    required this.user,
    required this.isGenderBasedColor,
    required this.themeGender,
    required this.onGenderChanged,
    required this.onInterestedInChanged,
    required this.onJobStatusChanged,
    required this.onReligionChanged,
    required this.onEthnicityChanged,
    required this.onHairColorChanged,
    required this.onLookingForNewJobChanged,
  });

  final String? selectedGender;
  final List<String> interestedIn;
  final String? jobStatus;
  final String? religion;
  final String? hairColor;
  final String? ethnicity;
  final TextEditingController occupationController;
  final TextEditingController schoolController;
  final TextEditingController companyController;
  final TextEditingController graduatedUniversityController;
  final bool? lookingForNewJob;
  final String lang;
  final bool isDark;
  final Color textColor;
  final Color subColor;
  final Color fillColor;
  final Color pillBg;
  final AuthUser? user;
  final bool isGenderBasedColor;
  final String themeGender;
  final void Function(String?) onGenderChanged;
  final void Function(List<String>) onInterestedInChanged;
  final void Function(String?) onJobStatusChanged;
  final void Function(String?) onReligionChanged;
  final void Function(String?) onEthnicityChanged;
  final void Function(String?) onHairColorChanged;
  final void Function(bool?) onLookingForNewJobChanged;

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? subColor : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Gender ────────────────────────────────────────────────────────────
        _sectionLabel(t('gender', lang), LucideIcons.users, iconColor),
        const SizedBox(height: 8),
        _buildGenderChips(context),
        const SizedBox(height: 24),

        // ── Interested In ─────────────────────────────────────────────────────
        _sectionLabel(t('want_to_meet', lang), LucideIcons.heart, iconColor),
        const SizedBox(height: 8),
        _buildInterestChips(context),
        const SizedBox(height: 24),

        // ── Status ───────────────────────────────────────────────────────────
        _sectionLabel(t('status', lang), LucideIcons.briefcase, iconColor),
        const SizedBox(height: 8),
        _buildOccupationChips(context),
        if (jobStatus != null) ...[
          const SizedBox(height: 12),
          _buildTextField(
            occupationController,
            t(jobStatus == 'student' ? 'course_of_study' : 'job_title', lang),
          ),
          if (jobStatus == 'student') ...[
            const SizedBox(height: 12),
            _buildTextField(
              schoolController,
              t('school_hint', lang),
            ),
          ],
          if (jobStatus == 'employed') ...[
            const SizedBox(height: 12),
            _buildTextField(
              graduatedUniversityController,
              t('graduated_university_hint', lang),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t('looking_for_new_job', lang),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              value: lookingForNewJob ?? false,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              activeTrackColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
              onChanged: onLookingForNewJobChanged,
            ),
          ],
        ],
        const SizedBox(height: 16),

        // ── Details ───────────────────────────────────────────────────────────
        PreferencePillRow(
          icon: LucideIcons.book,
          label: t('religion', lang),
          values: [religion],
          formatter: (v) => _formatValue(v, lang),
          iconMapper: IconUtils.getReligionIcon,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('religion', lang),
              user: authUser,
              rowIcon: LucideIcons.book,
              options: [
                {
                  'label': t('christianity', lang),
                  'value': 'christianity',
                  'icon': IconUtils.getReligionIcon('christianity')
                },
                {
                  'label': t('islam', lang),
                  'value': 'islam',
                  'icon': IconUtils.getReligionIcon('islam')
                },
                {
                  'label': t('hinduism', lang),
                  'value': 'hinduism',
                  'icon': IconUtils.getReligionIcon('hinduism')
                },
                {
                  'label': t('buddhism', lang),
                  'value': 'buddhism',
                  'icon': IconUtils.getReligionIcon('buddhism')
                },
                {
                  'label': t('judaism', lang),
                  'value': 'judaism',
                  'icon': IconUtils.getReligionIcon('judaism')
                },
                {
                  'label': t('agnostic', lang),
                  'value': 'agnostic',
                  'icon': IconUtils.getReligionIcon('agnostic')
                },
                {
                  'label': t('atheist', lang),
                  'value': 'atheist',
                  'icon': IconUtils.getReligionIcon('atheist')
                },
              ],
              currentValue: religion,
              onUpdate: onReligionChanged,
            );
          },
        ),
        const SizedBox(height: 12),

        PreferencePillRow(
          icon: LucideIcons.user,
          label: t('ethnicity', lang),
          values: [ethnicity],
          formatter: (v) => _formatValue(v, lang),
          iconMapper: (_) => LucideIcons.user,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('ethnicity', lang),
              user: authUser,
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
              currentValue: ethnicity,
              onUpdate: onEthnicityChanged,
            );
          },
        ),
        const SizedBox(height: 12),

        PreferencePillRow(
          icon: LucideIcons.scissors,
          label: t('hair_color', lang),
          values: [hairColor],
          formatter: (v) => _formatValue(v, lang),
          iconMapper: (_) => Icons.circle,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('hair_color', lang),
              user: authUser,
              rowIcon: LucideIcons.scissors,
              options: [
                {
                  'label': t('hair_blonde', lang),
                  'value': 'hair_blonde',
                  'icon': Icons.circle,
                  'iconColor': IconUtils.getHairColor('hair_blonde')
                },
                {
                  'label': t('hair_brunette', lang),
                  'value': 'hair_brunette',
                  'icon': Icons.circle,
                  'iconColor': IconUtils.getHairColor('hair_brunette')
                },
                {
                  'label': t('hair_black', lang),
                  'value': 'hair_black',
                  'icon': Icons.circle,
                  'iconColor': IconUtils.getHairColor('hair_black')
                },
                {
                  'label': t('hair_red', lang),
                  'value': 'hair_red',
                  'icon': Icons.circle,
                  'iconColor': IconUtils.getHairColor('hair_red')
                },
                {
                  'label': t('hair_gray_white', lang),
                  'value': 'hair_gray_white',
                  'icon': Icons.circle,
                  'iconColor': IconUtils.getHairColor('hair_gray_white')
                },
                {
                  'label': t('hair_bald', lang),
                  'value': 'hair_bald',
                  'icon': Icons.circle,
                  'iconColor': IconUtils.getHairColor('hair_bald')
                },
                {
                  'label': t('hair_other', lang),
                  'value': 'hair_other',
                  'icon': Icons.circle,
                  'iconColor': IconUtils.getHairColor('hair_other')
                },
              ],
              currentValue: hairColor,
              onUpdate: onHairColorChanged,
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionLabel(String label, IconData icon, Color iconColor) {
    return Row(
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
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
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

  Widget _buildGenderChips(BuildContext context) {
    final brandRose = Theme.of(context).colorScheme.primary;
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
            avatar: Icon(
              options[i]['icon'] as IconData,
              size: 16,
              color: selectedGender == options[i]['value']
                  ? brandRose
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            label: Text(options[i]['label'] as String),
            selected: selectedGender == options[i]['value'],
            onSelected: (s) {
              if (!s) return;
              final value = options[i]['value'] as String;
              onGenderChanged(value);

              if (value == 'non_binary') {
                showPlatformDialog(
                  context: context,
                  title: Text(t('gender_nonbinary_popup_title', lang)),
                  content: Text(t('gender_nonbinary_popup_body', lang)),
                  actions: [
                    TrembleDialogAction(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t('ok', lang)),
                    ),
                  ],
                );
              }
            },
            selectedColor: brandRose.withValues(alpha: 0.15),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            labelStyle: TextStyle(
              color: selectedGender == options[i]['value']
                  ? brandRose
                  : (isDark ? Colors.white : Colors.black87),
              fontWeight: FontWeight.bold,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: selectedGender == options[i]['value']
                    ? brandRose
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            ),
            showCheckmark: false,
          ),
          if (i < options.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildInterestChips(BuildContext context) {
    final brandRose = Theme.of(context).colorScheme.primary;
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
        final sel = interestedIn.contains(value);
        return ChoiceChip(
          avatar: Icon(
            icon,
            size: 16,
            color: sel ? brandRose : (isDark ? Colors.white70 : Colors.black54),
          ),
          label: Text(label),
          selected: sel,
          onSelected: (s) {
            if (s) {
              if (!interestedIn.contains(value)) {
                onInterestedInChanged([...interestedIn, value]);
              }
            } else {
              onInterestedInChanged(
                interestedIn.where((v) => v != value).toList(),
              );
            }
          },
          selectedColor: brandRose.withValues(alpha: 0.15),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          labelStyle: TextStyle(
            color: sel ? brandRose : (isDark ? Colors.white : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color:
                  sel ? brandRose : (isDark ? Colors.white24 : Colors.black12),
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildOccupationChips(BuildContext context) {
    final brandRose = Theme.of(context).colorScheme.primary;
    final options = [
      {
        'label': t('student', lang),
        'value': 'student',
        'icon': LucideIcons.graduationCap
      },
      {
        'label': t('employed', lang),
        'value': 'employed',
        'icon': LucideIcons.briefcase
      },
    ];
    return Wrap(
      spacing: 10,
      children: options.map((opt) {
        final label = opt['label'] as String;
        final value = opt['value'] as String;
        final icon = opt['icon'] as IconData;
        final sel = jobStatus == value;
        return ChoiceChip(
          avatar: Icon(
            icon,
            size: 16,
            color: sel ? brandRose : (isDark ? Colors.white70 : Colors.black54),
          ),
          label: Text(label),
          selected: sel,
          onSelected: (s) => onJobStatusChanged(s ? value : null),
          selectedColor: brandRose.withValues(alpha: 0.15),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          labelStyle: TextStyle(
            color: sel ? brandRose : (isDark ? Colors.white : Colors.black87),
            fontWeight: FontWeight.bold,
          ),
          shape: StadiumBorder(
            side: BorderSide(
              color:
                  sel ? brandRose : (isDark ? Colors.white24 : Colors.black12),
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  String _formatValue(String? raw, String lang) {
    if (raw == null) return '';
    final normalized = _normalizeLegacyValue(raw, {
      'Krščanstvo': 'christianity',
      'Islam': 'islam',
      'Hinduizem': 'hinduism',
      'Budizem': 'buddhism',
      'Judaizem': 'judaism',
      'Agnostik': 'agnostic',
      'Ateist': 'atheist',
      'Bela': 'ethnicity_white',
      'Črna': 'ethnicity_black',
      'Mešana': 'ethnicity_mixed',
      'Azijska': 'ethnicity_asian',
      'Blond': 'hair_blonde',
      'Rjavi': 'hair_brunette',
      'Črni': 'hair_black',
      'Rdeči': 'hair_red',
      'Sivi/Beli': 'hair_gray_white',
      'Drugo': 'hair_other',
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

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }
}

// ── Lifestyle section ─────────────────────────────────────────────────────────
class _LifestyleSection extends StatelessWidget {
  const _LifestyleSection({
    required this.nicotineUse,
    required this.nicotineUseToggle,
    required this.hasChildren,
    required this.drinkingHabit,
    required this.exerciseHabit,
    required this.sleepSchedule,
    required this.petPreference,
    required this.childrenPreference,
    required this.lang,
    required this.isDark,
    required this.textColor,
    required this.pillBg,
    required this.borderColor,
    required this.user,
    required this.isGenderBasedColor,
    required this.themeGender,
    required this.formatValue,
    required this.onNicotineUseToggleChanged,
    required this.onNicotineUseChanged,
    required this.onHasChildrenChanged,
    required this.onExerciseHabitChanged,
    required this.onDrinkingHabitChanged,
    required this.onSleepScheduleChanged,
    required this.onPetPreferenceChanged,
    required this.onChildrenPreferenceChanged,
  });

  final List<String> nicotineUse;
  final bool nicotineUseToggle;
  final bool? hasChildren;
  final String? drinkingHabit;
  final String? exerciseHabit;
  final String? sleepSchedule;
  final String? petPreference;
  final String? childrenPreference;
  final String lang;
  final bool isDark;
  final Color textColor;
  final Color pillBg;
  final Color borderColor;
  final AuthUser? user;
  final bool isGenderBasedColor;
  final String themeGender;
  final String Function(String?) formatValue;
  final void Function(bool) onNicotineUseToggleChanged;
  final void Function(List<String>) onNicotineUseChanged;
  final void Function(bool) onHasChildrenChanged;
  final void Function(String?) onExerciseHabitChanged;
  final void Function(String?) onDrinkingHabitChanged;
  final void Function(String?) onSleepScheduleChanged;
  final void Function(String?) onPetPreferenceChanged;
  final void Function(String?) onChildrenPreferenceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Nicotine & Children ───────────────────────────────────────────────
        _buildNicotineSelector(context),
        const SizedBox(height: 16),
        _buildChildrenSwitch(context),

        Divider(color: borderColor, height: 24),

        // ── Lifestyle Header (Centered, no icon) ─────────────────────────────
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

        // ── Lifestyle: pill rows + modals ────────────────────────────────────
        PreferencePillRow(
          icon: LucideIcons.zap,
          label: t('exercise', lang),
          values: [exerciseHabit],
          formatter: formatValue,
          iconMapper: IconUtils.getLifestyleIcon,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('exercise', lang),
              user: authUser,
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
              currentValue: exerciseHabit,
              onUpdate: onExerciseHabitChanged,
            );
          },
        ),
        const SizedBox(height: 12),

        PreferencePillRow(
          icon: LucideIcons.wine,
          label: t('alcohol', lang),
          values: [drinkingHabit],
          formatter: formatValue,
          iconMapper: IconUtils.getLifestyleIcon,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('alcohol', lang),
              user: authUser,
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
              currentValue: drinkingHabit,
              onUpdate: onDrinkingHabitChanged,
            );
          },
        ),
        const SizedBox(height: 12),

        PreferencePillRow(
          icon: LucideIcons.moon,
          label: t('sleep', lang),
          values: [sleepSchedule],
          formatter: formatValue,
          iconMapper: IconUtils.getLifestyleIcon,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('sleep', lang),
              user: authUser,
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
              currentValue: sleepSchedule,
              onUpdate: onSleepScheduleChanged,
            );
          },
        ),
        const SizedBox(height: 12),

        PreferencePillRow(
          icon: petPreference == 'cat' ? LucideIcons.cat : LucideIcons.dog,
          label: t('pets', lang),
          values: [petPreference],
          formatter: formatValue,
          iconMapper: IconUtils.getLifestyleIcon,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('pets', lang),
              user: authUser,
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
              currentValue: petPreference,
              onUpdate: onPetPreferenceChanged,
              allowOther: true,
            );
          },
        ),
        const SizedBox(height: 12),

        PreferencePillRow(
          icon: LucideIcons.baby,
          label: t('children', lang),
          values: [childrenPreference],
          formatter: formatValue,
          iconMapper: IconUtils.getLifestyleIcon,
          isGenderBasedColor: isGenderBasedColor,
          gender: themeGender,
          onEdit: () {
            final authUser = user;
            if (authUser == null) return;
            showPreferenceEditModal(
              context: context,
              title: t('children', lang),
              user: authUser,
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
                  'label': t('children_have_and_want_more', lang),
                  'value': 'have_and_want_more',
                  'icon': LucideIcons.users,
                },
                {
                  'label': t('children_have_and_dont_want_more', lang),
                  'value': 'have_and_dont_want_more',
                  'icon': LucideIcons.userCheck,
                },
                {
                  'label': t('children_not_sure', lang),
                  'value': 'not_sure',
                  'icon': LucideIcons.helpCircle,
                },
              ],
              currentValue: childrenPreference,
              onUpdate: onChildrenPreferenceChanged,
            );
          },
        ),
      ],
    );
  }

  Widget _buildNicotineSelector(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const nicotineProducts = [
      'cigarettes',
      'vape',
      'iqos',
      'zyn',
      'shisha',
    ];

    final productIcons = {
      'cigarettes': LucideIcons.cigarette,
      'vape': LucideIcons.wind,
      'iqos': LucideIcons.zap,
      'zyn': LucideIcons.square,
      'shisha': LucideIcons.flame,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            t('nicotine_title', lang),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          value: nicotineUseToggle,
          activeThumbColor: primary,
          activeTrackColor: primary.withValues(alpha: 0.3),
          inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
          onChanged: onNicotineUseToggleChanged,
        ),
        if (nicotineUseToggle) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nicotineProducts.map((key) {
              final sel = nicotineUse.contains(key);
              final icon = productIcons[key];
              return GestureDetector(
                onTap: () {
                  final next = [...nicotineUse];
                  if (sel) {
                    next.remove(key);
                  } else {
                    next.add(key);
                  }
                  onNicotineUseChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? primary.withValues(alpha: 0.15) : pillBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: sel
                          ? primary
                          : (isDark ? Colors.white24 : Colors.black12),
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 14,
                          color: sel
                              ? (isDark ? Colors.white : Colors.black)
                              : textColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        t('nicotine_$key', lang),
                        style: TextStyle(
                          color: sel
                              ? (isDark ? Colors.white : Colors.black)
                              : textColor,
                          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildChildrenSwitch(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(t('has_children', lang), style: TextStyle(color: textColor)),
      value: hasChildren ?? false,
      activeThumbColor: primary,
      activeTrackColor: primary.withValues(alpha: 0.3),
      inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
      onChanged: onHasChildrenChanged,
    );
  }
}

// ── Metrics section ───────────────────────────────────────────────────────────
class _MetricsSection extends StatelessWidget {
  const _MetricsSection({
    required this.introversionLevel,
    required this.isPremium,
    required this.lang,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.iconColor,
    required this.borderColor,
    required this.onIntroversionChanged,
  });

  final double introversionLevel;
  final bool isPremium;
  final String lang;
  final bool isDark;
  final Color textColor;
  final Color subColor;
  final Color iconColor;
  final Color borderColor;
  final void Function(double) onIntroversionChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: borderColor, height: 28),

        // ── Introvert / Extrovert ─────────────────────────────────────────────
        Center(
          child: _sectionLabel(
            t('introvert_extrovert', lang),
            LucideIcons.brain,
            centered: true,
          ),
        ),
        const SizedBox(height: 12),
        _buildIntrovertSlider(context),
        const SizedBox(height: 32),

        // ── Detection radius (fixed per tier) ─────────────────────────────
        // Backend uses RADIUS_FREE_M (100) / RADIUS_PRO_M (250), keyed off
        // isPremium — never user input. Shown as a static label, not a slider.
        Center(
          child: _sectionLabel(
            t('distance', lang),
            LucideIcons.map,
            centered: true,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetectionRadiusRow(context),

        Divider(color: borderColor, height: 28),
      ],
    );
  }

  Widget _sectionLabel(
    String label,
    IconData icon, {
    bool centered = false,
  }) {
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
      ],
    );
  }

  Widget _buildIntrovertSlider(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final percentLabel = introversionLevel <= 0.5
        ? '${((1.0 - introversionLevel) * 100).toInt()}% ${t('introvert', lang).toLowerCase()}'
        : '${(introversionLevel * 100).toInt()}% ${t('extrovert', lang).toLowerCase()}';
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
          value: introversionLevel,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: primary,
          inactiveColor: isDark ? Colors.white24 : Colors.black12,
          onChanged: onIntroversionChanged,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            percentLabel,
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionRadiusRow(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final radiusLabel = isPremium ? '250m' : '100m';
    return Text(
      radiusLabel,
      style: TextStyle(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }
}

// ── Preferences section ───────────────────────────────────────────────────────
class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection({
    required this.lookingFor,
    required this.languages,
    required this.lang,
    required this.isDark,
    required this.textColor,
    required this.subColor,
    required this.iconColor,
    required this.borderColor,
    required this.pillBg,
    required this.isGenderBasedColor,
    required this.themeGender,
    required this.languageOptions,
    required this.formatValue,
    required this.onLookingForChanged,
    required this.onLanguagesChanged,
  });

  final List<String> lookingFor;
  final List<String> languages;
  final String lang;
  final bool isDark;
  final Color textColor;
  final Color subColor;
  final Color iconColor;
  final Color borderColor;
  final Color pillBg;
  final bool isGenderBasedColor;
  final String themeGender;
  final List<Map<String, dynamic>> languageOptions;
  final String Function(String?) formatValue;
  final void Function(List<String>) onLookingForChanged;
  final void Function(List<String>) onLanguagesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Looking for ───────────────────────────────────────────────────────
        Row(
          children: [
            Icon(LucideIcons.heart, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Text(
              t('looking_for', lang),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _multiPill(
              lookingFor,
              iconMapper: IconUtils.getLookingForIcon,
            ),
            const SizedBox(width: 8),
            _editCircle(
              context,
              onTap: () => showMultiSelectModal(
                context: context,
                title: t('looking_for', lang),
                rowIcon: LucideIcons.heart,
                isGenderBased: isGenderBasedColor,
                gender: themeGender,
                options: [
                  {
                    'label': t('short_term_fun', lang),
                    'value': 'short_term_fun',
                    'icon': IconUtils.getLookingForIcon('short_term_fun'),
                  },
                  {
                    'label': t('long_term_partner', lang),
                    'value': 'long_term_partner',
                    'icon': IconUtils.getLookingForIcon('long_term_partner'),
                  },
                  {
                    'label': t('short_open_long', lang),
                    'value': 'short_open_long',
                    'icon': IconUtils.getLookingForIcon('short_open_long'),
                  },
                  {
                    'label': t('long_open_short', lang),
                    'value': 'long_open_short',
                    'icon': IconUtils.getLookingForIcon('long_open_short'),
                  },
                  {
                    'label': t('undecided', lang),
                    'value': 'undecided',
                    'icon': IconUtils.getLookingForIcon('undecided'),
                  },
                ],
                currentValues: lookingFor,
                onSave: onLookingForChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Languages ─────────────────────────────────────────────────────────
        Row(
          children: [
            Icon(LucideIcons.languages, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Text(
              t('i_speak', lang),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _multiPill(languages),
            const SizedBox(width: 8),
            _editCircle(
              context,
              onTap: () => showMultiSelectModal(
                context: context,
                title: t('i_speak', lang),
                rowIcon: LucideIcons.languages,
                isGenderBased: isGenderBasedColor,
                gender: themeGender,
                searchable: true,
                searchHint: 'Search language…',
                maxSelection: 5,
                options: languageOptions,
                currentValues: languages,
                onSave: onLanguagesChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _multiPill(
    List<String> values, {
    IconData? Function(String)? iconMapper,
  }) {
    final String display;
    IconData? icon;
    if (values.isEmpty) {
      display = '—';
    } else if (values.length == 1) {
      display = formatValue(values.first);
      icon = iconMapper?.call(values.first);
    } else {
      display = 'Selected ${values.length}';
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 130),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pillBg,
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

  Widget _editCircle(BuildContext context, {required VoidCallback onTap}) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pillBg,
          border: Border.all(
            color: isDark ? primary.withValues(alpha: 0.3) : borderColor,
          ),
        ),
        child: Icon(
          LucideIcons.pencil,
          size: 14,
          color: isDark ? primary : Colors.black38,
        ),
      ),
    );
  }
}

// ── Hobbies section ───────────────────────────────────────────────────────────
class _HobbiesSection extends StatelessWidget {
  const _HobbiesSection({
    required this.hobbies,
    required this.lang,
    required this.isDark,
    required this.textColor,
    required this.pillBg,
    required this.borderColor,
    required this.onEdit,
    required this.onRemoveHobby,
  });

  final List<Map<String, dynamic>> hobbies;
  final String lang;
  final bool isDark;
  final Color textColor;
  final Color pillBg;
  final Color borderColor;
  final VoidCallback onEdit;
  final void Function(Map<String, dynamic>) onRemoveHobby;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Hobbies ───────────────────────────────────────────────────────────
        Row(
          children: [
            const Spacer(),
            Text(
              t('hobbies', lang),
              style: GoogleFonts.instrumentSans(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _editCircle(context, onTap: onEdit),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCategorizedHobbies(),
      ],
    );
  }

  Widget _editCircle(BuildContext context, {required VoidCallback onTap}) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pillBg,
          border: Border.all(
            color: isDark ? primary.withValues(alpha: 0.3) : borderColor,
          ),
        ),
        child: Icon(
          LucideIcons.pencil,
          size: 14,
          color: isDark ? primary : Colors.black38,
        ),
      ),
    );
  }

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

  Widget _buildCategorizedHobbies() {
    if (hobbies.isEmpty) return const SizedBox.shrink();

    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final h in hobbies) {
      final cat = h['category'] as String? ?? 'Custom';
      grouped.putIfAbsent(cat, () => []).add(h);
    }

    return Column(
      children: [
        for (final entry in grouped.entries) ...[
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
            children: entry.value.map(_smallHobbyChip).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _smallHobbyChip(Map<String, dynamic> hobby) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hobby['emoji'] as String, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            HobbyData.hobbyDisplay(hobby, lang),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onRemoveHobby(hobby),
            child: Icon(
              LucideIcons.x,
              size: 10,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small age/zodiac pill ─────────────────────────────────────────────────────
class _AgePill extends StatelessWidget {
  const _AgePill(this.label, {required this.isDark, this.icon, this.pillBg});
  final String label;
  final bool isDark;
  final IconData? icon;
  final Color? pillBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: pillBg ??
            (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06)),
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
