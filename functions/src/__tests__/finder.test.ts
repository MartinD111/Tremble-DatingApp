import { beforeAll, beforeEach, describe, expect, it, jest } from "@jest/globals";

const NOW_MS = Date.parse("2026-07-22T12:00:00.000Z");
const CALLER_UID = "userA";
const PARTNER_UID = "userB";
const MATCH_ID = "userA_userB";

let capturedOnCallOptions: unknown;
const mockOnCall = jest.fn((options: unknown, handler: unknown) => {
    capturedOnCallOptions = options;
    return handler;
});
const mockRequireAuth = jest.fn<() => string>();
const mockTimestampFromMillis = jest.fn((millis: number) => ({
    toDate: () => new Date(millis),
    toMillis: () => millis,
}));
const mockServerTimestamp = jest.fn(() => "SERVER_TIMESTAMP");
const mockDeleteField = jest.fn(() => "DELETE_FIELD");

type DocumentData = Record<string, unknown>;

let matchData: DocumentData;
let partnerData: DocumentData | undefined;
let matchExists: boolean;
const matchUpdate = jest.fn<(data: DocumentData) => Promise<void>>();
const callerSet = jest.fn<(data: DocumentData, options?: unknown) => Promise<void>>();
const callerDelete = jest.fn<() => Promise<void>>();
const partnerSet = jest.fn<(data: DocumentData, options?: unknown) => Promise<void>>();
const partnerDelete = jest.fn<() => Promise<void>>();

function snapshot(exists: boolean, data?: DocumentData) {
    return {
        exists,
        data: () => data,
    };
}

function finderRef(uid: string) {
    const isCaller = uid === CALLER_UID;
    return {
        id: uid,
        kind: "finder",
        get: jest.fn(async () => isCaller
            ? snapshot(false)
            : snapshot(partnerData !== undefined, partnerData)),
        set: isCaller ? callerSet : partnerSet,
        delete: isCaller ? callerDelete : partnerDelete,
    };
}

function matchRef() {
    return {
        id: MATCH_ID,
        kind: "match",
        get: jest.fn(async () => snapshot(matchExists, matchData)),
        update: matchUpdate,
        collection: jest.fn((name: string) => {
            if (name !== "finder") throw new Error(`Unexpected subcollection: ${name}`);
            return { doc: jest.fn((uid: string) => finderRef(uid)) };
        }),
    };
}

const mockDb = {
    collection: jest.fn((name: string) => {
        if (name !== "matches") throw new Error(`Unexpected collection: ${name}`);
        return { doc: jest.fn(() => matchRef()) };
    }),
    runTransaction: jest.fn(async (handler: (transaction: {
        get: (ref: { get: () => Promise<unknown> }) => Promise<unknown>;
        update: (ref: { update: (data: DocumentData) => Promise<void> }, data: DocumentData) => Promise<void>;
        set: (ref: { set: (data: DocumentData, options?: unknown) => Promise<void> }, data: DocumentData, options?: unknown) => Promise<void>;
        delete: (ref: { delete: () => Promise<void> }) => Promise<void>;
    }) => Promise<unknown>) => handler({
        get: (ref) => ref.get(),
        update: (ref, data) => ref.update(data),
        set: (ref, data, options) => ref.set(data, options),
        delete: (ref) => ref.delete(),
    })),
};

jest.mock("firebase-functions/v2/https", () => ({
    onCall: mockOnCall,
    HttpsError: class HttpsError extends Error {
        code: string;

        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    FieldValue: {
        serverTimestamp: mockServerTimestamp,
        delete: mockDeleteField,
    },
    Timestamp: {
        fromMillis: mockTimestampFromMillis,
    },
}));

jest.mock("../../src/middleware/authGuard", () => ({
    requireAuth: mockRequireAuth,
}));

jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: true,
}));

type FinderResponse = {
    partnerSharing: boolean;
    bearing?: number;
    distanceM?: number;
    reason?: string;
};

let invoke: (request: unknown) => Promise<FinderResponse>;

function request(overrides: DocumentData = {}) {
    return {
        auth: { uid: CALLER_UID, token: {} },
        data: {
            matchId: MATCH_ID,
            lat: 45.548,
            lng: 13.730,
            accuracy: 8,
            optIn: true,
            ...overrides,
        },
    };
}

function expectExactKeys(value: FinderResponse, keys: string[]) {
    expect(Object.keys(value).sort()).toEqual([...keys].sort());
    expect(value).not.toHaveProperty("lat");
    expect(value).not.toHaveProperty("lng");
    expect(value).not.toHaveProperty("accuracy");
    expect(value).not.toHaveProperty("updatedAt");
    expect(value).not.toHaveProperty("expireAt");
}

