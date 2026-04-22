# 🛸 Tremble — Onboarding Implementation Blueprint v2.2
**Status:** `[✅] COMPLETE` | **Datum:** 2026-04-23
**Cilj:** Celovita preobrazba onboarding izkušnje v tehnično "aktivacijo naprave" z uporabo radar-estetike, vizualnih pingov in post-registracijske simulacije.

---

## [Phase 1] Infrastruktura in Jezik ✅ COMPLETE

### TASK-REG-06 — Language Persistence Fix
**Datoteka:** `lib/src/core/translations.dart`
- **Problem:** `appLanguageProvider` se ponastavi na 'sl', ko se `authStateProvider` spremeni, kar povzroči skakanje jezika med registracijo.
- **Fix:** Posodobi provider, da ohrani trenutno stanje (`ref.state`), če novi user nima nastavljenega jezika.
```dart
final appLanguageProvider = StateProvider<String>((ref) {
  final user = ref.watch(authStateProvider);
  if (user != null && user.appLanguage.isNotEmpty) return user.appLanguage;
  return ref.state.isEmpty ? 'sl' : ref.state;
});
```
- **Verifikacija:** Začni registracijo v EN -> jezik mora ostati EN do konca, kljub vmesnim klicem na Firebase.

---

## [Phase 2] Vizualni Onboarding Engine (UX) ✅ COMPLETE

### TASK-UX-01 — Pulse Sync Engine (Visual Ping)
**Nova datoteka:** `lib/src/features/auth/presentation/widgets/ping_overlay.dart`
- **Widget:** `StatefulWidget` z `AnimationController` (Duration: 450ms).
- **Painter:** `CustomPainter` za izris dveh koncentričnih krogov.
    - **Barva:** `Theme.of(context).colorScheme.primary` (Tremble Rose).
    - **Prosojnost:** Fading od 0.2 do 0.0 med animacijo.
    - **StrokeWidth:** 1.5 px.
- **Integracija:** V `registration_flow.dart` ovij `PageView` v `Stack`. Dodaj `PingOverlay` na vrh.
- **Trigger:** V metodi `_nextPage()` in `_previousPage()` pokliči `_pingKey.currentState?.startAnimation()`.
- **Haptics:** Dodaj `HapticFeedback.lightImpact()` ob sprožitvi pinga.

### TASK-UX-02 — Lofi Photo Framework
**Datoteka:** `lib/src/features/auth/presentation/widgets/registration_steps/photos_step.dart`
- **Directive Text:** Nad GridView dodaj besedilo v fontu `Lora` (Italic, Size 14, `colorSecondary`).
    - **Ključ:** `photos_lofi_hint`.
- **Technical Brackets:** Ustvari `ViewfinderPainter` za foto slote.
    - **Izgled:** 4 vogalni oklepaji (L-shape), dolžina 12px, debelina 1px.
    - **Radij:** Zmanjšaj `borderRadius` slotov iz 14 na 4.
    - **Barva:** `isDark ? Colors.white24 : Colors.black12`.
- **Placeholder:** Zamenjaj ikono kamere s preprostim `+` (LucideIcons.plus, strokeWidth: 1.0).

---

## [Phase 3] Post-Onboarding Aktivacija ✅ COMPLETE

### TASK-UX-04 — The Ritual Screen ("Pojdi živet.")
**Nova datoteka:** `lib/src/features/auth/presentation/widgets/registration_steps/ritual_step.dart`
- **Izgled:** `Scaffold` s popolnoma črnim ozadjem (`Color(0xFF1A1A18)` - Deep Graphite).
- **Tipografija:** `JetBrains Mono` za vse elemente na tem zaslonu.
- **Vsebina:**
    - Header: "SIGNAL LOCKED" (Tremble Rose).
    - Body: "Radar je aktiven. Oddajnik deluje v ozadju. Odloži telefon. Mi te pokličemo, ko bo kdo blizu."
- **Ritual:** Ob vstopu na zaslon sproži `HapticFeedback.heavyImpact()`.
- **Preusmeritev:** Gumb "RAZUMEM" izvede `context.go('/')`.

### TASK-UX-03 — Dashboard Wave Simulation
**Nova datoteka:** `lib/src/features/dashboard/presentation/widgets/wave_simulation_overlay.dart`
- **Trigger:** Ob prvem pristanku na Dashboardu (preveri `SharedPreferences: has_seen_tutorial`).
- **Overlay:** Skippable `ModalBarrier` z zameglitvijo (Blur sigma: 10).
- **Simulacija:**
    - Prikaži widget, ki simulira sistemsko notifikacijo: *"Nekdo je v bližini (20 m)"*.
    - Ob kliku prikaži tutorial Match kartico.
    - Uporabnik mora izvesti "Wave" gib (Long press na 👋).
- **Gumbi:** Dodaj diskreten gumb "Preskoči" v spodnjem delu zaslona.

---

## [Phase 4] Lokalizacija (translations.dart) ✅ COMPLETE

Dodaj naslednje ključe v oba bloka (`en` in `sl`):
```dart
'photos_lofi_hint': 'Slikaj se v naravni svetlobi, kot te vidijo ljudje v realnem svetu. Brez filtrov.',
'ritual_body': 'Radar je aktiven. Oddajnik deluje v ozadju. Odloži telefon. Mi te pokličemo, ko bo kdo blizu.',
'ritual_button': 'RAZUMEM',
'sim_someone_nearby': 'Nekdo je v bližini (20 m)',
'sim_instruction': 'Pridrži gumb 👋, da pošlješ pozdrav.',
```

---

## Verifikacijski Protokol (QA Gate) ✅ COMPLETE
- [x] **Visual Audit:** Preveri, če barve in fonti ustrezajo `tremble-brand-identity.html`.
- [x] **Performance:** Animacija `PingOverlay` ne sme povzročati janka pri preklopu strani.
- [x] **Haptics:** Implementirano in pripravljeno na testiranje.
- [x] **Skip Logic:** Implementirano in preverjeno (SharedPrefs persistence).
- [x] **Fix:** sim_instruction hardcoded (Zamenjano s tr('sim_distance')).

---

## Navodila za izvajalca (Agent Directive)
- Ne uporabljaj hardcoded barv; vedno uporabi `Theme.of(context).colorScheme` ali brand tokens.
- Vsako novo komponento preizkusi z `flutter analyze`.
- Pri `PingOverlay` uporabi `Stack` v `RegistrationFlow`, da animacija ne prekine interakcije z obrazci.
