# PLAN 02 — INFRASTRUKTURA IN OPERATIVA
**Faza 2 · Začne se takoj po PLAN_01 koraku 1.3 (merge PR #13) · Ocenjen čas: pol dneva**

Preberi PLAN_00_MASTER_INDEX.md pred tem dokumentom.

---

## KORAK 2.1 — 🧑‍⚖️ FOUNDER: Deploy stopBilling + izbris starega CF

**Kontekst:** `stop-billing-10eur` (ročno deployan, NI v repu) crashira s
`TypeError: Buffer.from(undefined)` na VSAKEM Cloud Billing Pub/Sub
sporočilu — gen1 signatura, deployana kot gen2 CloudEvent. Billing
kill-switch je nefunkcionalen, Pub/Sub retry-a fail-e. Pomembno vedeti:
budget sporočila prihajajo večkrat na uro RUTINSKO — to ni znak
prekoračitve; funkcija primerja cost z budgetom in ukrepa šele nad pragom.

**Kaj narediti (v tem vrstnem redu, brez preskakovanja):**
1. Predpogoj: PR #13 mergean (PLAN_01 korak 1.3).
2. ```
   cd functions
   npm ci && npm run build
   firebase deploy --only functions:stopBilling --project am---dating-app
   ```
   To JE prod deploy — founder ga izvede sam, ne CLI.
3. TAKOJ po uspešnem deployu (ne "kasneje"): GCP Console →
   Cloud Run functions (regija europe-west1) → poišči `stop-billing-10eur`
   → Delete. Če ostane, imaš DVA subscriberja na `budget-limit-reached`
   topicu — dvojno proženje + star še naprej crashira.
4. Verifikacija: Logs Explorer, filter `resource.labels.service_name="stopbilling"`
   — ob naslednjem budget sporočilu pričakuj log `cost=X budget=Y` in
   HTTP 200, ne TypeError/500.
5. Odločitev o pragu: privzeto €10 iz budget konfiguracije. Ob sprožitvi
   funkcija ODKLOPI billing za CEL projekt am---dating-app (vse CF umrejo,
   Firestore preide na Spark omejitve). Med aktivnim multi-device
   testiranjem razmisli o dvigu: Cloud Run → stopbilling → Edit →
   env var `STOP_BILLING_THRESHOLD_EUR` (brez redeploya).

**Output:**
```text
Deploy datum:
Star CF izbrisan (datum, screenshot):
Prvi uspešen log (cost=X budget=Y) viden (da/ne):
Prag potrjen/spremenjen:
```

## KORAK 2.2 — 🧑‍⚖️ FOUNDER: Neodvisna potrditev buildov na napravah

**Kontekst:** 11. jul sta OBE napravi (Android okhttp + iOS
tremble.dating.app 1.0.0) dobili 400 na updateProfile. Koda v main je
čista (grep: kanabis/politika = 0) — 400 pomeni, da napravi pošiljata
STARE fielde, torej poganjata stare builde. Claude Code je trdil, da je
build posodobljen — trditev, ne dokaz.

**Kaj narediti:**
1. **Android:** Nastavitve → Aplikacije → Tremble → verzija. Primerjaj z
   versionCode zadnjega AAB (67.8MB, iz commita e99e41c). Play Console →
   Testing → Internal testing → preveri, da je release "Available to
   testers" in KATERI versionCode. Če se ne ujema: odstrani app z
   naprave, ponovno namesti prek internal testing linka.
2. **iOS:** TestFlight app → Tremble → Build številka na dnu. Mora biti
   **15**. Če je 14: App Store Connect → TestFlight → preveri processing
   build 15 → dodaj v External "Family+Friends" → posodobi na napravi.
3. **Test:** na obeh napravah: registracija → nicotine step NE sme
   vsebovati kanabisa; shrani profil → v Firebase logih updateProfile
   mora vrniti 200, ne 400.
4. Če verziji PRAVILNI, a 400 vztraja → to je regresija v novi strict
   Zod shemi (resnejši problem). V tem primeru: poberi točen request iz
   loga (Logs Explorer → updateprofile → 400 → trace) in odpri nov task;
   NE nadaljuj z BLE testi, dokler ni razčiščeno.

**Output:**
```text
Android versionCode na napravi / v Play Console:
iOS build na napravi:
updateProfile → 200 potrjen na obeh (da/ne):
```

## KORAK 2.3 — 🧑‍⚖️ FOUNDER: R2 + Redis + Firestore čiščenje po ročnem brisanju

**Kontekst:** 11. jul so bili 4 računi (Aleksandar, Martin, wyattminer,
lyndahart) izbrisani prek Firebase Console. Console delete NE sproži
`deleteUserAccount` CF cleanup poti. Firestore je bil ročno počiščen,
R2 in Redis pa Console ne vidi. Dokazano: 2 fotografiji uploadani 11. jul
ob 11:46 (presigned URL-ji v logih, poti users/{uid}/photos/...).

**Kaj narediti:**
1. Cloudflare dashboard → R2 → bucket za media.trembledating.com →
   izbriši prefixe `users/{uid}/` za vse 4 UID-je:
   - sxkX6dMYD2XLzSxUvSV7bGACgwH3 (Aleksandar)
   - wjpkaTKNOuNyQ9FKAJjAFS5ZpjE3 (Martin)
   - z3jMpBhXS3gHOThW6uYR91Z… (wyattminer — poln UID iz starih screenshotov)
   - dK5MfsZi6oVf5CykywBWGaV… (lyndahart)
2. Upstash dashboard → preveri ključe `encounter_count:*` (90-dnevni TTL,
   ne izginejo sami) in proximity cooldown ključe. Če ni drugih živih
   testnih podatkov, je FLUSHDB najhitrejše.
3. Firestore → potrdi prazne: users, proximity, proximity_events, waves,
   matches, rateLimits, notifications.

**Zakaj to ni samo pospravljanje:** "as if a GDPR delete happened" mora
dejansko pomeniti popoln delete — delna izvedba je točno tip razkoraka
med izjavo in stanjem, ki ga compliance report šteje kot oteževalno
okoliščino.

**Output:**
```text
R2 4/4 izbrisano (datum):
Redis počiščen (da/ne):
Firestore potrjeno prazen (da/ne):
```

## KORAK 2.4 — 🧑‍⚖️ FOUNDER: Google pre-launch report potrditev

**Kontekst:** neznana računa (wyattminer.16607, lyndahart.02127) sta se
11. jul registrirala prek Google providerja, tik po Play Internal testing
uploadu. Delovna hipoteza: Googlovi pre-launch report boti (generična
imena, timing se ujema). NI potrjeno.

**Kaj narediti:**
1. Play Console → Release → Testing → Pre-launch report → preveri, ali
   je report tekel ~11. jul.
2. Ujemanje → potrjeno benigno; zaključi.
3. NI reporta → eskalacija: nekdo zunaj testerskega kroga je registriran
   na produkciji. Preveri Firebase Auth sign-in metode, App Check loge,
   in od kod je prišel dostop do internal testing linka. Odpri p1 task.

**Output:**
```text
Pre-launch report obstaja za ta datum (da/ne):
Zaključek:
```

---
**KONEC FAZE 2 — merila:** stopBilling deluje (log dokaz), star CF
izbrisan, obe napravi na post-compliance buildih z updateProfile → 200,
R2/Redis/Firestore čisti, bot računi pojasnjeni.
