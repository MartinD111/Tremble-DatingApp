/**
 * Tremble — Rate Limit Middleware Unit Tests
 */

import { afterEach, beforeEach, describe, expect, it, jest } from "@jest/globals";

type MockDocSnapshot = {
    exists: boolean;
    data?: () => {
        count: number;
        windowStart: number;
    };
};

const mockDocRef = { id: "userUid:endpoint" };
const mockGet = jest.fn<() => Promise<MockDocSnapshot>>();
const mockSet = jest.fn<(docRef: typeof mockDocRef, data: Record<string, unknown>) => void>();
const mockUpdate = jest.fn<(docRef: typeof mockDocRef, data: Record<string, unknown>) => void>();
const mockDoc = jest.fn(() => mockDocRef);
const mockCollection = jest.fn(() => ({ doc: mockDoc }));
const mockTransaction = {
    get: mockGet,
    set: mockSet,
    update: mockUpdate,
};
const mockRunTransaction = jest.fn(async (
    callback: (transaction: typeof mockTransaction) => Promise<void>
) => callback(mockTransaction));
const mockDb = {
    collection: mockCollection,
    runTransaction: mockRunTransaction,
};

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    FieldValue: {
        increment: jest.fn((count: number) => ({ increment: count })),
    },
}));

jest.mock("firebase-functions/v2/https", () => ({
    HttpsError: class HttpsError extends Error {
        readonly code: string;

        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));

describe("checkRateLimit", () => {
    beforeEach(() => {
        jest.spyOn(Date, "now").mockReturnValue(1_700_000_000_000);
    });

    afterEach(() => {
        jest.restoreAllMocks();
    });

    it("writes ttl, not expiresAt, when creating a rate limit document", async () => {
        const { checkRateLimit } = await import("../middleware/rateLimit");
        mockGet.mockResolvedValue({ exists: false });

        await checkRateLimit("userUid", "endpoint", { maxRequests: 2, windowMs: 5_000 });

        expect(mockCollection).toHaveBeenCalledWith("rateLimits");
        expect(mockDoc).toHaveBeenCalledWith("userUid:endpoint");
        expect(mockSet).toHaveBeenCalledWith(mockDocRef, {
            count: 1,
            windowStart: 1_700_000_000_000,
            ttl: new Date(1_700_000_005_000),
        });
        expect(mockSet.mock.calls[0][1]).not.toHaveProperty("expiresAt");
    });

    it("writes ttl, not expiresAt, when resetting an expired rate limit window", async () => {
        const { checkRateLimit } = await import("../middleware/rateLimit");
        mockGet.mockResolvedValue({
            exists: true,
            data: () => ({
                count: 1,
                windowStart: 1_699_999_990_000,
            }),
        });

        await checkRateLimit("userUid", "endpoint", { maxRequests: 2, windowMs: 5_000 });

        expect(mockSet).toHaveBeenCalledWith(mockDocRef, {
            count: 1,
            windowStart: 1_700_000_000_000,
            ttl: new Date(1_700_000_005_000),
        });
        expect(mockSet.mock.calls[0][1]).not.toHaveProperty("expiresAt");
    });
});
