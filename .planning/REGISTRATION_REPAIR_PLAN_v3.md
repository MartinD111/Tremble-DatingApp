# Tremble — Registration Flow Repair Plan v3
**Status:** `[ ] Not started` | **Datum:** 2026-04-22
**Predpogoj:** v1 in v2 plana zaključena.

---

## TASK-REG-14 — Back button: preostali stepi še vedno imajo Stack/Positioned pattern

**Status:** `[ ] Not started`
**Priority:** 🔴 BLOCKER — visual

**Problem:**
REG-08 ni bil apliciran na vse step datoteke. Prizadeti stepi ki še vedno kažejo cut/prekrit back button:
- `political_affiliation_step.dart` — back button je centriran (napačno), mora biti levo
- `children_step.dart` — gumb prekriva naslov
- `hair_color_step.dart` — gumb prekriva naslov
- `ethnicity_step.dart` — gumb prekriva naslov
- `religion_step.dart` — gumb prekriva naslov
- `sleep_step.dart` — gumb prekriva naslov
- `drinking_step.dart` — gumb prekriva naslov
- `exercise_step.dart` — gumb prekriva naslov
- `hobbies_step.dart` — gumb cut

**Fix za vse prizadete datoteke:**

Poišči v vsaki datoteki Stack/Positioned pattern za back button IN kakršenkoli back button ki ni v Row na levi strani.

Pravilen pattern:
```dart
Row(
  children: [
    TrembleBackButton(onPressed: onBack, label: tr('back')),
    const Spacer(),
  ],
),
const SizedBox(height: 16),
StepHeader(tr('title_key')),
```

Za `political_affiliation_step.dart` posebej — back button je trenutno centriran v Column brez Row. Premakni ga v Row na levo.

**Verifikacija:**
- [ ] Vsak step: back button je viden v celoti, levo poravnan
- [ ] Noben naslov ni prekrit z back button
- [ ] `flutter analyze` → 0 issues

---

## TASK-REG-15 — Intro slide 0: brez teksta, črno ozadje

**Status:** `[ ] Not started`
**Priority:** 🟠 Visoka

**Problem 1 — Brez teksta:**
`IntroSlideStep` za `index: 0` prikazuje prazen naslov in prazen body ker `titles[0]` in `bodies[0]` sta prazna stringa `''`.

**File:** `lib/src/features/auth/presentation/widgets/registration_steps/intro_slide_step.dart`

**Trenutna koda:**
```dart
final titles = [
  '',           // ← index 0: prazen
  tr('calib1_title'),
  tr('calib2_title'),
  tr('calib3_title'),
];
final bodies = [
  '',           // ← index 0: prazen
  tr('calib1_body'),
  tr('calib2_body'),
  tr('calib3_body'),
];
```

**Fix — dodaj prevode za index 0:**

V `lib/src/core/translations.dart` dodaj ključe `calib0_title` in `calib0_body` v vse jezikovne bloke:

| Jezik | `calib0_title` | `calib0_body` |
|-------|---------------|---------------|
| `en` | `'It runs while you live.'` | `'No swiping. No scrolling. Tremble works quietly in your pocket while you go live your life.'` |
| `sl` | `'Deluje medtem, ko živiš.'` | `'Brez swipanja. Brez scrollanja. Tremble dela tiho v tvojem žepu, medtem ko živiš.'` |
| `de` | `'Es läuft, während du lebst.'` | `'Kein Swipen. Kein Scrollen. Tremble arbeitet still in deiner Tasche, während du dein Leben lebst.'` |
| `it` | `'Funziona mentre vivi.'` | `'Niente swipe. Niente scroll. Tremble lavora silenziosamente in tasca mentre vivi la tua vita.'` |
| `fr` | `'Il tourne pendant que tu vis.'` | `'Pas de swipe. Pas de scroll. Tremble travaille silencieusement dans ta poche pendant que tu vis ta vie.'` |
| `hr` | `'Radi dok živiš.'` | `'Bez swipanja. Bez scrollanja. Tremble radi tiho u džepu dok živiš svoj život.'` |
| `hu` | `'Fut, amíg élsz.'` | `'Nincs swipe. Nincs görgetés. Tremble csendesen dolgozik a zsebedben, amíg éled az életed.'` |

Nato v `intro_slide_step.dart` posodobi arrays:
```dart
final titles = [
  tr('calib0_title'),  // ← ne več prazen
  tr('calib1_title'),
  tr('calib2_title'),
  tr('calib3_title'),
];
final bodies = [
  tr('calib0_body'),   // ← ne več prazen
  tr('calib1_body'),
  tr('calib2_body'),
  tr('calib3_body'),
];
```

**Problem 2 — Črno ozadje na intro slide 0:**
První intro slide ima skoraj črno ozadje namesto Deep Graphite gradient. Vzrok: `_selectedGender` je `null` na začetku in gradient computation vrne napačno vrednost.

**File:** `lib/src/features/auth/presentation/registration_flow.dart`

Poišči gradient logiko (metoda `build()`) in preveri da dark mode default gradient je `0xFF1A1A18 → 0xFF1F1F1D`, ne `0xFF0D0D0D` ali `Colors.black`.

**Verifikacija:**
- [ ] Intro slide 0: prikazuje naslov "It runs while you live." in body tekst
- [ ] Intro slide 0: ozadje je Deep Graphite (#1A1A18), ne črno
- [ ] Slides 1-3: nespremenjeni
- [ ] `flutter analyze` → 0 issues

---

## TASK-REG-16 — Logo na intro slidih: preveč dominanten

**Status:** `[ ] Not started`
**Priority:** 🟡 Srednja

**Problem:**
Logo (`TrembleLogo`) je prikazan na vsakem intro slidu. Za slide 0 (prvi kontakt z appom) je to OK. Za slide 1-3 (ki razlagajo funkcionalnosti) je logo odveč — vsebina naj govori sama.

**File:** `lib/src/features/auth/presentation/widgets/registration_steps/intro_slide_step.dart`

**Fix:**
```dart
// Prikaži logo samo na prvem slidu (index == 0)
if (index == 0) ...[
  const TrembleLogo(size: 56),
  const SizedBox(height: 40),
],
```

**Verifikacija:**
- [ ] Slide 0: logo viden
- [ ] Slide 1, 2, 3: logo ni prikazan
- [ ] Layout ostalih slidov ni broken
- [ ] `flutter analyze` → 0 issues

---

## Execution Notes

1. Delaj sekvenčno: REG-14 → REG-15 → REG-16.
2. `flutter analyze` 0 issues po vsakem tasku.
3. Commit format: `fix(registration): [TASK-REG-XX] opis`

## Definition of Done

- [ ] TASK-REG-14: Back button vsi stepi ✅
- [ ] TASK-REG-15: Intro slide 0 tekst + ozadje ✅
- [ ] TASK-REG-16: Logo samo na slide 0 ✅
- [ ] `flutter analyze` → 0 issues ✅