// lib/src/core/hobby_categories.dart
//
// Tremble Hobby Categories — Compatibility Layer
//
// Category classifier used by compatibility scoring and the
// CommonTraitsWidget. Keyed by the canonical hobby ID from
// hobby_data.dart. Legacy display-name inputs are normalised via
// `HobbyData.idForLegacyName`, so callers holding old strings keep
// working without a migration.

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'hobby_data.dart';

enum HobbyCategory {
  active, // hobby_cat_active
  leisure, // hobby_cat_leisure
  art, // hobby_cat_art
  travel, // hobby_cat_travel
}

class HobbyCategories {
  static const Map<String, HobbyCategory> _idToCategory = {
    // Active
    'hiking': HobbyCategory.active,
    'cycling': HobbyCategory.active,
    'swimming': HobbyCategory.active,
    'running': HobbyCategory.active,
    'climbing': HobbyCategory.active,
    'yoga': HobbyCategory.active,
    'pilates': HobbyCategory.active,
    'fitness': HobbyCategory.active,
    'calisthenics': HobbyCategory.active,
    'tennis': HobbyCategory.active,
    'squash': HobbyCategory.active,
    'dance': HobbyCategory.active,
    'bjj': HobbyCategory.active,
    'karate': HobbyCategory.active,
    'taekwondo': HobbyCategory.active,
    'judo': HobbyCategory.active,
    'mma': HobbyCategory.active,
    'boxing': HobbyCategory.active,
    'skiing': HobbyCategory.active,
    'snowboarding': HobbyCategory.active,
    'rollerblading': HobbyCategory.active,
    'iceskating': HobbyCategory.active,
    'kayaking': HobbyCategory.active,
    'sup': HobbyCategory.active,
    'sailing': HobbyCategory.active,
    'football': HobbyCategory.active,
    'basketball': HobbyCategory.active,
    'volleyball': HobbyCategory.active,
    'skateboarding': HobbyCategory.active,
    'ping_pong': HobbyCategory.active,
    'bowling': HobbyCategory.active,
    'billiards': HobbyCategory.active,
    'fishing': HobbyCategory.active,
    // Leisure
    'books': HobbyCategory.leisure,
    'comics': HobbyCategory.leisure,
    'video_games': HobbyCategory.leisure,
    'podcasts': HobbyCategory.leisure,
    'audiobooks': HobbyCategory.leisure,
    'gardening': HobbyCategory.leisure,
    'house_plants': HobbyCategory.leisure,
    'cooking': HobbyCategory.leisure,
    'baking': HobbyCategory.leisure,
    'board_games': HobbyCategory.leisure,
    'chess': HobbyCategory.leisure,
    'domino': HobbyCategory.leisure,
    'puzzles': HobbyCategory.leisure,
    'lego': HobbyCategory.leisure,
    'meditation': HobbyCategory.leisure,
    'collecting': HobbyCategory.leisure,
    'journaling': HobbyCategory.leisure,
    'astronomy': HobbyCategory.leisure,
    'crosswords': HobbyCategory.leisure,
    'sudoku': HobbyCategory.leisure,
    'rubiks_cube': HobbyCategory.leisure,
    'language_learning': HobbyCategory.leisure,
    'horror': HobbyCategory.leisure,
    'comedy': HobbyCategory.leisure,
    'thrillers': HobbyCategory.leisure,
    'drama': HobbyCategory.leisure,
    'romance': HobbyCategory.leisure,
    'documentaries': HobbyCategory.leisure,
    'historical_films': HobbyCategory.leisure,
    'series': HobbyCategory.leisure,
    'specialty_coffee': HobbyCategory.leisure,
    'specialty_tea': HobbyCategory.leisure,
    // Art
    'painting': HobbyCategory.art,
    'drawing': HobbyCategory.art,
    'photography': HobbyCategory.art,
    'pottery': HobbyCategory.art,
    'guitar': HobbyCategory.art,
    'piano': HobbyCategory.art,
    'drums': HobbyCategory.art,
    'violin': HobbyCategory.art,
    'accordion': HobbyCategory.art,
    'saxophone': HobbyCategory.art,
    'clarinet': HobbyCategory.art,
    'flute': HobbyCategory.art,
    'knitting': HobbyCategory.art,
    'crochet': HobbyCategory.art,
    'sewing': HobbyCategory.art,
    'graphic_design': HobbyCategory.art,
    'modeling_3d': HobbyCategory.art,
    'poetry': HobbyCategory.art,
    'blogging': HobbyCategory.art,
    'jewellery_making': HobbyCategory.art,
    'woodworking': HobbyCategory.art,
    'calligraphy': HobbyCategory.art,
    'origami': HobbyCategory.art,
    // Travel
    'backpacking': HobbyCategory.travel,
    'road_trips': HobbyCategory.travel,
    'camping': HobbyCategory.travel,
    'food_tourism': HobbyCategory.travel,
    'solo_travel': HobbyCategory.travel,
    'zoos': HobbyCategory.travel,
    'national_parks': HobbyCategory.travel,
    'geocaching': HobbyCategory.travel,
    'museums': HobbyCategory.travel,
    'ruins': HobbyCategory.travel,
    'galleries': HobbyCategory.travel,
    'slow_travel': HobbyCategory.travel,
  };

