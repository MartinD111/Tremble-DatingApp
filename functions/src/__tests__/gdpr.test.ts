/**
 * Tremble — GDPR Functions Unit Tests
 *
 * TDD: write tests first, expect RED before implementation.
 *
 * Mocks: firebase-admin/firestore, firebase-admin/auth,
 *        middleware/authGuard, middleware/rateLimit, @aws-sdk/client-s3
 */

import { describe, it, expect, jest, beforeEach } from "@jest/globals";

// ── Middleware mocks ──────────────────────────────────────────────────────

const TEST_UID = "gdpr-test-001";

jest.mock("../middleware/authGuard", () => ({
    requireAuth: jest.fn(() => TEST_UID),
}));

jest.mock("../middleware/rateLimit", () => ({
    checkRateLimit: jest.fn().mockImplementation(() => Promise.resolve()),
}));

// ── AWS S3 mock ───────────────────────────────────────────────────────────

jest.mock("@aws-sdk/client-s3", () => ({
    S3Client: jest.fn().mockImplementation(() => ({
        send: jest.fn().mockImplementation(() => Promise.resolve({ Contents: [], IsTruncated: false })),
    })),
    ListObjectsV2Command: jest.fn(),
    DeleteObjectsCommand: jest.fn(),
}));

// ── Config mock ───────────────────────────────────────────────────────────

jest.mock("../config/env", () => ({
    getConfig: jest.fn(() => ({
        r2: {
            endpoint: "https://example.r2.cloudflarestorage.com",
            accessKeyId: "test-key",
            secretAccessKey: "test-secret",
            bucketName: "test-bucket",
        },
    })),
}));

// ── Firebase Auth mock ────────────────────────────────────────────────────

const mockDeleteUser = jest.fn().mockImplementation(() => Promise.resolve());

jest.mock("firebase-admin/auth", () => ({
    getAuth: jest.fn(() => ({
        deleteUser: mockDeleteUser,
    })),
}));

// ── Firebase Functions mock ───────────────────────────────────────────────

jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, fn) => fn),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));

// ── Firestore mock helpers ────────────────────────────────────────────────

/** Returns a fake QuerySnapshot with N fake docs */
function fakeSnapshot(count: number) {
    const docs = Array.from({ length: count }, (_, i) => ({
        id: `doc-${i}`,
        ref: { id: `doc-${i}` },
        data: () => ({ uid: TEST_UID }),
    }));
    return { docs, empty: count === 0 };
}

/** Records every .collection(name) call and returns controlled snapshots */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function buildMockDb(collectionOverrides: Record<string, number> = {}): { mockDb: any; calledWith: string[]; batchCommitMock: jest.Mock; batchDeleteMock: jest.Mock } {
    const calledWith: string[] = [];
    const batchCommitMock = jest.fn().mockImplementation(() => Promise.resolve());
    const batchDeleteMock = jest.fn();

    const mockBatch = {
        delete: batchDeleteMock,
        update: jest.fn(),
        commit: batchCommitMock,
    };

    const mockDb = {
        collection: jest.fn((name: string) => {
            calledWith.push(name);
            const count = collectionOverrides[name] ?? 0;
            return {
                doc: jest.fn(() => ({
                    get: jest.fn().mockImplementation(() => Promise.resolve({ exists: true, data: () => ({}) })),
                    update: jest.fn().mockImplementation(() => Promise.resolve()),
                    set: jest.fn().mockImplementation(() => Promise.resolve()),
                    delete: jest.fn().mockImplementation(() => Promise.resolve()),
                    ref: { id: "gdpr-doc-ref" },
                })),
                add: jest.fn().mockImplementation(() => Promise.resolve({
                    id: "gdpr-doc-id",
                    update: jest.fn().mockImplementation(() => Promise.resolve()),
                })),
                where: jest.fn().mockReturnThis(),
                get: jest.fn().mockImplementation(() => Promise.resolve(fakeSnapshot(count))),
            };
        }),
        batch: jest.fn(() => mockBatch),
    };

    return { mockDb, calledWith, batchCommitMock, batchDeleteMock };
}

