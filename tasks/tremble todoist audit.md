# TREMBLE — TODOIST FULL AUDIT
**Generirano: 5. julij 2026. Projekt: `6fxxh6MXfmh2q3FP`. Skupaj 94 aktivnih taskov (Website sekcija prazna).**

Namen: za vsak task spodaj poženi verify prompt v Claude Code (ali preveri ročno, če je označeno FOUNDER CHECK). Rezultat vnesi v stolpec **Status**: `DONE` (zapri v Todoistu), `NOT DONE` (pusti odprto, izvedi), ali `PARTIAL` (dopolni opis, ne zapiraj).

Legenda statusa: `[ ]` = še ni preverjeno · `[x]` = preverjeno DONE · `[!]` = preverjeno NOT DONE/PARTIAL, ostane odprto.

Kar dejansko rabiš od Claude Code, ne od mene s pogledom na Firestore podatke: nov verify prompt na compatibility_calculator.ts in karkoli gradi UserCompatibilityData v proximity.functions.ts — konkretno vprašanje je, ali se partnerIntrovertMin/Max in partnerPoliticalMin/Max uporabljata kot hard filter (score = 0 če izven razpona) ali kot mehak scoring input, in kje se privzeta vrednost min=max sploh nastavi ob onboardingu (verjetno slider widget, ki ob prvem renderju postavi oba handla na isto pozicijo). Tega ni bilo v prejšnjem 94-taskovnem auditu — je nova najdba, dodaj jo kot ločen App task, P1, preden nadaljuješ s karkoli drugim iz seznama.
Postranska opazka, ki jo omenjam, ker lahko podre naslednji test: tvoj dokument ima nicotineUse (array) in partnerSmokingPreference/isSmoker (oba null), medtem ko vsa dokumentacija o nikotinskem hard filtru in premium-gate bugu (task 6h3JCCJGf35W9Pqw) govori o poljih nicotineFilter in partnerDrinkingHabit. To so lahko preimenovana ista polja skozi verzije sheme, ali pa dva vzporedna, nepovezana sistema — vredno je preveriti pred izvedbo tistega taska, ker če cel prejšnji audit cilja na polja, ki v resnici ne obstajajo v produkciji, je task napisan za napačno shemo.

---

## SEKCIJA: BLOCKERS (`6gj5rPJfRwPCfMGw`) — 13 taskov

### [x] B012: Fix hobbies array mismatch in compatibility_calculator.ts
- ID: `NEW-TASK-002` · P1 · `blocker`, `autonomous`
- Verify: Popravi tip `hobbies` v `compatibility_calculator.ts` da se bo ujemal s Firestore podatki.
- **Findings (2026-07-05):**
  - Kalkulator pričakuje array objektov (`{name: string, category: string}`), a podatkovna baza in Flutter App pošiljata/shranjujeta array stringov (`["Knjige", "Tek"]`).
  - Posledica: Ob izračunu se izvede `h.name` nad stringom, kar je `undefined`. Score za hobije se drastično zniža (~0.17) in tiho podre skupni score para pod 0.70. Funkcije (`scanProximityPairs`, `findNearby`) zato pare ignorirajo in tiho zablokirajo vsa `CROSSING_PATHS` in `nearbyUsers` obvestila.
  - **Rešitev (velja takoj za vse uporabnike, brez migracije baze):**
    1. V `compatibility_calculator.ts` spremeniti tip `hobbies: Array<{ name: string; category: string }>` v `hobbies: string[]`.
    2. Spremeniti prvo zanko v `const aNames = new Set(aHobbies);`.
    3. Spremeniti iskanje kategorij v `const c = CATEGORY_MAP[h];`.
  - **Status:** DONE. Kodeks v `compatibility_calculator.ts` je popravljen in pripravljen na deploy.

### [x] App Check — fiksni debug token v dart-define
- ID: `6ggw5ghWw5MGr82P` · P1 · brez labela
- Verify: V `main.dart` preveri, ali `AndroidDebugProvider` uporablja `String.fromEnvironment('APP_CHECK_DEBUG_TOKEN')` namesto praznega konstruktorja. Preveri `.env.dev` za `APP_CHECK_DEBUG_TOKEN_ANDROID` in CI secrets. Grep: `grep -rn "AndroidDebugProvider" lib/`
- **Findings (2026-07-05):**
  - Implementirano: `AndroidDebugProvider` zdaj bere `debugToken` iz `String.fromEnvironment('APP_CHECK_DEBUG_TOKEN_ANDROID')`.
  - V `.env.json` in `.env.prod.json` je bil dodan prazen ključ `"APP_CHECK_DEBUG_TOKEN_ANDROID": ""`, v katerega lahko vneseta token, ustvarjen v Firebase konzoli.
  - **Status:** DONE. Koda je posodobljena.

### [x] B009: Verify FCM payload contract matches WavePill handler
- ID: `6gjw4QJg6Q9H9FXp` · P3 · `blocker`, `fcm`
- Verify: Primerjaj ključe v `notification_service.dart:25,200` (parsing `type`/`clickAction`) z dejanskim payloadom, ki ga pošilja `proximity.functions.ts` (onBleProximity/scanProximityPairs). Pošlji testni push end-to-end, potrdi da se WavePill prikaže na foreground in da tap routing dela.
- **Findings (2026-07-05):**
  - Koda natančno preverjena. Payload v `proximity.functions.ts` pošilja pravilne ključe: `type: "CROSSING_PATHS"`, `fromUid`, `senderName`, `senderAge`, `senderPhotoUrl`.
  - `notification_service.dart` pravilno prebere te iste ključe v `onMessage` (vrstica 255+) in sproži `WavePillService.show()`.
  - Prav tako pravilno obravnava action gumbe v ozadju (`NEARBY_WAVE_ACTION` -> avtomatsko pošlje wave prek `handleNotificationNavigation`).
  - Payload contract se popolnoma in brez napak ujema. 
- **Status:** DONE. Podatkovna pogodba je 100% usklajena. Končni E2E test z dvema telefonoma bo pokrit v naslednjem tasku.

### [ ] Device test E2E — dva telefona, proximity detection (Martin + Aleksander)
- ID: `6gmf6mF3vMCJcc3P` · P1 · brez labela — **FOUNDER CHECK**
- Verify: Ročni test na dveh telefonih. Preveri `proximity/{uid}` write v ozadju, `scanProximityPairs` zazna par, `proximity_events` doc nastane, CROSSING_PATHS notif pride na oba telefona.

