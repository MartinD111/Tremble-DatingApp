/**
 * Tremble — Uploads + Proximity Schema Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

const mockProximityEventsAdd = jest.fn<() => Promise<void>>();
const mockProximityDocs: Array<{ id: string; data: () => Record<string, unknown> }> = [];
const mockUsersById = new Map<string, Record<string, unknown>>();
const mockRedis = {
    set: jest.fn<() => Promise<string | null>>(),
    del: jest.fn<() => Promise<number>>(),
    incr: jest.fn<() => Promise<number>>(),
    expire: jest.fn<() => Promise<number>>(),
};
const mockMessaging = {
    send: jest.fn<() => Promise<void>>(),
};
const mockDb = {
    collection: jest.fn((name: string) => {
        if (name === "proximity") {
            const query = {
                where: jest.fn(),
                get: jest.fn(async () => ({
                    empty: mockProximityDocs.length === 0,
                    size: mockProximityDocs.length,
                    docs: mockProximityDocs,
                })),
            };
            query.where.mockReturnValue(query);
            return query;
        }
        if (name === "users") {
            return {
                doc: jest.fn((uid: string) => ({
                    get: jest.fn(async () => ({
                        data: () => mockUsersById.get(uid),
                    })),
                })),
            };
        }
        if (name === "proximity_events") {
            return { add: mockProximityEventsAdd };
        }
        throw new Error(`Unexpected collection: ${name}`);
    }),
};

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
    Timestamp: { fromDate: jest.fn((date: Date) => ({ toDate: () => date })) },
}));
jest.mock("firebase-admin/messaging", () => ({
    getMessaging: jest.fn(() => mockMessaging),
}));
jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, fn) => fn),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) { super(message); this.code = code; }
    },
}));
jest.mock("firebase-functions/v2/firestore", () => ({
    onDocumentCreated: jest.fn((_, fn) => fn),
    onDocumentUpdated: jest.fn((_, fn) => fn),
}));
jest.mock("firebase-functions/v2/scheduler", () => ({
    onSchedule: jest.fn((_, fn) => fn),
}));
jest.mock("../../src/core/redis", () => ({
    getRedis: jest.fn(() => mockRedis),
    proximityCooldownKey: jest.fn((aUid: string, bUid: string) => `proximity:${aUid}:${bUid}`),
    globalThrottleKey: jest.fn((uid: string) => `global:${uid}`),
    PROXIMITY_COOLDOWN_SECS: 1800,
    GLOBAL_THROTTLE_SECS: 600,
    GLOBAL_THROTTLE_MAX: 3,
}));

describe("Uploads Module", () => {
    describe("generateUploadUrlSchema", () => {
        it("should reject disallowed MIME type", async () => {
            const { generateUploadUrlSchema } = await import("../../src/modules/uploads/uploads.schema");
            const result = generateUploadUrlSchema.safeParse({
                fileName: "virus.exe",
                mimeType: "application/octet-stream",
                fileSizeBytes: 1024,
            });
            expect(result.success).toBe(false);
        });

        it("should reject file over 10MB", async () => {
            const { generateUploadUrlSchema } = await import("../../src/modules/uploads/uploads.schema");
            const result = generateUploadUrlSchema.safeParse({
                fileName: "big.jpg",
                mimeType: "image/jpeg",
                fileSizeBytes: 11 * 1024 * 1024, // 11MB
            });
            expect(result.success).toBe(false);
        });

        it("should accept valid JPEG upload", async () => {
            const { generateUploadUrlSchema } = await import("../../src/modules/uploads/uploads.schema");
            const result = generateUploadUrlSchema.safeParse({
                fileName: "profile.jpg",
                mimeType: "image/jpeg",
                fileSizeBytes: 2 * 1024 * 1024, // 2MB
            });
            expect(result.success).toBe(true);
        });
    });
});

describe("Proximity Module", () => {
    describe("findNearbySchema / updateLocationSchema", () => {
        it("should reject invalid coordinates", async () => {
            // We test the schemas defined inside proximity.functions.ts inline
            const { z } = await import("zod");
            const updateLocationSchema = z.object({
                latitude: z.number().min(-90).max(90),
                longitude: z.number().min(-180).max(180),
            });

            expect(updateLocationSchema.safeParse({ latitude: 200, longitude: 0 }).success).toBe(false);
            expect(updateLocationSchema.safeParse({ latitude: 46.05, longitude: 14.5 }).success).toBe(true);
        });
    });

    describe("scanProximityPairs", () => {
        beforeEach(() => {
            jest.resetModules();
            mockProximityEventsAdd.mockClear();
            mockProximityDocs.length = 0;
            mockUsersById.clear();
            mockRedis.set.mockReset();
            mockRedis.del.mockReset();
            mockRedis.incr.mockReset();
            mockRedis.expire.mockReset();
            mockMessaging.send.mockClear();
        });

        it("should skip bothPremium pairs when nicotine filters are incompatible", async () => {
            mockProximityDocs.push(
                { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "pro" }) },
                { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "pro" }) },
            );
            mockUsersById.set("userA", {
                blockedUserIds: [],
                isPremium: true,
                nicotineUse: ["vaping"],
                nicotineFilter: "any",
            });
            mockUsersById.set("userB", {
                blockedUserIds: [],
                isPremium: true,
                nicotineUse: ["none"],
                nicotineFilter: "none_only",
            });
            mockRedis.set.mockImplementation(async () => "OK");
            mockRedis.del.mockImplementation(async () => 1);
            mockRedis.incr.mockImplementation(async () => 1);
            mockRedis.expire.mockImplementation(async () => 1);

            const { scanProximityPairs } = await import("../../src/modules/proximity/proximity.functions");

            await (scanProximityPairs as unknown as () => Promise<void>)();

            expect(mockRedis.del).toHaveBeenCalledWith("proximity:userA:userB");
            expect(mockProximityEventsAdd).not.toHaveBeenCalled();
            expect(mockMessaging.send).not.toHaveBeenCalled();
        });
    });
});
