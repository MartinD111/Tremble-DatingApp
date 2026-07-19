import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';

MatchProfile _profile(String id) => MatchProfile(
      id: id,
      name: 'Name-$id',
      age: 25,
      imageUrl: 'https://example.com/$id.jpg',
      hobbies: const [],
      bio: '',
      photoUrls: ['https://example.com/$id.jpg'],
    );

void main() {
  group('partnerMatchProfileProvider', () {
    test('resolves the partner MatchProfile by id from the matches stream',
        () async {
      final container = ProviderContainer(
        overrides: [
          matchesStreamProvider.overrideWith(
            (ref) => Stream.value([_profile('p1'), _profile('p2')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Settle the upstream stream before reading the derived provider.
      await container.read(matchesStreamProvider.future);

      final result = container.read(partnerMatchProfileProvider('p1'));
      expect(result.hasValue, isTrue);
      expect(result.value?.id, 'p1');
      expect(result.value?.name, 'Name-p1');
    });

    test('resolves to data(null) — not "?" — when the partner is absent',
        () async {
      final container = ProviderContainer(
        overrides: [
          matchesStreamProvider.overrideWith(
            (ref) => Stream.value([_profile('p1')]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(matchesStreamProvider.future);

      final missing = container.read(partnerMatchProfileProvider('ghost'));
      expect(missing.hasValue, isTrue,
          reason: 'absent partner must be a resolved null, not loading/error');
      expect(missing.value, isNull);
    });

    test('stays loading while the matches stream has not emitted', () {
      final container = ProviderContainer(
        overrides: [
          matchesStreamProvider.overrideWith(
            (ref) => const Stream<List<MatchProfile>>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(partnerMatchProfileProvider('p1'));
      expect(result.isLoading, isTrue);
    });
  });
}
