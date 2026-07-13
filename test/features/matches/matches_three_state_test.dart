import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:tremble/src/features/matches/presentation/matches_screen.dart';

MatchProfile _profile({
  required String id,
  required bool hasMutualWave,
  String matchType = 'standard',
}) =>
    MatchProfile(
      id: id,
      name: 'Test $id',
      age: 25,
      imageUrl: 'https://example.test/$id.jpg',
      hobbies: const [],
      bio: '',
      matchType: matchType,
      hasMutualWave: hasMutualWave,
    );

void main() {
  group('ADR-007 §1 — resolveMatchDisplayState', () {
    // ── Non-near-miss (standard match) three-state pipeline ──

    test(
        'non-mutual match on Free tier lands in nonMutual (State A — '
        'greyscaled minimal shape)', () {
      expect(
        resolveMatchDisplayState(
          profile: _profile(id: 'a', hasMutualWave: false),
          isPremium: false,
        ),
        MatchDisplayState.nonMutual,
      );
    });

    test(
        'non-mutual match on Premium tier ALSO lands in nonMutual — '
        'Premium falls back to the same greyed shape when no mutual '
        'wave exists', () {
      // Compound-gate contract: neither condition alone unlocks the
      // card. Premium without mutual wave = greyed minimal shape.
      expect(
        resolveMatchDisplayState(
          profile: _profile(id: 'b', hasMutualWave: false),
          isPremium: true,
        ),
        MatchDisplayState.nonMutual,
      );
    });

    test(
        'mutual wave + Free tier lands in mutualFree (State B — '
        'colour + name + age, tap surfaces upsell)', () {
      expect(
        resolveMatchDisplayState(
          profile: _profile(id: 'c', hasMutualWave: true),
          isPremium: false,
        ),
        MatchDisplayState.mutualFree,
      );
    });

    test(
        'mutual wave + Premium tier lands in mutualPremium (State C — '
        'full profile card openable, compound gate satisfied)', () {
      expect(
        resolveMatchDisplayState(
          profile: _profile(id: 'd', hasMutualWave: true),
          isPremium: true,
        ),
        MatchDisplayState.mutualPremium,
      );
    });

    // ── Near-miss (matchType == 'activity') keeps its own gate ──

    test(
        'near-miss match on Free tier lands in nearMissLocked '
        'regardless of hasMutualWave', () {
      for (final hasMutualWave in const [true, false]) {
        expect(
          resolveMatchDisplayState(
            profile: _profile(
              id: 'nm-$hasMutualWave',
              hasMutualWave: hasMutualWave,
              matchType: 'activity',
            ),
            isPremium: false,
          ),
          MatchDisplayState.nearMissLocked,
          reason: 'near-miss overrides the mutual-wave pipeline for Free',
        );
      }
    });

    test(
        'near-miss match on Premium tier lands in nearMissReadOnly '
        'regardless of hasMutualWave', () {
      for (final hasMutualWave in const [true, false]) {
        expect(
          resolveMatchDisplayState(
            profile: _profile(
              id: 'nmr-$hasMutualWave',
              hasMutualWave: hasMutualWave,
              matchType: 'activity',
            ),
            isPremium: true,
          ),
          MatchDisplayState.nearMissReadOnly,
          reason: 'near-miss overrides the mutual-wave pipeline for Premium',
        );
      }
    });

    // ── Compound-gate invariant: only mutualPremium opens the full card ──

    test(
        'compound gate — only isPremium && hasMutualWave unlocks the '
        'full card (mutualPremium)', () {
      // Enumerate the four permutations for non-near-miss profiles.
      // Only (Premium, mutual) satisfies the compound gate.
      const combos = <(bool, bool, MatchDisplayState)>[
        (false, false, MatchDisplayState.nonMutual),
        (false, true, MatchDisplayState.mutualFree),
        (true, false, MatchDisplayState.nonMutual),
        (true, true, MatchDisplayState.mutualPremium),
      ];
      for (final (isPremium, hasMutualWave, expected) in combos) {
        expect(
          resolveMatchDisplayState(
            profile: _profile(id: 'x', hasMutualWave: hasMutualWave),
            isPremium: isPremium,
          ),
          expected,
          reason: 'isPremium=$isPremium, hasMutualWave=$hasMutualWave',
        );
      }
    });
  });

  group('ADR-007 §1 — MatchProfile.hasMutualWave DTO contract', () {
    test(
        'defaults to false when not specified (backward compatible '
        'with mock data and direct constructor callers)', () {
      final profile = MatchProfile(
        id: 'legacy',
        name: 'Legacy',
        age: 30,
        imageUrl: '',
        hobbies: const [],
        bio: '',
      );
      expect(profile.hasMutualWave, false);
    });

    test('MatchProfile.fromApi reads hasMutualWave from response payload', () {
      final profile = MatchProfile.fromApi({
        'id': 'from-api',
        'name': 'From API',
        'age': 27,
        'photoUrls': <String>[],
        'hobbies': <Map<String, dynamic>>[],
        'hasMutualWave': true,
      });
      expect(profile.hasMutualWave, true);
    });

    test(
        'MatchProfile.fromApi defaults hasMutualWave to false when the '
        'field is missing (older CF responses during rollout)', () {
      final profile = MatchProfile.fromApi({
        'id': 'no-field',
        'name': 'No Field',
        'age': 27,
        'photoUrls': <String>[],
        'hobbies': <Map<String, dynamic>>[],
      });
      expect(profile.hasMutualWave, false);
    });
  });
}
