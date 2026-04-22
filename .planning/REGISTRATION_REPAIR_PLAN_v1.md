# Tremble — Registration Flow Repair Plan v2
**Status:** `[ ] Not started` | **Datum:** 2026-04-21
**Predpogoj:** REGISTRATION_REPAIR_PLAN.md (v1) je zaključen.

---
## TASK-REG-06b — Registracija: jezik se med flowom resetira na EN

**Problem:**
Med registracijo se appLanguageProvider resetira na 'en' namesto da ohrani 
izbrani jezik ('sl'). Vzrok: ob Firebase Auth state spremembi (novi user kreiran) 
se authStateProvider posodobi, appLanguageProvider pa re-evaluira z novim userjem 
ki nima appLanguage v Firestoreu → vrne 'en' (EN blok je fallback).

**File:** lib/src/core/translations.dart

**Fix:** appLanguageProvider naj ob re-evaluaciji ohrani trenutno vrednost 
če novi user nima appLanguage nastavljenega:

final appLanguageProvider = StateProvider<String>((ref) {
  final user = ref.watch(authStateProvider);
  if (user != null && user.appLanguage.isNotEmpty) return user.appLanguage;
  return ref.state.isEmpty ? 'sl' : ref.state; // ohrani trenutno
});

Preveri tudi registration_flow.dart — _selectedLanguage naj se ne 
reinicializira ob authStateProvider spremembi med flowom.

**Verifikacija:**
- [ ] Začni registracijo v SL → ostane SL do konca
- [ ] flutter analyze → 0 issues

## TASK-REG-07 — Smoke keys manjkajo v EN bloku translations.dart
**Status:** `[ ] Not started`
**Priority:** 🔴 BLOCKER

**Problem:**
`do_you_smoke`, `smoke_yes`, `smoke_no` niso definirani v `'en'` jezikovnem bloku.
`tr()` fallback gre: izbran jezik → `sl` → `en` → raw ključ.
Ko je jezik EN, sl fallback ne zadene, en fallback tudi ne → prikaže `do_you_smoke`.

**File:** `lib/src/core/translations.dart`

**Fix — dodaj v `'en': { ... }` blok** (poleg obstoječih lifestyle ključev):
```dart
'do_you_smoke': 'Do you smoke?',
'smoke_yes': 'Yes',
'smoke_no': 'No',
```

**Preveri tudi:** Ali obstajajo drugi lifestyle ključi ki so v `'sl'` bloku ampak ne v `'en'`:
```
grep za vse ključe v 'sl' bloku → primerjaj z 'en' blokom
Kandidati: drinking_*, sleep_*, exercise_*, pets_*
```

Dodaj vse manjkajoče ključe v `'en'` blok z angleškim prevodom.

**Verifikacija:**
- [ ] Preklopi app na EN → smoking step prikazuje "Do you smoke?" / "Yes" / "No"
- [ ] Preklopi na SL → "Ali kadiš?" / "Da" / "Ne"
- [ ] `flutter analyze` → 0 issues

---

## TASK-REG-08 — Back button prekriva naslov
**Status:** `[ ] Not started`
**Priority:** 🟠 Visoka

**Problem:**
`Stack` z `Positioned(left:0, top:0)` za back button + centriran `StepHeader`. Ko je naslov kratek (npr. "What's your name?"), 48px gumb prekriva prvo črko naslova.

**Prizadete datoteke — vse kjer je ta pattern:**
```
lib/src/features/auth/presentation/widgets/registration_steps/name_step.dart
lib/src/features/auth/presentation/widgets/registration_steps/birthday_step.dart
lib/src/features/auth/presentation/widgets/registration_steps/email_location_step.dart
lib/src/features/auth/presentation/widgets/registration_steps/gender_step.dart
```
(in vse ostale kjer je `Positioned(left: 0, top: 0)` z `TrembleBackButton`)

