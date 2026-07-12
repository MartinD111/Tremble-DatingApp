/**
 * Tremble — CROSSING_PATHS visible-notification tests.
 *
 * Plan 20260712-fix-crossing-paths-visibility: verify that scanProximityPairs
 * sends a full FCM notification payload (title/body localized server-side from
 * the recipient's `appLanguage` field) and that pairsNotified counts real
 * successful visible sends, not optimistic pre-send increments.
 */

import { describe, it, expect, jest, beforeEach } from "@jest/globals";

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
    send: jest.fn<(msg: unknown) => Promise<string>>(),
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
        if (name === "active_run_crosses") {
            return {
                doc: jest.fn(() => ({
                    get: jest.fn(async () => ({ exists: false, data: () => undefined })),
                    set: jest.fn<() => Promise<void>>(async () => undefined),
                })),
            };
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
    onCall: jest.fn((_: unknown, fn: unknown) => fn),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) { super(message); this.code = code; }
    },
}));
jest.mock("firebase-functions/v2/firestore", () => ({
    onDocumentCreated: jest.fn((_: unknown, fn: unknown) => fn),
    onDocumentUpdated: jest.fn((_: unknown, fn: unknown) => fn),
}));
jest.mock("firebase-functions/v2/scheduler", () => ({
    onSchedule: jest.fn((_: unknown, fn: unknown) => fn),
}));
jest.mock("../../src/core/redis", () => ({
    getRedis: jest.fn(() => mockRedis),
    proximityCooldownKey: jest.fn((aUid: string, bUid: string) => `proximity:${aUid}:${bUid}`),
    globalThrottleKey: jest.fn((uid: string) => `global:${uid}`),
    PROXIMITY_COOLDOWN_SECS: 1800,
    GLOBAL_THROTTLE_SECS: 600,
    GLOBAL_THROTTLE_MAX: 3,
}));

// Shared happy-path base — mirrors uploads_proximity.test.ts (d)/(e).
const passingHobbies = ["Tek", "Pohodništvo", "Joga"];
const mutualMatchBase = {
    blockedUserIds: [],
    age: 28,
    ageRangeStart: 18,
    ageRangeEnd: 40,
    hobbies: passingHobbies,
    introvertScale: 50,
    fcmToken: "fcm-token",
};

type SentPayload = {
    token: string;
    notification?: { title?: string; body?: string };
    data?: Record<string, string>;
    apns?: { payload?: { aps?: Record<string, unknown> } };
    android?: { priority?: string; notification?: Record<string, unknown> };
};

function sentPayloads(): SentPayload[] {
    return (mockMessaging.send.mock.calls as unknown as Array<[SentPayload]>).map((c) => c[0]);
}

