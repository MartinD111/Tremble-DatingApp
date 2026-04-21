# Tremble — Registration Flow Repair Plan
**Phase: Pre-10 UI Debt** | Status: `[ ] Not started` | Last updated: 2026-04-21

## Context

Registration flow je vizualno pokvarjen na več mestih. Ta plan popravlja vse znane probleme v določenem vrstnem redu. Vsak task ima jasno definiran scope, datoteke in verifikacijo. Ne skači na naslednji task dokler `flutter analyze` ne vrne 0 issues in manualni test potrdi fix.

**Build command (vedno):**
```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

**Analyze (po vsakem tasku):**
```bash
flutter analyze
# Required: 0 issues
```

**Ne dotikaj se:**
- `AndroidManifest.xml`
- `Info.plist`
- `google-services.json`
- `firebase_options.dart`

---

## Tasks

### TASK-REG-01 — Background gradient: teal → Deep Graphite
**Status:** `[ ] Not started`
**Priority:** 🔴 BLOCKER — brand

**Problem:**
Dark mode gradient v registration flow je `0xFF1E1E2E → 0xFF2A2A3E` (modro-vijolično). Brand token za dark scaffold je `#1A1A18` (Deep Graphite). Vse registration screene je videti kot drug produkt.

**File:**
```
lib/src/features/auth/presentation/registration_flow.dart
```

**Lokacija v datoteki:** Metoda `build()`, ~line 568–580. Iščeš:
```dart
Color topColor = isDark ? const Color(0xFF1E1E2E) : ...
Color bottomColor = isDark ? const Color(0xFF2A2A3E) : ...
```

**Fix:**
```dart
// Default dark gradient — Deep Graphite, subtilen
Color topColor = isDark ? const Color(0xFF1A1A18) : const Color(0xFFFAFAF7);
Color bottomColor = isDark ? const Color(0xFF1F1F1D) : const Color(0xFFF0F0EB);
```

Gender-specific dark gradients (male/female bloki) — pusti light mode, dark mode popravi na:
- Male dark: `0xFF0D1B2A → 0xFF0D1B2A` (subtilen navy tint, ne intenzivno teal)
- Female dark: `0xFF1F1018 → 0xFF1F1018` (subtilen rose tint)

**Verifikacija:**
- [ ] Intro slides: ozadje je temno grafitno (ne modro)
- [ ] Vsi registration koraki: konsistentno ozadje
- [ ] Light mode: cream ozadje `#FAFAF7`
- [ ] `flutter analyze` → 0 issues

---

### TASK-REG-02 — Defensive `tr()` — prepreči raw i18n ključe
**Status:** `[ ] Not started`
**Priority:** 🔴 BLOCKER — user-facing

**Problem:**
Screeni so v preteklosti pokazali `do_you_smoke`, `smoke_yes`, `smoke_no` kot literal tekst. Vzrok: `_selectedLanguage` dobi prazen string ali neveljaven jezik code pri inicializaciji → `t(key, lang)` ne najde prevoda → vrne ključ.

**File:**
```
lib/src/features/auth/presentation/registration_flow.dart
```

**Lokacija:** `String tr(String key)` metoda, ~line 193.

**Trenutna koda:**
```dart
String tr(String key) => t(key, _selectedLanguage);
```

**Fix:**
```dart
String tr(String key) {
  final lang = (_selectedLanguage.isNotEmpty) ? _selectedLanguage : 'sl';
  final result = t(key, lang);
  // Fallback: če ni prevoda v izbranem jeziku, vrni angleški prevod
  if (result == key) return t(key, 'en');
  return result;
}
```

**Dodatno — preveri initState:**
```dart
// ~line 92
_selectedLanguage = ref.read(appLanguageProvider);
```
Dodaj guard:
```dart
final lang = ref.read(appLanguageProvider);
_selectedLanguage = lang.isNotEmpty ? lang : 'sl';
```

**Verifikacija:**
- [ ] Preklopi app language na EN → registration flow pokaže angleške tekste
- [ ] Preklopi na SL → registration flow pokaže slovenske tekste
- [ ] Smoking step prikazuje "Do you smoke?" / "Ali kadiš?" — ne `do_you_smoke`
- [ ] Smoking opcije prikazujejo "Yes/No" ali "Da/Ne" — ne `smoke_yes/smoke_no`
- [ ] `flutter analyze` → 0 issues

---

### TASK-REG-03 — Consent step: "Izberi Vse" hardcoded string
**Status:** `[ ] Not started`
**Priority:** 🟠 Visoka

**Problem:**
`'Izberi Vse'` je hardcoded slovensko v consent_step.dart. Consent je zadnji korak registracije — pravni dokument, mora biti v jeziku uporabnika.

**Files:**
```
lib/src/features/auth/presentation/widgets/registration_steps/consent_step.dart
lib/src/core/translations.dart
```

**Fix v consent_step.dart:**
Poišči `label: 'Izberi Vse'` in zamenjaj z:
```dart
label: widget.tr('select_all'),
```

**Fix v translations.dart — dodaj ključ `select_all` v vse jezikovne bloke:**

| Jezik | Vrednost |
|-------|----------|
| `en` | `'Select All'` |
| `sl` | `'Izberi Vse'` |
| `de` | `'Alle auswählen'` |
| `it` | `'Seleziona tutto'` |
| `fr` | `'Tout sélectionner'` |
| `hr` | `'Odaberi sve'` |
| `hu` | `'Mindet kiválaszt'` |

Vsak jezikovni blok v translations.dart ima vzorec `'en': { ... }`. Dodaj `'select_all'` zraven ostalih splošnih ključev (npr. poleg `'save'`, `'cancel'`).

