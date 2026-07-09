# Active Implementation Plan

Plan ID: 20260709-strip-public-profile
Risk Level: HIGH
Founder Approval Required: YES
Branch: feature/strip-public-profile-pii

1. OBJECTIVE — Strip religion, ethnicity, and gender from `getPublicProfile` response with a compile-time-enforced `PublicProfile` interface so the fields cannot be silently re-added by a future edit.
2. SCOPE — `functions/src/modules/users/users.functions.ts`, `functions/src/modules/users/users.schema.ts`, `functions/src/__tests__/users.test.ts`. Does NOT touch `compatibility_calculator.ts` — server-side reads of religion/ethnicity remain intact for `calculateLifestyleScore`.
3. STEPS — Add `PublicProfile` TS interface enumerating allowed fields; annotate the returned profile object with that type so excess-property check flags any forbidden field; remove `religion`, `ethnicity`, `gender` from the literal; add regression tests asserting absence in the response and internal read continuity in the scoring function.
4. RISKS & TRADEOFFS — Client already stripped these fields cosmetically; a naked object literal previously allowed a silent regression. This adds a structural guarantee. Trade-off: coupling the schema module to the response shape — acceptable because both are user-facing surface area.
5. VERIFICATION — `cd functions && npm run build` clean, `npm test` all pass including new absence assertions, `compatibility_calculator.test.ts` unchanged and passes, grep shows 0 matches for `religion:|ethnicity:|gender:` inside the `getPublicProfile` return literal.
