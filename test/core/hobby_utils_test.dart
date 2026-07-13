import 'package:flutter_test/flutter_test.dart';
import 'package:tremble/src/core/hobby_data.dart';
import 'package:tremble/src/core/hobby_utils.dart';

void main() {
  group('HobbyUtils.parseHobbies — legacy display-name → ID migration', () {
    test('EN legacy string "Hiking" maps to id="hiking"', () {
      final parsed = HobbyUtils.parseHobbies(['Hiking']);
      expect(parsed, hasLength(1));
      expect(parsed.first['id'], 'hiking');
      expect(parsed.first['custom'], false);
    });

    test('SL legacy string "Pohodništvo" maps to id="hiking"', () {
      final parsed = HobbyUtils.parseHobbies(['Pohodništvo']);
      expect(parsed, hasLength(1));
      expect(parsed.first['id'], 'hiking');
    });

    test(
        'EN and SL legacy strings resolve to the SAME id — this is the '
        'cross-locale matching bug the migration exists to fix', () {
      final userA = HobbyUtils.parseHobbies(['Hiking']);
      final userB = HobbyUtils.parseHobbies(['Pohodništvo']);
      expect(userA.first['id'], userB.first['id']);
    });

    test('older translation-key values (hobby_running) map to canonical id',
        () {
      final parsed = HobbyUtils.parseHobbies(['hobby_running']);
      expect(parsed.first['id'], 'running');
    });

    test('map input with only legacy "name" is enriched with canonical id', () {
      final parsed = HobbyUtils.parseHobbies([
        {'name': 'Pohodništvo', 'emoji': '🥾', 'category': HobbyData.catActive},
      ]);
      expect(parsed.first['id'], 'hiking');
      expect(parsed.first['category'], HobbyData.catActive);
    });

    test('map input with new-format "id" resolves via predefined catalogue',
        () {
      final parsed = HobbyUtils.parseHobbies([
        {'id': 'bjj'},
      ]);
      expect(parsed.first['id'], 'bjj');
      expect(parsed.first['name'], 'BJJ');
      expect(parsed.first['category'], HobbyData.catActive);
    });

    test('custom hobby preserved with id empty and custom=true', () {
      final parsed = HobbyUtils.parseHobbies([
        {'name': 'Homebrew mead-making', 'custom': true, 'emoji': '🍯'},
      ]);
      expect(parsed.first['custom'], true);
      expect(parsed.first['id'], '');
      expect(parsed.first['name'], 'Homebrew mead-making');
    });

    test('unknown string becomes a custom entry (no crash)', () {
      final parsed = HobbyUtils.parseHobbies(['Underwater basket weaving']);
      expect(parsed.first['custom'], true);
      expect(parsed.first['name'], 'Underwater basket weaving');
      expect(parsed.first['id'], '');
    });

    test('null and non-list inputs return empty list', () {
      expect(HobbyUtils.parseHobbies(null), isEmpty);
      expect(HobbyUtils.parseHobbies('not-a-list'), isEmpty);
      expect(HobbyUtils.parseHobbies({}), isEmpty);
    });
  });

  group('HobbyData.hobbyDisplay — locale-aware rendering', () {
    test('English locale renders EN display for a Slovenian-canonical hobby',
        () {
      final hiking = HobbyData.hobbyById('hiking')!;
      expect(HobbyData.hobbyDisplay(hiking, 'en'), 'Hiking');
    });

    test('Slovenian locale keeps the canonical Slovenian display', () {
      final hiking = HobbyData.hobbyById('hiking')!;
      expect(HobbyData.hobbyDisplay(hiking, 'sl'), 'Pohodništvo');
    });

    test('Locale without an explicit translation falls back to EN', () {
      final hiking = HobbyData.hobbyById('hiking')!;
      expect(HobbyData.hobbyDisplay(hiking, 'hu'), 'Hiking');
    });

    test('Custom hobby renders the stored name verbatim in any locale', () {
      final custom = {
        'id': '',
        'name': 'Homebrew mead-making',
        'custom': true,
      };
      expect(HobbyData.hobbyDisplay(custom, 'en'), 'Homebrew mead-making');
      expect(HobbyData.hobbyDisplay(custom, 'sl'), 'Homebrew mead-making');
    });

    test(
        'Language-neutral hobbies (SUP, BJJ) use the canonical name in every '
        'locale — no forced English translation', () {
      final sup = HobbyData.hobbyById('sup')!;
      expect(HobbyData.hobbyDisplay(sup, 'en'), 'SUP');
      expect(HobbyData.hobbyDisplay(sup, 'sl'), 'SUP');
      expect(HobbyData.hobbyDisplay(sup, 'de'), 'SUP');
    });
  });

  group('HobbyUtils.toStorage — write path emits canonical IDs', () {
    test('predefined hobbies serialise to their canonical id', () {
      final list = [
        HobbyData.hobbyById('hiking')!,
        HobbyData.hobbyById('bjj')!,
      ];
      expect(HobbyUtils.toStorage(list), ['hiking', 'bjj']);
    });

    test('custom hobbies serialise to their display name', () {
      final list = [
        {
          'id': '',
          'name': 'Homebrew mead-making',
          'custom': true,
        },
      ];
      expect(HobbyUtils.toStorage(list), ['Homebrew mead-making']);
    });
  });
}
