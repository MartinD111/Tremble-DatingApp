import { calculateCompatibilityScore } from "../modules/compatibility/compatibility_calculator";

describe("compatibility_calculator", () => {
    it("should ignore nicotine preference of free candidate when evaluating compatibility", () => {
        // Point 4 regression test: free candidate + premium requester, candidate has none_only set
        // Since nicotine is handled in the outer pre-filter (nicotineCompatible), calculateCompatibilityScore
        // itself no longer filters out users based on nicotine. We verify it returns a valid score (> 0).
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

    it("should reduce score if religion prefer_same is set and religions do not match", () => {
        // Point 5 regression test: prej-0.0 pare mora zdaj dati zmanjšan-a-ne-ničeln score
        const requester = {
            uid: "req",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionPreference: "same_only" // Legacy name test
        };
        const candidate = {
            uid: "can",
            hobbies: ["Hiking"],
            religion: "Catholic",
            religionPreference: "any"
        };

        const score = calculateCompatibilityScore(requester, candidate);
        expect(score).toBeGreaterThan(0);
        
        // If neither cared, score would be higher.
        const reqAny = { ...requester, religionPreference: "any" };
        const scoreAny = calculateCompatibilityScore(reqAny, candidate);
        expect(scoreAny).toBeGreaterThan(score);
    });

    it("should process prefer_same correctly for both directions", () => {
        const req = {
            uid: "req",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionPreference: "prefer_same"
        };
        const can = {
            uid: "can",
            hobbies: ["Hiking"],
            religion: "Atheist",
            religionPreference: "prefer_same"
        };

        const scoreMatches = calculateCompatibilityScore(req, can);
        
        const canDiff = { ...can, religion: "Catholic" };
        const scoreDiff = calculateCompatibilityScore(req, canDiff);

        expect(scoreMatches).toBeGreaterThan(scoreDiff);
    });
});
