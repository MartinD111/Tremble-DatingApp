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
                    politicalAffiliation: "private",
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
                    politicalAffiliation: "private",
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
                nicotineUse: "vaping",
                nicotineFilter: "no_smoking",
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.nicotineUse).toBe("vaping");
                expect(result.data.nicotineFilter).toBe("no_smoking");
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
    });
});
