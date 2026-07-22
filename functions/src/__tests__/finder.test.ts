import { beforeAll, beforeEach, describe, expect, it, jest } from "@jest/globals";

const NOW_MS = Date.parse("2026-07-22T12:00:00.000Z");
const CALLER_UID = "userA";
const PARTNER_UID = "userB";
const MATCH_ID = "userA_userB";
const WINDOW_ID = "wave-current";

let capturedOnCallOptions: unknown;
const mockOnCall = jest.fn((options: unknown, handler: unknown) => {
    capturedOnCallOptions = options;
    return handler;
});
const mockRequireAuth = jest.fn<() => string>();
const mockCheckRateLimit = jest.fn<() => Promise<void>>();
const mockTimestampFromMillis = jest.fn((millis: number) => ({
    toDate: () => new Date(millis),
    toMillis: () => millis,
}));
const mockServerTimestamp = jest.fn(() => "SERVER_TIMESTAMP");
const mockDeleteField = jest.fn(() => "DELETE_FIELD");

type DocumentData = Record<string, unknown>;

let matchData: DocumentData;
let callerData: DocumentData | undefined;
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
            ? snapshot(callerData !== undefined, callerData)
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

jest.mock("../../src/middleware/rateLimit", () => ({
    checkRateLimit: mockCheckRateLimit,
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
            windowId: WINDOW_ID,
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
        mockCheckRateLimit.mockResolvedValue(undefined);
        matchExists = true;
        matchData = {
            userIds: [CALLER_UID, PARTNER_UID],
            notificationOwnerWaveId: WINDOW_ID,
            status: "pending",
            expiresAt: new Date(NOW_MS + 60_000),
            finderOptIn: { [PARTNER_UID]: true },
        };
        callerData = undefined;
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

    it("windowId input contract rejects an absent windowId", async () => {
        const completeInput = request();
        const data: DocumentData = { ...completeInput.data };
        delete data.windowId;
        const input = { ...completeInput, data };

        await expect(invoke(input)).rejects.toMatchObject({ code: "invalid-argument" });

        expect(mockDb.runTransaction).not.toHaveBeenCalled();
    });

    it.each([
        ["empty", ""],
        ["path-like", "old/window"],
        ["overlong", "w".repeat(129)],
    ])("windowId input contract rejects %s values", async (_label, windowId) => {
        await expect(invoke(request({ windowId }))).rejects.toMatchObject({
            code: "invalid-argument",
        });

        expect(mockDb.runTransaction).not.toHaveBeenCalled();
    });

    it("windowId input contract accepts the current Firestore-safe windowId", async () => {
        const result = await invoke(request());

        expect(result.partnerSharing).toBe(true);
    });

    it("window identity rejects a delayed request after deterministic restart", async () => {
        matchData.notificationOwnerWaveId = "wave-restarted";

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "window_over" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("window identity is rechecked when a transaction retry observes a new window", async () => {
        mockDb.runTransaction.mockImplementationOnce(async (handler) => {
            await handler({
                get: (ref) => ref.get(),
                update: async () => undefined,
                set: async () => undefined,
                delete: async () => undefined,
            });
            matchData.notificationOwnerWaveId = "wave-restarted";
            return handler({
                get: (ref) => ref.get(),
                update: (ref, data) => ref.update(data),
                set: (ref, data, options) => ref.set(data, options),
                delete: (ref) => ref.delete(),
            });
        });

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "window_over" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("rate-limits the caller with a static cadence-aware endpoint before Firestore", async () => {
        await invoke(request());

        expect(mockCheckRateLimit).toHaveBeenCalledWith(
            CALLER_UID,
            "updateFinderLocation",
            { maxRequests: 30, windowMs: 60_000 },
        );
        expect(mockCheckRateLimit.mock.invocationCallOrder[0]).toBeLessThan(
            mockDb.runTransaction.mock.invocationCallOrder[0],
        );
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

    it("fails closed for a malformed match expiry", async () => {
        matchData.expiresAt = new Date(Number.NaN);

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

    it("allows a found-match participant to revoke sharing", async () => {
        matchData.status = "found";

        const result = await invoke(request({ optIn: false }));

        expect(result).toEqual({ partnerSharing: false });
        expect(matchUpdate).toHaveBeenCalledWith({
            [`finderOptIn.${CALLER_UID}`]: "DELETE_FIELD",
        });
        expect(callerDelete).toHaveBeenCalledTimes(1);
    });

    it.each(["pending", "found", "expired"])(
        "revocation bypasses an unavailable polling limiter for a %s window",
        async (windowState) => {
            mockCheckRateLimit.mockRejectedValue(Object.assign(
                new Error("limiter unavailable"),
                { code: "resource-exhausted" },
            ));
            if (windowState === "found") matchData.status = "found";
            if (windowState === "expired") matchData.expiresAt = new Date(NOW_MS - 1);

            const result = await invoke(request({ optIn: false }));

            expect(result).toEqual({ partnerSharing: false });
            expectExactKeys(result, ["partnerSharing"]);
            expect(mockCheckRateLimit).not.toHaveBeenCalled();
            expect(matchUpdate).toHaveBeenCalledWith({
                [`finderOptIn.${CALLER_UID}`]: "DELETE_FIELD",
            });
            expect(callerDelete).toHaveBeenCalledTimes(1);
        },
    );

    it("revocation still rejects a nonparticipant when the polling limiter is unavailable", async () => {
        mockRequireAuth.mockReturnValue("intruder");
        mockCheckRateLimit.mockRejectedValue(Object.assign(
            new Error("limiter unavailable"),
            { code: "resource-exhausted" },
        ));

        await expect(invoke(request({ optIn: false }))).rejects.toMatchObject({
            code: "permission-denied",
        });

        expect(mockCheckRateLimit).not.toHaveBeenCalled();
        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerDelete).not.toHaveBeenCalled();
    });

    it("revocation validates windowId before cleanup", async () => {
        await expect(invoke(request({ optIn: false, windowId: "" }))).rejects.toMatchObject({
            code: "invalid-argument",
        });

        expect(matchUpdate).not.toHaveBeenCalled();
        expect(callerDelete).not.toHaveBeenCalled();
    });

    it("preserves opt-in but never stores a caller coordinate with accuracy over 30m", async () => {
        const result = await invoke(request({ accuracy: 30.01 }));

        expect(result).toEqual({ partnerSharing: false, reason: "poor_accuracy" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
        expect(matchUpdate).toHaveBeenCalledWith({ [`finderOptIn.${CALLER_UID}`]: true });
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("poor GPS deletes a prior fresh caller coordinate while preserving current-window opt-in", async () => {
        callerData = {
            lat: 45.548,
            lng: 13.730,
            accuracy: 5,
            updatedAt: mockTimestampFromMillis(NOW_MS - 1_000),
            expireAt: mockTimestampFromMillis(NOW_MS + 119_000),
        };

        const result = await invoke(request({ accuracy: 30.01 }));

        expect(result).toEqual({ partnerSharing: false, reason: "poor_accuracy" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
        expect(matchUpdate).toHaveBeenCalledWith({ [`finderOptIn.${CALLER_UID}`]: true });
        expect(callerDelete).toHaveBeenCalledTimes(1);
        expect(callerSet).not.toHaveBeenCalled();
    });

    it("poor GPS reciprocal fallback returns partner_stale when the counterpart record is absent", async () => {
        partnerData = undefined;

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "partner_stale" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
        expect(result).not.toHaveProperty("bearing");
        expect(result).not.toHaveProperty("distanceM");
    });

    it("never computes a precise result from a partner coordinate with accuracy over 30m", async () => {
        partnerData = { ...partnerData, accuracy: 30.01 };

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "poor_accuracy" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
    });

    it.each([
        ["negative", -1],
        ["NaN", Number.NaN],
        ["negative infinity", Number.NEGATIVE_INFINITY],
        ["malformed", "unknown"],
    ])("fails closed for %s partner accuracy", async (_label, accuracy) => {
        partnerData = { ...partnerData, accuracy };

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

    it("rejects a future-dated partner coordinate as stale", async () => {
        partnerData = {
            ...partnerData,
            updatedAt: mockTimestampFromMillis(NOW_MS + 1),
        };

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "partner_stale" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
    });

    it("rejects a malformed partner timestamp as stale", async () => {
        partnerData = {
            ...partnerData,
            updatedAt: new Date(Number.NaN),
        };

        const result = await invoke(request());

        expect(result).toEqual({ partnerSharing: false, reason: "partner_stale" });
        expectExactKeys(result, ["partnerSharing", "reason"]);
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

    it("rejects positive Infinity caller accuracy before rate limiting or Firestore access", async () => {
        await expect(invoke(request({ accuracy: Number.POSITIVE_INFINITY }))).rejects.toMatchObject({
            code: "invalid-argument",
        });

        expect(mockCheckRateLimit).not.toHaveBeenCalled();
        expect(mockDb.collection).not.toHaveBeenCalled();
        expect(mockDb.runTransaction).not.toHaveBeenCalled();
    });
});
