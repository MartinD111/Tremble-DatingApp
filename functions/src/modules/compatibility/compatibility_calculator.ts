// functions/src/modules/compatibility/compatibility_calculator.ts
//
// Tremble Compatibility Calculator v1.0
//
// KRITIČNO — beri preden kaj spreminjaš:
// - Score je INTERNI signal, nikoli se ne shrani v Firestore
// - Score se nikoli ne pošlje v UI response (ne kot polje na nearbyUsers)
// - Political affiliation NI input (čl. 9 GDPR posebna kategorija)
// - Hard filters vrnejo 0.0 — par se ne prikaže v proximity rezultatih
// - Soft score določa kakovost matcha znotraj threshold logike

export interface UserCompatibilityData {
  uid: string;
  hobbies: string[];
  introvertScale?: number;         // 0–100
  nicotineUse?: string[];          // [] = nekadilec
  nicotineFilter?: string;         // 'any' | 'none_only' | 'no_preference'
  drinkingHabit?: string;
  partnerDrinkingHabit?: string;   // 'any' | 'none_only' | 'no_preference'
  exerciseHabit?: string;
  sleepSchedule?: string;
  religion?: string;
  religionPreference?: string;
  ethnicity?: string;
  ethnicityPreference?: string;
  religionConsent?: boolean;   // GDPR Art. 9 — gates religion scoring bilaterally
  ethnicityConsent?: boolean;  // GDPR Art. 9 — gates ethnicity scoring bilaterally
  lookingFor?: string[];
  isPremium?: boolean;
}

// ── Hobby kategorije + ID normalizacija (mirror hobby_data.dart) ───────────
// Category lookup keyed by the canonical language-neutral hobby ID
// (snake_case). All hobby comparisons run against IDs, not display strings,
// so a profile stored as "Hiking" (EN) matches one stored as "Pohodništvo"
// (SL).
const ID_TO_CATEGORY: Record<string, string> = {
  // active
  hiking: 'active', cycling: 'active', swimming: 'active', running: 'active',
  climbing: 'active', yoga: 'active', pilates: 'active', fitness: 'active',
  calisthenics: 'active', tennis: 'active', squash: 'active', dance: 'active',
  bjj: 'active', karate: 'active', taekwondo: 'active', judo: 'active',
  mma: 'active', boxing: 'active', skiing: 'active', snowboarding: 'active',
  rollerblading: 'active', iceskating: 'active', kayaking: 'active',
  sup: 'active', sailing: 'active', football: 'active', basketball: 'active',
  volleyball: 'active', skateboarding: 'active', ping_pong: 'active',
  bowling: 'active', billiards: 'active', fishing: 'active',
  // leisure
  books: 'leisure', comics: 'leisure', video_games: 'leisure',
  podcasts: 'leisure', audiobooks: 'leisure', gardening: 'leisure',
  house_plants: 'leisure', cooking: 'leisure', baking: 'leisure',
  board_games: 'leisure', chess: 'leisure', domino: 'leisure',
  puzzles: 'leisure', lego: 'leisure', meditation: 'leisure',
  collecting: 'leisure', journaling: 'leisure', astronomy: 'leisure',
  crosswords: 'leisure', sudoku: 'leisure', rubiks_cube: 'leisure',
  language_learning: 'leisure', horror: 'leisure', comedy: 'leisure',
  thrillers: 'leisure', drama: 'leisure', romance: 'leisure',
  documentaries: 'leisure', historical_films: 'leisure', series: 'leisure',
  specialty_coffee: 'leisure', specialty_tea: 'leisure',
  // art
  painting: 'art', drawing: 'art', photography: 'art', pottery: 'art',
  guitar: 'art', piano: 'art', drums: 'art', violin: 'art',
  accordion: 'art', saxophone: 'art', clarinet: 'art', flute: 'art',
  knitting: 'art', crochet: 'art', sewing: 'art', graphic_design: 'art',
  modeling_3d: 'art', poetry: 'art', blogging: 'art', jewellery_making: 'art',
  woodworking: 'art', calligraphy: 'art', origami: 'art',
  // travel
  backpacking: 'travel', road_trips: 'travel', camping: 'travel',
  food_tourism: 'travel', solo_travel: 'travel', zoos: 'travel',
  national_parks: 'travel', geocaching: 'travel', museums: 'travel',
  ruins: 'travel', galleries: 'travel', slow_travel: 'travel',
};

