# TREMBLE — IMPLEMENTATION PLAN & EXECUTION LOG
**Ustvarjeno: 6. julij 2026 · Spremljevalni dokument k `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md`**

---

## Kako uporabljati ta dokument

To ni samo plan — je obrazec. Vsak korak ima polje **Output**, ki ostane prazno, dokler ga ne izpolniš (ročno izveden korak) ali dokler ga ne izpolni Claude Code/Codex (avtomatiziran korak). Ne preskakuj korakov in ne izvajaj jih izven vrstnega reda — vrstni red ni naključen, vsak naslednji korak je odvisen od odgovora ali izida prejšnjega. Če korak preskočiš in ga izvede prihodnji Claude Code brez konteksta iz prejšnjega koraka, se delo podvoji.

**Postopek s Claude Code:** naloži ta dokument + `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md` v projekt. Ukaži: *"Do step 1, report back into this file and here in chat."* Ko konča, preveri Output polje, nato reci: *"Proceed to step 2."* Ne dovoli, da preskoči naprej sam.

**Ko je cel dokument izpolnjen:** vrni ga meni skupaj z novim ZIP-om posneto stanje kode. Analiziram izpolnjen plan proti dejanski kodi in povem, ali je Tremble pripravljen za launch ali ne.

**Oznake kategorij:**
- 📄 **DOC** — pravni dokument / dokumentacija
- 🧑‍⚖️ **FOUNDER** — odločitev ali ročno dejanje, ki ga AI ne more izvesti namesto tebe
- 🤖 **CODE** — Claude Code / Codex prompt, izvedljivo avtonomno
- 🌐 **WEB** — sprememba na trembledating.com

**Vzporedna proga:** Korak 0 se začne TAKOJ in teče v ozadju — ne čaka na noben drug korak in ga noben drug korak ne čaka, razen finalnega submita.

---

## KORAK 0 — 🧑‍⚖️ FOUNDER (vzporedno, začni danes)
### Naslov: Google Play — sprožitev deklaracij za background location + foreground service

**Kaj rešujemo:** Google Play zahteva poseben pregledni postopek za `ACCESS_BACKGROUND_LOCATION` in za foreground service tipe (`location|connectedDevice|dataSync`). Pregled traja 2–4 tedne. Če to začneš teden pred nameravanim launchom, se launch zamakne za mesec. Ta korak je edini v celotnem planu, ki ni odvisen od nobene odločitve spodaj — dovoljenja so že v kodi, samo deklariraj jih.

**Kaj moraš narediti:**
1. Play Console → App content → Permissions declaration → izpolni utemeljitev za `ACCESS_BACKGROUND_LOCATION`.
2. Posnemi demo video Radarja, ki teče v ozadju.
3. Ustvari in objavi Prominent Disclosure zaslon v aplikaciji (ločen od Privacy Policy, prikazan PRED sistemskim permission promptom).
4. Play Console → App content → Foreground service permissions → deklariraj vse tri tipe (location, connectedDevice, dataSync) z utemeljitvijo.
5. Oddaj in počakaj na odobritev.

**Pričakovan rezultat:** Obe deklaraciji odobreni v Play Console pred nameravanim Android launch datumom.

**Todoist:** `6h3p8gWG7WHWV7JP`, `6h3p8gc78572RF9P`

**Output (izpolni ti):**
```
Status:
Datum oddaje v Play Console:
Datum odobritve (ali še čakam):
Opombe:
```

---

## FAZA A — TEMELJNE ODLOČITVE
Vse spodaj mora biti odločeno, PREDEN se dokumenti popravijo ali koda spremeni, sicer se popravlja dvakrat.

## KORAK 1 — 🧑‍⚖️ FOUNDER
### Naslov: Pravno posvetovanje — celoten Art. 9/10 obseg v enem sestanku

**Kaj rešujemo:** Štiri odprta pravna vprašanja, ki jih ne smem sam razrešiti: (1) katera pravna podlaga pokriva spolno usmerjenost (gender+lookingFor) kot jedrni matching podatek, (2) ali kanabis spada pod GDPR čl. 9 (zdravje, privolitev deluje) ali čl. 10 (kazniva dejanja, privolitev NI veljavna podlaga za zasebno podjetje), (3) potrditev pristopa k politični pripadnosti, (4) ali je obvezen location consent checkbox pri registraciji skladen s "freely given" standardom.