**Fix — zamenjaj Stack pattern z Row:**
```dart
// NAMESTO:
SizedBox(
  width: double.infinity,
  child: Stack(
    alignment: Alignment.center,
    children: [
      StepHeader(tr('whats_your_name')),
      Positioned(
        left: 0, top: 0,
        child: TrembleBackButton(...),
      ),
    ],
  ),
)

// UPORABI:
Row(
  children: [
    TrembleBackButton(onPressed: onBack, label: tr('back')),
    const Spacer(),
  ],
),
const SizedBox(height: 16),
StepHeader(tr('whats_your_name')),
```

Back button je v svoji vrstici, naslov spodaj — brez prekrivanja.

**Verifikacija:**
- [ ] Name step: naslov "What's your name?" je v celoti viden
- [ ] Birthday step: naslov viden
- [ ] Basic Info step: naslov viden
- [ ] Back button je tapljiv brez prekrivanja vsebine
- [ ] `flutter analyze` → 0 issues

---

## TASK-REG-09 — Icon na selected OptionPill je neviden (rose na rose)
**Status:** `[ ] Not started`
**Priority:** 🟠 Visoka

**Problem:**
Ko je `OptionPill` selected, ozadje je `colorScheme.primary` (rose `#F4436C`).
Icon color je hardcoded `colorScheme.primary` tudi ko je selected → rose ikona na rose ozadju = nevidno.

**File:** `lib/src/features/auth/presentation/widgets/registration_steps/step_shared.dart`

**Lokacija:** `OptionPill.build()`, icon Row child.

**Trenutna koda:**
```dart
Icon(
  icon,
  color: iconColor ??
      (selected
          ? Theme.of(context).colorScheme.primary  // ← NAPAKA
          : (isDark ? Colors.white70 : Colors.black54)),
  size: 20,
),
```

**Fix:**
```dart
Icon(
  icon,
  color: iconColor ??
      (selected
          ? Colors.white  // ← bela na rose ozadju
          : (isDark ? Colors.white70 : Colors.black54)),
  size: 20,
),
```

**Verifikacija:**
- [ ] Hair color step: Brunette selected — rjava pika vidna na rose ozadju? Ne — pika ima lastno `iconColor` barvo. Preveri da je vidna.
- [ ] Religion step: Agnostic selected — ikona je bela na rose
- [ ] Exercise step: Active selected — ikona je bela
- [ ] What to meet step: Female selected — ikona je bela
- [ ] `flutter analyze` → 0 issues

**Opomba za hair color:** `OptionPill` za barvo las ima `iconColor` eksplicitno nastavljeno (rjava, rumena...). Ta fix ne vpliva nanje — `iconColor ?? ...` vzame eksplicitno barvo če je podana.

---

## TASK-REG-10 — Age range: vrednosti niso stalno prikazane
**Status:** `[ ] Not started`
**Priority:** 🟡 Srednja

**Problem:**
`RangeSlider` z `RangeLabels` prikazuje vrednosti samo med interakcijo (iOS Flutter behavior). Ko uporabnik ne drži sliderja, ni nobene indikacije kaj je izbral.

**File:** `lib/src/features/auth/presentation/widgets/registration_steps/dating_preferences_step.dart`

**Fix — dodaj statičen text pod sliderjem:**
```dart
// Takoj pod RangeSlider widget dodaj:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        '${ageRangePref.start.round()}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      Text(
        '—',
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
      Text(
        '${ageRangePref.end.round()}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ],
  ),
),
```

**Verifikacija:**
- [ ] Age range step: pod sliderjem sta vedno vidni dve vrednosti v rose barvi
- [ ] Ko premakneš slider, vrednosti se posodobijo takoj
- [ ] `flutter analyze` → 0 issues

---

## TASK-REG-11 — Political affiliation: slider label prikazuje vse 5 vrednosti
**Status:** `[ ] Not started`
**Priority:** 🟡 Srednja

**Problem:**
Na screenu je prikazanih vseh 5 labelov (Left, Center-left, Center, Center-right, Right) hkrati. Aktivna vrednost je pobarvana rose. To je vizualno gneča. 

**Fix — prikaži samo aktivno vrednost kot čist text:**

V `political_affiliation_step.dart`, zamenjaj Row z 5 labeli z enim centiranim textom:

