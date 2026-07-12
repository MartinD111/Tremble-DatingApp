/**
 * Tremble — Gym Mode manual-activation tests.
 *
 * Plan 20260712-fix-gym-manual-activation: verify that onGymModeActivate no
 * longer rejects manual activation based on server-side geofence distance.
 * Manual activation is an explicit context declaration; physical detection
 * belongs to the geofence dwell service and is not touched here.
 */

import { describe, it, expect, jest, beforeEach } from "@jest/globals";

type UserData = Record<string, unknown> | undefined;

const mockUserUpdates: Array<{ uid: string; data: Record<string, unknown> }> = [];
const mockUserGetResults = new Map<string, UserData>();
const mockGymGetResults = new Map<
    string,
    { exists: boolean; data: () => Record<string, unknown> | undefined }
>();

const mockDb = {
    collection: jest.fn((name: string) => {
        if (name === "users") {
            return {
                doc: jest.fn((uid: string) => ({
                    get: jest.fn(async () => ({
                        data: () => mockUserGetResults.get(uid),
                    })),
                    update: jest.fn(async (data: Record<string, unknown>) => {
                        mockUserUpdates.push({ uid, data });
                    }),
                })),
            };
        }
        if (name === "gyms") {
            return {
                doc: jest.fn((gymId: string) => ({
                    get: jest.fn(async () => {
                        const result = mockGymGetResults.get(gymId);
                        return result ?? { exists: false, data: () => undefined };
                    }),
                })),
            };
        }
        throw new Error(`Unexpected collection: ${name}`);
    }),
};

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    Timestamp: {
        fromDate: jest.fn((date: Date) => ({ toDate: () => date, _date: date })),
        now: jest.fn(() => ({ toDate: () => new Date() })),
    },
    FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
}));
jest.mock("firebase-admin/messaging", () => ({
    getMessaging: jest.fn(() => ({ send: jest.fn() })),
}));
jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_: unknown, fn: unknown) => fn),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));
jest.mock("firebase-functions/v2/scheduler", () => ({
    onSchedule: jest.fn((_: unknown, fn: unknown) => fn),
}));
jest.mock("../../src/middleware/rateLimit", () => ({
    checkRateLimit: jest.fn(async () => undefined),
}));
jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: false,
}));

type CallableRequest = {
    auth?: { uid: string };
    data: Record<string, unknown>;
};

function buildRequest(uid: string, data: Record<string, unknown>): CallableRequest {
    return { auth: { uid }, data };
}

describe("onGymModeActivate — manual activation (no proximity gate)", () => {
    beforeEach(() => {
        jest.resetModules();
        mockUserUpdates.length = 0;
        mockUserGetResults.clear();
        mockGymGetResults.clear();
    });

    it("succeeds when caller is FAR from the gym (was: failed-precondition)", async () => {
        mockUserGetResults.set("uidA", { blockedUserIds: [] });
        mockGymGetResults.set("gym-planet-fit", {
            exists: true,
            data: () => ({
                name: "Planet Fit Koper",
                location: { lat: 45.5480, lng: 13.7302 },
                radiusMeters: 200,
            }),
        });

        const { onGymModeActivate } = await import("../../src/modules/gym/gym.functions");
        // Caller is in Ljubljana (~100km from Koper gym) — pre-fix this would throw.
        const result = await (onGymModeActivate as unknown as (r: CallableRequest) => Promise<{
            success: boolean;
            gymId: string;
            gymName: string;
        }>)(buildRequest("uidA", { gymId: "gym-planet-fit", latitude: 46.0569, longitude: 14.5058 }));

        expect(result.success).toBe(true);
        expect(result.gymId).toBe("gym-planet-fit");
        expect(result.gymName).toBe("Planet Fit Koper");
        expect(mockUserUpdates).toHaveLength(1);
        expect(mockUserUpdates[0].data).toHaveProperty("activeGymId", "gym-planet-fit");
        expect(mockUserUpdates[0].data).toHaveProperty("gymModeUntil");
    });

    it("succeeds when caller is INSIDE the geofence (unchanged behaviour)", async () => {
        mockUserGetResults.set("uidB", { blockedUserIds: [] });
        mockGymGetResults.set("gym-planet-fit", {
            exists: true,
            data: () => ({
                name: "Planet Fit Koper",
                location: { lat: 45.5480, lng: 13.7302 },
                radiusMeters: 200,
            }),
        });

        const { onGymModeActivate } = await import("../../src/modules/gym/gym.functions");
        const result = await (onGymModeActivate as unknown as (r: CallableRequest) => Promise<{
            success: boolean;
        }>)(buildRequest("uidB", {
            gymId: "gym-planet-fit",
            latitude: 45.5481, // ~10m from gym centre
            longitude: 13.7303,
        }));

        expect(result.success).toBe(true);
        expect(mockUserUpdates).toHaveLength(1);
    });

    it("still rejects when gymId does not exist", async () => {
        mockUserGetResults.set("uidC", { blockedUserIds: [] });
        // No entry in mockGymGetResults → exists: false

        const { onGymModeActivate } = await import("../../src/modules/gym/gym.functions");
        await expect(
            (onGymModeActivate as unknown as (r: CallableRequest) => Promise<unknown>)(
                buildRequest("uidC", { gymId: "gym-ghost", latitude: 45.5, longitude: 13.7 }),
            ),
        ).rejects.toMatchObject({ code: "not-found" });
        expect(mockUserUpdates).toHaveLength(0);
    });

    it("still rejects when latitude/longitude are missing", async () => {
        mockUserGetResults.set("uidD", { blockedUserIds: [] });

        const { onGymModeActivate } = await import("../../src/modules/gym/gym.functions");
        await expect(
            (onGymModeActivate as unknown as (r: CallableRequest) => Promise<unknown>)(
                buildRequest("uidD", { gymId: "gym-planet-fit" }),
            ),
        ).rejects.toMatchObject({ code: "invalid-argument" });
        expect(mockUserUpdates).toHaveLength(0);
    });

    it("still rejects when caller is not authenticated", async () => {
        const { onGymModeActivate } = await import("../../src/modules/gym/gym.functions");
        await expect(
            (onGymModeActivate as unknown as (r: CallableRequest) => Promise<unknown>)({
                data: { gymId: "gym-planet-fit", latitude: 45.5, longitude: 13.7 },
            }),
        ).rejects.toMatchObject({ code: "unauthenticated" });
        expect(mockUserUpdates).toHaveLength(0);
    });
});
