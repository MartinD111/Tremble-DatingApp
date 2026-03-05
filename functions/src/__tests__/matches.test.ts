/**
 * Tremble — Matches Functions Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => ({})),
    FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
}));
jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, fn) => fn),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) { super(message); this.code = code; }
    },
}));

describe("Matches Module", () => {
    describe("sendGreetingSchema", () => {
        it("should reject empty toUserId", async () => {
            const { sendGreetingSchema } = await import("../../src/modules/matches/matches.schema");
            const result = sendGreetingSchema.safeParse({ toUserId: "" });
            expect(result.success).toBe(false);
        });

        it("should accept valid greeting", async () => {
            const { sendGreetingSchema } = await import("../../src/modules/matches/matches.schema");
            const result = sendGreetingSchema.safeParse({
                toUserId: "user_abc_123",
                message: "Živjo!",
            });
            expect(result.success).toBe(true);
        });

        it("should accept greeting without optional message", async () => {
            const { sendGreetingSchema } = await import("../../src/modules/matches/matches.schema");
            const result = sendGreetingSchema.safeParse({ toUserId: "user_abc_123" });
            expect(result.success).toBe(true);
        });
    });

    describe("respondToGreetingSchema", () => {
        it("should require greetingId and accept fields", async () => {
            const { respondToGreetingSchema } = await import("../../src/modules/matches/matches.schema");

            expect(respondToGreetingSchema.safeParse({}).success).toBe(false);
            expect(respondToGreetingSchema.safeParse({
                greetingId: "greeting_123",
                accept: true,
            }).success).toBe(true);
            expect(respondToGreetingSchema.safeParse({
                greetingId: "greeting_123",
                accept: false,
            }).success).toBe(true);
        });
    });
});