describe("updateFinderLocation", () => {
    beforeAll(async () => {
        const module = await import("../../src/modules/matches/finder.functions");
        invoke = module.updateFinderLocation as unknown as typeof invoke;
    });

    beforeEach(() => {
        jest.clearAllMocks();
        jest.useFakeTimers().setSystemTime(NOW_MS);
        mockRequireAuth.mockReturnValue(CALLER_UID);
        matchExists = true;
        matchData = {
            userIds: [CALLER_UID, PARTNER_UID],
            status: "pending",
            expiresAt: new Date(NOW_MS + 60_000),
            finderOptIn: { [PARTNER_UID]: true },
        };
        partnerData = {
            lat: 45.549,
            lng: 13.731,
            accuracy: 9,
            updatedAt: mockTimestampFromMillis(NOW_MS - 3_000),
            expireAt: mockTimestampFromMillis(NOW_MS + 117_000),
        };
        matchUpdate.mockResolvedValue(undefined);
        callerSet.mockResolvedValue(undefined);
        callerDelete.mockResolvedValue(undefined);
        partnerSet.mockResolvedValue(undefined);
        partnerDelete.mockResolvedValue(undefined);
    });

    it("enforces App Check on the callable", () => {
        expect(capturedOnCallOptions).toEqual(expect.objectContaining({
            enforceAppCheck: true,
            region: "europe-west1",
        }));
    });

    it("returns only rounded bearing and distance when both participants share fresh accurate locations", async () => {
        const result = await invoke(request());

        expect(result).toEqual({
            partnerSharing: true,
            bearing: expect.any(Number),
            distanceM: expect.any(Number),
        });
        expect(Number.isInteger(result.bearing)).toBe(true);
        expect(Number.isInteger(result.distanceM)).toBe(true);
        expectExactKeys(result, ["partnerSharing", "bearing", "distanceM"]);
        expect(matchUpdate).toHaveBeenCalledWith({ [`finderOptIn.${CALLER_UID}`]: true });
        expect(callerSet.mock.calls[0][0]).toEqual(expect.objectContaining({
            lat: 45.548,
            lng: 13.730,
            accuracy: 8,
            updatedAt: "SERVER_TIMESTAMP",
        }));
    });

    it("sets a two-minute TTL on the caller coordinate", async () => {
        await invoke(request());

        expect(mockTimestampFromMillis).toHaveBeenCalledWith(NOW_MS + 120_000);
        const stored = callerSet.mock.calls[0][0];
        const expireAt = stored.expireAt as { toMillis: () => number };
        expect(expireAt.toMillis()).toBe(NOW_MS + 120_000);
    });

    it("returns partner_not_opted with an exact safe response while retaining the caller update", async () => {
        matchData.finderOptIn = {};

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "partner_not_opted" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
        expect(callerSet).toHaveBeenCalledTimes(1);
    });

    it("returns partner_stale when the partner coordinate is older than ten seconds", async () => {
        partnerData = {
            ...partnerData,
            updatedAt: mockTimestampFromMillis(NOW_MS - 10_001),
        };

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "partner_stale" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
    });

    it("returns window_over for a found match without recreating finder data", async () => {
        matchData.status = "found";

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "window_over" });
        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("returns window_over for an expired match without recreating finder data", async () => {
        matchData.expiresAt = new Date(NOW_MS - 1);

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "window_over" });
        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("rechecks expiry when Firestore retries the transaction", async () => {
        matchData.expiresAt = new Date(NOW_MS + 1);
        mockDb.runTransaction.mockImplementationOnce(async (handler) => {
            await handler({
                get: (ref) => ref.get(),
                update: async () => undefined,
                set: async () => undefined,
                delete: async () => undefined,
            });
            jest.setSystemTime(NOW_MS + 2);
            return handler({
                get: (ref) => ref.get(),
                update: (ref, data) => ref.update(data),
                set: (ref, data, options) => ref.set(data, options),
                delete: (ref) => ref.delete(),
            });
        });

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "window_over" });
        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("rejects a non-participant and performs no writes", async () => {
        mockRequireAuth.mockReturnValue("intruder");

        await expect(invoke(request())).rejects.toMatchObject({ code: "permission-denied" });

        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerSet).not.toHaveBeenCalled();
        expect(callerDelete).not.toHaveBeenCalled();
    });

    it("revokes sharing by deleting the caller coordinate and opt-in flag", async () => {
        const result = await invoke(request({ optIn: false }));

        expect(result).toEqual({ partnerSharing: false });
        expectExactKeys(result, ["partnerSharing"]);
        expect(matchUpdate).toHaveBeenCalledWith({
            [`finderOptIn.${CALLER_UID}`]: "DELETE_FIELD",
        });
        expect(callerDelete).toHaveBeenCalledTimes(1);
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("allows an expired-window participant to revoke sharing", async () => {
        matchData.expiresAt = new Date(NOW_MS - 1);

        const result = await invoke(request({ optIn: false }));

        expect(result).toEqual({ partnerSharing: false });
        expect(matchUpdate).toHaveBeenCalledTimes(1);
        expect(callerDelete).toHaveBeenCalledTimes(1);
    });

    it("preserves opt-in but never stores a caller coordinate with accuracy over 30m", async () => {
        const result = await invoke(request({ accuracy: 30.01 }));

        expect(result).toEqual({ partnerSharing: false, reason: "poor_accuracy" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
        expect(matchUpdate).toHaveBeenCalledWith({ [`finderOptIn.${CALLER_UID}`]: true });
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("never computes a precise result from a partner coordinate with accuracy over 30m", async () => {
        partnerData = { ...partnerData, accuracy: 30.01 };

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "poor_accuracy" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
    });

    it("treats a partner coordinate exactly ten seconds old as fresh", async () => {
        partnerData = {
            ...partnerData,
            updatedAt: mockTimestampFromMillis(NOW_MS - 10_000),
        };

        const result = await invoke(request());

        expect(result.partnerSharing).toBe(true);
    });

    it("normalizes a rounded north-by-west bearing to the 0-359 range", async () => {
        partnerData = {
            ...partnerData,
            lat: 0.001,
            lng: -0.000005,
        };

        const result = await invoke(request({ lat: 0, lng: 0 }));

        expect(result).toMatchObject({ partnerSharing: true, bearing: 0 });
    });

    it.each([
        ["lat", 90.01],
        ["lng", -180.01],
        ["accuracy", -0.01],
        ["matchId", "matches/escape"],
    ])("rejects invalid %s input before reading Firestore", async (field, value) => {
        await expect(invoke(request({ [field]: value }))).rejects.toMatchObject({
            code: "invalid-argument",
        });

        expect(mockDb.runTransaction).not.toHaveBeenCalled();
    });
});