**Kaj moraš narediti:** Rezerviraj sestanek z odvetnico/odvetnikom, specializiranim za GDPR v kontekstu obdelave občutljivih podatkov (ne splošno korporativno pravo). Predloži ji `TREMBLE_MASTER_COMPLIANCE_REPORT_06JUL2026.md`, sekcijo Del II. Pojasni dejansko delovanje kode za vsako od štirih točk (ne uganjuj namesto nje).

**Pričakovan rezultat:** Pisen odgovor na vsa štiri vprašanja, ki določa smer za korake 3, 13, 14, 23.

**Todoist:** `6h3JCC8m76XQPQ4P` (umbrella), `6h3j9q65vh3mG64P`, `6h3jHjr7Hf58G8pw`, `6h3c3FHcXV8HPc4P`

**Output (izpolni ti):**
```
Datum sestanka:
Odgovor na spolno usmerjenost (katera čl. 9(2) podlaga):
Odgovor na kanabis (čl. 9 ali čl. 10, in če čl. 10 — ali obstaja pravna podlaga za obdelavo):
Odgovor na politično pripadnost:
Odgovor na location consent:
Priložen dokument/email pravnice (da/ne, kje shranjen):
```

---

## KORAK 2 — 🧑‍⚖️ FOUNDER
### Naslov: getPublicProfile — popravi kodo ali dokumentiraj razkritje

**Kaj rešujemo:** Koda trenutno vrača religion/ethnicity/politicalAffiliation vsakemu ujemanju. DPIA trdi nasprotno. Eno od dvoje mora popustiti.

**Kaj moraš narediti:** Odloči: (a) je bilo razkritje teh polj matchu namerno (kot "razlog za ujemanje", podobno OkCupid profilnim atributom), ali (b) je bug, ki ga popravimo. Če (a) — koraki 14, 23, 34 dobijo drugačno besedilo. Če (b) — korak 11 postane aktiven, koraki 14/23/34 odpadejo v tej obliki.

**Pričakovan rezultat:** Ena zapisana odločitev: STRIP (odstrani iz kode) ali KEEP+DISCLOSE (popravi dokumente).

**Todoist:** `6h3jFhxVHpRmph9P`

**Output (izpolni ti):**
```
Odločitev: STRIP / KEEP+DISCLOSE
Razlog:
Datum:
```

---

## KORAK 3 — 🧑‍⚖️ FOUNDER
### Naslov: Politična pripadnost — izberi eno od treh poti

**Kaj rešujemo:** Polje se zbira, ni v scoringu, prikazuje se matchu. Trije možni pristopi: izbriši, vgradi v scoring (verjetno ne to, kar želiš), ali ohrani kot display atribut z lastnim consentom.

**Kaj moraš narediti:** Odloči, upoštevaj vhod iz koraka 1, če je pravnica komentirala politiko.

**Pričakovan rezultat:** Ena od treh poti izbrana, korak 12 se aktivira ali preskoči.

**Todoist:** `6h3JCCG8pC38rJhP`

**Output (izpolni ti):**
```
Odločitev: IZBRIŠI / VGRADI V SCORING / OHRANI KOT DISPLAY+CONSENT
Razlog:
Datum:
```

---

## KORAK 4 — 🧑‍⚖️ FOUNDER
### Naslov: Weekend Getaway — implementiraj enforcement ali umakni obljubo

**Kaj rešujemo:** ToS §7 obljublja avtomatsko časovno okno (pet 19h–ned 19h), koda tega ne izvaja. To je zdaj netočna pogodbena obljuba, ne le manjkajoča funkcija.

**Kaj moraš narediti:** Odloči: implementiraj backend enforcement (korak 15 se aktivira), ali odstrani časovno obljubo iz ToS in paywall copy (korak 15 odpade, korak 24 popravi ToS §7 ustrezno).

**Pričakovan rezultat:** Ena odločitev, ki določa ali korak 15 obstaja.

**Todoist:** `6h332RFRW946QWXw`

**Output (izpolni ti):**
```
Odločitev: IMPLEMENTIRAJ ENFORCEMENT / ODSTRANI OBLJUBO
Razlog:
Datum:
```

---

## KORAK 5 — 🧑‍⚖️ FOUNDER
### Naslov: DPO — imenuj ali dokumentiraj, da ni obvezen

**Kaj rešujemo:** GDPR čl. 37 in ZVOP-2 čl. 45 verjetno zahtevata DPO zaradi sistematičnega spremljanja lokacije + posebnih kategorij. Co-founder ne more biti DPO (konflikt interesov).

