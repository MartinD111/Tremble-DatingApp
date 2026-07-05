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

    // ── sensitiveDataConsent gate (GDPR Art. 9) ──────────────────────────

    it("should include religion in scoring when both users have sensitiveDataConsent === true and same religion", () => {
        const base = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            sensitiveDataConsent: true,
        };
        const match = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            sensitiveDataConsent: true,
        };
        const mismatch = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Catholic",
            sensitiveDataConsent: true,
        };

        const scoreMatch = calculateCompatibilityScore(base, match);
        const scoreMismatch = calculateCompatibilityScore(base, mismatch);
        expect(scoreMatch).toBeGreaterThan(scoreMismatch);
    });

    it("should exclude religion from scoring when one user lacks sensitiveDataConsent", () => {
        // Baseline: no religion data at all
        const noReligion = {
            uid: "a",
            hobbies: ["Hiking"],
        };
        const noReligionB = {
            uid: "b",
            hobbies: ["Hiking"],
        };
        const baselineScore = calculateCompatibilityScore(noReligion, noReligionB);

        // User A consented, User B did not (missing field = fail-closed)
        const withConsent = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            sensitiveDataConsent: true,
        };
        const withoutConsent = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            // sensitiveDataConsent is missing → fail-closed
        };

        const gatedScore = calculateCompatibilityScore(withConsent, withoutConsent);
        expect(gatedScore).toEqual(baselineScore);
    });

    it("should exclude religion from scoring when sensitiveDataConsent is explicitly false", () => {
        const noReligion = { uid: "a", hobbies: ["Hiking"] };
        const noReligionB = { uid: "b", hobbies: ["Hiking"] };
        const baselineScore = calculateCompatibilityScore(noReligion, noReligionB);

        const explicitFalseA = {
            uid: "a",
            hobbies: ["Hiking"],
            religion: "Atheist",
            sensitiveDataConsent: false,
        };
        const explicitFalseB = {
            uid: "b",
            hobbies: ["Hiking"],
            religion: "Atheist",
            sensitiveDataConsent: false,
        };

        const gatedScore = calculateCompatibilityScore(explicitFalseA, explicitFalseB);
        expect(gatedScore).toEqual(baselineScore);
    });

    it("should exclude ethnicity from scoring without bilateral consent", () => {
        const noEth = { uid: "a", hobbies: ["Hiking"] };
        const noEthB = { uid: "b", hobbies: ["Hiking"] };
        const baselineScore = calculateCompatibilityScore(noEth, noEthB);

        const withEthA = {
            uid: "a",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            sensitiveDataConsent: true,
        };
        const withEthB = {
            uid: "b",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            // missing consent
        };

        const gatedScore = calculateCompatibilityScore(withEthA, withEthB);
        expect(gatedScore).toEqual(baselineScore);
    });

    it("should include ethnicity in scoring when both users consent", () => {
        const ethMatchA = {
            uid: "a",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            sensitiveDataConsent: true,
        };
        const ethMatchB = {
            uid: "b",
            hobbies: ["Hiking"],
            ethnicity: "Slavic",
            sensitiveDataConsent: true,
        };
        const ethMismatchB = {
            uid: "b",
            hobbies: ["Hiking"],
            ethnicity: "Germanic",
            sensitiveDataConsent: true,
        };

        const scoreMatch = calculateCompatibilityScore(ethMatchA, ethMatchB);
        const scoreMismatch = calculateCompatibilityScore(ethMatchA, ethMismatchB);
        expect(scoreMatch).toBeGreaterThan(scoreMismatch);
    });
});
