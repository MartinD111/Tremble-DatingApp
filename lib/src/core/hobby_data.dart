// lib/src/core/hobby_data.dart
//
// Tremble Hobby Catalogue
//
// Canonical hobby list keyed by a **language-neutral snake_case ID**.
// Historically hobbies were stored by their display name (mixed EN + SL),
// which broke:
//   - Matching: user A "Hiking" ≠ user B "Pohodništvo" for the same hobby.
//   - Display: profile viewer saw hobbies in the other user's language.
//
// This module exposes:
//   - `predefinedHobbies`: canonical list with stable `id` + emoji + category.
//   - `displays`: per-locale display map (falls back through the chain
//     locale → en → canonical SL name → ID prettified).
//   - `hobbyDisplay(hobby, locale)`: safe lookup used by every widget render.
//   - `idForLegacyName(name)`: reverse map from historical display names
//     (both EN and SL variants) to canonical IDs — powers on-read migration
//     without a Firestore backfill.

class HobbyData {
  // Category keys used by translations.dart and hobby_categories.dart.
  static const String catActive = 'hobby_cat_active';
  static const String catLeisure = 'hobby_cat_leisure';
  static const String catArt = 'hobby_cat_art';
  static const String catTravel = 'hobby_cat_travel';

  // Canonical list. `id` is the source of truth. `name` remains for
  // legacy widget renders that don't have locale context yet — it holds
  // the Slovenian display and matches historical Firestore values.
  static const List<Map<String, dynamic>> predefinedHobbies = [
    // Active / Aktivni hobiji
    {
      'id': 'hiking',
      'name': 'Pohodništvo',
      'emoji': '🥾',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'cycling',
      'name': 'Kolesarjenje',
      'emoji': '🚴',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'swimming',
      'name': 'Plavanje',
      'emoji': '🏊',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'running',
      'name': 'Tek',
      'emoji': '🏃',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'climbing',
      'name': 'Plezanje',
      'emoji': '🧗',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'yoga',
      'name': 'Joga',
      'emoji': '🧘',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'pilates',
      'name': 'Pilates',
      'emoji': '🤸',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'fitness',
      'name': 'Fitnes',
      'emoji': '🏋️',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'calisthenics',
      'name': 'Kalistenika',
      'emoji': '💪',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'tennis',
      'name': 'Tenis',
      'emoji': '🎾',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'squash',
      'name': 'Skvoš',
      'emoji': '🏸',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'dance',
      'name': 'Ples',
      'emoji': '💃',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'bjj',
      'name': 'BJJ',
      'emoji': '🥋',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'karate',
      'name': 'Karate',
      'emoji': '🥋',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'taekwondo',
      'name': 'Taekwondo',
      'emoji': '🥋',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'judo',
      'name': 'Judo',
      'emoji': '🥋',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'mma',
      'name': 'Mixed martial arts',
      'emoji': '🥊',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'boxing',
      'name': 'Boks',
      'emoji': '🥊',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'skiing',
      'name': 'Smučanje',
      'emoji': '⛷️',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'snowboarding',
      'name': 'Bordanje',
      'emoji': '🏂',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'rollerblading',
      'name': 'Rolanje',
      'emoji': '🛼',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'iceskating',
      'name': 'Drsanje',
      'emoji': '⛸️',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'kayaking',
      'name': 'Kajak',
      'emoji': '🛶',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'sup',
      'name': 'SUP',
      'emoji': '🏄',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'sailing',
      'name': 'Jadranje',
      'emoji': '⛵',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'football',
      'name': 'Nogomet',
      'emoji': '⚽',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'basketball',
      'name': 'Košarka',
      'emoji': '🏀',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'volleyball',
      'name': 'Odbojka',
      'emoji': '🏐',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'skateboarding',
      'name': 'Skateboarding',
      'emoji': '🛹',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'ping_pong',
      'name': 'Ping pong',
      'emoji': '🏓',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'bowling',
      'name': 'Bowling',
      'emoji': '🎳',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'billiards',
      'name': 'Biljard',
      'emoji': '🎱',
      'category': catActive,
      'custom': false
    },
    {
      'id': 'fishing',
      'name': 'Ribolov',
      'emoji': '🎣',
      'category': catActive,
      'custom': false
    },

    // Leisure / Sprostitev
    {
      'id': 'books',
      'name': 'Knjige',
      'emoji': '📚',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'comics',
      'name': 'Stripi',
      'emoji': '🦸‍♂️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'video_games',
      'name': 'Videoigre',
      'emoji': '🎮',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'podcasts',
      'name': 'Podcasts',
      'emoji': '🎧',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'audiobooks',
      'name': 'Audiobooks',
      'emoji': '📖',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'gardening',
      'name': 'Vrtnarjenje',
      'emoji': '🪴',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'house_plants',
      'name': 'House plants',
      'emoji': '🌿',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'cooking',
      'name': 'Kuhanje',
      'emoji': '🍳',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'baking',
      'name': 'Baking',
      'emoji': '🧁',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'board_games',
      'name': 'Board games',
      'emoji': '🎲',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'chess',
      'name': 'Šah',
      'emoji': '♟️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'domino',
      'name': 'Domino',
      'emoji': '🁣',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'puzzles',
      'name': 'Puzzles',
      'emoji': '🧩',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'lego',
      'name': 'Lego',
      'emoji': '🧱',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'meditation',
      'name': 'Meditacija',
      'emoji': '🧘‍♀️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'collecting',
      'name': 'Collecting',
      'emoji': '🖼️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'journaling',
      'name': 'Journaling',
      'emoji': '📓',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'astronomy',
      'name': 'Astronomija',
      'emoji': '🔭',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'crosswords',
      'name': 'Reševanje križank',
      'emoji': '📝',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'sudoku',
      'name': 'Sudoku',
      'emoji': '🔢',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'rubiks_cube',
      'name': "Rubik's cube",
      'emoji': '🧊',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'language_learning',
      'name': 'Učenje novega jezika',
      'emoji': '🗣️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'horror',
      'name': 'Grozljivke',
      'emoji': '🧟',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'comedy',
      'name': 'Komedije',
      'emoji': '😂',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'thrillers',
      'name': 'Trilerji',
      'emoji': '🕵️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'drama',
      'name': 'Drame',
      'emoji': '🎭',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'romance',
      'name': 'Romantični filmi',
      'emoji': '❤️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'documentaries',
      'name': 'Dokumentarci',
      'emoji': '🎞️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'historical_films',
      'name': 'Historical films',
      'emoji': '🏛️',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'series',
      'name': 'Serije',
      'emoji': '📺',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'specialty_coffee',
      'name': 'Specialty coffee',
      'emoji': '☕',
      'category': catLeisure,
      'custom': false
    },
    {
      'id': 'specialty_tea',
      'name': 'Specialty tea',
      'emoji': '🍵',
      'category': catLeisure,
      'custom': false
    },

    // Art / Umetnost
    {
      'id': 'painting',
      'name': 'Slikanje',
      'emoji': '🎨',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'drawing',
      'name': 'Risanje',
      'emoji': '✏️',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'photography',
      'name': 'Fotografija',
      'emoji': '📸',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'pottery',
      'name': 'Oblikovanje gline',
      'emoji': '🏺',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'guitar',
      'name': 'Kitara',
      'emoji': '🎸',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'piano',
      'name': 'Klavir',
      'emoji': '🎹',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'drums',
      'name': 'Bobni',
      'emoji': '🥁',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'violin',
      'name': 'Violina',
      'emoji': '🎻',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'accordion',
      'name': 'Harmonika',
      'emoji': '🪗',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'saxophone',
      'name': 'Saksofon',
      'emoji': '🎷',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'clarinet',
      'name': 'Klarinet',
      'emoji': '🎵',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'flute',
      'name': 'Flavta',
      'emoji': '🎶',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'knitting',
      'name': 'Pletenje',
      'emoji': '🧶',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'crochet',
      'name': 'Kvačkanje',
      'emoji': '🧵',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'sewing',
      'name': 'Šivanje',
      'emoji': '🪡',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'graphic_design',
      'name': 'Grafični dizajn',
      'emoji': '💻',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'modeling_3d',
      'name': '3D modeliranje',
      'emoji': '🧊',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'poetry',
      'name': 'Poezija',
      'emoji': '✒️',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'blogging',
      'name': 'Blog',
      'emoji': '✍️',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'jewellery_making',
      'name': 'Izdelovanje nakita',
      'emoji': '💍',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'woodworking',
      'name': 'Obdelava lesa',
      'emoji': '🪚',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'calligraphy',
      'name': 'Kaligrafija',
      'emoji': '🖋️',
      'category': catArt,
      'custom': false
    },
    {
      'id': 'origami',
      'name': 'Origami',
      'emoji': '🕊️',
      'category': catArt,
      'custom': false
    },

    // Travel / Potovanja
    {
      'id': 'backpacking',
      'name': 'Backpacking',
      'emoji': '🎒',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'road_trips',
      'name': 'Road trips',
      'emoji': '🚗',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'camping',
      'name': 'Kampiranje',
      'emoji': '⛺',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'food_tourism',
      'name': 'Kulinarični turizem',
      'emoji': '🍽️',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'solo_travel',
      'name': 'Solo potovanja',
      'emoji': '🚶',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'zoos',
      'name': 'Živalski vrtovi',
      'emoji': '🦁',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'national_parks',
      'name': 'Nacionalni parki',
      'emoji': '🌲',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'geocaching',
      'name': 'Geocaching',
      'emoji': '🧭',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'museums',
      'name': 'Muzeji',
      'emoji': '🏛️',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'ruins',
      'name': 'Ruševine',
      'emoji': '🗿',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'galleries',
      'name': 'Galerije',
      'emoji': '🖼️',
      'category': catTravel,
      'custom': false
    },
    {
      'id': 'slow_travel',
      'name': 'Slow travel',
      'emoji': '🐌',
      'category': catTravel,
      'custom': false
    },
  ];