**Kaj moraš narediti:** Odloči, ali imenuješ zunanjega DPO, ali dokumentiraš pravno utemeljitev, zakaj ni obvezen. Če imenuješ: objavi kontakt na spletu (korak 33) in javi Informacijskemu pooblaščencu v 8 dneh.

**Pričakovan rezultat:** Odločitev + (če imenovan) ime/kontakt DPO za ROPA (korak 26) in website (korak 33).

**Todoist:** `6h3j9qH3m3p543QP`

**Output (izpolni ti):**
```
Odločitev: IMENUJEM DPO / NI OBVEZEN (pravna utemeljitev spodaj)
Ime/kontakt DPO (če imenovan):
IP obveščen dne (če imenovan):
Datum:
```

---

## KORAK 6 — 🧑‍⚖️ FOUNDER
### Naslov: Potrdi PostHog stanje na trembledating.com

**Kaj rešujemo:** DPA in Privacy Policy ne navajata PostHog, čeprav projektni kontekst omenja PostHog EU za website analitiko. Ni jasno, ali je dejansko live.

**Kaj moraš narediti:** Preveri Cloudflare Pages / website kodo — je PostHog inicializiran? Če da, v kakšnem načinu (cookies vključno ali cookieless)?

**Pričakovan rezultat:** Potrjeno dejansko stanje, ki določa vsebino korakov 25, 31.

**Todoist:** `6h3jFj2jfrw6VmVP`

**Output (izpolni ti):**
```
PostHog aktiven: DA / NE
Če DA — način (cookies / cookieless):
Datum:
```

---

## FAZA B — KODA, NEODVISNA OD ZGORNJIH ODLOČITEV
Ti koraki nimajo pravne odvisnosti — lahko tečejo takoj, vzporedno s Fazo A.

## KORAK 7 — 🤖 CODE
### Naslov: Info.plist — počisti podvojene ključe + popravi Contacts string

**Kaj rešujemo:** NSCameraUsageDescription in NSPhotoLibrary* se pojavijo dvakrat. NSContactsUsageDescription trdi, da app ne dostopa do kontaktov — Privacy Policy §2.5 opisuje funkcijo (Anonymity Mode), ki jih bere.

**Kaj mora Codex narediti:** Odstrani podvojene ključe (obdrži boljše besedilo od dveh). Popravi Contacts string, da resnično opiše Anonymity Mode, ALI potrdi, da funkcija ne obstaja in odstrani permission + PP referenco.

**Pričakovan rezultat:** En ključ na permission, Contacts string se ujema z dejanskim vedenjem.

**Todoist:** `6h3p8gWpxpq7rWXw`

**Output (izpolni AI):**
```
Status:
Datoteke spremenjene:
Ugotovitve (je Anonymity Mode dejansko implementiran?):
Testi (flutter analyze / test rezultat):
Blokerji:
```

---

## KORAK 8 — 🤖 CODE
### Naslov: Dodaj PrivacyInfo.xcprivacy manifest

**Kaj rešujemo:** Manjka od iOS 17.4 — avtomatska zavrnitev (ITMS-91053).

**Kaj mora Codex narediti:** Ustvari manifest z NSPrivacyCollectedDataTypes (lokacija, fotografije, ime, email, sensitive info) in NSPrivacyAccessedAPITypes (UserDefaults, FileTimestamp, SystemBootTime, DiskSpace). Dodaj v Xcode Runner target.

**Pričakovan rezultat:** Manifest prisoten in veljaven, xcodebuild archive uspe.

**Todoist:** `6h3grHhjVXFhMRJP`

**Output (izpolni AI):**
```
Status:
Datoteka ustvarjena na:
Testi:
Blokerji:
```

---

## KORAK 9 — 🤖 CODE
### Naslov: Dodaj ITSAppUsesNonExemptEncryption

**Kaj rešujemo:** Manjka v Info.plist, vsak upload zahteva ročni compliance odgovor.

**Kaj mora Codex narediti:** Dodaj `<key>ITSAppUsesNonExemptEncryption</key><false/>` v Info.plist.

**Pričakovan rezultat:** Ključ prisoten, TestFlight upload ne zahteva ročnega vprašanja.

**Todoist:** `6h3grHqC22mCcccP`

**Output (izpolni AI):**
```
Status:
Testi:
```

---

