# Active Implementation Plan

Plan ID: 20260705-sensitive-data-consent-gate
Risk Level: HIGH
Founder Approval Required: YES
Branch: feature/sensitive-data-consent-gate

1. OBJECTIVE — Gate religion and ethnicity scoring behind bilateral GDPR Art. 9 consent.
2. SCOPE — compatibility_calculator.ts, proximity.functions.ts, compatibility_calculator.test.ts
3. STEPS — Replace same_only with sensitiveDataConsent gate, pass consent through proximity calls.
4. RISKS & TRADEOFFS — Missing consent fails closed (excluded from scoring).
5. VERIFICATION — Unit tests pass, grep shows 0 matches for same_only/prefer_same, build green.
