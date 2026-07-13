/**
 * Tremble — Event Mode activation tests.
 *
 * Plan 20260713-event-locations-firestore (PLAN_03_APP_CODE.md KORAK 3.5):
 * verify that onEventModeActivate accepts BOTH the canonical Firestore
 * GeoPoint shape (seed_events.ts writes this) AND the legacy `{lat, lng}` map
 * shape (dev docs seeded before the migration) for the `location` field.
 */

import { describe, it, expect, jest, beforeEach } from "@jest/globals";

type UserData = Record<string, unknown> | undefined;
type EventData = Record<string, unknown> | undefined;

const mockUserUpdates: Array<{ uid: string; data: Record<string, unknown> }> = [];
const mockUserGetResults = new Map<string, UserData>();
const mockEventGetResults = new Map<
    string,
    { exists: boolean; data: () => EventData }
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
        if (name === "events") {
            return {
                doc: jest.fn((eventId: string) => ({
                    get: jest.fn(async () => {
                        const result = mockEventGetResults.get(eventId);
                        return result ?? { exists: false, data: () => undefined };
                    }),
                })),
            };
        }
        throw new Error(`Unexpected collection: ${name}`);
    }),
};

/**
 * Minimal stand-in for the admin SDK's GeoPoint. The CF check uses
 * `instanceof GeoPoint` — the mocked module below re-exports this same class,
 * so `instanceof` matches inside the function under test.
 */
class MockGeoPoint {
    constructor(public latitude: number, public longitude: number) {}
}

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    GeoPoint: MockGeoPoint,
    Timestamp: {
        fromDate: jest.fn((date: Date) => ({
            toMillis: () => date.getTime(),
            toDate: () => date,
            _date: date,
        })),
        now: jest.fn(() => ({ toMillis: () => Date.now() })),
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

// Ljubljana centre — used by all fixtures so haversine stays well under the
// 500 m default radius when the caller is at the venue.
const LJ_LAT = 46.0514;
const LJ_LNG = 14.5058;
const HOUR = 60 * 60 * 1000;

function futureTimestamp(msFromNow: number) {
    return {
        toMillis: () => Date.now() + msFromNow,
        toDate: () => new Date(Date.now() + msFromNow),
    };
}

describe("onEventModeActivate — GeoPoint + legacy map compatibility", () => {
    beforeEach(() => {
        jest.resetModules();
        mockUserUpdates.length = 0;
        mockUserGetResults.clear();
        mockEventGetResults.clear();
    });

    it("accepts a GeoPoint location when caller is inside the radius (KORAK 3.5 canonical shape)", async () => {
        mockUserGetResults.set("uidGP", {});
        mockEventGetResults.set("club_monokel", {
            exists: true,
            data: () => ({
                name: "Klub Monokel",
                active: true,
                location: new MockGeoPoint(LJ_LAT, LJ_LNG),
                radiusMeters: 150,
                startsAt: futureTimestamp(-HOUR),
                endsAt: futureTimestamp(HOUR),
            }),
        });

        const { onEventModeActivate } = await import("../../src/modules/events/events.functions");
        const result = await (onEventModeActivate as unknown as (r: CallableRequest) => Promise<{
            success: boolean;
            eventId: string;
        }>)(buildRequest("uidGP", {
            eventId: "club_monokel",
            latitude: LJ_LAT,
            longitude: LJ_LNG,
        }));

        expect(result.success).toBe(true);
        expect(result.eventId).toBe("club_monokel");
        expect(mockUserUpdates).toHaveLength(1);
        expect(mockUserUpdates[0].data).toHaveProperty("activeEventId", "club_monokel");
    });

    it("rejects a GeoPoint location when caller is outside the radius", async () => {
        mockUserGetResults.set("uidGPFar", {});
        mockEventGetResults.set("club_monokel", {
            exists: true,
            data: () => ({
                name: "Klub Monokel",
                active: true,
                location: new MockGeoPoint(LJ_LAT, LJ_LNG),
                radiusMeters: 150,
                startsAt: futureTimestamp(-HOUR),
                endsAt: futureTimestamp(HOUR),
            }),
        });

        const { onEventModeActivate } = await import("../../src/modules/events/events.functions");
        // Caller in Koper (~100 km away)
        await expect(
            (onEventModeActivate as unknown as (r: CallableRequest) => Promise<unknown>)(
                buildRequest("uidGPFar", {
                    eventId: "club_monokel",
                    latitude: 45.5480,
                    longitude: 13.7302,
                }),
            ),
        ).rejects.toMatchObject({ code: "failed-precondition" });
        expect(mockUserUpdates).toHaveLength(0);
    });

    it("still accepts the legacy {lat, lng} map shape for backwards compatibility", async () => {
        mockUserGetResults.set("uidLegacy", {});
        mockEventGetResults.set("labaratorij", {
            exists: true,
            data: () => ({
                name: "Laboratorij",
                active: true,
                location: { lat: LJ_LAT, lng: LJ_LNG },
                radiusMeters: 150,
                startsAt: futureTimestamp(-HOUR),
                endsAt: futureTimestamp(HOUR),
            }),
        });

        const { onEventModeActivate } = await import("../../src/modules/events/events.functions");
        const result = await (onEventModeActivate as unknown as (r: CallableRequest) => Promise<{
            success: boolean;
        }>)(buildRequest("uidLegacy", {
            eventId: "labaratorij",
            latitude: LJ_LAT,
            longitude: LJ_LNG,
        }));

        expect(result.success).toBe(true);
        expect(mockUserUpdates).toHaveLength(1);
    });

    it("rejects unknown eventId with not-found", async () => {
        mockUserGetResults.set("uidGhost", {});

        const { onEventModeActivate } = await import("../../src/modules/events/events.functions");
        await expect(
            (onEventModeActivate as unknown as (r: CallableRequest) => Promise<unknown>)(
                buildRequest("uidGhost", {
                    eventId: "does_not_exist",
                    latitude: LJ_LAT,
                    longitude: LJ_LNG,
                }),
            ),
        ).rejects.toMatchObject({ code: "not-found" });
        expect(mockUserUpdates).toHaveLength(0);
    });

    it("rejects inactive events with failed-precondition", async () => {
        mockUserGetResults.set("uidInactive", {});
        mockEventGetResults.set("club_monokel", {
            exists: true,
            data: () => ({
                name: "Klub Monokel",
                active: false,
                location: new MockGeoPoint(LJ_LAT, LJ_LNG),
                radiusMeters: 150,
                startsAt: futureTimestamp(-HOUR),
                endsAt: futureTimestamp(HOUR),
            }),
        });

        const { onEventModeActivate } = await import("../../src/modules/events/events.functions");
        await expect(
            (onEventModeActivate as unknown as (r: CallableRequest) => Promise<unknown>)(
                buildRequest("uidInactive", {
                    eventId: "club_monokel",
                    latitude: LJ_LAT,
                    longitude: LJ_LNG,
                }),
            ),
        ).rejects.toMatchObject({ code: "failed-precondition" });
        expect(mockUserUpdates).toHaveLength(0);
    });
});
