/**
 * Tremble — Auth Functions Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

// We mock the firebase-admin module before importing anything that needs it
// eslint-disable-next-line @typescript-eslint/no-explicit-any
jest.mock("firebase-admin/firestore", () => {
    const mockDocRef = {
        set: jest.fn(() => Promise.resolve()),
        get: jest.fn(() =>
            Promise.resolve({
                exists: true,
                data: () => ({ email: "test@example.com", name: "Test" }),
            })
        ),
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

describe("Auth Module", () => {
    describe("completeOnboarding", () => {
        it("should reject unauthenticated requests", async () => {
            const { requireAuth } = await import("../../src/middleware/authGuard");

            expect(() =>
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
});
