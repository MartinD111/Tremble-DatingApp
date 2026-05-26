import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/matches/data/match_repository.dart';
import 'package:tremble/src/features/recap/data/viewed_recaps_repository.dart';

void main() {
  test('free users hide matches with viewed event recap id', () {
    final profile = MatchProfile(
      id: 'partner-1',
      name: 'Lina',
      age: 28,
      imageUrl: '',
      hobbies: const [],
      bio: '',
      matchType: 'event',
      matchContext: const MatchContext(eventId: 'event-123'),
    );

    expect(
      shouldHideViewedMatchRecap(
        isPremium: false,
        profile: profile,
        viewedRecapIds: const {'event-123'},
      ),
      isTrue,
    );
  });

  test('free users hide matches with viewed run match id', () {
    final profile = MatchProfile(
      id: 'partner-1',
      name: 'Lina',
      age: 28,
      imageUrl: '',
      hobbies: const [],
      bio: '',
      matchType: 'activity',
    );

    expect(
      shouldHideViewedMatchRecap(
        isPremium: false,
        profile: profile,
        viewedRecapIds: const {'me_partner-1'},
        matchId: 'me_partner-1',
      ),
      isTrue,
    );
  });

  test('pro users never hide viewed recap history', () {
    final profile = MatchProfile(
      id: 'partner-1',
      name: 'Lina',
      age: 28,
      imageUrl: '',
      hobbies: const [],
      bio: '',
      matchType: 'gym',
      matchContext: const MatchContext(gymPlaceId: 'gym-123'),
    );

    expect(
      shouldHideViewedMatchRecap(
        isPremium: true,
        profile: profile,
        viewedRecapIds: const {'gym-123', 'partner-1'},
      ),
      isFalse,
    );
  });
}
