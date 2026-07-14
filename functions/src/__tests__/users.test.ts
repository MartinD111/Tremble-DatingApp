/**
 * Tremble — Users Functions Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

const mockDb = {
    collection: jest.fn(),
};

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    FieldValue: {
        serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
        delete: jest.fn(() => "FIELD_DELETE"),
    },
}));

jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, handler) => handler),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));

jest.mock("../../src/middleware/authGuard", () => ({
    requireAuth: jest.fn(),
    requireVerifiedEmail: jest.fn(),
}));

jest.mock("../../src/middleware/rateLimit", () => ({
    checkRateLimit: jest.fn(),
}));

jest.mock("../../src/middleware/validate", () => ({
    assertValidDocumentId: jest.fn(),
    validateRequest: jest.fn(),
}));

jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: false,
}));

describe("Users Module", () => {
    describe("updateProfile", () => {
        it("normalises nicotineUse string input to an array before writing", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const validate = await import("../../src/middleware/validate");
            const { updateProfile } = await import("../../src/modules/users/users.functions");

            const update = jest.fn<() => Promise<void>>().mockResolvedValue(undefined);
            const get = jest.fn<() => Promise<{ data: () => Record<string, unknown> }>>()
                .mockResolvedValue({ data: () => ({}) });
            mockDb.collection.mockReturnValue({
                doc: jest.fn(() => ({ update, get })),
            });
            jest.mocked(authGuard.requireAuth).mockReturnValue("userUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);
            jest.mocked(validate.validateRequest).mockReturnValue({
                nicotineUse: ["vape"],
            });

            const callableUpdateProfile = updateProfile as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableUpdateProfile({
                auth: { uid: "userUid" },
                data: { nicotineUse: ["vape"] },
            })).resolves.toEqual({ success: true });

            expect(update).toHaveBeenCalledWith(expect.objectContaining({
                nicotineUse: ["vape"],
            }));
        });

        it("preserves multi-select nicotineUse arrays before writing", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const validate = await import("../../src/middleware/validate");
            const { updateProfile } = await import("../../src/modules/users/users.functions");

            const update = jest.fn<() => Promise<void>>().mockResolvedValue(undefined);
            const get = jest.fn<() => Promise<{ data: () => Record<string, unknown> }>>()
                .mockResolvedValue({ data: () => ({ sexualOrientationConsent: true }) });
            mockDb.collection.mockReturnValue({
                doc: jest.fn(() => ({ update, get })),
            });
            jest.mocked(authGuard.requireAuth).mockReturnValue("userUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);
            jest.mocked(validate.validateRequest).mockReturnValue({
                nicotineUse: ["cigarettes", "vape", "shisha"],
            });

            const callableUpdateProfile = updateProfile as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableUpdateProfile({
                auth: { uid: "userUid" },
                data: { nicotineUse: ["cigarettes", "vape", "shisha"] },
            })).resolves.toEqual({ success: true });

            expect(update).toHaveBeenCalledWith(expect.objectContaining({
                nicotineUse: ["cigarettes", "vape", "shisha"],
            }));
        });

        // ── Art. 9 write gate — pair-of-tests per sensitive field ─────────
        //   Each pair proves rejection when consent is missing/false AND
        //   acceptance when the same request grants consent. Fail-closed on
        //   the write path is the load-bearing complement to the scorer's
        //   bilateral gate. See tasks/plan.md § LEGAL-003 step 1.

        function stubUpdateProfileMocks(
            existing: Record<string, unknown>,
            incoming: Record<string, unknown>,
        ) {
            const update = jest.fn<() => Promise<void>>().mockResolvedValue(undefined);
            const get = jest
                .fn<() => Promise<{ data: () => Record<string, unknown> }>>()
                .mockResolvedValue({ data: () => existing });
            mockDb.collection.mockReturnValue({
                doc: jest.fn(() => ({ update, get })),
            });
            return { update, incoming };
        }

        async function callUpdateProfile(incoming: Record<string, unknown>) {
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const validate = await import("../../src/middleware/validate");
            const { updateProfile } = await import(
                "../../src/modules/users/users.functions"
            );
            jest.mocked(authGuard.requireAuth).mockReturnValue("userUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);
            jest.mocked(validate.validateRequest).mockReturnValue(incoming);
            const callable = updateProfile as unknown as (
                request: unknown,
            ) => Promise<unknown>;
            return callable({ auth: { uid: "userUid" }, data: incoming });
        }

        it("rejects gender writes when sexualOrientationConsent is not held", async () => {
            jest.clearAllMocks();
            stubUpdateProfileMocks({}, { gender: "female" });
            await expect(callUpdateProfile({ gender: "female" })).rejects.toMatchObject(
                { code: "permission-denied", message: "art9_orientation_consent_required" },
            );
        });

        it("accepts gender writes when the same request grants orientation consent", async () => {
            jest.clearAllMocks();
            const { update } = stubUpdateProfileMocks(
                {},
                { gender: "female", sexualOrientationConsent: true },
            );
            await expect(
                callUpdateProfile({
                    gender: "female",
                    sexualOrientationConsent: true,
                }),
            ).resolves.toEqual({ success: true });
            expect(update).toHaveBeenCalledWith(
                expect.objectContaining({
                    gender: "female",
                    sexualOrientationConsent: true,
                    sexualOrientationConsentVersion: "v1",
                }),
            );
        });

        it("rejects lookingFor writes when sexualOrientationConsent is not held", async () => {
            jest.clearAllMocks();
            stubUpdateProfileMocks({}, { lookingFor: ["long_term_partner"] });
            await expect(
                callUpdateProfile({ lookingFor: ["long_term_partner"] }),
            ).rejects.toMatchObject({
                code: "permission-denied",
                message: "art9_orientation_consent_required",
            });
        });

        it("accepts lookingFor writes when consent is already held on the existing doc", async () => {
            jest.clearAllMocks();
            const { update } = stubUpdateProfileMocks(
                { sexualOrientationConsent: true },
                { lookingFor: ["long_term_partner"] },
            );
            await expect(
                callUpdateProfile({ lookingFor: ["long_term_partner"] }),
            ).resolves.toEqual({ success: true });
            expect(update).toHaveBeenCalledWith(
                expect.objectContaining({ lookingFor: ["long_term_partner"] }),
            );
        });

        it("rejects religion writes when religionConsent is not held", async () => {
            jest.clearAllMocks();
            stubUpdateProfileMocks({}, { religion: "atheist" });
            await expect(
                callUpdateProfile({ religion: "atheist" }),
            ).rejects.toMatchObject({
                code: "permission-denied",
                message: "art9_religion_consent_required",
            });
        });

        it("accepts religion writes when the same request grants religionConsent", async () => {
            jest.clearAllMocks();
            const { update } = stubUpdateProfileMocks(
                {},
                { religion: "atheist", religionConsent: true },
            );
            await expect(
                callUpdateProfile({ religion: "atheist", religionConsent: true }),
            ).resolves.toEqual({ success: true });
            expect(update).toHaveBeenCalledWith(
                expect.objectContaining({
                    religion: "atheist",
                    religionConsent: true,
                    religionConsentVersion: "v1",
                }),
            );
        });

        it("rejects ethnicity writes when ethnicityConsent is not held", async () => {
            jest.clearAllMocks();
            stubUpdateProfileMocks({}, { ethnicity: "slovenian" });
            await expect(
                callUpdateProfile({ ethnicity: "slovenian" }),
            ).rejects.toMatchObject({
                code: "permission-denied",
                message: "art9_ethnicity_consent_required",
            });
        });

        it("accepts ethnicity writes when the same request grants ethnicityConsent", async () => {
            jest.clearAllMocks();
            const { update } = stubUpdateProfileMocks(
                {},
                { ethnicity: "slovenian", ethnicityConsent: true },
            );
            await expect(
                callUpdateProfile({
                    ethnicity: "slovenian",
                    ethnicityConsent: true,
                }),
            ).resolves.toEqual({ success: true });
            expect(update).toHaveBeenCalledWith(
                expect.objectContaining({
                    ethnicity: "slovenian",
                    ethnicityConsent: true,
                    ethnicityConsentVersion: "v1",
                }),
            );
        });

        it("rejects sensitive writes when consent is flipped to false in the same request", async () => {
            // Withdrawal must land as its own withdraw call — you cannot
            // set consent=false AND still push a field write through the
            // same call, because the write itself is the abuse we're
            // preventing.
            jest.clearAllMocks();
            stubUpdateProfileMocks(
                { sexualOrientationConsent: true },
                { gender: "female", sexualOrientationConsent: false },
            );
            await expect(
                callUpdateProfile({
                    gender: "female",
                    sexualOrientationConsent: false,
                }),
            ).rejects.toMatchObject({
                code: "permission-denied",
                message: "art9_orientation_consent_required",
            });
        });
    });

    describe("withdrawArt9Consent", () => {
        it("orientation withdrawal deletes gender + lookingFor and stamps version", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const { withdrawArt9Consent } = await import(
                "../../src/modules/users/users.functions"
            );
            const update = jest
                .fn<(data: Record<string, unknown>) => Promise<void>>()
                .mockResolvedValue(undefined);
            mockDb.collection.mockReturnValue({ doc: jest.fn(() => ({ update })) });
            jest.mocked(authGuard.requireAuth).mockReturnValue("userUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);

            const callable = withdrawArt9Consent as unknown as (r: unknown) => Promise<unknown>;
            await expect(
                callable({ auth: { uid: "userUid" }, data: { category: "orientation" } }),
            ).resolves.toEqual({ success: true });

            expect(update).toHaveBeenCalledWith(
                expect.objectContaining({
                    sexualOrientationConsent: false,
                    sexualOrientationConsentVersion: "v1",
                    gender: "FIELD_DELETE",
                    lookingFor: "FIELD_DELETE",
                }),
            );
        });

        it("rejects an unknown withdrawal category", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const { withdrawArt9Consent } = await import(
                "../../src/modules/users/users.functions"
            );
            mockDb.collection.mockReturnValue({
                doc: jest.fn(() => ({ update: jest.fn() })),
            });
            jest.mocked(authGuard.requireAuth).mockReturnValue("userUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);

            const callable = withdrawArt9Consent as unknown as (r: unknown) => Promise<unknown>;
            await expect(
                callable({ auth: { uid: "userUid" }, data: { category: "phone" } }),
            ).rejects.toMatchObject({
                code: "invalid-argument",
                message: "art9_withdraw_category_invalid",
            });
        });
    });

    describe("getPublicProfile", () => {
        it("uses the lower read endpoint rate limit", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const { getPublicProfile } = await import("../../src/modules/users/users.functions");

            jest.mocked(authGuard.requireVerifiedEmail).mockReturnValue("callerUid");
            jest.mocked(rateLimit.checkRateLimit).mockRejectedValue(new Error("rate limit stop"));

            const callableGetPublicProfile = getPublicProfile as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableGetPublicProfile({
                auth: { uid: "callerUid", token: { email_verified: true } },
                data: { userId: "targetUid" },
            })).rejects.toThrow("rate limit stop");

            expect(rateLimit.checkRateLimit).toHaveBeenCalledWith(
                "callerUid",
                "getPublicProfile",
                { maxRequests: 20, windowMs: 60000 }
            );
        });

        it("returns null when the caller has no match with the target user", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const validate = await import("../../src/middleware/validate");
            const { getPublicProfile } = await import("../../src/modules/users/users.functions");

            jest.mocked(authGuard.requireVerifiedEmail).mockReturnValue("callerUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("targetUid");

            const targetGet = jest.fn<() => Promise<{
                exists: boolean;
                data: () => Record<string, unknown>;
            }>>().mockResolvedValue({
                exists: true,
                data: () => ({
                    name: "Target",
                    blockedBy: [],
                    ethnicity: "private",
                    religion: "private",
                }),
            });
            const matchGet = jest.fn<() => Promise<{ exists: boolean }>>().mockResolvedValue({
                exists: false,
            });

            mockDb.collection.mockImplementation((collectionName: unknown) => {
                if (collectionName === "users") {
                    return { doc: jest.fn(() => ({ get: targetGet })) };
                }
                if (collectionName === "matches") {
                    return { doc: jest.fn(() => ({ get: matchGet })) };
                }
                throw new Error(`Unexpected collection: ${collectionName}`);
            });

            const callableGetPublicProfile = getPublicProfile as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableGetPublicProfile({
                auth: { uid: "callerUid", token: { email_verified: true } },
                data: { userId: "targetUid" },
            })).resolves.toEqual({ profile: null });
        });

        it("strips religion, ethnicity, and gender from the client-facing response even when present in Firestore", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const validate = await import("../../src/middleware/validate");
            const { getPublicProfile } = await import("../../src/modules/users/users.functions");

            jest.mocked(authGuard.requireVerifiedEmail).mockReturnValue("callerUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("targetUid");

            const targetGet = jest.fn<() => Promise<{
                exists: boolean;
                data: () => Record<string, unknown>;
            }>>().mockResolvedValue({
                exists: true,
                data: () => ({
                    name: "Target",
                    age: 27,
                    gender: "female",
                    religion: "atheist",
                    ethnicity: "slovenian",
                    hairColor: "brown",
                    occupation: "designer",
                    blockedBy: [],
                }),
            });
            const matchGet = jest.fn<() => Promise<{ exists: boolean }>>().mockResolvedValue({
                exists: true,
            });

            mockDb.collection.mockImplementation((collectionName: unknown) => {
                if (collectionName === "users") {
                    return { doc: jest.fn(() => ({ get: targetGet })) };
                }
                if (collectionName === "matches") {
                    return { doc: jest.fn(() => ({ get: matchGet })) };
                }
                throw new Error(`Unexpected collection: ${collectionName}`);
            });

            const callableGetPublicProfile = getPublicProfile as unknown as (request: unknown) => Promise<{ profile: Record<string, unknown> | null }>;

            const response = await callableGetPublicProfile({
                auth: { uid: "callerUid", token: { email_verified: true } },
                data: { userId: "targetUid" },
            });

            expect(response.profile).not.toBeNull();
            expect(response.profile).not.toHaveProperty("religion");
            expect(response.profile).not.toHaveProperty("ethnicity");
            expect(response.profile).not.toHaveProperty("gender");

            // Positive assertions — non-sensitive fields still forwarded
            expect(response.profile).toMatchObject({
                id: "targetUid",
                name: "Target",
                age: 27,
                hairColor: "brown",
                occupation: "designer",
            });
        });

        it("keeps religion and ethnicity readable server-side so lifestyle scoring still uses them", async () => {
            // This test proves the client-facing strip did NOT regress the
            // server-side data model. `calculateCompatibilityScore` composes
            // `calculateLifestyleScore` internally, which reads religion and
            // ethnicity from Firestore-populated `UserCompatibilityData` — NOT
            // from the `getPublicProfile` response. Two identical users must
            // still score higher than two users with mismatched sensitive
            // attributes.
            const { calculateCompatibilityScore } = await import(
                "../../src/modules/compatibility/compatibility_calculator"
            );

            const base = {
                uid: "a",
                hobbies: ["Hiking"],
                religion: "atheist",
                ethnicity: "slovenian",
                religionConsent: true,
                ethnicityConsent: true,
            };
            const identical = {
                uid: "b",
                hobbies: ["Hiking"],
                religion: "atheist",
                ethnicity: "slovenian",
                religionConsent: true,
                ethnicityConsent: true,
            };
            const mismatched = {
                uid: "b",
                hobbies: ["Hiking"],
                religion: "buddhist",
                ethnicity: "croatian",
                religionConsent: true,
                ethnicityConsent: true,
            };

            const matchedScore = calculateCompatibilityScore(base, identical);
            const mismatchedScore = calculateCompatibilityScore(base, mismatched);

            expect(matchedScore).toBeGreaterThan(mismatchedScore);
        });

        it("returns null when the target user has blocked the caller", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const validate = await import("../../src/middleware/validate");
            const { getPublicProfile } = await import("../../src/modules/users/users.functions");

            jest.mocked(authGuard.requireVerifiedEmail).mockReturnValue("callerUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("targetUid");

            const targetGet = jest.fn<() => Promise<{
                exists: boolean;
                data: () => Record<string, unknown>;
            }>>().mockResolvedValue({
                exists: true,
                data: () => ({
                    name: "Target",
                    blockedBy: ["callerUid"],
                    ethnicity: "private",
                    religion: "private",
                }),
            });
            const matchGet = jest.fn<() => Promise<{ exists: boolean }>>().mockResolvedValue({
                exists: true,
            });

            mockDb.collection.mockImplementation((collectionName: unknown) => {
                if (collectionName === "users") {
                    return { doc: jest.fn(() => ({ get: targetGet })) };
                }
                if (collectionName === "matches") {
                    return { doc: jest.fn(() => ({ get: matchGet })) };
                }
                throw new Error(`Unexpected collection: ${collectionName}`);
            });

            const callableGetPublicProfile = getPublicProfile as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableGetPublicProfile({
                auth: { uid: "callerUid", token: { email_verified: true } },
                data: { userId: "targetUid" },
            })).resolves.toEqual({ profile: null });

            expect(matchGet).not.toHaveBeenCalled();
        });
    });

    describe("updateProfileSchema", () => {
        it("should accept Flutter interestedIn list payload", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                interestedIn: ["male", "female"],
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.interestedIn).toEqual(["male", "female"]);
            }
        });

        it("should accept nicotine fields", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                nicotineUse: ["vape"],
                nicotineFilter: "no_smoking",
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.nicotineUse).toEqual(["vape"]);
                expect(result.data.nicotineFilter).toBe("no_smoking");
            }
        });

        it("should accept multi-select nicotineUse arrays", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                nicotineUse: ["cigarettes", "vape", "shisha"],
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.nicotineUse).toEqual(["cigarettes", "vape", "shisha"]);
            }
        });

        it("should accept freetext location up to 80 chars, reject empty and oversized (PLAN 03 · KORAK 3.6)", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            // Legacy enum values still fit as-is (backward compat).
            expect(
                updateProfileSchema.safeParse({ location: "Koper" }).success
            ).toBe(true);
            // Freetext city name at the previous enum's rejection boundary
            // must now be accepted.
            expect(
                updateProfileSchema.safeParse({
                    location: "Prešernova cesta 10, Ljubljana",
                }).success
            ).toBe(true);
            // Whitespace-only trims to empty → rejected.
            expect(
                updateProfileSchema.safeParse({ location: "   " }).success
            ).toBe(false);
            // Over the 80-char bound → rejected.
            expect(
                updateProfileSchema.safeParse({ location: "x".repeat(81) })
                    .success
            ).toBe(false);
            // Explicit null still allowed (nullish).
            expect(
                updateProfileSchema.safeParse({ location: null }).success
            ).toBe(true);
        });

        it("should accept payload with all optional fields explicitly null", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                name: null,
                age: null,
                birthDate: null,
                gender: null,
                location: null,
                photoUrls: null,
                height: null,
                isSmoker: null,
                nicotineUse: null,
                nicotineFilter: null,
                hasChildren: null,
                drinkingHabit: null,
                exerciseHabit: null,
                sleepSchedule: null,
                petPreference: null,
                childrenPreference: null,
                introvertScale: null,
                occupation: null,
                company: null,
                school: null,
                jobStatus: null,
                religion: null,
                ethnicity: null,
                hairColor: null,
                interestedIn: null,
                lookingFor: null,
                languages: null,
                hobbies: null,
                prompts: null,
                appLanguage: null,
                isDarkMode: null,
                isPrideMode: null,
                ageRangeStart: null,
                ageRangeEnd: null,
                isTraveler: null,
            });

            expect(result.success).toBe(true);
        });

        it("should accept newly added client fields", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                selfIntrovertMin: 20,
                selfIntrovertMax: 80,
                lookingForNewJob: true,
                graduatedUniversity: "University of Ljubljana",
                onboardingCheckpoint: 5,
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.selfIntrovertMin).toBe(20);
                expect(result.data.selfIntrovertMax).toBe(80);
                expect(result.data.lookingForNewJob).toBe(true);
                expect(result.data.graduatedUniversity).toBe(
                    "University of Ljubljana"
                );
                expect(result.data.onboardingCheckpoint).toBe(5);
            }
        });

        it("should accept newly added client fields explicitly set to null", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                selfIntrovertMin: null,
                selfIntrovertMax: null,
                lookingForNewJob: null,
                graduatedUniversity: null,
                onboardingCheckpoint: null,
            });

            expect(result.success).toBe(true);
        });

        it("should accept gymNotificationsEnabled and phoneNumber", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                gymNotificationsEnabled: true,
                phoneNumber: "+38641000000",
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.gymNotificationsEnabled).toBe(true);
                expect(result.data.phoneNumber).toBe("+38641000000");
            }
        });

        it("should accept gymNotificationsEnabled and phoneNumber explicitly null", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                gymNotificationsEnabled: null,
                phoneNumber: null,
            });

            expect(result.success).toBe(true);
        });

        it("should still reject unknown fields (strict mode preserved)", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                isAdmin: true,
                isPremium: true,
            });

            expect(result.success).toBe(false);
        });
    });
});
