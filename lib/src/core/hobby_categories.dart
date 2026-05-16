// lib/src/core/hobby_categories.dart
//
// Tremble Hobby Categories — Compatibility Layer
// Mapiraj obstoječe hobbije iz hobby_data.dart na 4 kategorije za compatibility scoring.
// NE zamenjuje hobby_data.dart — samo dodaja kategorijsko logiko.

import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';

enum HobbyCategory {
  active, // hobby_cat_active
  leisure, // hobby_cat_leisure
  art, // hobby_cat_art
  travel, // hobby_cat_travel
}

class HobbyCategories {
  // Mapping: hobby name → category
  // Vsebuje vse hobbije iz hobby_data.dart
  static const Map<String, HobbyCategory> _nameToCategory = {
    // Active
    'Pohodništvo': HobbyCategory.active,
    'Hiking': HobbyCategory.active,
    'Kolesarjenje': HobbyCategory.active,
    'Plavanje': HobbyCategory.active,
    'Tek': HobbyCategory.active,
    'Plezanje': HobbyCategory.active,
    'Joga': HobbyCategory.active,
    'Pilates': HobbyCategory.active,
    'Fitnes': HobbyCategory.active,
    'Kalistenika': HobbyCategory.active,
    'Tenis': HobbyCategory.active,
    'Skvoš': HobbyCategory.active,
    'Ples': HobbyCategory.active,
    'BJJ': HobbyCategory.active,
    'Karate': HobbyCategory.active,
    'Taekwondo': HobbyCategory.active,
    'Judo': HobbyCategory.active,
    'Mixed martial arts': HobbyCategory.active,
    'Boks': HobbyCategory.active,
    'Smučanje': HobbyCategory.active,
    'Bordanje': HobbyCategory.active,
    'Rolanje': HobbyCategory.active,
    'Drsanje': HobbyCategory.active,
    'Kajak': HobbyCategory.active,
    'SUP': HobbyCategory.active,
    'Jadranje': HobbyCategory.active,
    'Nogomet': HobbyCategory.active,
    'Košarka': HobbyCategory.active,
    'Odbojka': HobbyCategory.active,
    'Skateboarding': HobbyCategory.active,
    'Ping pong': HobbyCategory.active,
    'Bowling': HobbyCategory.active,
    'Biljard': HobbyCategory.active,
    'Ribolov': HobbyCategory.active,
    // Leisure
    'Knjige': HobbyCategory.leisure,
    'Stripi': HobbyCategory.leisure,
    'Videoigre': HobbyCategory.leisure,
    'Podcasts': HobbyCategory.leisure,
    'Audiobooks': HobbyCategory.leisure,
    'Vrtnarjenje': HobbyCategory.leisure,
    'House plants': HobbyCategory.leisure,
    'Kuhanje': HobbyCategory.leisure,
    'Baking': HobbyCategory.leisure,
    'Board games': HobbyCategory.leisure,
    'Šah': HobbyCategory.leisure,
    'Domino': HobbyCategory.leisure,
    'Puzzles': HobbyCategory.leisure,
    'Lego': HobbyCategory.leisure,
    'Meditacija': HobbyCategory.leisure,
    'Collecting': HobbyCategory.leisure,
    'Journaling': HobbyCategory.leisure,
    'Astronomija': HobbyCategory.leisure,
    'Reševanje križank': HobbyCategory.leisure,
    'Sudoku': HobbyCategory.leisure,
    "Rubik's": HobbyCategory.leisure,
    'Učenje novega jezika': HobbyCategory.leisure,
    'Grozljivke': HobbyCategory.leisure,
    'Komedije': HobbyCategory.leisure,
    'Trilerji': HobbyCategory.leisure,
    'Drame': HobbyCategory.leisure,
    'Romantični filmi': HobbyCategory.leisure,
    'Dokumentarci': HobbyCategory.leisure,
    'Historical films': HobbyCategory.leisure,
    'Serije': HobbyCategory.leisure,
    'Specialty coffee': HobbyCategory.leisure,
    'Specialty tea': HobbyCategory.leisure,
    // Art
    'Slikanje': HobbyCategory.art,
    'Risanje': HobbyCategory.art,
    'Fotografija': HobbyCategory.art,
    'Oblikovanje gline': HobbyCategory.art,
    'Kitara': HobbyCategory.art,
    'Klavir': HobbyCategory.art,
    'Bobni': HobbyCategory.art,
    'Violina': HobbyCategory.art,
    'Harmonika': HobbyCategory.art,
    'Saksofon': HobbyCategory.art,
    'Klarinet': HobbyCategory.art,
    'Flavta': HobbyCategory.art,
    'Pletenje': HobbyCategory.art,
    'Kvačkanje': HobbyCategory.art,
    'Šivanje': HobbyCategory.art,
    'Grafični dizajn': HobbyCategory.art,
    '3D modeliranje': HobbyCategory.art,
    'Poezija': HobbyCategory.art,
    'Blog': HobbyCategory.art,
    'Izdelovanje nakita': HobbyCategory.art,
    'Obdelava lesa': HobbyCategory.art,
    'Kaligrafija': HobbyCategory.art,
    'Origami': HobbyCategory.art,
    // Travel
    'Backpacking': HobbyCategory.travel,
    'Road trips': HobbyCategory.travel,
    'Kampiranje': HobbyCategory.travel,
    'Kulinarični turizem': HobbyCategory.travel,
    'Solo potovanja': HobbyCategory.travel,
    'Živalski vrtovi': HobbyCategory.travel,
    'Nacionalni parki': HobbyCategory.travel,
    'Geocaching': HobbyCategory.travel,
    'Muzeji': HobbyCategory.travel,
    'Ruševine': HobbyCategory.travel,
    'Galerije': HobbyCategory.travel,
    'Slow travel': HobbyCategory.travel,
  };

  /// Vrne kategorijo za hobby po imenu. Null za custom hobbije.
  static HobbyCategory? getCategory(String hobbyName) =>
      _nameToCategory[hobbyName];

  /// Iz seznama hobby map objektov izračuna število hobijev po kategoriji.
  static Map<HobbyCategory, int> getCategoryCount(
      List<Map<String, dynamic>> hobbies) {
    final result = <HobbyCategory, int>{};
    for (final hobby in hobbies) {
      final name = hobby['name'] as String? ?? '';
      final cat = _nameToCategory[name];
      if (cat != null) result[cat] = (result[cat] ?? 0) + 1;
    }
    return result;
  }

  /// Vrne set imen hobijev iz seznama hobby map objektov.
  static Set<String> getNames(List<Map<String, dynamic>> hobbies) {
    return hobbies
        .map((h) => h['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toSet();
  }

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

  /// Vrne ikono za konkreten hobby po imenu.
  static IconData getHobbyIcon(String hobbyName) {
    final cat = _nameToCategory[hobbyName];
    if (cat == null) return LucideIcons.star;
    return getCategoryIcon(cat);
  }
}
