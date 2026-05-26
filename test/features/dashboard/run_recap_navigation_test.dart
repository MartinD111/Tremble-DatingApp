import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/dashboard/presentation/run_recap_screen.dart';
import 'package:tremble/src/features/profile/domain/public_profile.dart';

void main() {
  group('run recap profile navigation', () {
    test('builds the MatchProfile extra expected by the profile route', () {
      final publicProfile = PublicProfile(
        id: 'partner-123',
        name: 'Maja',
        age: 29,
        photoUrls: const ['https://example.com/maja.jpg'],
        hobbies: const [
          {'id': 'running', 'label': 'Running'},
        ],
        isTraveler: true,
      );

      final match = runRecapMatchProfileFromPublicProfile(publicProfile);

      expect(match.id, 'partner-123');
      expect(match.name, 'Maja');
      expect(match.age, 29);
      expect(match.imageUrl, 'https://example.com/maja.jpg');
      expect(match.photoUrls, ['https://example.com/maja.jpg']);
      expect(match.hobbies, [
        {'id': 'running', 'label': 'Running'},
      ]);
      expect(match.isTraveler, isTrue);
      expect(match.matchType, 'activity');
    });
  });
}
