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
    describe("coordinate schema", () => {
        it("should reject invalid coordinates", async () => {
            const { z } = await import("zod");
            const coordinateSchema = z.object({
                latitude: z.number().min(-90).max(90),
                longitude: z.number().min(-180).max(180),
            });

            expect(coordinateSchema.safeParse({ latitude: 200, longitude: 0 }).success).toBe(false);
            expect(coordinateSchema.safeParse({ latitude: 46.05, longitude: 14.5 }).success).toBe(true);
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

        // Reusable mutual-match base: gender/age satisfy the cheap gates and hobbies
        // satisfy the 0.70 score threshold. Tests override specific fields.
        const passingHobbies = [
            { name: "Tek", category: "active" },
            { name: "Hiking", category: "active" },
            { name: "Joga", category: "active" },
        ];
        const mutualMatchBase = {
            blockedUserIds: [],
            age: 28,
            ageRangeStart: 18,
            ageRangeEnd: 40,
            hobbies: passingHobbies,
            introvertScale: 50,
            fcmToken: "fcm-token",
        };

        it("should skip bothPremium pairs when nicotine filters are incompatible", async () => {
            mockProximityDocs.push(
                { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "pro" }) },
                { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "pro" }) },
            );
            mockUsersById.set("userA", {
                ...mutualMatchBase,
                gender: "Male",
                interestedIn: ["Female"],
                isPremium: true,
                nicotineUse: ["vaping"],
                nicotineFilter: "any",
            });
            mockUsersById.set("userB", {
                ...mutualMatchBase,
                gender: "Female",
                interestedIn: ["Male"],
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

        it("(a) skips pair when gender preferences mismatch in both directions", async () => {
            mockProximityDocs.push(
                { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
                { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
            );
            // Both men looking for women → neither direction matches.
            mockUsersById.set("userA", {
                ...mutualMatchBase,
                gender: "Male",
                interestedIn: ["Female"],
            });
            mockUsersById.set("userB", {
                ...mutualMatchBase,
                gender: "Male",
                interestedIn: ["Female"],
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

        it("(b) skips pair when age falls outside requester's range", async () => {
            mockProximityDocs.push(
                { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
                { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
            );
            mockUsersById.set("userA", {
                ...mutualMatchBase,
                gender: "Male",
                interestedIn: ["Female"],
                ageRangeStart: 30,
                ageRangeEnd: 40,
                age: 28,
            });
            // B is 22 — outside A's 30-40 range.
            mockUsersById.set("userB", {
                ...mutualMatchBase,
                gender: "Female",
                interestedIn: ["Male"],
                age: 22,
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

        it("(c) skips pair when compatibility score is below threshold", async () => {
            mockProximityDocs.push(
                { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
                { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
            );
            // Gender + age pass, but no shared hobbies and opposite introvert/lifestyle.
            mockUsersById.set("userA", {
                blockedUserIds: [],
                gender: "Male",
                interestedIn: ["Female"],
                age: 28,
                ageRangeStart: 18,
                ageRangeEnd: 40,
                hobbies: [],
                introvertScale: 0,
                drinkingHabit: "frequently",
                fcmToken: "fcm-a",
            });
            mockUsersById.set("userB", {
                blockedUserIds: [],
                gender: "Female",
                interestedIn: ["Male"],
                age: 28,
                ageRangeStart: 18,
                ageRangeEnd: 40,
                hobbies: [],
                introvertScale: 100,
                drinkingHabit: "none",
                fcmToken: "fcm-b",
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

        it("(d) notifies both users when gender + age + score all pass", async () => {
            mockProximityDocs.push(
                { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
                { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
            );
            mockUsersById.set("userA", {
                ...mutualMatchBase,
                gender: "Male",
                interestedIn: ["Female"],
                fcmToken: "fcm-a",
            });
            mockUsersById.set("userB", {
                ...mutualMatchBase,
                gender: "Female",
                interestedIn: ["Male"],
                fcmToken: "fcm-b",
            });
            mockRedis.set.mockImplementation(async () => "OK");
            mockRedis.del.mockImplementation(async () => 1);
            // Returns 1 for both encounter count and per-recipient throttle.
            mockRedis.incr.mockImplementation(async () => 1);
            mockRedis.expire.mockImplementation(async () => 1);

            const { scanProximityPairs } = await import("../../src/modules/proximity/proximity.functions");

            await (scanProximityPairs as unknown as () => Promise<void>)();

            // Pair survived all gates → proximity event written and BOTH directions notified.
            expect(mockProximityEventsAdd).toHaveBeenCalledTimes(1);
            const tokens = (mockMessaging.send.mock.calls as unknown as Array<[{ token: string }]>).map(
                (call) => call[0].token,
            );
            expect(tokens).toEqual(expect.arrayContaining(["fcm-a", "fcm-b"]));
            // Cooldown is held (not deleted) when the pair passes.
            expect(mockRedis.del).not.toHaveBeenCalledWith("proximity:userA:userB");
        });

        it("(e) Run Club mode lowers threshold to 0.55 — pair that would fail at 0.70 now notifies", async () => {
            mockProximityDocs.push(
                { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
                { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
            );
            // 3 shared "active" hobbies → hobbyScore ≈ 0.647.
            // introvertScale 0 vs 100 → personality = 0.0.
            // Lifestyle: nicotine both empty → match → 1.0.
            // Total ≈ 0.647*0.5 + 0.0*0.25 + 1.0*0.25 ≈ 0.57.
            // 0.57 is below the 0.70 standard threshold but above the 0.55 special-context threshold.
            mockUsersById.set("userA", {
                ...mutualMatchBase,
                gender: "Male",
                interestedIn: ["Female"],
                introvertScale: 0,
                isRunModeActive: true, // triggers sharedContext → threshold 0.55
                fcmToken: "fcm-a",
            });
            mockUsersById.set("userB", {
                ...mutualMatchBase,
                gender: "Female",
                interestedIn: ["Male"],
                introvertScale: 100,
                fcmToken: "fcm-b",
            });
            mockRedis.set.mockImplementation(async () => "OK");
            mockRedis.del.mockImplementation(async () => 1);
            mockRedis.incr.mockImplementation(async () => 1);
            mockRedis.expire.mockImplementation(async () => 1);

            const { scanProximityPairs } = await import("../../src/modules/proximity/proximity.functions");

            await (scanProximityPairs as unknown as () => Promise<void>)();

            expect(mockProximityEventsAdd).toHaveBeenCalledTimes(1);
            const tokens = (mockMessaging.send.mock.calls as unknown as Array<[{ token: string }]>).map(
                (call) => call[0].token,
            );
            expect(tokens).toEqual(expect.arrayContaining(["fcm-a", "fcm-b"]));
            expect(mockRedis.del).not.toHaveBeenCalledWith("proximity:userA:userB");
        });
    });
});
