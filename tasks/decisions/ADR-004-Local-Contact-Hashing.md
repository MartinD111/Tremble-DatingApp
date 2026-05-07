# ADR-004: Local Contact Hashing for Anonymity Mode
**Status:** Accepted
**Date:** 2026-05-08

## Context
Tremble requires an "Anonymity Mode" to allow users to hide from people in their phone's contact list. Traditional implementations upload raw phone numbers to a server, which violates our strict "Zero-Data" privacy philosophy and poses a GDPR risk.

## Decision
We will implement local-only hashing of contacts before transmission. 

1. **Permission:** We explicitly ask for contact access.
2. **Normalization:** Phone numbers must be normalized to E.164 format (e.g., +38640123456) using a robust parsing strategy to handle various local inputs (040 123 456, 00386...).
3. **Hashing:** We use the Dart `crypto` package to hash the normalized string using SHA-256 locally on the device.
4. **Transmission:** Only the list of SHA-256 hashes is sent to the Cloud Function `onContactAnonymityCheck`.
5. **Processing:** The Cloud Function performs an in-memory comparison of these hashes against a temporary set of registered user hashes.
6. **Purging:** The Cloud Function strictly does not persist the received hashes. They are garbage collected immediately after processing.

## Trade-offs
- **Performance:** Hashing thousands of contacts locally on the UI thread will cause jank.
  - *Mitigation:* We must use `compute()` or `Isolate.run()` to offload the normalization and hashing process to a background thread.
- **Security:** SHA-256 without a salt on a relatively small entropy space (phone numbers) is vulnerable to brute-force if intercepted.
  - *Mitigation:* Hashes are only ever in transit over HTTPS and never stored. App Check ensures only authentic clients make the request.

## Consequences
- Requires `flutter_contacts` and `crypto` packages.
- Zero risk of leaking the user's raw address book.
- Aligns perfectly with Tremble's brand identity: "Tvoja stvar je tvoja stvar."
