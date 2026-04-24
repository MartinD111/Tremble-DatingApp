# Session Handoff — Aleksandar → Martin
**Date:** 2026-04-24
**Build:** ✅ Passing (commit 887abe3) | `flutter analyze`: 0 issues

---

## Kaj je bilo narejeno danes

| # | Fix | Commit |
|---|-----|--------|
| BUILD-001 | `notification_service.dart` — const DarwinInitializationSettings | 6cff719 |
| BUILD-002 | `proximity.functions.ts` — `imageUrl` key + haversineDistance removal | 6cff719 |
| SPLASH-001 | Splash — rose ikona, #1A1A18 fullscreen ozadje, pravilno centrirana | aee4c18 |
| ICONS-001 | Launcher ikone — full-color vir (iOS), padded rose PNG (Android adaptive) | 887abe3 |
| RADAR-001 | Radar pulse maxRadius 0.45 → 0.5 (pulz doseže zunanji krog) | 887abe3 |
| MATCHES-001 | Matches naslov — Padding(horizontal: 100), ni več prekrivanja z gumbi | 887abe3 |
| ANIM-001 | Tab AnimatedSwitcher — samo fade 200 ms, brez scale efekta | 887abe3 |

---

## Kako namestiti debug APK (Android)

```bash
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev
# APK: build/app/outputs/flutter-apk/app-dev-debug.apk
```

---

## Kaj mora Martin preveriti

### 1. App ikona — KRITIČNO
Zapri app → poglej ikono na home screenu + app switcherju.
**Pričakovano:** Rožnat srček na temnem ozadju — NE črno-bela maska.

### 2. Splash screen
Force-close → odpri app.
**Pričakovano:** Cel zaslon temen, rožnat logo točno v centru, brez belih robov.

### 3. Radar pulse
Odpri Dashboard.
**Pričakovano:** Pulz doseže ZUNANJI krog mreže (prej se je ustavil prej).

### 4. Matches naslov
Odpri Matches tab.
**Pričakovano:** Naslov NE sme biti prekrit z "?" in svinčnik gumbom.

### 5. Tab prehodi
Preklapljaj Dashboard ↔ Matches ↔ Profile.
**Pričakovano:** Hiter čist fade (~200 ms), NI "popping/swelling" efekta.

### 6. 3-state Map Toggle — D-37 (Samsung S25 Ultra)
Map zaslon → preizkusi Off / City / Country stanja.
Maps API je zdaj aktiven. Sporoči ali toggle deluje.

---

## App Check — Martinov debug token

**POTREBNO pred testiranjem Cloud Functions** (waves, matches, notifikacije):

1. Martin zažene debug build → v Android logih poišče:
   ```
   I/FirebaseAppCheck: Debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
2. Aleksandar ga registrira: Firebase Console → tremble-dev → App Check → Android → Debug tokens.

Brez tega: vse Cloud Function klice vrnjene z `UNAUTHENTICATED`.

---

## Odprte zadeve za Martina

| Naloga | Prioriteta |
|--------|-----------|
| Vizualna potrditev novih ikon na Samsung | 🔴 High |
| App Check debug token → Aleksandar | 🔴 High |
| D-37: 3-state Map Toggle test (Samsung S25 Ultra) | 🟡 Medium |

---

## Naslednji korak za Aleksandra

```
/gsd:execute-phase 10
```
TASK-10-03 (Framing & Metadata) → TASK-10-04 (TestFlight) → TASK-10-05 (Landing Page).
