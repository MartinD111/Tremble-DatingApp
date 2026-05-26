import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/recap/providers/recap_ttl_provider.dart';

void main() {
  test('recap TTL does not start until start is called', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(recapTTLProvider('recap-1')).remainingSeconds, 600);

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(container.read(recapTTLProvider('recap-1')).remainingSeconds, 600);
    expect(container.read(recapTTLProvider('recap-1')).isExpired, isFalse);
  });

  test('recap TTL start decrements once and does not double-start', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(recapTTLProvider('recap-1').notifier);
    notifier.start();
    notifier.start();

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(container.read(recapTTLProvider('recap-1')).remainingSeconds, 599);
    expect(container.read(recapTTLProvider('recap-1')).isExpired, isFalse);
  });
}