**Verifikacija:**
- [ ] EN: gumb prikazuje "Select All"
- [ ] SL: gumb prikazuje "Izberi Vse"
- [ ] DE: gumb prikazuje "Alle auswählen"
- [ ] `flutter analyze` → 0 issues

---

### TASK-REG-04 — Photos copy: "4 photos" ≠ 6-slot grid
**Status:** `[ ] Not started`
**Priority:** 🟡 Srednja

**Problem:**
`photos_hint` tekst pravi "Add up to 4 photos" ampak `_photos` lista ima 6 slotov in grid prikazuje 6 celic. Copy laže.

**Odločitev:** Max je **6** (skladno s kodo). Popravi copy, ne kode.

**File:**
```
lib/src/core/translations.dart
```

**Fix — posodobi `photos_hint` v vseh jezikih:**

| Jezik | Nova vrednost |
|-------|--------------|
| `en` | `'Add up to 6 photos. First photo is main.'` |
| `sl` | `'Dodaj do 6 slik. Prva slika je glavna.'` |
| `de` | `'Bis zu 6 Fotos hinzufügen. Erstes Foto ist Hauptfoto.'` |
| `it` | `'Aggiungi fino a 6 foto. La prima è la principale.'` |
| `fr` | `'Ajoute jusqu\'à 6 photos. La première est principale.'` |
| `hr` | `'Dodaj do 6 fotografija. Prva je glavna.'` |
| `hu` | `'Adj hozzá max. 6 fotót. Az első a főfotó.'` |

**Verifikacija:**
- [ ] Photos step subtitle prikazuje "6" v EN in SL
- [ ] Grid ima 6 slotov (ni spremenjen)
- [ ] `flutter analyze` → 0 issues

---

### TASK-REG-05 — Layout: vertikalne praznine na step-ih z malo vsebine
**Status:** `[ ] Not started`
**Priority:** 🟠 Visoka

**Problem:**
`ScrollableFormPage` uporablja `IntrinsicHeight` + `ConstrainedBox(minHeight)` ampak vsebina je poravnana na vrh. Na screenih z 2–3 opcijami (Status, Smoking) je ogromna praznina med vsebino in CTA gumbom.

**Prizadeti files:**
```
lib/src/features/auth/presentation/widgets/registration_steps/name_step.dart
lib/src/features/auth/presentation/widgets/registration_steps/status_step.dart
lib/src/features/auth/presentation/widgets/registration_steps/smoking_step.dart
```

**Fix pattern — za vsak prizadet step:**

Zamenjaj `ScrollableFormPage(child: Column(...))` z layoutom ki centrira vsebino:

```dart
SafeArea(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Back button + header
        TrembleBackButton(...),
        const Spacer(),
        // Glavna vsebina (opcije, input...)
        StepHeader(...),
        const SizedBox(height: 32),
        // ... opcije ...
        const Spacer(),
        // CTA na dnu
        ContinueButton(...),
        const SizedBox(height: 32),
      ],
    ),
  ),
)
```

**Opomba:** Za step-e kjer je vsebine dovolj (npr. Children z 5 opcijami, Languages z 8 vrsticami) — `ScrollableFormPage` ostane. Popravi samo tam kjer je vidna velika praznina.

**Verifikacija:**
- [ ] Name step: input je vertikalno centriran, gumb na dnu
- [ ] Status step: 2 opciji sta vertikalno centrirani
- [ ] Smoking step: 2 opciji sta vertikalno centrirani
- [ ] Na manjšem telefonu (iPhone SE simulacija) ni overflow
- [ ] `flutter analyze` → 0 issues

---

### TASK-REG-06 — Progress bar: totalSteps mismatch
**Status:** `[ ] Not started`
**Priority:** 🟢 Nizka

**Problem:**
```dart
const totalSteps = 26; // line ~484
```
PageView ima strani 0–26 = 27 strani. Progress bar nikoli ne doseže 100%.

**File:**
```
lib/src/features/auth/presentation/registration_flow.dart
```

**Fix:**
```dart
const totalSteps = 27;
```

**Verifikacija:**
- [ ] Na zadnjem screenu (Consent, page 26) progress bar je 100%
- [ ] Na prvem screenu (Intro 0) progress bar je ~4%
- [ ] `flutter analyze` → 0 issues

---

## Execution Notes za Claude CLI

1. **Delaj sekvenčno** — en task, commit, naslednji task. Ne paralelno.
2. **Po vsakem tasku** zaženi `flutter analyze`. Nadaljuj samo pri 0 issues.
3. **Commit message format:** `fix(registration): [TASK-REG-XX] kratek opis`
4. **Ne deployi** v production. Vse spremembe gredo v dev branch.
5. **Ne spreminjaj** routing logike, Firebase konfiguracije, ali BLE engine.
6. Ko vse tasks so `[x] Done`, posodobi `.planning/STATE.md`:
   - Dodaj v Known Tech Debt: `~~D-25~~ ✅ i18n raw keys fixed` itd.
   - Dodaj v Resolved Blockers z datumom

---

## Definition of Done

- [ ] TASK-REG-01: Gradient popravljan ✅
- [ ] TASK-REG-02: Defensive tr() ✅
- [ ] TASK-REG-03: select_all i18n ✅
- [ ] TASK-REG-04: Photos copy 4→6 ✅
- [ ] TASK-REG-05: Layout praznine ✅
- [ ] TASK-REG-06: Progress bar count ✅
- [ ] `flutter analyze` → 0 issues ✅
- [ ] Manualni test: full registration flow v EN in SL ✅
- [ ] `.planning/STATE.md` posodobljen ✅
