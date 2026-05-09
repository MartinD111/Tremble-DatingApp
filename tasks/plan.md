# UI & UX Polish Implementation Plan

**Plan ID**: 20260509-UI-POLISH
**Risk Level**: MEDIUM
**Branch**: feature/ui-ux-polish

Ta dokument vsebuje strukturiran načrt za odpravo vseh 7 napak in pomanjkljivosti, ki si jih opazil na fizični napravi. Lotili se jih bomo sistematično, od lažjih UI popravkov do native (iOS) crashov.

---

## 1. OBJECTIVE
Odpraviti vizualne anomalije (bele robove, nevidne gumbe), urediti lokalizacijo in perzistenco jezika, zamenjati pokvarjeno ikono radarja s custom Flutter animacijo ter preprečiti crash ob uporabi Gym Mode / Radar state kanalov.

## 2. SCOPE
- **Localization:** `sl.json`, `en.json`, Login screen, Language Provider.
- **UI/UX:** Permission gate (Tutorial), Gym Mode bottom sheet, Scaffold/SafeArea backgrounds.
- **Animations:** Radar core widget (zamenjava belega kvadrata za custom SVG/Canvas animacijo srčnega utripa).
- **Native iOS:** `AppDelegate.swift` (registracija `app.tremble/motion` kanala in popravek `app.tremble/radar`).

## 3. STEPS & EXECUTION PLAN

### Faza 1: Lokalizacija in perzistenca (Issues #1, #3)
1. **"Are you new" hardcoded text:**
   - Preveriti `login_screen.dart` (ali `auth_screen.dart`).
   - Dodati ključ `"are_you_new": "Nimaš računa?"` (ali podobno) v `sl.json` in `en.json`.
   - Zamenjati hardcoded text z `context.tr('are_you_new')`.
2. **Jezik se ponastavi po prijavi:**
   - Preveriti `appLanguageProvider` in Riverpod state.
   - Jezik se ob avtentikaciji verjetno ponastavi (ker se provider invalidira ali prebere default locale naprave).
   - Zagotoviti, da se izbira jezika takoj shrani v `SharedPreferences` in obdrži tudi, ko se `authStateChanges` spremeni.

### Faza 2: Vizualni popravki (Issues #2, #6, #7)
1. **Beli rob na dnu zaslona (#2):**
   - V `main.dart` ali globalni `theme.dart` preveriti `Scaffold` background color. Zgleda, da ima `SafeArea` ali dno zaslona belo ozadje.
   - Nastaviti `SystemChrome.setSystemUIOverlayStyle`, da bottom navigation bar ustreza dark/light temi (ali transparentno).
2. **Gym Mode "Cancel" gumb neviden (#7):**
   - V `gym_mode_sheet.dart` (ali podobnem widgetu) je gumb `Cancel` uporabil belo barvo teksta na svetlem ozadju (GlassCard).
   - Spremeniti barvo teksta v temno sivo (`#1A1A18`) ali primarno roza (`#F4436C`).
3. **Tutorial vizualno nepraktičen (#6):**
   - Popraviti contrast in padding na `permission_gate_screen.dart`.
   - Zamenjati sivo ozadje / temen tekst z ustreznimi Tremble brand barvami (npr. Deep graphite za tekst, če je svetlo ozadje).

### Faza 3: Radar Ikona in Custom Animacija (#4)
1. **Odstranitev belega kvadrata:**
   - V `radar_screen.dart` odstraniti pokvarjen `SvgPicture` ali `Image`, ki povzroča bel kvadrat.
2. **Implementacija CustomPainterja za srce in valove:**
   - Ker Flutter ne podpira CSS `@keyframes` in SVG filtrov (`feGaussianBlur`) direktno, bom ustvaril `CustomPainter` (npr. `TrembleRadarHeart`).
   - Z uporabo `AnimationController` bomo poustvarili `liquid-pulse` animacijo, kjer se `.wave-inner`, `.wave-mid` in `.wave-outer` s faznim zamikom (delay) širijo in spreminjajo `opacity` in `strokeWidth`.
   - Za "bloom" filter bomo uporabili `MaskFilter.blur` znotraj `Paint` objekta.

### Faza 4: Native Crash - MethodChannels (#5)
1. **Manjkajoč `app.tremble/motion` kanal:**
   - V `AppDelegate.swift` dodati `FlutterMethodChannel` za `"app.tremble/motion"`.
   - Implementirati dummy/proxy klice za `startMonitoring` in `stopMonitoring`, da aplikacija ne crasha (ali pa dejansko povezati z native CoreMotion, če je to planirano).
2. **`app.tremble/radar` kanal MissingPluginException:**
   - V logih: `MissingPluginException(No implementation found for method setRadarActive on channel app.tremble/radar)`.
   - Preveriti, ali je bil `binaryMessenger` pravilno podan in ali je kanal sploh odprt, preden Flutter začne pošiljati sporočila. 

## 4. RISKS & TRADEOFFS
- **Radar Animacija:** Complex SVG-ji z zunanjim CSS ne delujejo out-of-the-box v Flutterju (`flutter_svg` ne podpira `@keyframes`). Prepis v `CustomPainter` bo vzel nekaj vrstic kode, a bo na koncu veliko bolj performanten (60fps) kot renderiranje SVG-ja.
- **Native iOS Channels:** Treba je biti previden pri `AppDelegate.swift`, da ne zmotimo obstoječih Firebase in Flutter konfiguracij.

## 5. VERIFICATION
- Zagnati `flutter analyze` in `flutter test` po končanih UI spremembah.
- Preveriti `SharedPreferences` za shranjevanje jezika.
- Hot restart naprave, da testiramo, če `MissingPluginException` izgine.
