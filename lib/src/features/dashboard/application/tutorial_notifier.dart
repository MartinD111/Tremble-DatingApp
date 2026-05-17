import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialState {
  final bool isActive;
  final int currentStep;

  const TutorialState({
    required this.isActive,
    required this.currentStep,
  });

  TutorialState copyWith({
    bool? isActive,
    int? currentStep,
  }) {
    return TutorialState(
      isActive: isActive ?? this.isActive,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class TutorialNotifier extends Notifier<TutorialState> {
  static const prefsKey = 'has_seen_premium_tutorial';
  static const lastStep = 5;

  @override
  TutorialState build() {
    return const TutorialState(isActive: false, currentStep: 0);
  }

  Future<void> checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(prefsKey) ?? false;
    if (!hasSeen) {
      state = const TutorialState(isActive: true, currentStep: 0);
    }
  }

  void nextStep() {
    if (state.currentStep < lastStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      return;
    }
    completeTutorial();
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> completeTutorial() async {
    state = const TutorialState(isActive: false, currentStep: 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, false);
    state = const TutorialState(isActive: true, currentStep: 0);
  }
}

final tutorialProvider = NotifierProvider<TutorialNotifier, TutorialState>(
  TutorialNotifier.new,
);
