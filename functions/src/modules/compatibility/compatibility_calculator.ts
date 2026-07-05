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
  sensitiveDataConsent?: boolean;  // GDPR Art. 9 — gates religion/ethnicity scoring
  lookingFor?: string[];
  isPremium?: boolean;
}

// ── Hobby kategorije (mirror hobby_data.dart) ──────────────────────────────
const CATEGORY_MAP: Record<string, string> = {
  // active
  'Pohodništvo': 'active', 'Hiking': 'active', 'Kolesarjenje': 'active',
  'Plavanje': 'active', 'Tek': 'active', 'Plezanje': 'active',
  'Joga': 'active', 'Pilates': 'active', 'Fitnes': 'active',
  'Kalistenika': 'active', 'Tenis': 'active', 'Skvoš': 'active',
  'Ples': 'active', 'BJJ': 'active', 'Karate': 'active',
  'Taekwondo': 'active', 'Judo': 'active', 'Mixed martial arts': 'active',
  'Boks': 'active', 'Smučanje': 'active', 'Bordanje': 'active',
  'Rolanje': 'active', 'Drsanje': 'active', 'Kajak': 'active',
  'SUP': 'active', 'Jadranje': 'active', 'Nogomet': 'active',
  'Košarka': 'active', 'Odbojka': 'active', 'Skateboarding': 'active',
  'Ping pong': 'active', 'Bowling': 'active', 'Biljard': 'active',
  'Ribolov': 'active',
  // leisure
  'Knjige': 'leisure', 'Stripi': 'leisure', 'Videoigre': 'leisure',
  'Podcasts': 'leisure', 'Audiobooks': 'leisure', 'Vrtnarjenje': 'leisure',
  'House plants': 'leisure', 'Kuhanje': 'leisure', 'Baking': 'leisure',
  'Board games': 'leisure', 'Šah': 'leisure', 'Domino': 'leisure',
  'Puzzles': 'leisure', 'Lego': 'leisure', 'Meditacija': 'leisure',
  'Collecting': 'leisure', 'Journaling': 'leisure', 'Astronomija': 'leisure',
  'Reševanje križank': 'leisure', 'Sudoku': 'leisure', "Rubik's": 'leisure',
  'Učenje novega jezika': 'leisure', 'Grozljivke': 'leisure',
  'Komedije': 'leisure', 'Trilerji': 'leisure', 'Drame': 'leisure',
  'Romantični filmi': 'leisure', 'Dokumentarci': 'leisure',
  'Historical films': 'leisure', 'Serije': 'leisure',
  'Specialty coffee': 'leisure', 'Specialty tea': 'leisure',
  // art
  'Slikanje': 'art', 'Risanje': 'art', 'Fotografija': 'art',
  'Oblikovanje gline': 'art', 'Kitara': 'art', 'Klavir': 'art',
  'Bobni': 'art', 'Violina': 'art', 'Harmonika': 'art',
  'Saksofon': 'art', 'Klarinet': 'art', 'Flavta': 'art',
  'Pletenje': 'art', 'Kvačkanje': 'art', 'Šivanje': 'art',
  'Grafični dizajn': 'art', '3D modeliranje': 'art', 'Poezija': 'art',
  'Blog': 'art', 'Izdelovanje nakita': 'art', 'Obdelava lesa': 'art',
  'Kaligrafija': 'art', 'Origami': 'art',
  // travel
  'Backpacking': 'travel', 'Road trips': 'travel', 'Kampiranje': 'travel',
  'Kulinarični turizem': 'travel', 'Solo potovanja': 'travel',
  'Živalski vrtovi': 'travel', 'Nacionalni parki': 'travel',
  'Geocaching': 'travel', 'Muzeji': 'travel', 'Ruševine': 'travel',
  'Galerije': 'travel', 'Slow travel': 'travel',
};

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
  const aHobbies = a.hobbies ?? [];
  const bHobbies = b.hobbies ?? [];

  // Empty-hobby profiles get a penalised neutral (0.30 instead of 0.50).
  // Rationale: an unconfigured profile shouldn't out-score a thoughtful but mismatched one,
  // and an incomplete profile won't clear the 0.70 standard threshold on its own — it can
  // still pass the 0.55 special-context (event / run / gym) threshold when other signals align.
  if (aHobbies.length === 0 || bHobbies.length === 0) return 0.30;

  let score = 0;
  const maxScore = 85;

  // Exact matches — primerjaj po imenu
  const aNames = new Set(aHobbies);
  const bNames = new Set(bHobbies);
  let exactCount = 0;
  for (const name of aNames) {
    if (bNames.has(name)) exactCount++;
  }
  score += Math.min(exactCount, 3) * 15;

  // Kategorijska podobnost — lookup iz CATEGORY_MAP
  const aCats: Record<string, number> = {};
  const bCats: Record<string, number> = {};
  aHobbies.forEach(h => {
    const c = CATEGORY_MAP[h];
    if (c) aCats[c] = (aCats[c] ?? 0) + 1;
  });
  bHobbies.forEach(h => {
    const c = CATEGORY_MAP[h];
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

  // Religion — GDPR Art. 9 special category, requires bilateral consent
  const bothConsentReligion =
    a.sensitiveDataConsent === true && b.sensitiveDataConsent === true;
  if (bothConsentReligion && a.religion && b.religion) {
    total++;
    if (a.religion === b.religion) matches++;
  }

  // Ethnicity — GDPR Art. 9 special category, requires bilateral consent
  const bothConsentEthnicity =
    a.sensitiveDataConsent === true && b.sensitiveDataConsent === true;
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