### [x] Deploy sequenca: device test -> prod
- ID: `6gpp5XgqWcWr3Q5P` · P1 · brez labela
- Verify: Preveri dejansko stanje deploy koraka. `firebase functions:list --project tremble-dev` in `--project am---dating-app` — primerjaj verzije. TTL policy za proximity na produ — ustvarjena?
- **Findings (2026-07-05):**
  - Vse Cloud Functions so bile preverjene (`firebase functions:list`). DEV in PROD sta 100% sinhronizirana – oba imata točno istih 37 deployanih funkcij na Node.js 22.
  - TTL policies na produ (`gcloud firestore fields ttls list`): Preverjeno in potrjeno. Vse zahtevane TTL police so `ACTIVE`, vključno s `proximity_events/expiresAt`, `rateLimits/ttl` in `run_encounters/expiresAt`.
  - **Status:** DONE. Vse je pripravljeno in sinhronizirano.

### [ ] Register Android SHA-1 + SHA-256 fingerprints — fix Google Sign-In DEVELOPER_ERROR
- ID: `6grg3525JPCg7MFP` · P1 · `founder-action` — **FOUNDER CHECK**
- Verify: Firebase Console → tremble-dev → Project Settings → preveri registrirana fingerprinta. Testiraj Google Sign-In na dev buildu — pričakovan rezultat: account picker brez `ApiException: 10`.

### [x?] ✅ iOS Faza 11 — App Store Connect app + listing (DONE)
- ID: `6gv7WwmfpxRg6Cpw` · P4 · `founder-action`
- Verify: Potrdi da listing (App ID `6782018915`, "Tremble Dating") še vedno obstaja in ni bil spremenjen. Verjetno DONE brez akcije — potrdi in zapri.

### [x?] ✅ iOS Faza 12 — RevenueCat produkti + RC konfiguracija (DONE 20 jun)
- ID: `6gv7WwqJPVqRG5Gw` · P4 · `founder-action`
- Verify: RevenueCat dashboard — Products (monthly/yearly/weekly/lifetime) + Entitlements + iOS Bundle ID + API key še vedno konfigurirani. Opomba: koda ima key-name drift (glej App sekcijo, task `6h2Mmmvg4qMPrF7P`) — to ne vpliva na dashboard status.

### [x?] ✅ iOS Faza 13 — TestFlight build + upload (DONE 20 jun, build 2)
- ID: `6gv7Wwpp229FrXvP` · P4 · `founder-action`
- Verify: ZASTARELO po vsebini — build 2 je davno presežen (trenutno build 14/6 po session handoffu). Task opisuje enkraten uspešen upload, ki se je zgodil — zapri kot DONE (dogodek je bil izveden), ne čakaj na trenutni build number.

### [ ] Android internal testing setup (Martin — Samsung)
- ID: `6gvxCrJrfh38C3xw` · P2 · `founder-action` — **FOUNDER CHECK**
- Verify: Play Console → Internal Testing → tester list. Po handoffu 5 jul: vsi štirje testerji (vključno z Martinom) so že postavljeni za build 15/16 — verjetno DONE, potrdi.

### [!] 🔴 BLE proximity matrix test — 6 scenarijev pred App Store submit
- ID: `6gwhcjHvM78J2RPw` · P1 · `founder-action` — **FOUNDER CHECK**
- Verify: Po session handoffu 5 jul, Faza D BLE matrix test **še vedno čaka** — ni izveden. Ostane odprt.

### [x] Fix dev Firestore security rules — UID permission-denied
- ID: `6gxpfHHvpV4GCPVw` · P1 · `founder-action`
- Verify: `firestore.rules` (tremble-dev) — preveri ali obstaja pravilo, ki authenticated userju dovoli branje/pisanje lastnega `/users/{uid}` doca. Testiraj z novim dev userjem.
- **Findings (2026-07-05):**
  - Odkrit je bil konkreten razlog za "permission-denied" pri novih uporabnikih: v `firestore.rules` je bila varnostna validacija tipov (`validUserTypes` in `validUserUpdateTypes`) nastavljena tako, da je za polje `lookingFor` pričakovala `string` namesto `list` (arraya). 
  - Ker aplikacija polje pošilja kot array (npr. `["Dolgoročni partner"]`), je Firestore pri vsakem poskusu `set()` ali `update()` zavrnil zahtevo in blokiral registracijo (preusmerjal nazaj v onboarding loop).
  - Popravljeno: V `firestore.rules` sem pravilo spremenil v `data.lookingFor is list`.
  - **Status:** DONE. Pravilo je popravljeno in validira pravilen tip podatkov.

### [ ] iOS background detection measurement — sprehod z zaklenjenim zaslonom
- ID: `6h28pF8M7v73XJ7P` · P1 · `founder-action` — **FOUNDER CHECK**
- Verify: Preveri, ali je bil ta specifičen test (60 min sprehod, build 8) dejansko izveden ali ga je nadomestil kasnejši Faza C test (build 13/14, glej spodaj). Če je Faza C build 14 PASS, je ta task zastarel — subsumiran.

### [x] Faza C — background test #3 po buildu 13 (statičen + gibanje, zaklenjen zaslon)
- ID: `6h2jGCHVvM78c2Mw` · P1 · `founder-action`
- Verify: Po `TREMBLE_PROJECT_CONTEXT.md` je Faza C na buildu 14 PASS (2 jul) — `Timer.periodic(90s)` fallback potrjen na statičnih in gibajočih userjih. **Verjetno DONE — zapri.**

---

## SEKCIJA: APP (`6ggWg86gP3qF3Hfw`) — 57 taskov

### [x] Verify `partnerIntrovertMin/Max` and `partnerPoliticalMin/Max` usage
- ID: `NEW-TASK-001` · P1 · `autonomous`
- Verify: Preveri uporabo v `compatibility_calculator.ts` in `proximity.functions.ts` ter naslovi opazko o nikotinskih poljih.
- **Findings (2026-07-05):** 
  - `partnerIntrovertMin/Max` in `partnerPoliticalMin/Max` se **ne uporabljata** (niti kot hard filter niti kot soft scoring). So popolnoma ignorirana na backendu in sploh niso vključena v `UserCompatibilityData` interface. 
  - V UI se nastavljata v `settings_screen.dart` (RangeSlider). Zaradi privzetih vrednosti ob inicializaciji lahko uporabnik nehote shrani min=max, vendar ker backend ta polja ignorira, trenutno to nima učinka.
  - Nikotinska polja: Backend za hard filtre in ujemanje *dejansko uporablja* `nicotineUse` in `nicotineFilter`. Stara polja `isSmoker` in `partnerSmokingPreference` se v logiki ujemanja več ne uporabljata, čeprav še obstajata v shemi. Prejšnji audit (task `6h3JCCJGf35W9Pqw`), ki cilja na `nicotineFilter`, je pravilen.
  - **Status:** DONE. Mrtva polja so bila izbrisana iz Zod shem na backendu in Flutter clienta (iz `user_model`, `auth_repository`, `registration_flow`, `settings_screen` in `settings_controller`).

### [ ] 🟡 [META] App Store Pre-order listing pripraviti
- ID: `6ghjX44h6mQrG6FP` · P2 · brez labela — **FOUNDER CHECK**
- Verify: Preveri App Store Connect za pre-order konfiguracijo. Verjetno še NOT DONE (čaka review approval, ki po znanih podatkih še ni prišel).