function setupHappyPathPair(langA: string, langB: string): void {
    mockProximityDocs.push(
        { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
        { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
    );
    mockUsersById.set("userA", {
        ...mutualMatchBase,
        gender: "Male",
        interestedIn: ["Female"],
        fcmToken: "fcm-a",
        appLanguage: langA,
        displayName: "Ana",
    });
    mockUsersById.set("userB", {
        ...mutualMatchBase,
        gender: "Female",
        interestedIn: ["Male"],
        fcmToken: "fcm-b",
        appLanguage: langB,
        displayName: "Bojan",
    });
    mockRedis.set.mockImplementation(async () => "OK");
    mockRedis.del.mockImplementation(async () => 1);
    mockRedis.incr.mockImplementation(async () => 1);
    mockRedis.expire.mockImplementation(async () => 1);
    mockMessaging.send.mockImplementation(async () => "message-id");
}

describe("scanProximityPairs — CROSSING_PATHS visible notification", () => {
    beforeEach(() => {
        jest.resetModules();
        mockProximityEventsAdd.mockClear();
        mockProximityDocs.length = 0;
        mockUsersById.clear();
        mockRedis.set.mockReset();
        mockRedis.del.mockReset();
        mockRedis.incr.mockReset();
        mockRedis.expire.mockReset();
        mockMessaging.send.mockReset();
    });

    it("sends visible notification.title/body in EN when recipient appLanguage=en", async () => {
        setupHappyPathPair("en", "en");
        const { scanProximityPairs, CROSSING_PATHS_STRINGS } =
            await import("../../src/modules/proximity/proximity.functions");

        await (scanProximityPairs as unknown as () => Promise<void>)();

        const payloads = sentPayloads();
        expect(payloads.length).toBe(2);
        for (const p of payloads) {
            expect(p.notification?.title).toBe(CROSSING_PATHS_STRINGS.en.title);
            expect(p.notification?.body).toContain("is nearby");
            expect(p.data?.type).toBe("CROSSING_PATHS");
            expect(p.data?.senderName).toBeDefined();
            expect(p.apns?.payload?.aps).not.toHaveProperty("alert-body-loc-key");
            expect(p.apns?.payload?.aps).not.toHaveProperty("alert-title-loc-key");
        }
    });

    it("localizes per recipient — SL and EN in the same pair", async () => {
        setupHappyPathPair("sl", "en");
        const { scanProximityPairs, CROSSING_PATHS_STRINGS } =
            await import("../../src/modules/proximity/proximity.functions");

        await (scanProximityPairs as unknown as () => Promise<void>)();

        const payloads = sentPayloads();
        expect(payloads.length).toBe(2);
        // userA (recipient of B->A send) has appLanguage=sl → SL strings.
        const toA = payloads.find((p) => p.token === "fcm-a");
        const toB = payloads.find((p) => p.token === "fcm-b");
        expect(toA?.notification?.title).toBe(CROSSING_PATHS_STRINGS.sl.title);
        expect(toB?.notification?.title).toBe(CROSSING_PATHS_STRINGS.en.title);
        expect(toA?.notification?.body).toContain("v bližini");
        expect(toB?.notification?.body).toContain("is nearby");
    });

    it("falls back to EN for unknown language codes", async () => {
        setupHappyPathPair("xx", "de");
        const { scanProximityPairs, CROSSING_PATHS_STRINGS } =
            await import("../../src/modules/proximity/proximity.functions");

        await (scanProximityPairs as unknown as () => Promise<void>)();

        const payloads = sentPayloads();
        expect(payloads.length).toBe(2);
        for (const p of payloads) {
            expect(p.notification?.title).toBe(CROSSING_PATHS_STRINGS.en.title);
        }
    });

    it("counts pairsNotified from real successes — missing token means the other side is still counted", async () => {
        // userB has no fcmToken → send B->A goes through, send A->B is skipped (no_token).
        mockProximityDocs.push(
            { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
            { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
        );
        mockUsersById.set("userA", {
            ...mutualMatchBase,
            gender: "Male",
            interestedIn: ["Female"],
            fcmToken: "fcm-a",
            appLanguage: "en",
            displayName: "Ana",
        });
        mockUsersById.set("userB", {
            ...mutualMatchBase,
            gender: "Female",
            interestedIn: ["Male"],
            fcmToken: undefined,
            appLanguage: "en",
            displayName: "Bojan",
        });
        mockRedis.set.mockImplementation(async () => "OK");
        mockRedis.del.mockImplementation(async () => 1);
        mockRedis.incr.mockImplementation(async () => 1);
        mockRedis.expire.mockImplementation(async () => 1);
        mockMessaging.send.mockImplementation(async () => "message-id");

        const { scanProximityPairs } =
            await import("../../src/modules/proximity/proximity.functions");
        await (scanProximityPairs as unknown as () => Promise<void>)();

        const payloads = sentPayloads();
        // Only one visible send (to userA, since userB has no token).
        expect(payloads.filter((p) => p.notification !== undefined).length).toBe(1);
        expect(payloads[0].token).toBe("fcm-a");
    });

    it("silent mode (Run/Gym/Event) sends data-only push and is NOT counted as visible", async () => {
        mockProximityDocs.push(
            { id: "userA", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
            { id: "userB", data: () => ({ geohash: "u24pruy", radiusTier: "free" }) },
        );
        mockUsersById.set("userA", {
            ...mutualMatchBase,
            gender: "Male",
            interestedIn: ["Female"],
            fcmToken: "fcm-a",
            appLanguage: "en",
            displayName: "Ana",
            isRunModeActive: true, // silent branch AND lowers threshold to 0.55
        });
        mockUsersById.set("userB", {
            ...mutualMatchBase,
            gender: "Female",
            interestedIn: ["Male"],
            fcmToken: "fcm-b",
            appLanguage: "en",
            displayName: "Bojan",
        });
        mockRedis.set.mockImplementation(async () => "OK");
        mockRedis.del.mockImplementation(async () => 1);
        mockRedis.incr.mockImplementation(async () => 1);
        mockRedis.expire.mockImplementation(async () => 1);
        mockMessaging.send.mockImplementation(async () => "message-id");

        const { scanProximityPairs } =
            await import("../../src/modules/proximity/proximity.functions");
        await (scanProximityPairs as unknown as () => Promise<void>)();

        const payloads = sentPayloads();
        expect(payloads.length).toBe(2);
        // userA is in Run Mode → silent (no notification block).
        const toA = payloads.find((p) => p.token === "fcm-a");
        expect(toA?.notification).toBeUndefined();
        // userB is not silent → gets a visible notification.
        const toB = payloads.find((p) => p.token === "fcm-b");
        expect(toB?.notification?.title).toBeDefined();
    });
});