// Legacy migration: historical Firestore documents stored hobbies as
// display names in EN or SL. Mapping them into canonical IDs on read
// removes the "Hiking ≠ Pohodništvo" bug without needing a Firestore
// backfill. Keys are lowercased so lookup is case-insensitive.
const LEGACY_NAME_TO_ID: Record<string, string> = {
  // Slovenian display names
  'pohodništvo': 'hiking', 'kolesarjenje': 'cycling', 'plavanje': 'swimming',
  'tek': 'running', 'plezanje': 'climbing', 'joga': 'yoga',
  'fitnes': 'fitness', 'kalistenika': 'calisthenics', 'tenis': 'tennis',
  'skvoš': 'squash', 'ples': 'dance', 'boks': 'boxing', 'smučanje': 'skiing',
  'bordanje': 'snowboarding', 'rolanje': 'rollerblading', 'drsanje': 'iceskating',
  'kajak': 'kayaking', 'jadranje': 'sailing', 'nogomet': 'football',
  'košarka': 'basketball', 'odbojka': 'volleyball', 'biljard': 'billiards',
  'ribolov': 'fishing', 'knjige': 'books', 'stripi': 'comics',
  'videoigre': 'video_games', 'vrtnarjenje': 'gardening', 'kuhanje': 'cooking',
  'šah': 'chess', 'meditacija': 'meditation', 'astronomija': 'astronomy',
  'reševanje križank': 'crosswords', 'učenje novega jezika': 'language_learning',
  'grozljivke': 'horror', 'komedije': 'comedy', 'trilerji': 'thrillers',
  'drame': 'drama', 'romantični filmi': 'romance', 'dokumentarci': 'documentaries',
  'serije': 'series', 'slikanje': 'painting', 'risanje': 'drawing',
  'fotografija': 'photography', 'oblikovanje gline': 'pottery',
  'kitara': 'guitar', 'klavir': 'piano', 'bobni': 'drums', 'violina': 'violin',
  'harmonika': 'accordion', 'saksofon': 'saxophone', 'klarinet': 'clarinet',
  'flavta': 'flute', 'pletenje': 'knitting', 'kvačkanje': 'crochet',
  'šivanje': 'sewing', 'grafični dizajn': 'graphic_design',
  '3d modeliranje': 'modeling_3d', 'poezija': 'poetry', 'blog': 'blogging',
  'izdelovanje nakita': 'jewellery_making', 'obdelava lesa': 'woodworking',
  'kaligrafija': 'calligraphy', 'kampiranje': 'camping',
  'kulinarični turizem': 'food_tourism', 'solo potovanja': 'solo_travel',
  'živalski vrtovi': 'zoos', 'nacionalni parki': 'national_parks',
  'muzeji': 'museums', 'ruševine': 'ruins', 'galerije': 'galleries',
  // English display names
  'hiking': 'hiking', 'cycling': 'cycling', 'swimming': 'swimming',
  'running': 'running', 'climbing': 'climbing', 'yoga': 'yoga',
  'fitness': 'fitness', 'calisthenics': 'calisthenics', 'tennis': 'tennis',
  'squash': 'squash', 'dance': 'dance', 'boxing': 'boxing', 'skiing': 'skiing',
  'snowboarding': 'snowboarding', 'rollerblading': 'rollerblading',
  'ice skating': 'iceskating', 'kayaking': 'kayaking', 'sailing': 'sailing',
  'football': 'football', 'basketball': 'basketball', 'volleyball': 'volleyball',
  'billiards': 'billiards', 'fishing': 'fishing', 'books': 'books',
  'comics': 'comics', 'video games': 'video_games', 'gardening': 'gardening',
  'cooking': 'cooking', 'chess': 'chess', 'meditation': 'meditation',
  'astronomy': 'astronomy', 'crosswords': 'crosswords',
  'learning a new language': 'language_learning', 'horror': 'horror',
  'comedy': 'comedy', 'thrillers': 'thrillers', 'drama': 'drama',
  'romance': 'romance', 'documentaries': 'documentaries', 'series': 'series',
  'painting': 'painting', 'drawing': 'drawing', 'photography': 'photography',
  'pottery': 'pottery', 'guitar': 'guitar', 'piano': 'piano', 'drums': 'drums',
  'violin': 'violin', 'accordion': 'accordion', 'saxophone': 'saxophone',
  'clarinet': 'clarinet', 'flute': 'flute', 'knitting': 'knitting',
  'crochet': 'crochet', 'sewing': 'sewing', 'graphic design': 'graphic_design',
  '3d modelling': 'modeling_3d', 'poetry': 'poetry', 'blogging': 'blogging',
  'jewellery making': 'jewellery_making', 'woodworking': 'woodworking',
  'calligraphy': 'calligraphy', 'camping': 'camping', 'food tourism': 'food_tourism',
  'solo travel': 'solo_travel', 'zoos': 'zoos', 'national parks': 'national_parks',
  'museums': 'museums', 'ruins': 'ruins', 'galleries': 'galleries',
  // Language-neutral values (already stored consistently across locales)
  'pilates': 'pilates', 'bjj': 'bjj', 'karate': 'karate', 'taekwondo': 'taekwondo',
  'judo': 'judo', 'mixed martial arts': 'mma', 'sup': 'sup',
  'skateboarding': 'skateboarding', 'ping pong': 'ping_pong', 'bowling': 'bowling',
  'podcasts': 'podcasts', 'audiobooks': 'audiobooks', 'house plants': 'house_plants',
  'baking': 'baking', 'board games': 'board_games', 'domino': 'domino',
  'puzzles': 'puzzles', 'lego': 'lego', 'collecting': 'collecting',
  'journaling': 'journaling', 'sudoku': 'sudoku', "rubik's cube": 'rubiks_cube',
  'historical films': 'historical_films', 'specialty coffee': 'specialty_coffee',
  'specialty tea': 'specialty_tea', 'backpacking': 'backpacking',
  'road trips': 'road_trips', 'geocaching': 'geocaching', 'slow travel': 'slow_travel',
  'origami': 'origami',
};

