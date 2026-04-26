import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matches/data/match_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// In-memory dev-only cache of mock matches that completed a mutual-wave
// simulation. Lives for the duration of the app session.
//
// The Matches tab merges this list with the real `matchesStreamProvider` so
// dev-injected profiles appear alongside server-backed matches without
// touching Firestore.
// ─────────────────────────────────────────────────────────────────────────────
class DevMockMatches extends StateNotifier<List<MatchProfile>> {
  DevMockMatches() : super(const []);

  void add(MatchProfile profile) {
    if (state.any((m) => m.id == profile.id)) return;
    state = [profile, ...state];
  }

  void clear() => state = const [];
}

final devMockMatchesProvider =
    StateNotifierProvider<DevMockMatches, List<MatchProfile>>((ref) {
  return DevMockMatches();
});
