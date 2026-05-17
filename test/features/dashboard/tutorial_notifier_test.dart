import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tremble/src/features/dashboard/application/tutorial_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('checkFirstLaunch activates tutorial when it has not been seen',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(tutorialProvider.notifier).checkFirstLaunch();

    final state = container.read(tutorialProvider);
    expect(state.isActive, isTrue);
    expect(state.currentStep, 0);
  });

  test('completeTutorial hides tutorial and persists seen flag', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(tutorialProvider.notifier);

    await notifier.checkFirstLaunch();
    await notifier.completeTutorial();

    final prefs = await SharedPreferences.getInstance();
    expect(container.read(tutorialProvider).isActive, isFalse);
    expect(prefs.getBool(TutorialNotifier.prefsKey), isTrue);
  });

  test('resetTutorial clears seen flag and starts from first step', () async {
    SharedPreferences.setMockInitialValues({
      TutorialNotifier.prefsKey: true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(tutorialProvider.notifier).resetTutorial();

    final prefs = await SharedPreferences.getInstance();
    final state = container.read(tutorialProvider);
    expect(state.isActive, isTrue);
    expect(state.currentStep, 0);
    expect(prefs.getBool(TutorialNotifier.prefsKey), isFalse);
  });
}
