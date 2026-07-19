import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Match reveal UX repair (cluster 5b/5c): the invisible tap-anywhere gesture
/// became an explicit "Start radar" button (users felt stuck), and the free
/// card now shows up to 3 shared/partner hobbies.
void main() {
  final source =
      File('lib/src/features/match/presentation/match_reveal_screen.dart')
          .readAsStringSync();

  test('reveal uses an explicit Start radar button, not tap-anywhere', () {
    expect(source, contains('_StartRadarButton'));
    expect(source, contains("'Start radar'"));
    expect(source, isNot(contains('Tap anywhere to start radar')));
  });

  test('reveal renders common hobby chips from partner + my hobbies', () {
    expect(source, contains('_pickCommonHobbies'));
    expect(source, contains('_HobbyChip'));
    expect(source, contains('commonHobbies'));
  });
}