## KORAK 10 — 🤖 CODE
### Naslov: Uskladi proximity TTL (2h) med kodo in Firebase Console

**Kaj rešujemo:** UI besedilo obljublja 2h, ADR-002 pravi 2h, DPIA trdi 24h. Preveri, kaj Firebase Console dejansko izvaja.

**Kaj mora Codex narediti:** Preveri Firebase Console TTL policy za `proximity/{uid}` — ujemanje polja `geoHashExpiresAt` in vrednosti 2h. Popravi geo_service.dart, če se ne ujema.

**Pričakovan rezultat:** Koda, UI copy in Firebase Console vsi navajajo 2h.

**Todoist:** `6h332R4PwWhvrfxP`

**Output (izpolni AI):**
```
Status:
Dejanska vrednost v Firebase Console pred popravkom:
Sprememba narejena:
Testi:
```

---

## KORAK 11 — 🤖 CODE *(pogojno — samo če je Korak 2 = STRIP)*
### Naslov: Odstrani religion/ethnicity/politicalAffiliation iz getPublicProfile

**Kaj rešujemo:** Art. 9 podatki se razkrivajo matchu brez razkritega namena v Privacy Policy.

**Kaj mora Codex narediti:** V `users.functions.ts` odstrani navedena polja iz response objekta funkcije getPublicProfile. Dodaj regression test, ki potrdi odsotnost.

**Pričakovan rezultat:** getPublicProfile ne vrača nobenega Art. 9 polja.

**Todoist:** `6h3jFhxVHpRmph9P`

**Preveri pred izvedbo:** Korak 2 Output = STRIP? Če KEEP+DISCLOSE, preskoči ta korak in pojdi na korak 12.

**Output (izpolni AI):**
```
Status (izvedeno / preskočeno ker Korak 2 = KEEP+DISCLOSE):
Datoteke spremenjene:
Test dodan:
```

---

## KORAK 12 — 🤖 CODE *(pogojno — samo če je Korak 3 = OHRANI KOT DISPLAY+CONSENT)*
### Naslov: Implementiraj politicalAffiliationConsent

**Kaj rešujemo:** Ni consent mehanizma za politično pripadnost, čeprav se prikazuje matchu.

**Kaj mora Codex narediti:** Dodaj `politicalAffiliationConsent` (bool?, nullable) v AuthUser model, backend interface, in nov ločen consent checkbox v consent_step.dart z besedilom "shown on your profile to matches" (ne "used for matchmaking").

**Pričakovan rezultat:** Ločen, neblokirajoč consent za politiko, ki ne trdi napačnega namena.

**Todoist:** `6h3jHjhfQ2vH2wMP`

**Preveri pred izvedbo:** Korak 3 Output = OHRANI KOT DISPLAY+CONSENT? Če ne, preskoči.

**Output (izpolni AI):**
```
Status (izvedeno / preskočeno):
Datoteke spremenjene:
Testi:
```

---

## KORAK 13 — 🤖 CODE *(pogojno — glede na Korak 1 pravni odgovor o kanabisu)*
### Naslov: Kanabis — implementiraj ločen consent ALI odstrani vprašanje

**Kaj rešujemo:** Ni consent mehanizma, združeno z nikotinom v eno polje, možna čl. 10 izpostavljenost.

**Kaj mora Codex narediti:**
- Če Korak 1 pravni odgovor = čl. 9 pot varna: implementiraj ločen `cannabisConsent`, disclaimer pred vprašanjem, ločeno polje od nicotineUse.
- Če Korak 1 pravni odgovor = čl. 10 ali negotovo: odstrani cannabis opcijo iz nicotine_step.dart popolnoma.

**Pričakovan rezultat:** Skladno stanje z Korak 1 pravnim odgovorom.

**Todoist:** `6h3jHjr7Hf58G8pw` + podtaski `6gq4M39XVH3VmXPw`

**Preveri pred izvedbo:** Korak 1 Output — kanabis odgovor.

**Output (izpolni AI):**
```
Pot izbrana glede na Korak 1 (implementiraj / odstrani):
Status:
Datoteke spremenjene:
```

---

## KORAK 14 — 🤖 CODE *(pogojno — samo če je Korak 2 = KEEP+DISCLOSE)*
### Naslov: Religion/ethnicity consent copy — dodaj razkritje "viden matchu"

**Kaj rešujemo:** Če se getPublicProfile ohrani, mora consent besedilo to razkriti.

