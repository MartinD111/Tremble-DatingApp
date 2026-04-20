import 'dart:io';

void main() {
  var file = File('lib/src/features/auth/presentation/registration_flow.dart');
  var content = file.readAsStringSync();

  var restoreFunc = '''
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
    if (appUser.occupation != null) _customOccupationController.text = appUser.occupation!;
    _exerciseHabit = appUser.exerciseHabit;
    _drinkingHabit = appUser.drinkingHabit;
    _smokingHabit = appUser.isSmoker == true ? 'yes' : (appUser.isSmoker == false ? 'no' : null);
    _childrenPreference = appUser.childrenPreference;
    if (appUser.introvertScale != null) _introversionLevel = appUser.introvertScale! / 100.0;
    _sleepHabit = appUser.sleepSchedule;
    _petPreference = appUser.petPreference;
    _religion = appUser.religion;
    _ethnicity = appUser.ethnicity;
    _hairColor = appUser.hairColor;
    if (appUser.lookingFor.isNotEmpty) _datingPreference = appUser.lookingFor.first;
    if (appUser.interestedIn.isNotEmpty) _wantToMeet.addAll(appUser.interestedIn);
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
    if (appUser.partnerReligion != null) _partnerReligion = appUser.partnerReligion!.split(', ');
    if (appUser.partnerEthnicity != null) _partnerEthnicity = appUser.partnerEthnicity!.split(', ');
    if (appUser.partnerHairColor != null) _partnerHairColor = appUser.partnerHairColor!.split(', ');
    if (appUser.partnerExerciseHabit != null) _partnerExerciseHabit = appUser.partnerExerciseHabit!.split(', ');
    if (appUser.partnerDrinkingHabit != null) _partnerDrinkingHabit = appUser.partnerDrinkingHabit!.split(', ');
    if (appUser.partnerSleepSchedule != null) _partnerSleepHabit = appUser.partnerSleepSchedule!.split(', ');
    if (appUser.partnerPetPreference != null) _partnerPetPreference = appUser.partnerPetPreference!.split(', ');
    if (appUser.partnerChildrenPreference != null) _partnerChildrenPreference = appUser.partnerChildrenPreference!.split(', ');
    if (appUser.partnerSmokingPreference != null) _partnerSmokingHabit = appUser.partnerSmokingPreference!.split(', ');
    _partnerPoliticalAffiliationPreference = appUser.politicalAffiliationPreference;
    _partnerIntroversionRange = appUser.partnerIntrovertPreference;
    _partnerHeightRange = appUser.partnerHeightPreference;
  }
''';

  var initStateTarget = '''    if (currentUser != null) {
      // Pre-fill known fields for any authenticated user resuming onboarding
      _emailController.text = currentUser.email ?? '';
      if (isGoogleUser) {
        _nameController.text = currentUser.displayName ?? '';
      }
    }
    _currentPage = 0;''';

  var initStateReplacement = '''    if (currentUser != null) {
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
    }''';

  content = content.replaceFirst(initStateTarget, initStateReplacement);

  var nextPageTarget = '''    setState(() => _currentPage++);
  }''';

  var nextPageReplacement = '''    setState(() => _currentPage++);
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
        age: _birthDate != null ? (DateTime.now().difference(_birthDate!).inDays ~/ 365) : 20,
        birthDate: _birthDate,
        height: _heightCm,
        gender: _selectedGender ?? 'male',
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        interestedIn: _wantToMeet,
        isSmoker: _smokingHabit == 'yes',
        jobStatus: _status ?? 'student',
        occupation: _customOccupationController.text.isNotEmpty ? _customOccupationController.text : null,
        drinkingHabit: _drinkingHabit ?? 'never',
        introvertScale: (_introversionLevel * 100).toInt(),
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
                : ['politics_left', 'politics_center_left', 'politics_center', 'politics_center_right', 'politics_right'][(_politicalAffiliationValue - 1).toInt()],
        onboardingCheckpoint: index,
        isOnboarded: false,
      ).toApiPayload();
      
      await ref.read(authRepositoryProvider).updateRegistrationDraft(currentUser.uid, dump);
    } catch (e) {
      debugPrint("Failed to save checkpoint: \$e");
    }
  }''';

  content = content.replaceFirst(nextPageTarget, nextPageReplacement);
  content = content.replaceFirst(
      '  String tr(String key) => t(key, _selectedLanguage);',
      '  String tr(String key) => t(key, _selectedLanguage);\n\n' +
          restoreFunc);

  file.writeAsStringSync(content);
}
