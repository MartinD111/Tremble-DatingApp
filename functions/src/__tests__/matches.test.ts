/**
 * Tremble — Match Functions Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => ({
        collection: jest.fn(),
        batch: jest.fn(),
        runTransaction: jest.fn(),
    })),
    FieldValue: {
        increment: jest.fn((value: number) => ({ increment: value })),
        serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
    },
}));

jest.mock("firebase-admin/messaging", () => ({
    getMessaging: jest.fn(() => ({
        send: jest.fn(),
    })),
}));

jest.mock("firebase-functions/v2/firestore", () => ({
    onDocumentCreated: jest.fn((_, handler) => handler),
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
    requireAdmin: jest.fn(),
    assertNotBanned: jest.fn(),
}));

jest.mock("../../src/middleware/rateLimit", () => ({
    checkRateLimit: jest.fn(),
}));

jest.mock("../../src/middleware/validate", () => ({
    assertValidDocumentId: jest.fn(),
}));

jest.mock("../../src/modules/email/email.functions", () => ({
    sendMatchNotificationEmail: jest.fn(),
}));

jest.mock("../../src/core/redis", () => ({
    getRedis: jest.fn(),
    waveDedupKey: jest.fn(),
    WAVE_DEDUP_SECS: 300,
}));

jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: false,
}));

describe("Matches Module", () => {
    describe("mutual wave monthly counters", () => {
        it("uses a calendar-month users/{uid} counter field", async () => {
            const { mutualWaveCounterField } = await import(
                "../../src/modules/matches/matches.functions"
            );

            expect(mutualWaveCounterField(new Date("2026-06-02T12:00:00Z"))).toBe(
                "mutualWaves_2026_06"
            );
        });

        it("uses free and premium mutual wave limits", async () => {
            const { mutualWaveLimitForUser, mutualWaveCountForUser } = await import(
                "../../src/modules/matches/matches.functions"
            );

            expect(mutualWaveLimitForUser({ isPremium: false })).toBe(5);
            expect(mutualWaveLimitForUser({ isPremium: true })).toBe(20);
            expect(mutualWaveCountForUser({ mutualWaves_2026_06: 4 }, "mutualWaves_2026_06")).toBe(4);
            expect(mutualWaveCountForUser({}, "mutualWaves_2026_06")).toBe(0);
        });
    });
});