```dart
// NAMESTO Row z Expanded labels:
if (!isSpecial)
  Center(
    child: Text(
      labels[idx - 1],
      style: GoogleFonts.instrumentSans(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
const SizedBox(height: 8),
// nato slider...
```

Pusti mala "Left" / "Right" oznaki samo na robovih sliderja za orientacijo:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(tr('politics_left'), style: TextStyle(fontSize: 11, color: labelColor)),
    Text(tr('politics_right'), style: TextStyle(fontSize: 11, color: labelColor)),
  ],
),
```

**Verifikacija:**
- [ ] Slider prikazuje samo aktivno vrednost nad njim (npr. "Center-right")
- [ ] Levo/desno oznaki za orientacijo sta vidni
- [ ] "I don't care" / "I don't want to say" opciji delujeta
- [ ] `flutter analyze` → 0 issues

---

## TASK-REG-12 — Name step: input polje previsoko / layout necentriranje
**Status:** `[ ] Not started`
**Priority:** 🟠 Visoka

**Problem:**
Na screenshotu 4 (14:26) je naslov "What's your name?" zgoraj, input polje pa zelo nizko — ogromna praznina med njima. `ScrollableFormPage` + `IntrinsicHeight` ne centrira vsebine ko je tipkovnica skrita.

**File:** `lib/src/features/auth/presentation/widgets/registration_steps/name_step.dart`

**Fix — REG-05 fix ni bil apliciran pravilno.** Datoteka še vedno uporablja `ScrollableFormPage`. Zamenjaj z vertikalno centriranim layoutom:

```dart
@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              TrembleBackButton(onPressed: onBack, label: tr('back')),
              const Spacer(),
            ],
          ),
          const Spacer(),
          StepHeader(tr('whats_your_name')),
          if (verificationBanner != null) ...[
            const SizedBox(height: 16),
            verificationBanner!,
          ],
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            autofocus: true,
            // ... obstoječ styling ...
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: nameController,
            builder: (_, __) => ContinueButton(
              enabled: nameController.text.trim().isNotEmpty,
              onTap: onNext,
              label: tr('continue_btn'),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}
```

**Verifikacija:**
- [ ] Name input je vertikalno centriran na zaslonu
- [ ] Back button je v svoji vrstici, ne prekriva naslova
- [ ] Continue gumb se aktivira ob vnosu teksta
- [ ] `flutter analyze` → 0 issues

---

## TASK-REG-13 — Auth: registracija ne deluje (API error)
**Status:** `[ ] Not started`
**Priority:** 🔴 BLOCKER

**Problem:**
Registracija se ne zaključi. Potrebno je preveriti:

```bash
# 1. Poglej Flutter konzolo med registracijo za error
flutter run --flavor dev --dart-define=FLAVOR=dev

# 2. Poišči error v logih:
grep -r "TREMBLE_AUTH_FLOW\|registerUser\|_registerUser" lib/src/features/auth/presentation/registration_flow.dart
```

**Možni vzroki:**
- Firebase Auth email/password provider ni omogočen v `tremble-dev` konzoli
- Email verifikacija je required preden se flow zaključi
- Checkpoint save faila tiho

**Ne popravljaj brez da najprej prebereš error iz konzole in ga sem poročaš.**

---

## Execution Notes

1. Delaj sekvenčno: REG-07 → REG-08 → REG-09 → REG-10 → REG-11 → REG-12.
2. REG-13 je blocker — NE deployi production brez tega.
3. `flutter analyze` 0 issues po vsakem tasku.
4. Commit format: `fix(registration): [TASK-REG-XX] opis`

## Definition of Done

- [ ] TASK-REG-07: EN smoke translations ✅
- [ ] TASK-REG-08: Back button layout ✅
- [ ] TASK-REG-09: Icon white on selected ✅
- [ ] TASK-REG-10: Age range display ✅
- [ ] TASK-REG-11: Politics slider label ✅
- [ ] TASK-REG-12: Name step layout ✅
- [ ] TASK-REG-13: Auth error diagnosed ✅
- [ ] `flutter analyze` → 0 issues ✅
- [ ] Manualni test: full flow EN + SL ✅