**Kaj mora Codex narediti:** Dodaj stavek "This information may also be visible to users you match with, on your profile" v oba (religion/ethnicity) checkboxa, EN+SL.

**Pričakovan rezultat:** Consent besedilo se ujema z dejanskim razkritjem.

**Todoist:** `6h3jHm6rgRW49GPP`

**Preveri pred izvedbo:** Korak 2 Output = KEEP+DISCLOSE? Če STRIP, preskoči (korak 11 to že rešuje).

**Output (izpolni AI):**
```
Status (izvedeno / preskočeno):
Besedilo dodano (EN):
Besedilo dodano (SL):
```

---

## KORAK 15 — 🤖 CODE *(pogojno — samo če je Korak 4 = IMPLEMENTIRAJ ENFORCEMENT)*
### Naslov: Weekend Getaway — implementiraj backend časovno okno

**Kaj rešujemo:** ToS obljublja avtomatsko okno pet 19h–ned 19h, ki ga koda ne izvaja.

**Kaj mora Codex narediti:** `processWeekendPasses` CF naj enforce-a časovno okno, prekliče entitlement izven njega.

**Pričakovan rezultat:** Weekend Pass se dejansko samodejno vklopi/izklopi po urniku.

**Preveri pred izvedbo:** Korak 4 Output = IMPLEMENTIRAJ? Če ODSTRANI OBLJUBO, preskoči — namesto tega korak 24 popravi ToS copy.

**Output (izpolni AI):**
```
Status (izvedeno / preskočeno):
Datoteke spremenjene:
Testi:
```

---

## KORAK 16 — 🤖 CODE
### Naslov: Gym Mode — odstrani proximity gate na ročni aktivaciji

**Kaj rešujemo:** Backend zavrne ročno aktivacijo, če uporabnik ni fizično v telovadnici — izniči smisel ročne aktivacije.

**Kaj mora Codex narediti:** V `gym.functions.ts` (onGymModeActivate) odstrani haversine distance check. Ohrani lat/lng za prvo proximity iteracijo, a jih ne uporabi za gate.

**Pričakovan rezultat:** Ročna aktivacija uspe od koderkoli; geofence dwell service ostane kot samodejna nadgradnja.

**Todoist:** `6h3pjGP2jHCgcgWw`

**Output (izpolni AI):**
```
Status:
Datoteke spremenjene:
Test posodobljen (gym.test.ts):
```

---

## KORAK 17 — 🤖 CODE
### Naslov: Map heatmap — realna geohash agregacija namesto mock podatkov

**Kaj rešujemo:** Heatmap krogi so naključno generirani in v produkciji sploh ne prikazani — mapa je prazna.

**Kaj mora Codex narediti:** Nov CF `getHeatmapDensity(precision, boundingBox)` z geohash-prefix agregacijo, k-anonymity gate (≥5 uporabnikov na celico), bucketiziran count, Upstash cache TTL 60s. Frontend zamenja mock generator s streamom iz endpointa, zoom mapira na precision.

**Pričakovan rezultat:** Realna, privacy-safe gostota v produkciji.

**Todoist:** `6h3pjGRx7rmV6hcw`

**Output (izpolni AI):**
```
Status:
Nov endpoint:
K-anonymity test rezultat:
Cache implementiran (da/ne):
```

---

## KORAK 18 — 🤖 CODE
### Naslov: Event Mode — prestavi koordinate v Firestore

**Kaj rešujemo:** 3 lokacije so hardcoded, v produkciji se ne prikazujejo.

**Kaj mora Codex narediti:** Dodaj `location` (GeoPoint) polje v Firestore `events` dokumente. Odstrani hardcoded `_eventLocations` in `_isDev` gate v tremble_map_screen.dart.

**Pričakovan rezultat:** Event pini se prikazujejo v produkciji iz realnih podatkov.

**Todoist:** `6h3pjGpMqrpVHqFw`

**Output (izpolni AI):**
```
Status:
Firestore dokumenti posodobljeni (da/ne):
```

---

## KORAK 19 — 🤖 CODE
### Naslov: Hobby lokalizacija — jezikovno-nevtralni ID-ji

**Kaj rešujemo:** Hobbiji mešajo SL/EN ne glede na jezik, ker so imena shranjena kot ključi. Matching primerja tekst — "Hiking" ≠ "Pohodništvo".