  /// Per-locale display map. Only includes locales where the display
  /// differs from the canonical `name` (Slovenian). Missing locales fall
  /// back to `en` then to the canonical `name`.
  static const Map<String, Map<String, String>> displays = {
    // Active
    'hiking': {'en': 'Hiking'},
    'cycling': {'en': 'Cycling'},
    'swimming': {'en': 'Swimming'},
    'running': {'en': 'Running'},
    'climbing': {'en': 'Climbing'},
    'yoga': {'en': 'Yoga'},
    'fitness': {'en': 'Fitness'},
    'calisthenics': {'en': 'Calisthenics'},
    'tennis': {'en': 'Tennis'},
    'squash': {'en': 'Squash'},
    'dance': {'en': 'Dance'},
    'boxing': {'en': 'Boxing'},
    'skiing': {'en': 'Skiing'},
    'snowboarding': {'en': 'Snowboarding'},
    'rollerblading': {'en': 'Rollerblading'},
    'iceskating': {'en': 'Ice skating'},
    'kayaking': {'en': 'Kayaking'},
    'sailing': {'en': 'Sailing'},
    'football': {'en': 'Football'},
    'basketball': {'en': 'Basketball'},
    'volleyball': {'en': 'Volleyball'},
    'billiards': {'en': 'Billiards'},
    'fishing': {'en': 'Fishing'},
    // Leisure
    'books': {'en': 'Books'},
    'comics': {'en': 'Comics'},
    'video_games': {'en': 'Video games'},
    'gardening': {'en': 'Gardening'},
    'cooking': {'en': 'Cooking'},
    'chess': {'en': 'Chess'},
    'meditation': {'en': 'Meditation'},
    'astronomy': {'en': 'Astronomy'},
    'crosswords': {'en': 'Crosswords'},
    'language_learning': {'en': 'Learning a new language'},
    'horror': {'en': 'Horror'},
    'comedy': {'en': 'Comedy'},
    'thrillers': {'en': 'Thrillers'},
    'drama': {'en': 'Drama'},
    'romance': {'en': 'Romance'},
    'documentaries': {'en': 'Documentaries'},
    'series': {'en': 'Series'},
    // Art
    'painting': {'en': 'Painting'},
    'drawing': {'en': 'Drawing'},
    'photography': {'en': 'Photography'},
    'pottery': {'en': 'Pottery'},
    'guitar': {'en': 'Guitar'},
    'piano': {'en': 'Piano'},
    'drums': {'en': 'Drums'},
    'violin': {'en': 'Violin'},
    'accordion': {'en': 'Accordion'},
    'saxophone': {'en': 'Saxophone'},
    'clarinet': {'en': 'Clarinet'},
    'flute': {'en': 'Flute'},
    'knitting': {'en': 'Knitting'},
    'crochet': {'en': 'Crochet'},
    'sewing': {'en': 'Sewing'},
    'graphic_design': {'en': 'Graphic design'},
    'modeling_3d': {'en': '3D modelling'},
    'poetry': {'en': 'Poetry'},
    'blogging': {'en': 'Blogging'},
    'jewellery_making': {'en': 'Jewellery making'},
    'woodworking': {'en': 'Woodworking'},
    'calligraphy': {'en': 'Calligraphy'},
    // Travel
    'camping': {'en': 'Camping'},
    'food_tourism': {'en': 'Food tourism'},
    'solo_travel': {'en': 'Solo travel'},
    'zoos': {'en': 'Zoos'},
    'national_parks': {'en': 'National parks'},
    'museums': {'en': 'Museums'},
    'ruins': {'en': 'Ruins'},
    'galleries': {'en': 'Galleries'},
  };