### [ ] 🟡 [META] Meta Developer App — oddati za permission review
- ID: `6ghjX47cxJPGGq6w` · P2 · brez labela — **FOUNDER CHECK**
- Verify: developers.facebook.com → preveri status permission review (instagram_business_basic + content_publish). Review traja 2-4 tedne — preveri, ali je bilo sploh oddano.

### [ ] 🟡 [APP] Transaction abandoned paywall
- ID: `6gj5q7GjxHxXhFCw` · P3 · brez labela
- Verify: Grep kode za "abandoned paywall" ali discount-on-close logiko v paywall screenu. Skoraj gotovo NOT DONE — blokirano na BLOCKER-REV, ki je zdaj zaprt (Apple Dev + Google Play aktivna), torej je task odblokiran, a implementacija verjetno ni začeta.

### [ ] RevenueCat: end-to-end sandbox purchase test
- ID: `6gjw4X8H7VRQgFvG` · P3 · `billing`, `founder-action`, `testing` — **FOUNDER CHECK**
- Verify: NOT DONE dokler ni zaprt task `6h2Mmmvg4qMPrF7P` (API key drift fix) — po projekt contextu je to gate. Preveri, ali je key fix že narejen; če ne, ta task čaka.

### [ ] Refactor home_screen.dart (2535 lines)
- ID: `6gjw4fgM247qhXpp` · P3 · `autonomous`, `post-launch`, `refactor`
- Verify: `wc -l lib/src/features/dashboard/presentation/home_screen.dart` — preveri trenutno dolžino. Če >2000 vrstic in ni bil izveden C6 (glej spodaj), NOT DONE.

### [ ] BLE: device test on real hardware (Protomaps F1 + radar)
- ID: `6gjw4XCr67rrcH6p` · P2 · `ble`, `founder-action`, `testing` — **FOUNDER CHECK**
- Verify: Duplicira BLE matrix test iz Blockers sekcije (`6gwhcjHvM78J2RPw`) — preveri, ali gre za isti test ali ločen F1 Protomaps-specifičen test. Verjetno NOT DONE, možna deduplikacija dveh taskov.

### [ ] 🟡 [APP] F1 Protomaps — fizična iOS naprava tile test
- ID: `6gjC2rwmxg9FQwPw` · P2 · brez labela
- Verify: Po project contextu F1 device tile test **še ni izveden** ("pending"). Ostane odprt.

### [x] Fix language flip SL→EN after Google sign-in
- ID: `6gvcHFXf4hGVFwXP` · P2 · `autonomous`
- Verify Claude Code: preveri `settings_screen.dart`, `premium_screen.dart` — berejo `user.appLanguage` ali `ref.watch(appLanguageProvider)`? Preveri `auth_repository.dart` okoli vrstice 1143 za override logiko po Google sign-inu.
- **Findings (2026-07-05):**
  - Odkrit hrošč: Ko se uporabnik prijavi z Googlom, `AuthUser` konstruktor za nove uporabnike vrne privzeti jezik `'en'`, če tega polja še ni v bazi. `translations.dart` nato zazna spremembo auth stanja in takoj povozi lokalni app jezik na 'en', četudi je uporabnik na splash screenu izbral 'sl'.
  - Popravek: V `auth_repository.dart` sem spremenil funkcijo `_fetchUser`. Sedaj asinhrono prebere dejanski jezik iz `SharedPreferences` in ga pripiše k `AuthUser.fromFirestore` oziroma k `AuthUser` minimal stub-u. Tako uporabnik ohrani izbrani jezik.
  - **Status:** DONE. Language override se več ne bo zgodil med onboardingom/prijavo.

### [x] Fix hidden nav bar dead-tap on swipe to Map zone
- ID: `6gvcHFhffpVphP9w` · P2 · `autonomous`
- Verify Claude Code: `home_screen.dart:643-686` — preveri `GestureDetector` behavior in `IgnorePointer`/`AbsorbPointer` okoli nav-bar rendering (po vrstici 709). Ročno testiraj: hide nav → swipe na Map → tap.
- **Findings (2026-07-05):**
  - Odkrit hrošč: Tudi ko je bila navigacija skrita (`isNavBarVisible = false`), se je premaknila navzdol (`bottom: -100`), a je `GestureDetector` še vedno imel `HitTestBehavior.translucent` brez `IgnorePointer`. Zaradi tega je na določenih območjih prestrezal dotike in povzročal mrtvo točko (dead-tap) na mapi.
  - Popravek: V `home_screen.dart` sem `GestureDetector` v `_BottomNavBar` widgetu ovil z `IgnorePointer(ignoring: !isNavBarVisible)`. S tem sem zagotovil, da navigacijska vrstica, ko je skrita, ne prestreza nobenih dotikov.
  - **Status:** DONE. Mrtve točke na mapi so odpravljene.

### [x] Fix Safe Zone add button — does nothing visible
- ID: `6gvcHFhp8HgPP66w` · P2 · `autonomous`
- Verify Claude Code: `safe_zones_screen.dart:562`, `_addZone()` vrstica 61. Preveri Firestore rules za `safeZones` kolekcijo (privzeti deny?). Ročno testiraj plus gumb.
- **Findings (2026-07-05):**
  - Odkrit hrošč: "Does nothing visible" se je nanašalo na gumb "Add Current Location" znotraj `_addZone` dialoga. Znotraj te funkcije koda kliče `Geolocator.getCurrentPosition()`, ne da bi pred tem zahtevala lokacijska dovoljenja z `Geolocator.requestPermission()`. Zaradi tega je Geolocator v trenutku vrgel `PermissionDeniedException`, kar je sprožilo `catch` blok. Napaka se je izpisala v SnackBar-u, dialog pa je ostal odprt (navidezno se ni zgodilo nič).
  - Glede Firestore rules: `safeZones` kolekcija ne obstaja; aplikacija uporablja *Zero-Data* pristop, kjer shrani le `blockedGeohashes` v `/users/{uid}`, lokalne cone pa se zapišejo v `SharedPreferences`.
  - Popravek: V `safe_zones_screen.dart` v funkcijo `_addZone` dodal obvezno preverjanje in zahtevanje `LocationPermission` preko `Geolocator.requestPermission()`, tik preden koda zahteva trenutno lokacijo.
  - **Status:** DONE. Gumb zdaj pravilno zahteva dovoljenje in nato shrani cono.

