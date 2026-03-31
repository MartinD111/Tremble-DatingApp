# Permanent Project Knowledge (Lessons)

Rule #1
[2026-03-31] Never run un-flavored `flutter build` or `flutter run`. Must provide `--flavor dev --dart-define=FLAVOR=dev` or prod equivalents.
Source: Multi-Env Setup March 2026.

Rule #2
[2026-03] Do not bypass Riverpod strictly typed state. Avoid mutating state directly in UI.
