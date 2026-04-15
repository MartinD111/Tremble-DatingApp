# Permanent Project Knowledge (Lessons)

Rule #1
[2026-03-31] Never run un-flavored `flutter build` or `flutter run`. Must provide `--flavor dev --dart-define=FLAVOR=dev` or prod equivalents.
Source: Multi-Env Setup March 2026.

Rule #2
[2026-03] Do not bypass Riverpod strictly typed state. Avoid mutating state directly in UI.

**Rule #3 — TREMBLE HAS NO IN-APP CHAT. EVER.**
[2026-04-09] The core product mechanic is: Wave → Mutual Wave → 30-minute real-life finding game → meet in person.
There is no chat, no messaging, no text exchange inside the app. This is the entire point of Tremble.
Any implementation of a chat UI, ChatRepository, Message model, or messaging routes is WRONG and must be reverted immediately.
After MatchRevealScreen, the only action is returning to the Radar to find the person physically.
Source: Founder correction, April 2026.

**Rule #4 — NEVER change objectVersion in project.pbxproj back to 70.**
[2026-04-09] During Phase 7.5 iOS Notification Service Extension setup, objectVersion was manually set to 63
for compatibility with CocoaPods 1.16.2 + Xcode 26.3. Reverting to 70 breaks `pod install`.
Leave it at 63. Do not "fix" this.
Source: Phase 7.5 Xcode integration, April 2026.

**Rule #5 — Firestore batches are hard-capped at 500 operations. Always paginate.**
[2026-04-09] Firestore's `WriteBatch.commit()` silently truncates or throws on >500 ops in a single batch.
Any function that accumulates docs into a single batch (GDPR deletion, bulk cleanup) MUST use a paginated
helper (e.g. `deleteBatch`) that slices into 500-doc chunks and commits each chunk separately.
Pattern: `for (let i = 0; i < refs.length; i += 500) { const b = db.batch(); refs.slice(i,i+500).forEach(r => b.delete(r)); await b.commit(); }`
Source: GDPR deletion pipeline fix, April 2026.

**Rule #6 — When a Firestore collection is renamed/replaced, audit ALL functions that reference the old name.**
[2026-04-09] The `greetings` collection was replaced by `waves` in Phase 6, but `exportUserData` and
`deleteUserAccount` still referenced `greetings` — silently querying a non-existent collection and
returning empty data. When renaming a collection: grep the entire functions/ directory for the old name
and update every reference (queries, exports, deletion pipeline, tests) before deploying.
Source: GDPR export fix (greetings → waves), April 2026.

**Rule #7 — Google OAuth Web Client ID is NOT a secret. Do not rotate it.**
[2026-04-09] `GOOGLE_WEB_CLIENT_ID` (format: `XXXXXXXX.apps.googleusercontent.com`) is a public OAuth
identifier embedded in every compiled app. It cannot be "rotated" without breaking all existing Google
Sign-In sessions for all users. It belongs in `.env` for environment separation (dev vs prod project),
but treat it as config — not a secret. Only the OAuth Client Secret (server-side flows) is sensitive.
Source: Security scan session, April 2026.

**Rule #8 — `functions/.env` must NEVER mix dev and prod credentials.**
[2026-04-09] Having both dev and prod secrets in one `.env` file means the last block always wins —
whichever env is active could silently inject prod credentials into a dev emulator or vice versa.
Always use `functions/.env.dev` and `functions/.env.prod` as separate files. Both must be gitignored.
Update `.gitignore` with explicit per-file entries, not just wildcards.
Source: Security audit, April 2026.

**Rule #9 — `Colors.pinkAccent` is NOT the Tremble brand rose. Never use it.**
[2026-04-09] `Colors.pinkAccent` (#FF4081) is a Material Design default. The Tremble brand rose is
`TrembleTheme.rose` (#F4436C). In the RadarAnimation and 5+ other screens, `Colors.pinkAccent` was
used instead of the brand color — most visible in the app's primary widget. Always use theme tokens:
`TrembleTheme.rose`, `TrembleTheme.roseLight`, `TrembleTheme.roseDark`. Never use Material color names.
Source: UI audit, April 2026.

**Rule #10 — Remove ALL debug artifacts before any TestFlight or store build.**
[2026-04-09] A DEV TEST flame button (amber, LucideIcons.flame) was found rendered on HomeScreen
when `isScanning == true`. It had an empty `onPressed` but was visually present. Any debug button,
mock data label, test overlay, or console.log must be removed before sharing the app externally.
Do a grep for `DEV TEST`, `TODO`, `mock`, `hardcoded`, `fake` before every beta build.
Source: UI audit, April 2026.

**Rule #11 — Use Node.js 22 for all Cloud Functions.**
[2026-04-10] Firebase Cloud Functions must use Node.js 22 to ensure compliance with the latest runtime requirements and to leverage modern JS/TS features. Update `engines` in `package.json` and run `npm install` to refresh metadata before deployment.
Source: Technical audit, April 2026.

**Rule #12 — Always use `Theme.of(context).brightness` as the source of truth for dark mode detection in UI.**
[2026-04-15] The `AuthUser.isDarkMode` field can diverge from the application's actual theme state (e.g. while syncing, in guest mode, or when using local overrides). Relying on `user.isDarkMode ?? default` in the UI can cause "light mode leakage" on specific screens. Always use `Theme.of(context).brightness == Brightness.dark` to determine the current visual mode for widgets, map styles, and gradients.
Source: Map Dark Mode fix, April 2026.