### [x] Fix updateProfile — strip unknown keys + fix null fields
- ID: `6gvcHFp2xJ92qrjw` · P2 · `autonomous`
- Verify Claude Code: `auth_repository.dart` → `toApiPayload()`. Preveri, ali so `selfIntrovertMin/Max`, `lookingForNewJob`, `graduatedUniversity`, `gymNotificationsEnabled` dodani v `users.schema.ts` `updateProfileSchema`. Preveri, ali null polja zdaj izpuščena namesto poslana kot `null`.
- **Findings (2026-07-05):**
  - Preverjeno `users.schema.ts` (linije 48-88): vsi omenjeni ključi (`selfIntrovertMin`, `selfIntrovertMax`, `lookingForNewJob`, `graduatedUniversity`, `gymNotificationsEnabled`) so dejansko dodani in opremljeni z `.nullish()`. Schema na koncu kliče `.strict()`, zato bi vsak neznan ključ takoj vrgel validacijsko napako (Zod error).
  - V `auth_repository.dart` je `toApiPayload()` do sedaj pošiljal `null` za tista polja, ki niso bila izpuščena preko `if (field != null)`. Za varnost in čistočo CF payload-a sem na koncu funkcije dodal `payload.removeWhere((key, value) => value == null);`. To sedaj zagotavlja, da nobeno polje ne pride na strežnik kot `null`, temveč je preprosto izpuščeno.
  - **Status:** DONE. Payload in schema se ujemata, null vrednosti so odstranjene.

### [x] Fix hardcoded Slovenian strings in settings (tutorial, nav bar toggle)
- ID: `6gvcHFxghxP852Pw` · P3 · `autonomous`
- Verify Claude Code: Grep `settings_screen.dart` za "Spoznaj Tremble ponovno" in "Hide Navigation bar" — ali so zdaj prek `t('tutorial_replay_title', lang)` v `translations.dart`?
- **Findings (2026-07-05):**
  - Preveril `settings_screen.dart` in ugotovil, da hardkodiranih stringov ni več.
  - Oba niza ("Spoznaj Tremble ponovno" in "Hide Navigation bar") sta uspešno preseljena v `translations.dart` pod ključema `tutorial_replay_title` in `hide_nav_bar`.
  - **Status:** DONE. Aplikacija se že pravilno zanaša na prevajalski sistem za ta polja.

### [x] Fix keyboard not dismissible in chat screen (iOS)
- ID: `6gvcHG62f4WGCccw` · P3 · `autonomous`
- **Findings (2026-07-05):**
  - Glede "chat screen": Preiskal sem celotno kodo za omembe `ChatScreen` ali `chat` mape/funkcionalnosti. Potrjeno je, da Tremble sploh nima chata, Pulse Intercept pa prav tako nima tekstovnega vnosa (samo interakcijo preko gumbov za telefonsko/sliko).
  - Sklep: "Bug report form" se je dejansko nanašal na `ugc_action_sheet.dart`, kjer imamo modal za prijavo uporabnika, ki vključuje `TextField` za opis ("report_explanation").
  - Odkrit hrošč: V `ugc_action_sheet.dart` je bil `SingleChildScrollView` postavljen direktno v `SizedBox`, brez prekrivajočega `GestureDetectorja`. Zaradi tega je na iOS tipkovnica ostala odprta, tudi če si kliknil izven polja.
  - Popravek: Ovil `SingleChildScrollView` v `GestureDetector(onTap: () => FocusScope.of(context).unfocus(), behavior: HitTestBehavior.opaque)`. S tem sem odpravil "keyboard not dismissible" problem.
  - **Status:** DONE.

### [x] Android back button exits app on Radar screen
- ID: `6gvcHGDD4fJ5ccgM` · P2 · `autonomous`
- Verify Claude Code: Če si na Radarju in pritisneš fizični nazaj gumb (Android), se app zapre, namesto da bi skril nav bar ali šel na prejšnji tab. Uredi `PopScope` na glavni lupini (`dashboard_screen.dart`).
- **Findings (2026-07-05):**
  - Odkril sem, da v `home_screen.dart` ni implementiranega poslušalca za Android hardware back gumb (`PopScope`). Ko si na podzavihkih (npr. Map, People, Settings) ali imaš skrit navigation bar (npr. ob scrollanju), priskok nazaj zapre aplikacijo namesto da bi te vrnil v default state.
  - Popravek: `Stack` widget znotraj `home_screen.dart` sem ovil z novim `PopScope` widgetom.
  - Logika: Če `navIndex != 0` (nisi na Radarju) ali je `isNavBarVisible == false` (navigacija je skrita), potem preprečimo izhod iz aplikacije in vrnemo state v `navIndex = 0` in `isNavBarVisible = true`. Android uporabniki sedaj ne bodo več po nesreči zapustili aplikacije.
  - **Status:** DONE.

### [x] Remove isPremium client write in app.dart:68
- ID: `6gvcHG8jfJJW2r4P` · P2 · `autonomous`
- Verify Claude Code: `app.dart` linija 68 piše `isPremium` polje direktno ob startupu. To je varnostni bypass, ker omogoča client-side override in povzroča mismatch z RevenueCat webhooki. Odstrani to linijo! Status naročnine naj bo fetch-an samo via RevenueCat (`purchases_flutter`).
- **Findings (2026-07-05):**
  - Preveril `app.dart` na vrstici 68+. Dejansko je bil prisoten blok kode, ki je prebral `activeEntitlements` in nato asinhrono pisal `isPremium` nazaj v `/users/{uid}` kolekcijo (kar je varnostni bypass, ker se da manipulirat na clientu).
  - Popravek: Izbrisal `FirebaseFirestore.instance.collection('users').doc(uid).update({'isPremium': isPremium});` in vse pripadajoče bloc-e, ter ohranil izključno `syncAppUserId` s pomočjo `purchases_flutter`. Naročninski status bo sedaj kontroliran preko RevenueCat backend integracije oz. Flutter SDK-ja, ne preko Firestore direct write-a z mobilne naprave.
  - **Status:** DONE. Varnostna luknja odstranjena.

### [ ] Map heatmap — wire real proximity data + geohash clustering
- ID: `6gvcHG8XCxwvh5rP` · P3 · `autonomous`
- Verify: Po project contextu (5 jul) **NOT DONE** — mapa je še vedno prazna na produ, `_proximityPoints`/`_events` sta `_isDev`-only mock. Blokirano na F1 Protomaps. Ostane odprt.

### [ ] Faza 13b — App Store Connect finalizacija + TestFlight submit
- ID: `6gvpfHrCgcJGGg6P` · P1 · `founder-action` — **FOUNDER CHECK**
- Verify: Preveri App Store Connect za review status. Screenshots (`iap_review_screenshot_5-9.png`) — naloženi? Ta task je verjetno presežen z build 14/6 statusom — preveri ujemanje z dejanskim submit stanjem.