// ── Firestore module mock (set up before imports) ─────────────────────────

const firestoreMockState = {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    mockDb: null as any,
};

// Proxy: db.collection/batch always delegates to firestoreMockState.mockDb
// so module-level `const db = getFirestore()` still picks up per-test mocks.
jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => ({
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        collection: (...args: any[]) => firestoreMockState.mockDb?.collection(...args),
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        batch: (...args: any[]) => firestoreMockState.mockDb?.batch(...args),
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        runTransaction: (...args: any[]) => firestoreMockState.mockDb?.runTransaction?.(...args),
    })),
    FieldValue: {
        serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
        arrayUnion: jest.fn((...args: unknown[]) => args),
    },
    Timestamp: {
        fromDate: jest.fn((d: Date) => ({ _seconds: Math.floor(d.getTime() / 1000) })),
    },
    DocumentReference: jest.fn(),
}));

// ─────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────

describe("GDPR Functions", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    // ── Case 1: unauthenticated request rejected ──────────────────────────

    describe("Case 1 — unauthenticated request rejected", () => {
        it("deleteUserAccount rejects unauthenticated request", async () => {
            const { requireAuth } = await import("../middleware/authGuard");
            const HttpsErrorClass = (await import("firebase-functions/v2/https")).HttpsError;

            (requireAuth as jest.MockedFunction<typeof requireAuth>).mockImplementationOnce(() => {
                throw new HttpsErrorClass("unauthenticated", "Not authenticated");
            });

            const { mockDb } = buildMockDb();
            firestoreMockState.mockDb = mockDb;

            const { deleteUserAccount } = await import("../modules/gdpr/gdpr.functions");
            const handler = deleteUserAccount as unknown as (req: unknown) => Promise<unknown>;

            await expect(handler({ auth: null })).rejects.toMatchObject({ code: "unauthenticated" });
        });
    });

    // ── Case 2: deleteUserAccount queries all expected collections ────────

    describe("Case 2 — deleteUserAccount queries all 12 expected collections", () => {
        it("calls collection() for all required collections and deletes auth", async () => {
            const { mockDb, calledWith } = buildMockDb({
                waves: 1,
                proximity_events: 1,
                proximity_notifications: 1,
                matches: 1,
                rateLimits: 1,
                reports: 1,
                idempotencyKeys: 0,
            });
            firestoreMockState.mockDb = mockDb;

            const { deleteUserAccount } = await import("../modules/gdpr/gdpr.functions");
            const handler = deleteUserAccount as unknown as (req: unknown) => Promise<unknown>;

            await handler({ auth: { uid: TEST_UID } });

            // Must delete from all expected collections
            expect(calledWith).toContain("users");
            expect(calledWith).toContain("proximity");
            expect(calledWith).toContain("waves");
            expect(calledWith).toContain("proximity_events");
            expect(calledWith).toContain("proximity_notifications");
            expect(calledWith).toContain("idempotencyKeys");
            expect(calledWith).toContain("reports");
            expect(calledWith).toContain("matches");
            expect(calledWith).toContain("rateLimits");
            expect(calledWith).toContain("gdprRequests");

            // waves queried twice: fromUid + toUid
            expect(calledWith.filter((c) => c === "waves").length).toBeGreaterThanOrEqual(2);
            // matches queried twice: userA + userB
            expect(calledWith.filter((c) => c === "matches").length).toBeGreaterThanOrEqual(2);

            // Auth account deleted
            expect(mockDeleteUser).toHaveBeenCalledWith(TEST_UID);
        });
    });

    // ── Case 3: batch pagination — 501 docs triggers two commits ─────────

    describe("Case 3 — batch pagination: 501 documents triggers second commit", () => {
        it("commits twice when waves fromUid returns 501 docs", async () => {
            // Build 501 fake wave docs
            const waveDocs = Array.from({ length: 501 }, (_, i) => ({
                id: `wave-${i}`,
                ref: { id: `wave-${i}` },
                data: () => ({}),
            }));

            const batchCommitMock = jest.fn().mockImplementation(() => Promise.resolve());
            const batchDeleteMock = jest.fn();

            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const mockDb: any = {
                collection: jest.fn((name: string) => ({
                    doc: jest.fn(() => ({
                        get: jest.fn().mockImplementation(() => Promise.resolve({ exists: true, data: () => ({}) })),
                        update: jest.fn().mockImplementation(() => Promise.resolve()),
                        set: jest.fn().mockImplementation(() => Promise.resolve()),
                    })),
                    add: jest.fn().mockImplementation(() => Promise.resolve({
                        id: "gdpr-ref",
                        update: jest.fn().mockImplementation(() => Promise.resolve()),
                    })),
                    where: jest.fn().mockReturnThis(),
                    get: jest.fn().mockImplementation(async () => {
                        // Only waves fromUid returns 501 docs
                        if (name === "waves") {
                            return { docs: waveDocs, empty: false };
                        }
                        return { docs: [], empty: true };
                    }),
                })),
                batch: jest.fn(() => ({ delete: batchDeleteMock, commit: batchCommitMock })),
            };

            firestoreMockState.mockDb = mockDb;

            const { deleteUserAccount } = await import("../modules/gdpr/gdpr.functions");
            const handler = deleteUserAccount as unknown as (req: unknown) => Promise<unknown>;

            await handler({ auth: { uid: TEST_UID } });

            // 501 docs in waves alone → at least 2 batch commits (500 + 1)
            expect(batchCommitMock.mock.calls.length).toBeGreaterThanOrEqual(2);
        });
    });

    // ── Case 4: exportUserData returns wavesSent/wavesReceived ───────────

    describe("Case 4 — exportUserData returns wavesSent/wavesReceived, not greetings keys", () => {
        it("returns wavesSent and wavesReceived, not greetingsSent or greetingsReceived", async () => {
            const sentDocs = [
                { id: "w1", data: () => ({ fromUid: TEST_UID, toUid: "other-1" }) },
                { id: "w2", data: () => ({ fromUid: TEST_UID, toUid: "other-2" }) },
            ];
            const receivedDocs = [
                { id: "w3", data: () => ({ fromUid: "other-3", toUid: TEST_UID }) },
            ];

            let waveCallCount = 0;
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const mockDb: any = {
                collection: jest.fn((name: string) => ({
                    doc: jest.fn(() => ({
                        get: jest.fn().mockImplementation(() => Promise.resolve({ exists: true, data: () => ({ displayName: "Test" }) })),
                        update: jest.fn().mockImplementation(() => Promise.resolve()),
                    })),
                    add: jest.fn().mockImplementation(() => Promise.resolve({ id: "gdpr-ref", update: jest.fn() })),
                    where: jest.fn().mockReturnThis(),
                    get: jest.fn().mockImplementation(async () => {
                        if (name === "waves") {
                            waveCallCount++;
                            if (waveCallCount === 1) return { docs: sentDocs, empty: false };
                            return { docs: receivedDocs, empty: false };
                        }
                        if (name === "matches") return { docs: [], empty: true };
                        return { docs: [], empty: true };
                    }),
                })),
                batch: jest.fn(() => ({ delete: jest.fn(), commit: jest.fn().mockImplementation(() => Promise.resolve()) })),
            };

            firestoreMockState.mockDb = mockDb;

            const { exportUserData } = await import("../modules/gdpr/gdpr.functions");
            const handler = exportUserData as unknown as (req: unknown) => Promise<{ data: Record<string, unknown> }>;

            const result = await handler({ auth: { uid: TEST_UID } });

            expect(result.data).toHaveProperty("wavesSent");
            expect(result.data).toHaveProperty("wavesReceived");
            expect((result.data.wavesSent as unknown[]).length).toBe(2);
            expect((result.data.wavesReceived as unknown[]).length).toBe(1);

            expect(result.data).not.toHaveProperty("greetingsSent");
            expect(result.data).not.toHaveProperty("greetingsReceived");
        });
    });
});