**Kaj mora Codex narediti:** Kanoničen seznam hobby ID-jev v hobby_data.dart, lokalizacijska tabela za prikaz, migracijska preslikava starih imen ob branju (parseHobbies), zamenjaj vse `hobby['name']` renderje s tr(id).

**Pričakovan rezultat:** Hobbiji dosledno v izbranem jeziku, matching deluje ne glede na jezik vnosa.

**Todoist:** `6h3pjGcGJPpWGrpw`

**Output (izpolni AI):**
```
Status:
Migracija testirana proti obstoječim profilom (da/ne):
```

---

## KORAK 20 — 🤖 CODE
### Naslov: Registracijsko lokacijsko polje — prost tekst namesto selektorja

**Kaj rešujemo:** KP/LJ/ZG/Other nima funkcije, matching ne uporablja tega polja.

**Kaj mora Codex narediti:** Zamenjaj OptionPill selektor z navadnim TextField. Brez Places API, brez geocodinga.

**Pričakovan rezultat:** Prost tekst, manj podatka, en procesor manj v DPA (če se Places API tu odstrani).

**Todoist:** `6h3pjGjHpGwq9vCP`

**Output (izpolni AI):**
```
Status:
Places API še uporabljen drugje (da/ne, kje):
```

---

## FAZA C — PAYWALL (po odločitvah A, pred finalno kodo)

## KORAK 21 — 🧑‍⚖️ FOUNDER
### Naslov: Pulse Intercept — določi tier (Free/Premium)

**Kaj rešujemo:** Koda tega jasno ne gate-a.

**Kaj moraš narediti:** Odloči Free ali Premium, glede na core-mechanic argument vs monetizacijski argument v master reportu Del V.

**Todoist:** `6h3pmrQ5wgFxRrCw`

**Output (izpolni ti):**
```
Odločitev: FREE / PREMIUM
Razlog:
```

---

## KORAK 22 — 🤖 CODE
### Naslov: Paywall — uskladi oglaševane funkcije s kodo, prioritiziraj prave triggerje

**Kaj rešujemo:** Paywall oglašuje "unlimited geofence pings" in "advanced filtering matrix", ki v kodi ne obstajata. Hkrati skriva "see who waved" in "near-miss recap" — najmočnejša konverzijska trigger-ja.

**Kaj mora Codex narediti:** Za vsako oglaševano funkcijo potrdi obstoj gate-a v kodi — implementiraj manjkajoče ali odstrani iz paywalla. Premakni see-who-waved in near-miss v ospredje feature liste. Vgradi Korak 21 odločitev za Pulse Intercept.

**Pričakovan rezultat:** Paywall točno odraža kodo; močnejša trigger-ja v ospredju.

**Todoist:** `6h3pmrF84Cf6JVQP`, `6h3pmrHP7C6j6Cfw`

**Output (izpolni AI):**
```
Status:
Funkcije odstranjene iz paywalla:
Funkcije implementirane:
Nov vrstni red feature liste:
```

---

## FAZA D — DOKUMENTI (enkratni prepis, po vseh zgornjih odločitvah)
Ne začni te faze, dokler koraki 1–20 niso zaključeni ali eksplicitno preskočeni z razlogom — sicer prepisuješ dokumente dvakrat.

## KORAK 23 — 📄 DOC
### Naslov: Popravi DPIA (enoten prepis)

**Kaj rešujemo:** DPIA vsebuje napačne trditve o TTL (24h namesto 2h), T3 mitigaciji (getPublicProfile), in politični privolitvi.

**Kaj moraš narediti:** Prepiši §3.2, §4.2 (T3), §8 skladno z izidi korakov 2, 10; §2.3 skladno z izidom koraka 1 (spolna usmerjenost, kanabis) in koraka 3 (politika).

**Pričakovan rezultat:** DPIA se v celoti ujema z dejansko kodo.

**Todoist:** povezano z `6h332R4PwWhvrfxP`, `6h3jFhxVHpRmph9P`

**Output (izpolni ti/pravnica):**
```
Status:
Verzija dokumenta:
Datum:
```

---

## KORAK 24 — 📄 DOC
### Naslov: Finaliziraj ToS

**Kaj rešujemo:** §7 Weekend Getaway obljuba, §16 slovenska klavzula brez SL verzije, DSA kontaktne točke niso eksplicitno označene.

**Kaj moraš narediti:** Uskladi §7 z izidom koraka 4. Razreši §16 (dodaj SL verzijo ali popravi klavzulo). Dodaj eksplicitno "DSA Contact Points" sekcijo.

