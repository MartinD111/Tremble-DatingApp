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
