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
