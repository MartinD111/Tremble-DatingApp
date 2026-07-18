import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/api_client.dart';
import 'package:tremble/src/features/match/presentation/wave_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Wave UI call sites guard monthly limit (Free+Pro) before sendWave', () {
    final profileDetail =
        File('lib/src/features/profile/presentation/profile_detail_screen.dart')
            .readAsStringSync();
    final matchDialog =
        File('lib/src/features/matches/presentation/match_dialog.dart')
            .readAsStringSync();
    final router = File('lib/src/core/router.dart').readAsStringSync();

    for (final source in [profileDetail, matchDialog]) {
      expect(source, contains('hasReachedWaveLimit'));
      expect(source, contains('PremiumPaywallBottomSheet.show(context)'));
    }
    // The router's shared pill presenter shows the paywall from the overlay's
    // context (the navigator context resolves to null — see
    // root_overlay_resolution_test.dart), but still guards the limit first.
    expect(router, contains('hasReachedWaveLimit'));
    expect(router, contains('PremiumPaywallBottomSheet.show(overlay.context)'));
  });

  test('profile Wave UI uses optimistic AsyncValue state with inline rollback',
      () {
    final waveController =
        File('lib/src/features/match/presentation/wave_controller.dart')
            .readAsStringSync();
    final profileDetail =
        File('lib/src/features/profile/presentation/profile_detail_screen.dart')
            .readAsStringSync();

    expect(waveController, contains('class WaveSendState'));
    expect(waveController, contains('state = AsyncData(optimisticValue);'));
    expect(waveController, contains('withInlineError('));
    expect(waveController, contains('Wave ni bil poslan. Poskusi znova.'));
    expect(profileDetail, contains('ref.watch(waveControllerProvider)'));
    expect(profileDetail, contains('inlineErrorMessage'));
    expect(profileDetail, contains('inlineErrorFor(match.id)'));
    expect(
      profileDetail,
      isNot(contains(
          "SnackBar(content: Text('Wave ni bil poslan. Poskusi znova.'))")),
    );
  });

  test('WaveRepository routes sendWave through TrembleApiClient', () {
    final waveRepository =
        File('lib/src/features/match/data/wave_repository.dart')
            .readAsStringSync();

    expect(waveRepository, contains("TrembleApiClient()"));
    expect(waveRepository, contains("_api.call('sendWave'"));
    expect(waveRepository, isNot(contains("httpsCallable('sendWave')")));
    expect(waveRepository, isNot(contains('FirebaseFunctions.instanceFor')));
  });

  test('Wave write failures render inline instead of SnackBars', () {
    final matchDialog =
        File('lib/src/features/matches/presentation/match_dialog.dart')
            .readAsStringSync();
    final liveRunCard = File(
      'lib/src/features/dashboard/presentation/widgets/live_run_card.dart',
    ).readAsStringSync();
    final runRecap =
        File('lib/src/features/dashboard/presentation/run_recap_screen.dart')
            .readAsStringSync();
    final wavePill = File(
      'lib/src/features/match/presentation/widgets/match_notification_pill.dart',
    ).readAsStringSync();
    final homeScreen =
        File('lib/src/features/dashboard/presentation/home_screen.dart')
            .readAsStringSync();

    for (final source in [matchDialog, liveRunCard, runRecap, wavePill]) {
      expect(source, contains('Ni uspelo. Poskusi znova.'));
      expect(source, contains('TrembleTheme.rose'));
    }

    expect(
        matchDialog,
        isNot(contains(
            "SnackBar(\n          content: Text(t('greet_failed', lang))")));
    expect(runRecap,
        isNot(contains("SnackBar(content: Text(t('wave_failed', lang)))")));
    expect(homeScreen,
        isNot(contains("SnackBar(content: Text(t('wave_failed', lang)))")));
    expect(homeScreen, isNot(contains('LiveRunCard sendWave error:')));
    expect(homeScreen, isNot(contains('WavePill sendWave error:')));
  });

  test('WaveController sets optimistic data before write and rolls back inline',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final writeCompleter = Completer<void>();
    final future = container.read(waveControllerProvider.notifier).handleWave(
          'target-user',
          writeWave: () => writeCompleter.future,
        );

    final optimistic = container.read(waveControllerProvider).requireValue;
    expect(optimistic.isOptimisticFor('target-user'), isTrue);
    expect(optimistic.inlineErrorFor('target-user'), isNull);

    writeCompleter.completeError(Exception('network failed'));
    await future;

    final rolledBack = container.read(waveControllerProvider).requireValue;
    expect(rolledBack.isOptimisticFor('target-user'), isFalse);
    expect(
      rolledBack.inlineErrorFor('target-user'),
      'Wave ni bil poslan. Poskusi znova.',
    );
  });

  test('WaveController surfaces actionable permission-denied API message',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(waveControllerProvider.notifier).handleWave(
      'target-user',
      writeWave: () async {
        throw TrembleApiException(
          code: 'permission-denied',
          message: "You can't wave at this person right now.",
        );
      },
    );

    final rolledBack = container.read(waveControllerProvider).requireValue;
    expect(
      rolledBack.inlineErrorFor('target-user'),
      "You can't wave at this person right now.",
    );
  });
}