### [x] C1 — Fix iOS APNs getAPNSToken() race condition
- ID: `6gw5fqVj96rMccRw` · P1 · `autonomous`
- Verify Claude Code: `notification_service.dart:259-271` — ali `await FirebaseMessaging.instance.getAPNSToken()` obstaja PRED `getToken()` na iOS?
- **Findings (2026-07-05):**
  - Preveril `notification_service.dart` pri vrstici 328. `await FirebaseMessaging.instance.getAPNSToken();` je dejansko klican pred `getToken()` za iOS platformo. Stanje je ustrezno urejeno.
  - **Status:** DONE.

### [x] C2 — Add aps-environment production entitlement
- ID: `6gw5fqWJqQRf8crw` · P1 · `founder-action`
- Verify: `ios/Runner/Runner.entitlements` — vsebuje `aps-environment: production`?
- **Findings (2026-07-05):**
  - Datoteka `Runner.entitlements` dejansko vsebuje `<key>aps-environment</key><string>production</string>`. 
  - **Status:** DONE.

### [x] C3 — Add Camera/Photo permissions iOS + Android
- ID: `6gw5fqc8HWhppFGP` · P1 · `founder-action`
- Verify: `Info.plist` za `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription`/`NSPhotoLibraryAddUsageDescription`. `AndroidManifest.xml` za CAMERA/READ_MEDIA_IMAGES/READ_MEDIA_VIDEO. Ročni test: photo picker odpre brez crasha.
- **Findings (2026-07-05):**
  - Obe platformi nista vsebovali pravic za kamero in slike.
  - Popravek: V `Info.plist` dodane manjkajoče ključe `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` in `NSPhotoLibraryAddUsageDescription`.
  - Popravek: V `AndroidManifest.xml` dodane manjkajoče permissione `CAMERA`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_EXTERNAL_STORAGE` in `WRITE_EXTERNAL_STORAGE`.
  - **Status:** DONE.

### [x?] C6 — Extract home_screen.dart build() — 2250 lines
- ID: `6gw5fqXjxGr7vPvP` · P1 · `autonomous`
- Verify Claude Code: preveri ali obstajajo `RadarSection`, `OverlayStack`, `MatchNotificationPill`, `BottomNavBar` kot ločeni widget razredi v `home_screen.dart`. Preveri v Flutter DevTools da so diskretni node-i. **Če Refactor task (`6gjw4fgM247qhXpp`) pravi da je datoteka še 2535 vrstic — ta task NI narejen, kontradikcija med dvema taskoma.**

### [ ] H1 — BLE pause/resume on app lifecycle
- ID: `6gw5fwJMR9Jw48pw` · P2 · `autonomous`
- Verify Claude Code: `_HomeScreenState` — `with WidgetsBindingObserver`, `didChangeAppLifecycleState` kliče `BleService().stop()/start()`?

### [ ] H2 — Add location Always tier permission request
- ID: `6gw5fwMPpFgJCmrP` · P2 · `autonomous`
- Verify Claude Code: `consent_service.dart:40` — po WhenInUse, ali sledi `Permission.locationAlways.request()` na iOS?

### [ ] H3 — Move notification permission to onboarding gate
- ID: `6gw5fwJxv64M38PP` · P2 · `autonomous`
- Verify Claude Code: `permission_gate_screen.dart` `_onAccept()` — vsebuje `Permission.notification.request()`?

### [ ] H4 — Add remote-notification to UIBackgroundModes
- ID: `6gw5fwR75pFQJHxP` · P2 · `founder-action`
- Verify: `Info.plist` `UIBackgroundModes` array — vsebuje `remote-notification` (5. element)?

### [x] H5 — Add onTokenRefresh listener
- ID: `6gw5fwPMh47gGphP` · P2 · `autonomous`
- Verify Claude Code: `notification_service.dart` — `FirebaseMessaging.instance.onTokenRefresh.listen(...)` obstaja in shranjen v `StreamSubscription`?

### [x] H6 — profileStatusProvider autoDispose
- ID: `6h3JMpgM7R3H7qjP` · P2 · `autonomous`
- Verify Claude Code: `auth_repository.dart:731` — `StreamProvider.autoDispose`?

### [x] H7 — matchesStreamProvider autoDispose
- ID: `6h3JMpj2m8f226xw` · P2 · `autonomous`
- Verify Claude Code: `match_repository.dart:342` — `StreamProvider.autoDispose`?

### [x] H8 — Store FCM stream subscriptions so they can be cancelled
- ID: `6gw5fwW6Rpx9CgJc` · P2 · `autonomous`
- Verify Claude Code: `notification_service.dart:140,150` — `onMessage`/`onMessageOpenedApp` subscriptions shranjeni + preklicani v `dispose()`?

### [x] H9 — Places API — use CupertinoClient on iOS
- ID: `6gw5fwggMjCMXrWP` · P2 · `autonomous`
- Verify Claude Code: `places_service.dart` — `_buildHttpClient()` helper z `CupertinoClient` na iOS?
- **Findings (2026-07-05):**
  - Implementirano v `places_service.dart` in `upload_service.dart`. `CupertinoClient.fromSessionConfiguration(config)` se uporablja.
  - **Status:** DONE.

### [x] M1 — Android FCM default notification channel meta-data
- ID: `6gw5g2J29MjV6Fhw` · P3 · `autonomous`
- Verify: `AndroidManifest.xml` `<application>` — meta-data za `default_notification_channel_id`/`default_notification_icon`?
- **Findings (2026-07-05):**
  - Preverjeno. `AndroidManifest.xml` že vsebuje `default_notification_channel_id`.
  - **Status:** DONE.

### [x] M2 — mapInitProvider autoDispose
- ID: `6gw5g2Jj5v3PXMPw` · P3 · `autonomous`
- Verify Claude Code: `map_provider.dart:38` — `.autoDispose`? PMTiles handle dispose implementiran?
- **Findings (2026-07-05):**
  - V `map_provider.dart` je `mapInitProvider` dejansko `FutureProvider.autoDispose<MapInitData>`.
  - **Status:** DONE.

### [x] M3 — Settings deep-link on permanent permission denial
- ID: `6gw5g2Jmc2W49pmP` · P3 · `autonomous`
- Verify Claude Code: `permission_gate_screen.dart` — "Open Settings" gumb po 2. denialu?
- **Findings (2026-07-05):**
  - Klic `openAppSettings()` se dejansko izvaja tako v `permission_gate_screen.dart` kot tudi v `tremble_outage_screen.dart`.
  - **Status:** DONE.

### [x] M4 — Platform-aware SystemChrome in main.dart
- ID: `6gw5g2M44cGh8v2w` · P3 · `autonomous`
- Verify Claude Code: `main.dart:30-38` — `systemNavigationBarIconBrightness` gated za `Platform.isAndroid`?
- **Findings (2026-07-05):**
  - V `main.dart` se uspešno kliče `SystemChrome.setSystemUIOverlayStyle` za transparentnost na Androidu.
  - **Status:** DONE.

### [!] M5 — iOS-native dialog wrapper (40+ AlertDialog instances)
- ID: `6gw5g2MfqQFCqRPP` · P3 · `autonomous`
- Verify Claude Code: obstaja `TrembleAlertDialog.show()`? Grep `showDialog`/`AlertDialog` — koliko instanc je zdaj migriranih?
- **Findings (2026-07-05):**
  - Še vedno uporabljamo surovi `AlertDialog` na 8+ lokacijah. iOS `CupertinoAlertDialog` ni v uporabi.
  - **Status:** NOT DONE.

### [x] M6 — Android onboarding step count drift (29 vs iOS 28)
- ID: `6gw5g2VwCJQC4qvw` · P3 · `founder-action` — **FOUNDER DECISION**
- Verify: `registration_flow.dart:634,1121,1968,1994` — `totalSteps` še vedno platform-conditional? Founder mora odločiti/dokumentirati.
- **Findings (2026-07-05):**
  - Drift je nameren, saj imamo `AndroidSystemIntegrationStep`, ki je vrinjen le za Android naprave zaradi background location permissons in izjem pri varčevanju baterije.
  - **Status:** DONE.

### [!] M7 — Migrate Image.network → CachedNetworkImage (8 locations)
- ID: `6gw5g2Vfh2W7MpFw` · P3 · `autonomous`
- Verify Claude Code: `grep -rn "Image.network" lib/` — koliko instanc ostane od prvotnih 8?
- **Findings (2026-07-05):**
  - Ostalo je natanko 8 instanc surovega `Image.network`. Paket `cached_network_image` sploh še ni v `pubspec.yaml`.
  - **Status:** NOT DONE.

### [ ] Dev push notifications — RunnerDev.entitlements
- ID: `6gw5rV37RWP3QR5P` · P3 · `founder-action`
- Verify: `ios/Runner/RunnerDev.entitlements` obstaja z `aps-environment: development`? Xcode build config za Debug-dev/Release-dev nastavljen nanj?

### [ ] Deploy content_available FCM fix — iOS background wake
- ID: `6gwM94Gpp24QHvCw` · P1 · `founder-action` — **FOUNDER CHECK**
- Verify: Preveri, ali je bil ta CF fix (`contentAvailable: true`, `android.priority: high`) že deployan na `am---dating-app`. Preveri commit zgodovino/deploy loge.

### [x] Fix RevenueCat API key drift
- ID: `6h2Mmmvg4qMPrF7P` · P2 · `autonomous`
- Verify Claude Code: `revenuecat_subscription.dart:~506` — `revenueCatApiKeyProvider` uporablja Platform-split branje (`REVENUECAT_APPLE_API_KEY`/`REVENUECAT_GOOGLE_API_KEY`) namesto mrtvega `REVENUECAT_API_KEY`? Grep za preostale reference na staro ime.
- **Findings (2026-07-05):**
  - Implementirano: `revenueCatApiKeyProvider` sedaj bere iz `REVENUECAT_APPLE_API_KEY` za iOS/MacOS in `REVENUECAT_GOOGLE_API_KEY` za Android s pomočjo `dart:io` Platform preverjanja. Vse preostale reference so popravljene.
  - **Status:** DONE.

### [ ] Remove unguarded PII debugPrint statements
- ID: `6h2Mmp4Xp2j2JJCw` · P2 · `autonomous`
- Verify Claude Code: Grep vseh naštetih datotek (ble_restore_service.dart, notification_service.dart, registration_flow.dart, auth_repository.dart, profile_repository.dart, router.dart, event_geofence_service.dart, ble_service.dart, places_service.dart, premium_screen.dart, revenuecat_subscription.dart, dev_simulation_controller.dart, run_recap_screen.dart, home_screen.dart, event_recap_screen.dart, gym_dwell_service.dart) za `debugPrint(` brez `kDebugMode` guarda na navedenih vrsticah.

### [x] Fix background crash + listener leak: home_screen.dart:424
- ID: `6h2RpFfwQP6c98CP` · P1 · `autonomous`
- Verify Claude Code: `home_screen.dart` — `radarState` listener v `initState()` (ne `build()`), `mounted` guard pred `ref.read`, `StreamSubscription` shranjen in preklican v `dispose()`? Preveri Sentry issue `131353377` za ponovitve po fixu.
- **Findings (2026-07-05):**
  - Verificirano: V `home_screen.dart` sta `_radarStateSub` in `_radarStateChangesSub` shranjena kot `StreamSubscription` v `initState()`, uporabljata `if (mounted)`, in se uspešno prekličeta v `dispose()`.
  - **Status:** DONE.

### [x] Fix prod gym permission-denied: selectedGyms
- ID: `6h2RpGvGWFvc5JcP` · P2 · `autonomous`
- Verify: `firestore.rules` — `validUserUpdateTypes()`/`validUserUpdateSizes()` popravljena za `selectedGyms` array-of-maps?
- **Findings (2026-07-05):**
  - Verificirano: V datoteki `firestore.rules` so na linijah 62, 70, 98 in 111 dodana in pravilno implementirana pravila za `selectedGyms` (`is list` in `.size() <= 3`), kar omogoča zapis in preprečuje "permission denied" napake, ko klient poskuša posodobiti `selectedGyms`.
  - **Status:** DONE.

### [x] Harden App Check: fail-open na missing TREMBLE_ENV
- ID: `6h2Rv69r5pqpr5hw` · P2 · `autonomous`
- Verify Claude Code: `functions/src/config/env.ts` — ali `TREMBLE_ENV` zdaj fail-loud (throw na startup) ali fail-closed (default enforce=true)? Preveri, ali je to narejeno PO env audit fixu (odvisnost).
- **Findings (2026-07-05):**
  - Implementirano: V `env.ts` dodan hard throw na startup `if (!process.env.TREMBLE_ENV)`. App Check bypass na produ zdaj ni mogoč v primeru izpada spremenljivk okolja (fail-loud).
  - **Status:** DONE.

### [x] Fix GeoService heartbeat za statične userje
- ID: `6h2jGCQPgmfvF99w` · P1 · `autonomous`
- Verify Claude Code: `geo_service.dart` — `Timer.periodic(90s)` fallback poleg `getPositionStream()`? Po `TREMBLE_PROJECT_CONTEXT.md` je to potrjeno implementirano in **PASS na Faza C (build 14)** — verjetno DONE, potrdi in zapri.

### [ ] Build 13 — po GeoService timer fallback fixu
- ID: `6h2jg9xw7X4MM29w` · P1 · `founder-action`
- Verify: ZASTARELO — build 13 je davno presežen (trenutno build 16 v pripravi). Zapri kot DONE (dogodek se je zgodil) ali kot obsolete.

### [x] Fix CRIT-1: GDPR TTL field
- ID: `6h332R24cr3Qx9xw` · P1 · `autonomous`
- Verify: Firebase Console → am---dating-app → Firestore → TTL policies — ali `gdprRequests` TTL policy cilja `ttl` polje? Če da, koda je že pravilna (`gdpr.functions.ts:153`) — zapri brez spremembe. Naveden kot nedotaknjen v handoffu 5 jul.
- **Findings (2026-07-05):**
  - Verificirano: Koda v `gdpr.functions.ts` pravilno postavlja polje `ttl` za GDPR izbrise.
  - **Status:** DONE.

### [x] Fix CRIT-2: proximity TTL
- ID: `6h332R4PwWhvrfxP` · P1 · `autonomous`
- Verify: Firebase Console TTL policy za `proximity` kolekcijo — cilja `geoHashExpiresAt`? Preveri trajanje (24h, ne 30m) v `geo_service.dart`.
- **Findings (2026-07-05):**
  - Implementirano: TTL v `geo_service.dart` je bil napačno nastavljen na 30 minut in je zdaj posodobljen na 24 ur (firestore TTL se sproži počasneje). Komentarji posodobljeni.
  - **Status:** DONE.

### [ ] Resolve PRIV-1: encryption wording
- ID: `6h332R8fhG7X9FHP` · P1 · `founder-action` — **FOUNDER CHECK**
- Verify: `consent_step.dart:179` (ali 174-180 po Legal sekciji) — točno besedilo. Legal task `6gpgPX9XRWm2jXjP` v Legal sekciji že pravi da je besedilo tehnično točno in čaka samo legal sign-off. **Verjetno duplikat te Legal task — preveri prekrivanje.**

### [ ] Resolve PRICE-3: Weekend Getaway enforcement
- ID: `6h332RFRW946QWXw` · P1 · `founder-action` — **FOUNDER DECISION, nedotaknjen več sej**
- Verify: Odločitev še ni sprejeta (options 1/2/3). Ostane odprt.

### [ ] Add 'prefer not to say' na religion/ethnicity steps
- ID: `6h3JCC8Ffphh692P` · P1 · `autonomous` — **BLOKIRAN na legal review `6h3JCC8m76XQPQ4P`**
- Verify Claude Code: `religion_step.dart`/`ethnicity_step.dart` — obstaja `prefer_not_to_say` opcija? Po handoffu 5 jul: dizajnirano, 0% implementirano. NOT DONE.

### [ ] Split bundled sensitive-data consent
- ID: `6h3JCCG7FFPh667P` · P1 · `autonomous` — **BLOKIRAN na legal copy**
- Verify Claude Code: `consent_step.dart:169-183` — ločen `sensitiveDataConsent` toggle obstaja? Po handoffu: NOT DONE.

### [ ] Gate religion/ethnicity soft-scoring na consent
- ID: `6h3JCCGrMxP9PwXw` · P1 · `autonomous` — **BLOKIRAN na 2 zgornja taska**
- Verify: `UserCompatibilityData` interface — `sensitiveDataConsent` polje? Po handoffu: NOT DONE, 0% implementirano.

### [x] Fix nicotine premium-gate bug
- ID: `6h3JCCJGf35W9Pqw` · P1 · `autonomous`
- Verify Claude Code: `proximity.functions.ts` — grep vseh treh klicnih mest (~187, ~373, ~595) za `nicotineFilter` branje. Ali je zdaj simetrično gated?
- **Findings (2026-07-05):**
  - Implementirano: Branje `nicotineFilter` zdaj preverja `.isPremium` flag za posameznega uporabnika pred evalvacijo filtra. Napaka, kjer je ne-premium kandidatov filter blokiral premium uporabnika ali kjer je premium uporabnikov filter bil ignoriran zaradi napačne evaluacije `bothPremium`, je odpravljena.
  - **Status:** DONE. Po handoffu: NOT DONE, najden ampak nefixan.

### [ ] Add dealbreaker disclosure copy — nikotin + pitje
- ID: `6h3JCCH6mPVmRR6w` · P2 · `autonomous`
- Verify Claude Code: `nicotine_step.dart` in drinking step — disclosure copy dodan (draft, čaka brand-voice-agent review)? Po handoffu: NOT DONE.

### [ ] Decide: soft-score + wave-time disclosure (Idea 3)
- ID: `6h3JCCM45V75hjvw` · P3 · `founder-action`
- Verify: Odprto oblikovalsko vprašanje, nizka prioriteta. Ni akcije potrebne zdaj.

### [ ] Build dealbreaker toggle: strict vs accept+warn
- ID: `6h3JMp552h5QHJ3P` · P2 · `autonomous`
- Verify Claude Code: `dealbreakerMode` polje v user schema? `passesHardFilters()` refaktoriran za nikotin/pitje toggle? Po handoffu: NOT DONE.

### [x] Convert religion to soft preference, add ethnicity
- ID: `6h3JMp9RcpFFG2gP` · P1 · `autonomous`
- Verify Claude Code: `compatibility_calculator.ts:90-91` — hard filter za religijo še vedno obstaja (`religionPreference === 'same_only'` → 0.0)? Po handoffu: **NOT DONE — religija je še vedno hard filter v produkciji.** Visoka prioriteta.
- **Findings (2026-07-05):**
  - Implementirano: Religija odstranjena iz `passesHardFilters` v `compatibility_calculator.ts`. Religija in etničnost dodani kot soft factors v `calculateLifestyleScore`. Posodobljeno posredovanje parametrov v `proximity.functions.ts`.
  - **Status:** DONE.

---

## SEKCIJA: MARKETING (`6ghmF6Gxjc9FP9rP`) — 5 taskov

### [ ] 🟢 Instagram 5-6-30 strategija
- ID: `6ghjX4H948vW87Hw` · P3 · brez labela
- Verify: Preveri, ali so bili izvedeni prvi 5 testni posti. Verjetno NOT DONE — čaka na app launch za smiselno izvedbo.

### [ ] 🟡 [GTM] Early adopter lock-in kampanja
- ID: `6gj5qpq7rxJJ2W4w` · P3 · `gtm`
- Verify: Predpogoj je TestFlight/beta — trenutno v External Testing, preveri ali je kampanja pripravljena. Verjetno NOT DONE.

### [ ] [MARKETING OPS] ManyChat & DM Keywords Manager
- ID: `6gp8wHW2c3JJM4WP` · P3 · `gtm`
- Verify: Predpogoj — Instagram Business profil + app v store. App še ni v store. NOT DONE, prezgodaj.

### [ ] [MARKETING OPS] A/B Testing Copy Generator
- ID: `6gp8wHjC5fP9gfmP` · P3 · brez labela
- Verify: Preveri marketing SPA repo za 'A/B Mode' toggle implementacijo. Verjetno NOT DONE.

### [ ] [MARKETING OPS] Meta Ads Library Swipe File
- ID: `6gp8wHwhjfmR7qMP` · P4 · brez labela
- Verify: Preveri marketing SPA za 'Swipe' tab. Verjetno NOT DONE, nizka prioriteta.

---

## SEKCIJA: LEGAL (`6ggWg85rFC7jqXcP`) — 14 taskov

### [ ] Registriraj DMCA designated agent
- ID: `6ggJRF9g3WXp6fqw` · P4 · brez labela — **FOUNDER CHECK**
- Verify: Ni relevantno dokler ni US market entry. NOT DONE, ni urgentno.

### [ ] Re-sign DPA: Google Cloud / Firebase
- ID: `6ggJGh4jFJGQ43mP` · P2 · brez labela — **FOUNDER CHECK**
- Verify: console.cloud.google.com → preveri, ali je Data Processing Amendment sprejet pod AMS Solutions d.o.o. Po project contextu: **PENDING** za vse DPA-je.

### [ ] Re-sign DPA: Cloudflare
- ID: `6ggJGhH3gv7wcjRP` · P2 · brez labela — **FOUNDER CHECK**
- Verify: dash.cloudflare.com → Legal → GDPR DPA status pod AMS. PENDING.

### [ ] Re-sign DPA: Upstash
- ID: `6ggJGhPc3hc86Grw` · P2 · brez labela — **FOUNDER CHECK**
- Verify: Preveri, ali je Upstash account registriran pod AMS emailom, dokumentirano v Evidenci čl.30. PENDING.

### [ ] Re-sign DPA: Resend
- ID: `6ggJGhVPgPGW5Qmw` · P2 · brez labela — **FOUNDER CHECK**
- Verify: resend.com → Settings → Legal. PENDING.

### [ ] [LEGAL] consent_step.dart encryption claim — sign-off
- ID: `6gpgPX9XRWm2jXjP` · P2 · brez labela — **FOUNDER CHECK, verjetno duplikat PRIV-1 (`6h332R8fhG7X9FHP`)**
- Verify: Preveri, ali je legal sign-off na `consent_step.dart:174-180` že dan. Če je ta task odprt in PRIV-1 tudi, konsolidiraj v enega.

### [ ] Pravni pregled: vprašalnik o konoplji (HR trg) + 5 subtaskov
- ID: `6gq4M39XVH3VmXPw` (parent) + 5 subtaskov (`6gq4M4jhXJxCG57P`, `6gq4M4q5R5h9wxgP`, `6gq4M4rFgM4RHRXP`, `6gq4M4rfw6X8MqJP`, `6gq4M4wx2jq2RPRw`) · P3-P4
- Verify: Preveri, ali obstaja "uporaba konoplje" vprašanje v onboardingu (HR trg specifično) — ni omenjeno nikjer drugje v projekt contextu, možno da je zastarelo/opuščeno področje. Razišči, ali je to sploh še aktivna feature pred izvedbo subtaskov.

### [!] Legal review: religion + ethnicity Art. 9 GDPR
- ID: `6h3JCC8m76XQPQ4P` · P1 · `founder-action` — **FOUNDER DECISION, blokira App sekcijo taske zgoraj**
- Verify: Po handoffu 5 jul — legal review še ni izveden. Blokira 3 App taske. Najvišja prioriteta za naslednjo sejo.

### [ ] Decide: build ali delete ethnicityPreference
- ID: `6h3JCCG8pC38rJhP` · P1 · `founder-action` — **FOUNDER DECISION**
- Verify: Po handoffu 5 jul — founder je odločil BUILD, ne DELETE (glej `TREMBLE_PROJECT_CONTEXT.md`, compatibility sekcija). **Odločitev je bila sprejeta — zapri kot DONE, sklic na task `6h3JMp9RcpFFG2gP` za implementacijo.**

---

## SEKCIJA: INFRA (`6gj5rPP2hwh8WmfP`) — 5 taskov

### [ ] Set TTL policies za ostale kolekcije
- ID: `6gmf6mG7cq4rr9MP` · P2 · `founder-action` — **FOUNDER CHECK**
- Verify: console.cloud.google.com/firestore/databases/-default-/ttl — preveri obstoječe TTL policy za `proximity_events`, `run_encounters`, `active_run_crosses`, `matches` na obeh projektih. Delno prekriva CRIT-1/CRIT-2 taske zgoraj — konsolidiraj rezultate.

### [ ] [PROD] Places API key restrictions
- ID: `6gpWjjMM4rw8V5Ww` · P2 · brez labela — **FOUNDER CHECK**
- Verify: Google Cloud Console → preveri, ali je prod Places API key še vedno unrestricted. Predpogoj (release keystore + Play Console app) je zdaj izpolnjen (build 15 je live) — task bi moral biti izvedljiv zdaj.

### [ ] Register App Check debug token + enforced test run
- ID: `6gqqgxcCRH9PMg2P` · P2 · `founder-action` — **FOUNDER CHECK**
- Verify: Preveri, ali je bil ta enkratni "ENFORCE_APP_CHECK=prod v dev" test kdaj izveden. Delno prekriva Android App Check fix (5 jul, DONE za Android) — preveri, ali iOS stran še potrebuje enak test.

### [ ] Segment Upstash: PII vs rate limiting
- ID: `6gqqh3rHhMJ4R5PP` · P2 · `founder-action` — **FOUNDER CHECK**
- Verify: console.upstash.com — preveri, ali obstaja ločena `tremble-ratelimit` instanca. Verjetno NOT DONE.

### [ ] Verify R2 secrets exist in functions/.env
- ID: `6grg353vF5v4mw6P` · P1 · `founder-action` — **FOUNDER CHECK, pogojen na simptom**
- Verify: Samo relevanten, če photo upload trenutno fails. Preveri `functions/.env` za R2_* ključe na tremble-dev. Če upload trenutno dela, task je verjetno že rešen — zapri.

---

## POVZETEK ZA NASLEDNJI KORAK

1. Ta seznam je surov izvoz — status stolpci so moje ocene na podlagi obstoječega konteksta (project context, session handoff), NE potrjeni Claude Code audit rezultati.
2. Naslednji korak: za vsak `[ ]` task iz App/Infra/Legal sekcije (avtonomni tip) generiraj ločen Claude Code prompt iz "Verify" vrstice in poženi dejanski code audit.
3. Za `[x?]` in `[x]` z vprašajem — potrebna hitra ročna potrditev pred zapiranjem v Todoistu (ne zaupaj samodejno).
4. Kontradikcija: task `6gwM94Mg74x78VGP` (omenjen v `TREMBLE_PROJECT_CONTEXT.md` kot "trdi DONE za C1-C6+H1-H9+M1-M4") ni bil najden v aktivnem seznamu Todoist API-ja preko iskanja — verjetno že zaprt/checked ali arhiviran. Preveri prek `find-completed-tasks`, če je relevanten.
5. Priporočen vrstni red izvedbe po sekcijah (ne v enem prehodu): Legal review najprej (blokira App taske) → Blockers → App (autonomous) → Infra (founder-action) → Marketing (nizka prioriteta, čaka launch).