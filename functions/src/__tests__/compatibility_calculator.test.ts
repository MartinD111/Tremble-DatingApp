import { calculateCompatibilityScore } from "../modules/compatibility/compatibility_calculator";

describe("compatibility_calculator", () => {
    it("should ignore nicotine preference of free candidate when evaluating compatibility", () => {
        // Regression: free candidate + premium requester, candidate has none_only set.
        // Since nicotine is handled in the outer pre-filter (nicotineCompatible),
        // calculateCompatibilityScore itself no longer filters out users based on nicotine.
        const requester = {
            uid: "req",
            hobbies: ["Hiking"],
            nicotineUse: ["vaping"],
            nicotineFilter: "any",
            isPremium: true
        };
        const candidate = {
            uid: "can",
            hobbies: ["Hiking"],
            nicotineUse: [],
            nicotineFilter: "none_only",
            isPremium: false
        };

        const score = calculateCompatibilityScore(requester, candidate);
        expect(score).toBeGreaterThan(0);
    });

    // ── Granular consent gate (GDPR Art. 9): religion and ethnicity are
    //    now controlled by independent flags. Missing flag = fail-closed. ─

    it("should include religion in scoring when both users have religionConsent === true and same religion", () => {
        const base = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionConsent: true,
        };
        const match = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionConsent: true,
        };
        const mismatch = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Catholic",
            religionConsent: true,
        };

        const scoreMatch = calculateCompatibilityScore(base, match);
        const scoreMismatch = calculateCompatibilityScore(base, mismatch);
        expect(scoreMatch).toBeGreaterThan(scoreMismatch);
    });

    it("should exclude religion from scoring when one user lacks religionConsent (missing = fail-closed)", () => {
        const noReligion = { uid: "a", hobbies: ["Hiking"] };
        const noReligionB = { uid: "b", hobbies: ["Hiking"] };
        const baselineScore = calculateCompatibilityScore(noReligion, noReligionB);

        const withConsent = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionConsent: true,
        };
        const withoutConsent = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            // religionConsent missing → fail-closed
        };

        const gatedScore = calculateCompatibilityScore(withConsent, withoutConsent);
        expect(gatedScore).toEqual(baselineScore);
    });

    it("should exclude religion from scoring when religionConsent is explicitly false", () => {
        const noReligion = { uid: "a", hobbies: ["Hiking"] };
        const noReligionB = { uid: "b", hobbies: ["Hiking"] };
        const baselineScore = calculateCompatibilityScore(noReligion, noReligionB);

        const explicitFalseA = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionConsent: false,
        };
        const explicitFalseB = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionConsent: false,
        };

        const gatedScore = calculateCompatibilityScore(explicitFalseA, explicitFalseB);
        expect(gatedScore).toEqual(baselineScore);
    });

    it("should exclude ethnicity from scoring without bilateral ethnicityConsent", () => {
        const noEth = { uid: "a", hobbies: ["Hiking"] };
        const noEthB = { uid: "b", hobbies: ["Hiking"] };
        const baselineScore = calculateCompatibilityScore(noEth, noEthB);

        const withEthA = {
            uid: "a",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            ethnicityConsent: true,
        };
        const withEthB = {
            uid: "b",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            // ethnicityConsent missing → fail-closed
        };

        const gatedScore = calculateCompatibilityScore(withEthA, withEthB);
        expect(gatedScore).toEqual(baselineScore);
    });

    it("should include ethnicity in scoring when both users have ethnicityConsent === true", () => {
        const ethMatchA = {
            uid: "a",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            ethnicityConsent: true,
        };
        const ethMatchB = {
            uid: "b",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            ethnicityConsent: true,
        };
        const ethMismatchB = {
            uid: "b",
            hobbies: ["Hiking"],
            ethnicity: "Germanic",
            ethnicityConsent: true,
        };

        const scoreMatch = calculateCompatibilityScore(ethMatchA, ethMatchB);
        const scoreMismatch = calculateCompatibilityScore(ethMatchA, ethMismatchB);
        expect(scoreMatch).toBeGreaterThan(scoreMismatch);
    });

    // ── Independence: religionConsent and ethnicityConsent gate independently.
    //    We prove independence by holding one dimension as a match and the
    //    other as a mismatch, then verifying the mismatch only counts against
    //    the score when its OWN consent is bilaterally present. ────────────

    it("should exclude ethnicity mismatch when ethnicityConsent is not bilateral, even if religionConsent is", () => {
        // Same religion (match), DIFFERENT ethnicity.
        const a = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            ethnicity: "Slavic",
            religionConsent: true,
            ethnicityConsent: true,
        };
        const bReligionOnly = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            ethnicity: "Germanic",
            religionConsent: true,
            // ethnicityConsent missing → ethnicity mismatch is not scored
        };
        const bBoth = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            ethnicity: "Germanic",
            religionConsent: true,
            ethnicityConsent: true,
        };

        // With only religionConsent bilateral, ethnicity mismatch is hidden →
        // score should be HIGHER than when ethnicity mismatch is exposed.
        const gated = calculateCompatibilityScore(a, bReligionOnly);
        const fullyScored = calculateCompatibilityScore(a, bBoth);
        expect(gated).toBeGreaterThan(fullyScored);
    });

    it("should exclude religion mismatch when religionConsent is not bilateral, even if ethnicityConsent is", () => {
        // Same ethnicity (match), DIFFERENT religion.
        const a = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            ethnicity: "Slavic",
            religionConsent: true,
            ethnicityConsent: true,
        };
        const bEthnicityOnly = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Catholic",
            ethnicity: "Slavic",
            ethnicityConsent: true,
            // religionConsent missing → religion mismatch is not scored
        };
        const bBoth = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Catholic",
            ethnicity: "Slavic",
            religionConsent: true,
            ethnicityConsent: true,
        };

        const gated = calculateCompatibilityScore(a, bEthnicityOnly);
        const fullyScored = calculateCompatibilityScore(a, bBoth);
        expect(gated).toBeGreaterThan(fullyScored);
    });

    // ── Cross-locale hobby matching (Plan 20260713-hobby-neutral-ids) ─────
    //   "Hiking" and "Pohodništvo" are the same hobby stored in different
    //   locales. Before the migration they scored as no shared hobby;
    //   after the migration they score identically to two matching ID
    //   strings, because the calculator normalises to canonical IDs.

    it("counts EN + SL variants of the same hobby as a shared match", () => {
        const en = {
            uid: "en",
            hobbies: ["Hiking", "Cycling", "Yoga"],
        };
        const sl = {
            uid: "sl",
            hobbies: ["Pohodništvo", "Kolesarjenje", "Joga"],
        };
        const canonical = {
            uid: "id",
            hobbies: ["hiking", "cycling", "yoga"],
        };

        const crossLocaleScore = calculateCompatibilityScore(en, sl);
        const canonicalScore = calculateCompatibilityScore(en, canonical);

        expect(crossLocaleScore).toBeGreaterThan(0.5);
        expect(crossLocaleScore).toBeCloseTo(canonicalScore, 5);
    });

    it("mixed-locale profile (EN + SL strings) still normalises to IDs", () => {
        const mixed = {
            uid: "mix",
            hobbies: ["Hiking", "Kolesarjenje"], // EN + SL in the same array
        };
        const other = {
            uid: "other",
            hobbies: ["hiking", "cycling"], // canonical IDs
        };

        const score = calculateCompatibilityScore(mixed, other);
        // Two exact matches → hobby subscore = min(2,3)*15 / 85 = 0.3529...
        // Weighted at 0.50, plus 0.5 personality (no data) + 0.5 lifestyle (base)
        // = 0.176 + 0.125 + 0.125 = 0.426 → rounded to 0.43.
        expect(score).toBeGreaterThan(0.35);
    });

    it("legacy translation keys (hobby_running) also normalise", () => {
        const legacyKey = { uid: "a", hobbies: ["hobby_running"] };
        const canonical = { uid: "b", hobbies: ["running"] };
        const score = calculateCompatibilityScore(legacyKey, canonical);
        // One exact match after normalisation.
        expect(score).toBeGreaterThan(0.25);
    });

    it("unknown/custom hobby strings do not cross-match with other unknowns", () => {
        const a = { uid: "a", hobbies: ["Underwater basket weaving"] };
        const b = { uid: "b", hobbies: ["Homebrew mead-making"] };
        const same = { uid: "c", hobbies: ["Underwater basket weaving"] };

        const noMatchScore = calculateCompatibilityScore(a, b);
        const matchScore = calculateCompatibilityScore(a, same);
        expect(matchScore).toBeGreaterThan(noMatchScore);
    });
});
