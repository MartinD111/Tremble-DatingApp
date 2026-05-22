import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TutorialPhase { hidden, optIn, active }

class TutorialState {
  final TutorialPhase phase;
  final int currentStep;
  final bool isPopupActive;

  const TutorialState({
    required this.phase,
    required this.currentStep,
    this.isPopupActive = false,
  });

  bool get isActive => phase == TutorialPhase.active;
  bool get showOptIn => phase == TutorialPhase.optIn;

  TutorialState copyWith({
    TutorialPhase? phase,
    int? currentStep,
    bool? isPopupActive,
  }) {
    return TutorialState(
      phase: phase ?? this.phase,
      currentStep: currentStep ?? this.currentStep,
      isPopupActive: isPopupActive ?? this.isPopupActive,
    );
  }
}

class TutorialNotifier extends Notifier<TutorialState> {
  static const prefsKey = 'has_seen_premium_tutorial';
  static const lastStep = 5;

  @override
  TutorialState build() {
    return const TutorialState(
      phase: TutorialPhase.hidden,
      currentStep: 0,
      isPopupActive: false,
    );
  }

  Future<void> checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(prefsKey) ?? false;
    if (!hasSeen) {
      state = const TutorialState(
        phase: TutorialPhase.optIn,
        currentStep: 0,
        isPopupActive: false,
      );
    }
  }

  void startTutorial() {
    state = const TutorialState(
      phase: TutorialPhase.active,
      currentStep: 0,
      isPopupActive: false,
    );
  }

  void setPopupActive(bool active) {
    if (state.isActive) {
      state = state.copyWith(isPopupActive: active);
    }
  }

  Future<void> nextStep() async {
    if (!state.isActive) return;
    if (state.currentStep < lastStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      return;
    }
    await completeTutorial();
  }

  void previousStep() {
    if (state.isActive && state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> completeTutorial() async {
    state = const TutorialState(phase: TutorialPhase.hidden, currentStep: 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, false);
    state = const TutorialState(phase: TutorialPhase.optIn, currentStep: 0);
  }
}

final tutorialProvider = NotifierProvider<TutorialNotifier, TutorialState>(
  TutorialNotifier.new,
);

final tutorialTargetRectsProvider =
    StateProvider<Map<int, Rect>>((ref) => const {});