**Todoist:** `6h332RFRW946QWXw`, `6h3jFj7ppxRM7pWP`, `6h3j9qQVcqwXQjfP`

**Output (izpolni ti):**
```
Status:
SL verzija ustvarjena (da/ne):
Datum:
```

---

## KORAK 25 — 📄 DOC
### Naslov: Finaliziraj Privacy Policy

**Kaj rešujemo:** §2.2 napačno trdi "voluntarily provided" za spolno usmerjenost; getPublicProfile razkritje ni omenjeno (če Korak 2 = KEEP); PostHog ni naveden.

**Kaj moraš narediti:** Popravi §2.2 skladno s Korakom 1 pravnim odgovorom. Dodaj razkritje matchu, če Korak 2 = KEEP+DISCLOSE. Dodaj PostHog v §6, če Korak 6 = aktiven.

**Todoist:** `6h3j9q65vh3mG64P`, `6h3jFhxVHpRmph9P`, `6h3jFj2jfrw6VmVP`

**Output (izpolni ti):**
```
Status:
Datum:
```

---

## KORAK 26 — 📄 DOC
### Naslov: Dopolni DPA

**Kaj rešujemo:** Manjka matična številka, PostHog kot procesor (če aktiven), re-sign pod AMS Solutions.

**Kaj moraš narediti:** Dopolni matično številko. Dodaj PostHog v Prilogo 1, če Korak 6 = aktiven. Re-sign Google/Cloudflare/Upstash/Resend pod AMS Solutions.

**Todoist:** `6h3jFj5pQhxpm9xw`, `6h3jFj2jfrw6VmVP`, `6ggJGh4jFJGQ43mP`, `6ggJGhH3gv7wcjRP`, `6ggJGhPc3hc86Grw`, `6ggJGhVPgPGW5Qmw`

**Output (izpolni ti):**
```
Matična številka dopolnjena (da/ne):
DPA re-signed: Google [ ] Cloudflare [ ] Upstash [ ] Resend [ ]
Datum:
```

---

## KORAK 27 — 📄 DOC
### Naslov: Konsolidiraj ROPA v en dokument

**Kaj rešujemo:** Vsebina obstaja raztresena po DPA/DPIA/PP.

**Kaj moraš narediti:** En xlsx/md dokument v obliki čl. 30(1), vključno z DPO kontaktom (Korak 5) in PostHog (Korak 6).

**Todoist:** `6h3j9qG7pC7jVX5P`

**Output (izpolni ti):**
```
Status:
Datum:
```

---

## KORAK 28 — 📄 DOC
### Naslov: Napiši breach notification postopek + register

**Kaj rešujemo:** Manjka smer upravljavec→IP (72h) in upravljavec→posamezniki.

**Kaj moraš narediti:** 1-stranski postopek + prazna tabela registra kršitev.

**Todoist:** `6h3j9qhmmhXjHPPP`

**Output (izpolni ti):**
```
Status:
Datum:
```

---

## KORAK 29 — 📄 DOC
### Naslov: DSA čl. 18 interni postopek

**Kaj rešujemo:** Manjka postopek za prijavo suma kaznivega dejanja organom pregona.

**Kaj moraš narediti:** 1-stranski interni postopek.

**Todoist:** `6h3j9qfCPj9VM4Qw`

**Output (izpolni ti):**
```
Status:
Datum:
```

---

## KORAK 30 — 📄 DOC
### Naslov: DSA čl. 16 notice-and-action preverba

**Kaj rešujemo:** Preveri, ali obstoječi report flow izpolnjuje potrdilo o prejemu + obvestilo o odločitvi.

**Kaj moraš narediti:** Preveri safety.functions.ts reportUser proti čl. 16(4)/(5). Dodaj javno pot brez računa, če manjka.

**Todoist:** `6h3j9qR73JFM6Gmw`

**Output (izpolni ti/AI):**
```
Status:
Manjkajoče elemente dodano:
```

---

## FAZA E — WEBSITE (po Fazi D)

## KORAK 31 — 🌐 WEB
### Naslov: Objavi DSA Contact Points stran

**Kaj rešujemo:** Kontaktni točki čl. 11/12 morata biti javno dostopni.

**Kaj moraš narediti:** Objavi sekcijo/stran na trembledating.com, EN+SL.

**Todoist:** `6h3j9qQVcqwXQjfP`

**Output (izpolni ti):**
```
URL:
Datum:
```

---