/**
 * Normalise a stored hobby value (ID or legacy display name) to its
 * canonical ID. Values that don't match any known hobby (custom entries)
 * fall through unchanged — they still get compared verbatim, so two
 * custom hobbies with the same string still match.
 */
function normaliseHobbyId(raw: string): string {
  if (raw in ID_TO_CATEGORY) return raw;
  const lower = raw.toLowerCase();
  return LEGACY_NAME_TO_ID[lower] ?? raw;
}

// ── Hard filters ───────────────────────────────────────────────────────────
// Vrne false → score = 0.0, par se ne prikaže
function passesHardFilters(
  a: UserCompatibilityData,
  b: UserCompatibilityData,
): boolean {
  // Nicotine removed from hard filters - checked by zunanji nicotineCompatible pre-filter

  // Drinking
  if (a.partnerDrinkingHabit === 'none_only' && b.drinkingHabit !== 'none') return false;
  if (b.partnerDrinkingHabit === 'none_only' && a.drinkingHabit !== 'none') return false;



  // Looking for — vsaj en skupen cilj
  if (a.lookingFor?.length && b.lookingFor?.length) {
    const overlap = a.lookingFor.filter(x => b.lookingFor!.includes(x));
    if (overlap.length === 0) return false;
  }

  return true;
}

// ── Hobby score ────────────────────────────────────────────────────────────
// Exact match hobby: +15 točk (max 3 = 45)
// Kategorijska podobnost 2+ hobbije v isti kategoriji: +10 točk (max 4 kategorije = 40)
// Normalizirano na 0.0–1.0
function calculateHobbyScore(
  a: UserCompatibilityData,
  b: UserCompatibilityData,
): number {
  const aHobbies = (a.hobbies ?? []).map(normaliseHobbyId);
  const bHobbies = (b.hobbies ?? []).map(normaliseHobbyId);

  // Empty-hobby profiles get a penalised neutral (0.30 instead of 0.50).
  // Rationale: an unconfigured profile shouldn't out-score a thoughtful but mismatched one,
  // and an incomplete profile won't clear the 0.70 standard threshold on its own — it can
  // still pass the 0.55 special-context (event / run / gym) threshold when other signals align.
  if (aHobbies.length === 0 || bHobbies.length === 0) return 0.30;

  let score = 0;
  const maxScore = 85;

  // Exact matches — primerjaj po canonical ID.
  const aIds = new Set(aHobbies);
  const bIds = new Set(bHobbies);
  let exactCount = 0;
  for (const id of aIds) {
    if (bIds.has(id)) exactCount++;
  }
  score += Math.min(exactCount, 3) * 15;

  // Kategorijska podobnost — lookup iz ID_TO_CATEGORY.
  const aCats: Record<string, number> = {};
  const bCats: Record<string, number> = {};
  aHobbies.forEach(h => {
    const c = ID_TO_CATEGORY[h];
    if (c) aCats[c] = (aCats[c] ?? 0) + 1;
  });
  bHobbies.forEach(h => {
    const c = ID_TO_CATEGORY[h];
    if (c) bCats[c] = (bCats[c] ?? 0) + 1;
  });

  for (const cat of ['active', 'leisure', 'art', 'travel']) {
    if ((aCats[cat] ?? 0) >= 2 && (bCats[cat] ?? 0) >= 2) {
      score += 10;
    }
  }

  return Math.min(score / maxScore, 1.0);
}