  /// Reverse map: any legacy display value (EN or SL, plus older
  /// translation keys) → canonical ID. Populated from `predefinedHobbies`
  /// and the `displays` table at first access.
  static Map<String, String>? _legacyIndex;

  static Map<String, String> _buildLegacyIndex() {
    final Map<String, String> map = {};
    for (final h in predefinedHobbies) {
      final id = h['id'] as String;
      map[id] = id;
      map[(h['name'] as String).toLowerCase()] = id;
      final loc = displays[id];
      if (loc != null) {
        for (final entry in loc.entries) {
          map[entry.value.toLowerCase()] = id;
        }
      }
    }
    // Older i18n keys that used to live in translations.dart.
    const oldKeyMap = {
      'hobby_fitness': 'fitness',
      'hobby_pilates': 'pilates',
      'hobby_walking': 'hiking',
      'hobby_running': 'running',
      'hobby_skiing': 'skiing',
      'hobby_snowboarding': 'snowboarding',
      'hobby_climbing': 'climbing',
      'hobby_swimming': 'swimming',
      'hobby_reading': 'books',
      'hobby_coffee': 'specialty_coffee',
      'hobby_tea': 'specialty_tea',
      'hobby_cooking': 'cooking',
      'hobby_series': 'series',
      'hobby_video_games': 'video_games',
      'hobby_painting': 'painting',
      'hobby_photography': 'photography',
      'hobby_museums': 'museums',
      'hobby_camping': 'camping',
    };
    map.addAll(oldKeyMap);
    return map;
  }

