// lib/src/features/match/domain/common_traits_calculator.dart
//
// Tremble Common Traits Calculator
// Iz dveh MatchProfile objektov izlušči top 3 skupne lastnosti za prikaz
// na Match Reveal Screenu (FREE tier).
//
// KRITIČNO: Ta logika NE prikaže compatibility score-a.
// Prikaže samo konkretne skupne lastnosti — brez % in brez rangiranja.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/hobby_categories.dart';
import '../../matches/data/match_repository.dart';

class CommonTrait {
  final IconData icon;
  final String label;

  const CommonTrait({required this.icon, required this.label});
}

class CommonTraitsCalculator {
  /// Vrne do 3 skupne lastnosti med dvema profiloma.
  /// Prioritetni vrstni red:
  /// 1. Exact hobby match (ista hobija)
  /// 2. Lifestyle match (nicotine, drinking, exercise, sleep)
  /// 3. Hobby kategorija (oba imata 2+ hobbije v isti kategoriji)
  /// 4. Introvert scale podobnost (razlika < 20)
  static List<CommonTrait> getTop3(MatchProfile a, MatchProfile b) {
    final traits = <CommonTrait>[];

    // ── 1. Exact hobby matches ────────────────────────────────────────────────
    final aNamesSet = HobbyCategories.getNames(a.hobbies);
    final bNamesSet = HobbyCategories.getNames(b.hobbies);
    final exactMatches = aNamesSet.intersection(bNamesSet).take(2).toList();

    for (final name in exactMatches) {
      traits.add(CommonTrait(
        icon: HobbyCategories.getHobbyIcon(name),
        label: name,
      ));
    }

    if (traits.length >= 3) return traits.take(3).toList();

    // ── 2. Lifestyle matches ──────────────────────────────────────────────────

    // Nicotine — obadva nekadilca
    final aNicotine = a.nicotineUse;
    final bNicotine = b.nicotineUse;
    if (aNicotine.isEmpty && bNicotine.isEmpty) {
      traits.add(const CommonTrait(
        icon: LucideIcons.wind,
        label: 'Both non-smokers',
      ));
    }

    if (traits.length >= 3) return traits.take(3).toList();

    // Drinking
    if (a.drinkingHabit != null &&
        b.drinkingHabit != null &&
        a.drinkingHabit == b.drinkingHabit) {
      traits.add(CommonTrait(
        icon: LucideIcons.glassWater,
        label: _drinkingLabel(a.drinkingHabit!),
      ));
    }

    if (traits.length >= 3) return traits.take(3).toList();

    // Exercise
    if (a.exerciseHabit != null &&
        b.exerciseHabit != null &&
        a.exerciseHabit == b.exerciseHabit) {
      traits.add(const CommonTrait(
        icon: LucideIcons.dumbbell,
        label: 'Same activity level',
      ));
    }

    if (traits.length >= 3) return traits.take(3).toList();

    // Sleep
    if (a.sleepSchedule != null &&
        b.sleepSchedule != null &&
        a.sleepSchedule == b.sleepSchedule) {
      traits.add(CommonTrait(
        icon: LucideIcons.moon,
        label: _sleepLabel(a.sleepSchedule!),
      ));
    }

    if (traits.length >= 3) return traits.take(3).toList();

    // ── 3. Hobby kategorija ───────────────────────────────────────────────────
    final aCats = HobbyCategories.getCategoryCount(a.hobbies);
    final bCats = HobbyCategories.getCategoryCount(b.hobbies);

    for (final cat in HobbyCategory.values) {
      if ((aCats[cat] ?? 0) >= 2 && (bCats[cat] ?? 0) >= 2) {
        traits.add(CommonTrait(
          icon: HobbyCategories.getCategoryIcon(cat),
          label: HobbyCategories.getCategoryLabel(cat),
        ));
        break; // samo ena kategorija
      }
    }

    if (traits.length >= 3) return traits.take(3).toList();

    // ── 4. Introvert scale ────────────────────────────────────────────────────
    final aIntro = a.introvertLevel;
    final bIntro = b.introvertLevel;
    if (aIntro != null && bIntro != null) {
      final diff = (aIntro - bIntro).abs();
      if (diff < 20) {
        traits.add(const CommonTrait(
          icon: LucideIcons.zap,
          label: 'Similar energy',
        ));
      }
    }

    return traits.take(3).toList();
  }

  static String _drinkingLabel(String habit) {
    return switch (habit) {
      'none' => 'Both non-drinkers',
      'social' => 'Both social drinkers',
      'regular' => 'Both drink regularly',
      _ => 'Similar drinking habits',
    };
  }

  static String _sleepLabel(String schedule) {
    return switch (schedule) {
      'early_bird' || 'morning' => 'Both early birds',
      'night_owl' || 'late' => 'Both night owls',
      _ => 'Similar sleep schedule',
    };
  }
}
