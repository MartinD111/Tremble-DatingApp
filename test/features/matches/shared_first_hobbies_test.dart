import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/features/matches/presentation/matches_screen.dart';

Map<String, dynamic> _h(String id, [String? name]) =>
    {'id': id, 'name': name ?? id};

void main() {
  group('sharedFirstHobbyNames', () {
    test('puts shared hobbies (matched by id) first, then the rest', () {
      final mine = [_h('climbing'), _h('coffee')];
      final partner = [_h('running'), _h('coffee'), _h('painting')];

      // coffee is shared -> first; running/painting follow in partner order.
      expect(
        sharedFirstHobbyNames(mine, partner),
        ['coffee', 'running', 'painting'],
      );
    });

    test('caps at max (default 3)', () {
      final partner = [_h('a'), _h('b'), _h('c'), _h('d')];
      expect(sharedFirstHobbyNames(const [], partner), ['a', 'b', 'c']);
    });

    test('is deterministic across calls (no shuffle)', () {
      final mine = [_h('x')];
      final partner = [_h('p'), _h('q'), _h('r'), _h('s')];
      expect(
        sharedFirstHobbyNames(mine, partner),
        sharedFirstHobbyNames(mine, partner),
      );
    });

    test('skips empty names and tolerates missing ids', () {
      final partner = [
        {'name': ''},
        {'name': 'yoga'},
        {'emoji': '✨'},
      ];
      expect(sharedFirstHobbyNames(const [], partner), ['yoga']);
    });

    test('returns empty when the partner has no hobbies', () {
      expect(sharedFirstHobbyNames([_h('a')], const []), isEmpty);
    });
  });
}