## KORAK 32 — 🌐 WEB
### Naslov: Objavi slovensko različico ToS (ali popravi klavzulo)

**Kaj rešujemo:** §16 trdi SL izvirnik brez obstoječe SL verzije.

**Todoist:** `6h3jFj7ppxRM7pWP`

**Output (izpolni ti):**
```
URL SL verzije (če ustvarjena):
Odločitev, če ne:
Datum:
```

---

## KORAK 33 — 🌐 WEB
### Naslov: Cookie consent banner za PostHog

**Kaj rešujemo:** Če PostHog nastavlja ne-nujne piškotke, je potreben opt-in banner.

**Preveri pred izvedbo:** Korak 6 Output = aktiven?

**Todoist:** `6h3jFj2jfrw6VmVP`

**Output (izpolni ti):**
```
Status (izvedeno / ni potrebno):
Datum:
```

---

## KORAK 34 — 🌐 WEB
### Naslov: Objavi DPO kontakt (če imenovan)

**Preveri pred izvedbo:** Korak 5 Output = imenujem DPO?

**Output (izpolni ti):**
```
Status (izvedeno / ni potrebno):
URL:
```

---

## FAZA F — STORE DEKLARACIJE (po Fazi A, lahko vzporedno s Fazo D/E)

## KORAK 35 — 🧑‍⚖️ FOUNDER
### Naslov: Apple Privacy Nutrition Labels + Google Play Data Safety

**Kaj rešujemo:** Morata točno odražati dejansko zbiranje, vključno s spolno usmerjenostjo in razkritjem matchu (odvisno od Koraka 2).

**Preveri pred izvedbo:** Koraki 1, 2, 3 morajo biti zaključeni — potrebuješ končno stanje kategorij.

**Todoist:** `6h3p8gg65JvGh8Ww`

**Output (izpolni ti):**
```
Apple Privacy Labels izpolnjeno (da/ne):
Play Data Safety izpolnjeno (da/ne):
Datum:
```

---

## KORAK 36 — 🧑‍⚖️ FOUNDER
### Naslov: Preveri Sign in with Apple + in-app account deletion vizualno

**Todoist:** `6h3p8ghgxjG93xpP`

**Output (izpolni ti):**
```
Oba gumba vidna in delujeta (da/ne):
```

---

## FAZA G — FINALNI BUILD IN VERIFIKACIJA

## KORAK 37 — 🤖 CODE
### Naslov: Nov iOS + Android build z vsemi popravki

**Preveri pred izvedbo:** Koraki 7–20, 22 zaključeni.

**Output (izpolni AI):**
```
Build number iOS:
Build number Android:
flutter analyze / test rezultat:
```

---

## KORAK 38 — 🧑‍⚖️ FOUNDER
### Naslov: Re-registracija testnih računov + poln profil

**Output (izpolni ti):**
```
Datum:
Oba računa izpolnjena do 3+ ujemajočih hobijev (da/ne):
```

---

## KORAK 39 — 🧑‍⚖️ FOUNDER + 🤖 CODE
### Naslov: Live scanProximityPairs smoke test

**Output (izpolni ti/AI):**
```
Rezultat (proximity_events zapis potrjen, pairsNotified vrednost):
```

---

## KORAK 40 — 🧑‍⚖️ FOUNDER
### Naslov: Potrdi Korak 0 (Play Console) odobren

**Output (izpolni ti):**
```
Odobreno (da/ne, datum):
```

---

## KORAK 41 — 🧑‍⚖️ FOUNDER
### Naslov: Submit v App Store / Play Store

**Output (izpolni ti):**
```
Datum oddaje iOS:
Datum oddaje Android:
Status review:
```

---

## KORAK 42 — Vrni ta dokument Claude-u
Priloži izpolnjen plan + nov ZIP kode. Vprašanje: je Tremble pripravljen za launch?

---

## PO LAUNCHU — priporočeno, ne blokira (opcijsko izvedi po zgornjih 42 korakih)
- PII redaction sweep v CF logih (`6h3grJ2fC632cmxw`)
- Zod `.strict()` na vse onCall sheme (`6h3grJ6RcvMpmMpP`)
- MCP prod dostop test (`6h3Vg3PxfhH77MGP`)
- Branch protection na main (Martin)
- App Check fail-open na typo hardening
- 228 hardcoded hex → tokeni
- DMCA designated agent (`6ggJRF9g3WXp6fqw`), ko greš na US trg
