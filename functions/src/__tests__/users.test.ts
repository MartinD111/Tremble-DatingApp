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
    },
}));

jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, handler) => handler),
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
            mockDb.collection.mockReturnValue({
                doc: jest.fn(() => ({ update })),
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
            mockDb.collection.mockReturnValue({
                doc: jest.fn(() => ({ update })),
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

        it("should constrain location to the city enum", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            expect(
                updateProfileSchema.safeParse({ location: "Koper" }).success
            ).toBe(true);
            expect(
                updateProfileSchema.safeParse({
                    location: "Prešernova cesta 10, Ljubljana",
                }).success
            ).toBe(false);
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