  /// Category for a hobby. Accepts either the canonical ID or a
  /// legacy display name — normalises through `HobbyData.idForLegacyName`.
  static HobbyCategory? getCategory(String hobbyIdOrName) {
    final direct = _idToCategory[hobbyIdOrName];
    if (direct != null) return direct;
    final id = HobbyData.idForLegacyName(hobbyIdOrName);
    if (id == null) return null;
    return _idToCategory[id];
  }

  /// Count hobbies per category from parsed hobby maps.
  static Map<HobbyCategory, int> getCategoryCount(
      List<Map<String, dynamic>> hobbies) {
    final result = <HobbyCategory, int>{};
    for (final hobby in hobbies) {
      final id = (hobby['id'] as String?) ?? '';
      final key = id.isNotEmpty ? id : (hobby['name'] as String? ?? '');
      final cat = getCategory(key);
      if (cat != null) result[cat] = (result[cat] ?? 0) + 1;
    }
    return result;
  }

  /// Set of canonical IDs for the supplied hobby maps (custom hobbies
  /// contribute their display name so they don't cross-match).
  static Set<String> getIds(List<Map<String, dynamic>> hobbies) {
    return hobbies
        .map((h) {
          final id = h['id'] as String? ?? '';
          if (id.isNotEmpty) return id;
          return h['name'] as String? ?? '';
        })
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  /// Deprecated alias kept for the CommonTraitsWidget call site — same
  /// semantics as `getIds`, name preserved so widget diffs stay minimal.
  static Set<String> getNames(List<Map<String, dynamic>> hobbies) =>
      getIds(hobbies);

  static IconData getCategoryIcon(HobbyCategory cat) {
    return switch (cat) {
      HobbyCategory.active => LucideIcons.dumbbell,
      HobbyCategory.leisure => LucideIcons.coffee,
      HobbyCategory.art => LucideIcons.palette,
      HobbyCategory.travel => LucideIcons.plane,
    };
  }

  /// Kratki label za prikaz v CommonTraitsWidget.
  static String getCategoryLabel(HobbyCategory cat) {
    return switch (cat) {
      HobbyCategory.active => 'Both active',
      HobbyCategory.leisure => 'Similar downtime',
      HobbyCategory.art => 'Both creative',
      HobbyCategory.travel => 'Both love travel',
    };
  }

  /// Icon for a hobby — accepts ID or legacy display name.
  static IconData getHobbyIcon(String hobbyIdOrName) {
    final cat = getCategory(hobbyIdOrName);
    if (cat == null) return LucideIcons.star;
    return getCategoryIcon(cat);
  }
}
