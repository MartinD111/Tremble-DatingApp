/**
 * Tremble — Auth Functions Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

const mockVerifyIdToken = jest.fn<() => Promise<unknown>>();
const mockUserDocSet = jest.fn(() => Promise.resolve());
const mockUserDocGet = jest.fn(() =>
    Promise.resolve({
        exists: true,
        data: () => ({ email: "test@example.com", name: "Test" }),
    })
);

// We mock the firebase-admin module before importing anything that needs it
// eslint-disable-next-line @typescript-eslint/no-explicit-any
jest.mock("firebase-admin/firestore", () => {
    const mockDocRef = {
        set: mockUserDocSet,
        get: mockUserDocGet,
    };
    return {
        getFirestore: jest.fn(() => ({
            collection: jest.fn(() => ({
                doc: jest.fn(() => mockDocRef),
            })),
        })),
        FieldValue: {
            serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
        },
    };
});

jest.mock("firebase-functions/v2/identity", () => ({
    beforeUserCreated: jest.fn((handler) => handler),
}));

jest.mock("google-auth-library", () => ({
    OAuth2Client: jest.fn(() => ({
        verifyIdToken: mockVerifyIdToken,
    })),
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

jest.mock("../../src/middleware/rateLimit", () => ({
    checkRateLimit: jest.fn(() => Promise.resolve()),
}));

describe("Auth Module", () => {
    describe("completeOnboarding", () => {
        it("normalises nicotineUse to an array before writing profile data", async () => {
            jest.clearAllMocks();
            mockUserDocSet.mockResolvedValue(undefined);
            mockUserDocGet.mockResolvedValue({
                exists: true,
                data: () => ({ email: "test@example.com", name: "Ana" }),
            });
            const { completeOnboarding } = await import("../../src/modules/auth/auth.functions");

            const callableCompleteOnboarding = completeOnboarding as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableCompleteOnboarding({
                auth: { uid: "userUid" },
                data: {
                    name: "Ana",
                    birthDate: "1995-06-15",
                    gender: "female",
                    interestedIn: "male",
                    photoUrls: ["https://r2.example.com/photo.jpg"],
                    nicotineUse: ["cigarettes", "vape", "shisha"],
                    consentGiven: true,
                },
            })).resolves.toEqual({ success: true });

            expect(mockUserDocSet).toHaveBeenCalledWith(
                expect.objectContaining({
                    nicotineUse: ["cigarettes", "vape", "shisha"],
                }),
                { merge: true }
            );
        });

        it("should reject unauthenticated requests", async () => {
            const { requireAuth } = await import("../../src/middleware/authGuard");

            expect(() =>
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                requireAuth({ auth: undefined } as any)
            ).toThrow();
        });

        it("should validate onboarding schema — reject missing required fields", async () => {
            const { completeOnboardingSchema } = await import(
                "../../src/modules/auth/auth.schema"
            );

            const result = completeOnboardingSchema.safeParse({});
            expect(result.success).toBe(false);
        });

        it("should validate onboarding schema — accept valid data", async () => {
            const { completeOnboardingSchema } = await import(
                "../../src/modules/auth/auth.schema"
            );

            const result = completeOnboardingSchema.safeParse({
                name: "Ana",
                birthDate: "1995-06-15",
                gender: "female",
                interestedIn: "male",
                location: "Ljubljana",
                photoUrls: ["https://r2.example.com/photo.jpg"],
                lookingFor: ["long_term"],
                languages: ["Slovenian"],
                hobbies: ["Hiking"],
                prompts: {},
                appLanguage: "sl",
                isDarkMode: true,
                isPrideMode: false,
                showPingAnimation: true,
                ageRangeStart: 22,
                ageRangeEnd: 35,
                maxDistance: 10,
                consentGiven: true,
            });
            expect(result.success).toBe(true);
        });

        it("should validate onboarding schema — reject precise free-text location", async () => {
            const { completeOnboardingSchema } = await import(
                "../../src/modules/auth/auth.schema"
            );

            const result = completeOnboardingSchema.safeParse({
                name: "Ana",
                birthDate: "1995-06-15",
                gender: "female",
                interestedIn: "male",
                location: "Prešernova cesta 10, Ljubljana",
                photoUrls: ["https://r2.example.com/photo.jpg"],
                consentGiven: true,
            });

            expect(result.success).toBe(false);
        });

        it("should validate onboarding schema — accept nicotine fields", async () => {
            const { completeOnboardingSchema } = await import(
                "../../src/modules/auth/auth.schema"
            );

            const result = completeOnboardingSchema.safeParse({
                name: "Ana",
                birthDate: "1995-06-15",
                gender: "female",
                interestedIn: "male",
                photoUrls: ["https://r2.example.com/photo.jpg"],
                nicotineUse: "vaping",
                nicotineFilter: "no_smoking",
                consentGiven: true,
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.nicotineUse).toBe("vaping");
                expect(result.data.nicotineFilter).toBe("no_smoking");
            }
        });

        it("should validate onboarding schema — accept multi-select nicotineUse arrays", async () => {
            const { completeOnboardingSchema } = await import(
                "../../src/modules/auth/auth.schema"
            );

            const result = completeOnboardingSchema.safeParse({
                name: "Ana",
                birthDate: "1995-06-15",
                gender: "female",
                interestedIn: "male",
                photoUrls: ["https://r2.example.com/photo.jpg"],
                nicotineUse: ["cigarettes", "vape", "shisha"],
                consentGiven: true,
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.nicotineUse).toEqual(["cigarettes", "vape", "shisha"]);
            }
        });

        it("should validate onboarding schema — accept Flutter interestedIn list payload", async () => {
            const { completeOnboardingSchema } = await import(
                "../../src/modules/auth/auth.schema"
            );

            const result = completeOnboardingSchema.safeParse({
                name: "Ana",
                birthDate: "1995-06-15",
                gender: "female",
                interestedIn: ["male", "female"],
                photoUrls: ["https://media.trembledating.com/users/u/photos/p.jpg"],
                lookingFor: ["long_term"],
                languages: ["Slovenian"],
                hobbies: ["Hiking"],
                prompts: {},
                appLanguage: "sl",
                isDarkMode: true,
                isPrideMode: false,
                showPingAnimation: true,
                ageRangeStart: 22,
                ageRangeEnd: 35,
                maxDistance: 10,
                consentGiven: true,
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.interestedIn).toEqual(["male", "female"]);
            }
        });

        it("should reject a user under 18", async () => {
            const { completeOnboardingSchema } = await import(
                "../../src/modules/auth/auth.schema"
            );

            const underageDate = new Date();
            underageDate.setFullYear(underageDate.getFullYear() - 17);

            const result = completeOnboardingSchema.safeParse({
                name: "Minor",
                birthDate: underageDate.toISOString().split("T")[0],
                gender: "male",
                interestedIn: "both",
                photoUrls: [],
                lookingFor: [],
                languages: ["Slovenian"],
                hobbies: [],
                prompts: {},
                appLanguage: "sl",
                isDarkMode: false,
                isPrideMode: false,
                showPingAnimation: false,
                ageRangeStart: 18,
                ageRangeEnd: 35,
                maxDistance: 5,
                consentGiven: true,
            });
            expect(result.success).toBe(false);
            if (!result.success) {
                const ageError = result.error.issues.find((i) =>
                    i.message.toLowerCase().includes("18")
                );
                expect(ageError).toBeDefined();
            }
        });
    });

    describe("verifyGoogleToken", () => {
        it("throws HttpsError for invalid Google tokens", async () => {
            const originalClientId = process.env.GOOGLE_WEB_CLIENT_ID;
            process.env.GOOGLE_WEB_CLIENT_ID = "test-web-client-id";
            mockVerifyIdToken.mockRejectedValueOnce(new Error("bad token"));

            const { verifyGoogleToken } = await import(
                "../../src/modules/auth/auth.functions"
            );
            const { HttpsError } = await import("firebase-functions/v2/https");
            const callableVerifyGoogleToken = verifyGoogleToken as unknown as (
                request: unknown
            ) => Promise<unknown>;

            try {
                await callableVerifyGoogleToken({
                    rawRequest: { ip: "127.0.0.1" },
                    data: { idToken: "invalid-id-token" },
                });
                throw new Error("Expected verifyGoogleToken to throw");
            } catch (error) {
                expect(error).toBeInstanceOf(HttpsError);
                expect(error).toMatchObject({
                    code: "unauthenticated",
                    message: "Invalid Google token",
                });
            } finally {
                process.env.GOOGLE_WEB_CLIENT_ID = originalClientId;
            }
        });
    });
});
