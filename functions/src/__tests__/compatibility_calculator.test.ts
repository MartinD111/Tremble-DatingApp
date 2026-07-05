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
});
