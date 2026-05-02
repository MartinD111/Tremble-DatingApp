import '../features/matches/data/match_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dev-only mock users injected when Admin Mode (Bypass Radar) is active.
// These are never visible in prod — kDebugMode gates all call sites.
// ─────────────────────────────────────────────────────────────────────────────

/// 3 handcrafted mock profiles to demo the radar notification + profile card
/// in both free and premium mode without touching Firebase.
const List<MatchProfile> kMockNearbyUsers = [
  // User 1 — 22F, student, Ljubljana — visible to free + premium
  MatchProfile(
    id: 'mock_user_001',
    name: 'Nika',
    age: 22,
    gender: 'Female',
    imageUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&q=80',
    hobbies: [
      {'name': 'Potovanja', 'emoji': '✈️', 'category': 'hobby_cat_travel', 'custom': false},
      {'name': 'Glasba', 'emoji': '🎵', 'category': 'hobby_cat_art', 'custom': false},
      {'name': 'Fitnes', 'emoji': '💪', 'category': 'hobby_cat_active', 'custom': false},
    ],
    bio:
        'Rada potavam in spoznavam nove ljudi. Iščem nekoga, ki ceni fine pogovore in dobre kave.',
    height: 168,
    jobStatus: 'student',
    school: 'Univerza v Ljubljani — Ekonomska fakulteta',
    occupation: 'Štipendistka',
    religion: 'agnostic',
    ethnicity: 'white',
    hairColor: 'brunette',
    drinkingHabit: 'socially',
    exerciseHabit: 'active',
    sleepSchedule: 'night_owl',
    petPreference: 'dog',
    childrenPreference: 'want_someday',
    introvertLevel: 40,
    lookingFor: ['long_term_partner', 'short_open_long'],
    prompts: [
      {
        'question': 'Moja skrita talenta sta ...',
        'answer': 'Kuhanje in orientacija brez Google Maps 😅',
      },
      {
        'question': 'Popoln vikend zame je ...',
        'answer': 'Sončen dan, kolesarjenje ob Savi in dobra serija zvečer.',
      },
    ],
  ),

  // User 2 — 26M, software engineer, Ljubljana — demo for male profile card
  MatchProfile(
    id: 'mock_user_002',
    name: 'Luka',
    age: 26,
    gender: 'Male',
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
    hobbies: [
      {'name': 'Branje', 'emoji': '📚', 'category': 'hobby_cat_leisure', 'custom': false},
      {'name': 'Videoigre', 'emoji': '🎮', 'category': 'hobby_cat_leisure', 'custom': false},
      {'name': 'Filmi', 'emoji': '🎬', 'category': 'hobby_cat_leisure', 'custom': false},
    ],
    bio:
        'Software engineer po dnevu, gamer po noči. Ljubim kavo, minimalizem in knjige, ki te nehote premislijo.',
    height: 182,
    jobStatus: 'employed',
    occupation: 'Software Engineer',
    company: 'Outfit7',
    religion: 'atheist',
    ethnicity: 'white',
    hairColor: 'black',
    drinkingHabit: 'never',
    exerciseHabit: 'sometimes',
    sleepSchedule: 'night_owl',
    petPreference: 'cat',
    childrenPreference: 'not_sure',
    introvertLevel: 75,
    lookingFor: ['long_term_partner'],
    prompts: [
      {
        'question': 'Moja filozofija v življenju ...',
        'answer': 'Delaj manj, ampak boljše. Kakovost nad količino.',
      },
      {
        'question': 'Nikoli se ne naveličam ...',
        'answer': 'Dobrega sci-fi filma in domino\'s pizze.',
      },
    ],
  ),

  // User 3 — 24F, designer, Koper — premium-tier demo (richer profile)
  MatchProfile(
    id: 'mock_user_003',
    name: 'Sara',
    age: 24,
    gender: 'Female',
    imageUrl:
        'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600&q=80',
    hobbies: [
      {'name': 'Umetnost', 'emoji': '🎨', 'category': 'hobby_cat_art', 'custom': false},
      {'name': 'Šport', 'emoji': '🏃‍♀️', 'category': 'hobby_cat_active', 'custom': false},
      {'name': 'Potovanja', 'emoji': '✈️', 'category': 'hobby_cat_travel', 'custom': false},
    ],
    bio:
        'UX designerka, ki verjame, da so detajli tisto, kar loči povprečno od izjemnega — v dizajnu in v življenju.',
    height: 165,
    jobStatus: 'employed',
    occupation: 'UX Designer',
    company: 'Studio Poper',
    religion: 'christianity',
    ethnicity: 'white',
    hairColor: 'blonde',
    drinkingHabit: 'socially',
    exerciseHabit: 'active',
    sleepSchedule: 'early_bird',
    petPreference: 'dog',
    childrenPreference: 'want_someday',
    introvertLevel: 30,
    lookingFor: ['long_term_partner', 'short_open_long'],
    prompts: [
      {
        'question': 'Kar mi je pri sebi najbolj všeč ...',
        'answer':
            'Da znam prisluhniti — res prisluhniti, ne samo čakati na vrsto.',
      },
      {
        'question': 'Moj deal-breaker je ...',
        'answer': 'Brez smisla za humor. Življenje je prekratko za dolgočasne.',
      },
    ],
  ),
];
