import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('run recap wires premium TTL and free read-only card states', () {
    final source = File(
      'lib/src/features/dashboard/presentation/run_recap_screen.dart',
    ).readAsStringSync();

    expect(source, contains('effectiveIsPremiumProvider'));
    expect(source, contains('recapTTLProvider(widget.partnerId)'));
    expect(source, contains('.notifier).start()'));
    expect(source, contains('ColorFilter.mode'));
    expect(source, contains('Colors.grey'));
    expect(source, contains('BlendMode.saturation'));
    expect(source, contains('remainingSeconds'));
    expect(source, contains('~/ 60'));
    expect(source, contains("padLeft(2, '0')"));
  });

  test('matches locked recap paywall opens the premium bottom sheet', () {
    final source = File(
      'lib/src/features/matches/presentation/matches_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('TODO: odpri paywall')));
    expect(source, contains('PremiumPaywallBottomSheet.show'));
  });
}