// ── Personality score ──────────────────────────────────────────────────────
// Introvert scale: razlika 0 → 1.0, razlika 100 → 0.0
function calculatePersonalityScore(
  a: UserCompatibilityData,
  b: UserCompatibilityData,
): number {
  if (a.introvertScale == null || b.introvertScale == null) return 0.5;
  const diff = Math.abs(a.introvertScale - b.introvertScale);
  return Math.max(0, 1.0 - diff / 100);
}

// ── Lifestyle score ────────────────────────────────────────────────────────
// Smoking, drinking, exercise, sleep — NE political affiliation
function calculateLifestyleScore(
  a: UserCompatibilityData,
  b: UserCompatibilityData,
): number {
  let matches = 0;
  let total = 0;

  // Nicotine
  const aSmoker = (a.nicotineUse?.length ?? 0) > 0;
  const bSmoker = (b.nicotineUse?.length ?? 0) > 0;
  total++;
  if (aSmoker === bSmoker) matches++;

  // Drinking
  if (a.drinkingHabit && b.drinkingHabit) {
    total++;
    if (a.drinkingHabit === b.drinkingHabit) matches++;
  }

  // Exercise
  if (a.exerciseHabit && b.exerciseHabit) {
    total++;
    if (a.exerciseHabit === b.exerciseHabit) matches++;
  }

  // Sleep
  if (a.sleepSchedule && b.sleepSchedule) {
    total++;
    if (a.sleepSchedule === b.sleepSchedule) matches++;
  }

  // Religion — GDPR Art. 9, requires bilateral religionConsent (fail-closed:
  // missing consent = excluded from scoring, does not count as a 0 match).
  const bothConsentReligion =
    a.religionConsent === true && b.religionConsent === true;
  if (bothConsentReligion && a.religion && b.religion) {
    total++;
    if (a.religion === b.religion) matches++;
  }

  // Ethnicity — GDPR Art. 9, requires bilateral ethnicityConsent (fail-closed:
  // missing consent = excluded from scoring, does not count as a 0 match).
  const bothConsentEthnicity =
    a.ethnicityConsent === true && b.ethnicityConsent === true;
  if (bothConsentEthnicity && a.ethnicity && b.ethnicity) {
    total++;
    if (a.ethnicity === b.ethnicity) matches++;
  }

  return total === 0 ? 0.5 : matches / total;
}

// ── Glavni kalkulator ──────────────────────────────────────────────────────
/**
 * Izračuna compatibility score med dvema uporabnikoma.
 *
 * Vrne vrednost 0.0–1.0.
 *
 * KRITIČNO:
 * - 0.0 = hard filter fail (par se ne prikaže)
 * - 0.0–1.0 = soft score (za threshold primerjavo)
 * - Ta vrednost se NIKOLI ne shrani v Firestore
 * - Ta vrednost se NIKOLI ne vrne v UI response
 */
export function calculateCompatibilityScore(
  a: UserCompatibilityData,
  b: UserCompatibilityData,
): number {
  if (!passesHardFilters(a, b)) return 0.0;

  // Weights: hobbies 50%, personality 25%, lifestyle 25%
  const hobbyScore = calculateHobbyScore(a, b);
  const personalityScore = calculatePersonalityScore(a, b);
  const lifestyleScore = calculateLifestyleScore(a, b);

  const total =
    hobbyScore * 0.50 +
    personalityScore * 0.25 +
    lifestyleScore * 0.25;

  return Math.round(total * 100) / 100;
}
