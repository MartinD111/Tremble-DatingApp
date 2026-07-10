/**
 * Tremble — Weekend Pass (ToS §7) enforcement tests
 *
 * The Weekend Getaway window is anchored to Europe/Ljubljana:
 * Friday 19:00 → Sunday 19:00 local time.
 *
 * Boundary tests are asserted at the exact minute to catch off-by-one
 * timezone bugs (UTC-naive server time being the most common failure).
 */

import { describe, it, expect, jest, beforeEach, afterEach } from "@jest/globals";
import { DateTime } from "luxon";

// A UTC instant that renders as a given wall-clock time in Europe/Ljubljana.
function ljubljanaInstant(iso: string): Date {
    const dt = DateTime.fromISO(iso, { zone: "Europe/Ljubljana" });
    if (!dt.isValid) throw new Error(`Invalid Ljubljana time: ${iso}`);
    return dt.toJSDate();
}

describe("weekend-window (ToS §7 Fri 19:00 → Sun 19:00 Europe/Ljubljana)", () => {
    afterEach(() => {
        jest.useRealTimers();
    });

    it("returns false one minute before Friday 19:00 Ljubljana", async () => {
        jest.useFakeTimers();
        jest.setSystemTime(ljubljanaInstant("2026-07-10T18:59:00"));
        const { isInWeekendWindow } = await import("../../src/utils/weekend-window");
        expect(isInWeekendWindow("Europe/Ljubljana")).toBe(false);
    });

    it("returns true at exactly Friday 19:00 Ljubljana", async () => {
        jest.useFakeTimers();
        jest.setSystemTime(ljubljanaInstant("2026-07-10T19:00:00"));
        const { isInWeekendWindow } = await import("../../src/utils/weekend-window");
        expect(isInWeekendWindow("Europe/Ljubljana")).toBe(true);
    });

    it("returns true one minute before Sunday 19:00 Ljubljana", async () => {
        jest.useFakeTimers();
        jest.setSystemTime(ljubljanaInstant("2026-07-12T18:59:00"));
        const { isInWeekendWindow } = await import("../../src/utils/weekend-window");
        expect(isInWeekendWindow("Europe/Ljubljana")).toBe(true);
    });

    it("returns false at exactly Sunday 19:00 Ljubljana", async () => {
        jest.useFakeTimers();
        jest.setSystemTime(ljubljanaInstant("2026-07-12T19:00:00"));
        const { isInWeekendWindow } = await import("../../src/utils/weekend-window");
        expect(isInWeekendWindow("Europe/Ljubljana")).toBe(false);
    });

    it("mid-window purchase gets partial window: activatesAt is now, expiresAt is Sun 19:00 (not next Fri)", async () => {
        jest.useFakeTimers();
        const saturdayNoon = ljubljanaInstant("2026-07-11T12:00:00");
        jest.setSystemTime(saturdayNoon);

        const { getNextWeekendWindow } = await import("../../src/utils/weekend-window");
        const w = getNextWeekendWindow("Europe/Ljubljana");

        expect(w.activatesAt.getTime()).toBe(saturdayNoon.getTime());
        expect(w.expiresAt.getTime()).toBe(ljubljanaInstant("2026-07-12T19:00:00").getTime());

        // Not a full window granted to a late purchase.
        const durationHours = (w.expiresAt.getTime() - w.activatesAt.getTime()) / 3_600_000;
        expect(durationHours).toBeLessThan(48);
        expect(durationHours).toBeCloseTo(31, 0);
    });

    it("outside-window purchase schedules the next Fri 19:00 → Sun 19:00 window", async () => {
        jest.useFakeTimers();
        jest.setSystemTime(ljubljanaInstant("2026-07-07T10:00:00")); // Tuesday
        const { getNextWeekendWindow } = await import("../../src/utils/weekend-window");
        const w = getNextWeekendWindow("Europe/Ljubljana");
        expect(w.activatesAt.getTime()).toBe(ljubljanaInstant("2026-07-10T19:00:00").getTime());
        expect(w.expiresAt.getTime()).toBe(ljubljanaInstant("2026-07-12T19:00:00").getTime());
    });

    it("timezone correctness: same UTC instant is in-window for Ljubljana but not for UTC-naive server", async () => {
        jest.useFakeTimers();
        // Friday 19:30 in Ljubljana (summer = UTC+2) = 17:30 UTC.
        // A UTC-naive check would think this is Friday 17:30 and be outside the window.
        jest.setSystemTime(ljubljanaInstant("2026-07-10T19:30:00"));
        const { isInWeekendWindow } = await import("../../src/utils/weekend-window");
        expect(isInWeekendWindow("Europe/Ljubljana")).toBe(true);
        expect(isInWeekendWindow("UTC")).toBe(false);
    });
});

