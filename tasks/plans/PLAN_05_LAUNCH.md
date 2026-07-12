# PLAN 05 — FINALNI BUILD, TEST, SUBMISSION, LAUNCH
**Faza 5 · Zadnja · Predpogoj: Faze 1-3 zaključene, Faza 4 vsaj oddana · Ocenjen čas: 1 teden + Apple review**

Preberi PLAN_00_MASTER_INDEX.md pred tem dokumentom.

**Strateška odločitev (že sprejeta, compliance report Del I): iOS-first.**
Apple pregleda background lokacijo v rednem reviewu; Google zahteva
vnaprejšnjo večtedensko deklaracijo. iOS se odda takoj, ko je build
pripravljen; Android sledi, ko Play deklaracije (PLAN_04 4.1) preidejo.
Ne čakaj Androida za iOS.

---

## KORAK 5.1 — 🤖 CODE + 🧑‍⚖️ FOUNDER: Finalni build

**Predpogoj-check (CLI naj VERIFICIRA, ne predpostavlja):**
```
Confirm each is in main (git log / grep evidence, list commit hashes):
- CI injection fix
- stopBilling CF
- CROSSING_PATHS visible notification
- prefer_not_to_say key
- gym manual activation fix
- hobby neutral IDs
- event locations Firestore
- registration location freetext
- paywall alignment
- prominent disclosure screen
Then run full verification: flutter analyze, flutter test,
cd functions && npm run build && npm run lint && npm test.
Report all counts.
```

**Founder — build ukazi (iz memory, preveri .env datoteke pred zagonom):**
```
# iOS (build number: prejšnji+1, torej 16 ali višje):
flutter build ipa --flavor prod --dart-define-from-file=.env.prod.json \
  --export-options-plist=ios/ExportOptions.plist --build-number=16
xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa \
  --apiKey V24BM2VRC2 --apiIssuer 752b6022-1929-42dd-b8a4-c894cd4f131d

# Android (versionCode MORA biti višji od prejšnjega!):
flutter build appbundle --flavor prod --dart-define-from-file=.env.prod.json
# podpis: tremble-release.jks, alias tremble
# → Play Console Internal testing
```

**Output:**
```text
iOS build št. / datum uploada:
Android versionCode / datum uploada:
Predpogoj-check dokaz (vseh 10 potrjenih):
```

## KORAK 5.2 — 🧑‍⚖️ FOUNDER: Re-registracija + BLE proximity matrix test

**Kontekst:** vsi testni računi so bili 11. jul izbrisani — začenjaš od
nič, kar je pravzaprav dobro (test polnega registracijskega flowa na
finalnem buildu).

**Postopek:**
1. Aleksandar + Martin: polna registracija na finalnem buildu.
   Med registracijo preveri: 18+ besedilo, consent checkboxi (gender/
   lookingFor), NI kanabisa, NI politike, prefer_not_to_say pravilno
   preveden, hobbiji v izbranem jeziku.
2. Profila morata biti KOMPATIBILNA za matching: 3+ skupni hobiji v
   isti kategoriji, kompatibilen lifestyle, gender/lookingFor ujemanje.
   Score ročno preveri ≥ 0.70 (compatibility_calculator logika) — sicer
   scanProximityPairs par legitimno preskoči in test ne pove ničesar.
3. Test matrix (za vsak scenarij zabeleži: proximity_events zapis v
   Firestore Console + ali je VIDNA notifikacija prišla na obe napravi):
   - Obe app v foregroundu, <100m
   - Obe app v ozadju (home screen), <100m
   - Obe app FORCE-QUIT, <100m, hoja skupaj 5+ min
   - Ena naprava foreground, druga force-quit
4. Wave → mutual wave → Trembling Window (30 min) → Pulse Intercept
   (Send Phone / Send Photo view-once) — cel jedrni flow enkrat E2E.
5. updateProfile, findNearby, getMatches → vsi 200 v logih.

**Merilo uspeha:** vidna notifikacija na OBEH platformah v scenariju
"obe v ozadju" — to je jedrna obljuba produkta ("app works for you").
Če force-quit scenarij na iOS ne dela, je to znana iOS omejitev BLE
restore — zabeleži, ne blokira launcha, ampak mora biti odraženo v
marketing obljubah (ne obljubljaj force-quit delovanja).

