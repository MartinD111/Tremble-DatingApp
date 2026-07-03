# Implementation Plan — Compatibility Score + Card Visibility
**Verzija:** v1.1  
**Datum:** 16. maj 2026  
**Status:** Vse datoteke ustvarjene, ready to deploy

---

## Finalne produktne odločitve

| Odločitev | Status |
|---|---|
| Compatibility score — interni sistem, nikoli viden | ✅ Potrjeno |
| Filtered count na PRO heatmapu (agregat, brez UID) | ✅ Potrjeno — implementira se po F1 Protomaps |
| Score na match reveal screenu ali profilni kartici | ❌ Nikoli |
| Political affiliation kot input v formulo | ❌ Nikoli (čl. 9 GDPR) |

---

## Datoteke — status

| Datoteka | Status | Kje |
|---|---|---|
| `hobby_categories.dart` | ✅ Ready | outputs/ |
| `common_traits_calculator.dart` | ✅ Ready | outputs/ |
| `common_traits_widget.dart` | ✅ Ready | outputs/ |
| `compatibility_calculator.ts` | ✅ Ready | outputs/ |
| `proximity.functions.PATCH.md` | ✅ Ready | outputs/ |
| `matches_screen.PATCH.md` | ✅ Ready | outputs/ |
| `match_reveal_screen.PATCH.md` | ✅ Ready | outputs/ |

---

## Kam gre vsaka datoteka

```
lib/src/core/
  └── hobby_categories.dart               ← nov file

lib/src/features/match/domain/
  └── common_traits_calculator.dart       ← nov file

lib/src/features/match/presentation/widgets/
  └── common_traits_widget.dart           ← nov file

functions/src/modules/compatibility/
  └── compatibility_calculator.ts         ← nov file (ustvari mapo)

functions/src/modules/proximity/
  └── proximity.functions.ts              ← patch (glej PATCH.md)

lib/src/features/matches/presentation/
  └── matches_screen.dart                 ← patch (glej PATCH.md)

lib/src/features/match/presentation/
  └── match_reveal_screen.dart            ← patch (glej PATCH.md)

lib/src/core/
  └── translations.dart                   ← dodaj 2 keya (v matches_screen PATCH)
```

---

## Deployment vrstni red

### Faza A — Flutter only (brez Firebase deploy)

Delata lahko vzporedno, brez odvisnosti med sabo.

1. Kopiraj `hobby_categories.dart` → `lib/src/core/`
2. Kopiraj `common_traits_calculator.dart` → `lib/src/features/match/domain/`
3. Kopiraj `common_traits_widget.dart` → `lib/src/features/match/presentation/widgets/`
4. Apliciraj `matches_screen.PATCH.md` na `matches_screen.dart`
5. Apliciraj `match_reveal_screen.PATCH.md` na `match_reveal_screen.dart`
6. Dodaj translation keys (v PATCH.md navedeni)
7. `flutter run --flavor dev --dart-define=FLAVOR=dev`
8. Testiraj z mock profili v dev_mock_users.dart

**Kaj preveriti v Faza A:**
- [ ] Locked kartica prikaže "Nekdo ti je poslal val" namesto "Hidden person"
- [ ] PRO upsell chip je viden na locked kartici
- [ ] Mutual wave kartica (isFound=true) je vidna brez locka
- [ ] Wave poslana kartica (ti si iniciator) je vidna brez locka
- [ ] Match reveal screen prikaže do 3 skupne lastnosti
- [ ] PRO user vidi "View Full Profile" gumb
- [ ] Free user NE vidi "View Full Profile" gumba

### Faza B — Cloud Functions (tremble-dev)

1. Ustvari mapo `functions/src/modules/compatibility/`
2. Kopiraj `compatibility_calculator.ts` v to mapo
3. Apliciraj `proximity.functions.PATCH.md` na `proximity.functions.ts`
4. `cd functions && npm run build` — preveri da ni TypeScript napak
5. `firebase deploy --only functions:getProximityUsers --project tremble-dev`
6. Test: 2 dev profila z različnimi hobbiji in lifestyle → preveri logove

**Kaj preveriti v Faza B:**
- [ ] `npm run build` brez napak
- [ ] Hard filter: profil z `nicotineFilter: 'none_only'` ne vidi kadilca
- [ ] Hard filter: profil z `religionPreference: 'same_only'` ne vidi drugačne religije
- [ ] Score nikoli ni v Firestore (preveri Firebase console po testu)
- [ ] Score nikoli ni v Cloud Function response (preveri z emulatorjem)

### Faza C — Prod

**Samo z obema ustanoviteljema.**

```bash
firebase deploy --only functions:getProximityUsers --project am---dating-app
```

### Faza D — PRO Filtered Heatmap Count

**Blokirano na F1 Protomaps (Martin, in progress).**

Po F1 completion dodaj v proximity.functions.ts response:

```typescript
// V getProximityUsers return:
return {
  nearby: nearbyUsers, // brez score polja
  radiusTier,
  radiusM,
  // Samo za PRO — agregat brez UID-jev
  compatibleNearbyCount: isPremium ? nearbyUsers.length : undefined,
};
```

Flutter heatmap prejme `compatibleNearbyCount` in ga prikaže kot overlay.  
Brez UID-jev, brez profilov — samo število. Izven GDPR scope.

---

## Logika po scenarijih (za testiranje)

| Scenarij | gestures Map | isRecapLock | Prikaže |
|---|---|---|---|
| Ti si poslal wave | `{ myUid: true }` | false | foto + ime + starost |
| Mutual wave | `{ myUid: true, theirUid: true }` | false | foto + ime + starost + 3 traits |
| Oni so poslali wave (free) | `{ theirUid: true }` | **true** | blur + upsell |
| Oni so poslali wave (pro) | `{ theirUid: true }` | false | foto + ime + starost |
| Near-Miss (ni wave, isFound=false) | `{}` | false | foto + ime + starost |

---

## GDPR — ni sprememb v dokumentih

Score je interni signal. Nikoli shranjen. Nikoli viden.  
DPIA: dodaj eno vrstico: *"Compatibility score se izračuna interno iz preferenčnih podatkov za izboljšanje kakovosti proximity matchov. Vrednost ni shranjena in ni vidna uporabniku."*

PP, ToS, Evidenca čl. 30: brez sprememb.

---

*Plan v1.0 ustvarjen: 16. maj 2026*  
*Plan v1.1: vse datoteke ready, deployment vrstni red finaliziran*