// ── processWeekendPasses scheduler ───────────────────────────────────────

const mockBatchCommit = jest.fn<() => Promise<void>>();
const mockBatchUpdate = jest.fn();
const mockPendingDocs: Array<{ ref: unknown }> = [];
const mockActiveDocs: Array<{ ref: unknown }> = [];
let capturedException: unknown = null;

const mockDb = {
    collection: jest.fn((name: string) => {
        if (name !== "users") throw new Error(`Unexpected collection: ${name}`);
        const query = {
            _isPending: false,
            _isActive: false,
            where: jest.fn(function (this: { _isPending: boolean; _isActive: boolean }, field: string, _op: string, value: unknown) {
                if (field === "weekendPassStatus" && value === "pending") this._isPending = true;
                if (field === "weekendPassStatus" && value === "active") this._isActive = true;
                return this;
            }),
            get: jest.fn(async function (this: { _isPending: boolean; _isActive: boolean }) {
                const docs = this._isPending
                    ? mockPendingDocs
                    : this._isActive
                        ? mockActiveDocs
                        : [];
                return { docs, size: docs.length };
            }),
        };
        return query;
    }),
    batch: jest.fn(() => ({
        update: mockBatchUpdate,
        commit: mockBatchCommit,
    })),
};

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    Timestamp: {
        now: jest.fn(() => ({ toDate: () => new Date() })),
        fromDate: jest.fn((date: Date) => ({ toDate: () => date })),
    },
}));
jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, fn) => fn),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) { super(message); this.code = code; }
    },
}));
jest.mock("firebase-functions/v2/scheduler", () => ({
    onSchedule: jest.fn((_, fn) => fn),
}));
jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: false,
    SENTRY_DSN: "",
    TREMBLE_ENV: "test",
}));
jest.mock("../../src/core/sentry", () => ({
    Sentry: {
        captureException: jest.fn((err: unknown) => { capturedException = err; }),
        flush: jest.fn(async () => true),
    },
}));

describe("processWeekendPasses scheduler", () => {
    beforeEach(() => {
        mockBatchCommit.mockReset();
        mockBatchUpdate.mockReset();
        mockPendingDocs.length = 0;
        mockActiveDocs.length = 0;
        mockBatchCommit.mockResolvedValue(undefined);
        capturedException = null;
    });

    it("activates pending users whose activation instant has passed", async () => {
        const pendingRef1 = { id: "pending1" };
        const pendingRef2 = { id: "pending2" };
        mockPendingDocs.push({ ref: pendingRef1 }, { ref: pendingRef2 });

        const { processWeekendPasses } = await import("../../src/modules/subscriptions/subscriptions.functions");
        await (processWeekendPasses as unknown as (event: unknown) => Promise<void>)({});

        expect(mockBatchUpdate).toHaveBeenCalledWith(pendingRef1, { weekendPassStatus: "active" });
        expect(mockBatchUpdate).toHaveBeenCalledWith(pendingRef2, { weekendPassStatus: "active" });
    });

    it("revokes active users whose expiry has passed by clearing the entitlement fields", async () => {
        const activeRef = { id: "active1" };
        mockActiveDocs.push({ ref: activeRef });

        const { processWeekendPasses } = await import("../../src/modules/subscriptions/subscriptions.functions");
        await (processWeekendPasses as unknown as (event: unknown) => Promise<void>)({});

        expect(mockBatchUpdate).toHaveBeenCalledWith(activeRef, {
            weekendPassStatus: null,
            weekendPassActivatesAt: null,
            weekendPassExpiresAt: null,
        });
    });

    it("captures exceptions with Sentry and rethrows so the scheduler retries", async () => {
        mockBatchCommit.mockRejectedValueOnce(new Error("firestore boom"));
        mockPendingDocs.push({ ref: { id: "p1" } });

        const { processWeekendPasses } = await import("../../src/modules/subscriptions/subscriptions.functions");

        await expect(
            (processWeekendPasses as unknown as (event: unknown) => Promise<void>)({})
        ).rejects.toThrow("firestore boom");

        expect(capturedException).toBeInstanceOf(Error);
        expect((capturedException as Error).message).toBe("firestore boom");
    });
});