**Output:**
```text
Datum testa:
Matrix rezultati (4 scenariji × 2 platformi):
Jedrni flow E2E (da/ne):
Odprte najdbe:
```

## KORAK 5.3 — 🧑‍⚖️ FOUNDER: Pre-submission checklist (iOS)

Zadnji pregled pred oddajo — vse mora biti DA:
- [ ] PrivacyInfo.xcprivacy v buildu (že v repu — potrdi v arhivu)
- [ ] ITSAppUsesNonExemptEncryption v Info.plist
- [ ] Info.plist brez podvojenih ključev, Contacts string usklajen
      (implementation plan Korak 7 — preveri Output!)
- [ ] Privacy Labels izpolnjeni (PLAN_04 4.4)
- [ ] Support URL živ: trembledating.com/bug
- [ ] Privacy Policy URL živ: trembledating.com/privacy
- [ ] ToS živ (EN + SL)
- [ ] Sign in with Apple + in-app account deletion vidna in delujeta
- [ ] Age rating 17+
- [ ] Brez "beta"/"test" teksta v UI
- [ ] Brez referenc na Android/Google Play v iOS UI
- [ ] IAP produkti v App Store Connect ustrezajo kodi (monthly/yearly/
      weekly; lifetime = "coming soon" v ToS → NE objavljaj IAP zanj,
      dokler founder ne odloči drugače)
- [ ] RevenueCat: REVENUECAT_APPLE_API_KEY dart-define v prod buildu,
      entitlementi v RC dashboardu ustrezajo produktom
- [ ] Screenshoti + opis (brand pravila: brez prepovedanih fraz,
      opisuje mehaniko)
- [ ] Mapa v produkciji NI prazna (event pini iz 3.5 vidni)

**Output:**
```text
Vse DA (datum):
Izjeme/opombe:
```

## KORAK 5.4 — 🧑‍⚖️ FOUNDER: Submit + review spremljanje

1. App Store Connect → build 16 → Submit for Review.
2. Notes for reviewer: pojasni BLE+background location mehaniko v 3
   stavkih (reviewerji dating + background location kombinacijo radi
   vprašajo); priloži demo video iz PLAN_04 4.1; testna računa za
   review (ustvari dva sveža).
3. Zavrnitev NI katastrofa — je iteracija. Preberi točen guideline
   citat, popravi samo to, ponovno oddaj. Ne prepiraj se z reviewerjem
   prek Resolution Centra, razen če je očitno narobe razumel.
4. Android: ko Play deklaracije odobrene (PLAN_04 4.1) → Production
   release z istim AAB → staged rollout 20% → 100% po 48h brez crash
   spike-ov.

**Output:**
```text
iOS oddano (datum):
iOS odobreno (datum):
iOS LIVE (datum):
Android oddano/odobreno/live (datumi):
```

## KORAK 5.5 — 🧑‍⚖️ FOUNDER: Launch-day operativa

- Firebase Console + Sentry odprta prvi dan; spremljaj: updateProfile
  napake, scanProximityPairs durationMs rast, App Check zavrnitve.
- stopBilling prag: pred launchom PREVERI vrednost — €10 je za launch
  dan skoraj gotovo prenizek (autoscaling ob prvih uporabnikih).
  Realen budget + alert na 50%/80% pred kill-switchom.
- App Check: potrdi ENFORCE mode (ne debug) na obeh platformah.
- Debug tokeni: odstrani vse razen dev naprav (Firebase Console →
  App Check → Manage debug tokens).
- Prva 2 tedna: NE deployaj novih funkcij med Apple review oknom.

**Output:**
```text
Launch datum:
Dan-1 opombe:
```

---
## PO LAUNCHU (ne blokira, iz implementation plana + te seje)
- Heatmap realni podatki (PLAN_03 3.8)
- PII redaction sweep v CF logih
- Zod .strict() na vse onCall sheme
- 228 hardcoded hex → TrembleTheme tokeni
- DPO ponovna ocena (PLAN_04 4.2 — pade ob rasti uporabnikov)
- DMCA agent (ob US ekspanziji)
- Meta Dating Advertiser Application (oglaševanje šele po odobritvi;
  organski Instagram lahko takoj)