  /// Resolve any historical or new value to a canonical hobby ID.
  /// Returns `null` for values that don't match any known hobby
  /// (custom hobbies stay as-is).
  static String? idForLegacyName(String value) {
    _legacyIndex ??= _buildLegacyIndex();
    return _legacyIndex![value.toLowerCase()];
  }

  /// Fetch the predefined hobby map by ID. Returns `null` for custom.
  static Map<String, dynamic>? hobbyById(String id) {
    for (final h in predefinedHobbies) {
      if (h['id'] == id) return h;
    }
    return null;
  }

  /// Localized display for a hobby. Accepts either the map form
  /// emitted by `HobbyUtils.parseHobbies` or a bare ID/legacy string.
  /// Custom hobbies (`custom: true`) render their stored name verbatim.
  static String hobbyDisplay(dynamic hobby, String locale) {
    // Case 1: map form.
    if (hobby is Map) {
      if (hobby['custom'] == true) {
        return (hobby['name'] as String?) ?? '';
      }
      final id = hobby['id'] as String?;
      if (id != null) {
        return _displayFor(id, locale, fallback: hobby['name'] as String?);
      }
      final name = hobby['name'] as String?;
      if (name != null) {
        final mapped = idForLegacyName(name);
        if (mapped != null) return _displayFor(mapped, locale, fallback: name);
        return name;
      }
      return '';
    }
    // Case 2: bare string (id or legacy display).
    if (hobby is String) {
      final id = idForLegacyName(hobby) ?? hobby;
      final entry = hobbyById(id);
      return _displayFor(id, locale, fallback: entry?['name'] as String?);
    }
    return '';
  }

  static String _displayFor(String id, String locale, {String? fallback}) {
    final loc = displays[id];
    if (loc != null) {
      final direct = loc[locale];
      if (direct != null) return direct;
      final en = loc['en'];
      if (en != null && locale != 'sl') return en;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    final entry = hobbyById(id);
    if (entry != null) return entry['name'] as String;
    return id;
  }

  static Map<String, List<Map<String, dynamic>>> get groupedHobbies {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (var hobby in predefinedHobbies) {
      final category = hobby['category'] as String;
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(hobby);
    }
    return map;
  }
}
