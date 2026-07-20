/**
 * Tremble — Safety Functions Unit Tests
 *
 * Covers getBlockedUsers, the callable that replaces the client's forbidden
 * direct `/users/{id}` reads on the Blocked Users screen (BUG-BLOCKED-USERS-LIST).
 * Firestore rules allow a client to read only its own user doc
 * (`firestore.rules` — `allow read: if isSelf(userId)`), so listing OTHER
 * users the caller has blocked must go through an Admin-SDK callable.
 */

import { describe, it, expect, jest, beforeEach } from "@jest/globals";

const mockDb = {
    collection: jest.fn(),
    batch: jest.fn(),
    getAll: jest.fn<(...refs: unknown[]) => Promise<unknown[]>>(),
};

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    FieldValue: {
        arrayUnion: jest.fn((...v: unknown[]) => ({ arrayUnion: v })),
        arrayRemove: jest.fn((...v: unknown[]) => ({ arrayRemove: v })),
    },
    Timestamp: { now: jest.fn(() => "NOW") },
}));

jest.mock("firebase-admin/auth", () => ({
    getAuth: jest.fn(() => ({ listUsers: jest.fn() })),
}));

jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_: unknown, handler: unknown) => handler),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));

jest.mock("firebase-functions/v2/firestore", () => ({
    onDocumentCreated: jest.fn((_: unknown, handler: unknown) => handler),
}));

jest.mock("../../src/middleware/authGuard", () => ({
    requireAuth: jest.fn(),
}));

jest.mock("../../src/middleware/rateLimit", () => ({
    checkRateLimit: jest.fn(),
}));

jest.mock("../../src/middleware/validate", () => ({
    validateRequest: jest.fn(),
}));

jest.mock("../../src/modules/email/email.functions", () => ({
    sendAdminReportAlert: jest.fn(),
}));

jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: false,
}));

type CallableFn = (request: unknown) => Promise<unknown>;

describe("getBlockedUsers", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    async function loadCallable() {
        const authGuard = await import("../../src/middleware/authGuard");
        const rateLimit = await import("../../src/middleware/rateLimit");
        const mod = await import("../../src/modules/safety/safety.functions");
        return {
            getBlockedUsers: mod.getBlockedUsers as unknown as CallableFn,
            requireAuth: jest.mocked(authGuard.requireAuth),
            checkRateLimit: jest.mocked(rateLimit.checkRateLimit),
        };
    }

    function stubUserDoc(blockedUserIds: string[] | undefined, exists = true) {
        const selfGet = jest.fn(async () => ({
            exists,
            data: () => (blockedUserIds === undefined ? {} : { blockedUserIds }),
        }));
        mockDb.collection.mockImplementation((name: unknown) => {
            if (name === "users") {
                return {
                    doc: (id: unknown) =>
                        id === "callerUid" ? { get: selfGet } : { path: `users/${String(id)}` },
                };
            }
            throw new Error(`Unexpected collection: ${String(name)}`);
        });
        return selfGet;
    }

    it("returns an empty list when the caller has no blockedUserIds", async () => {
        const { getBlockedUsers, requireAuth, checkRateLimit } = await loadCallable();
        requireAuth.mockReturnValue("callerUid");
        checkRateLimit.mockResolvedValue(undefined);
        stubUserDoc([]);

        await expect(
            getBlockedUsers({ auth: { uid: "callerUid" }, data: {} }),
        ).resolves.toEqual({ blockedUsers: [] });
        expect(mockDb.getAll).not.toHaveBeenCalled();
    });

    it("returns an empty list when the caller doc is missing", async () => {
        const { getBlockedUsers, requireAuth, checkRateLimit } = await loadCallable();
        requireAuth.mockReturnValue("callerUid");
        checkRateLimit.mockResolvedValue(undefined);
        stubUserDoc(undefined, false);

        await expect(
            getBlockedUsers({ auth: { uid: "callerUid" }, data: {} }),
        ).resolves.toEqual({ blockedUsers: [] });
    });

    it("batch-reads blocked user docs via the Admin SDK and maps id/name/imageUrl", async () => {
        const { getBlockedUsers, requireAuth, checkRateLimit } = await loadCallable();
        requireAuth.mockReturnValue("callerUid");
        checkRateLimit.mockResolvedValue(undefined);
        stubUserDoc(["blockedA", "blockedB", "goneC"]);

        mockDb.getAll.mockResolvedValue([
            {
                id: "blockedA",
                exists: true,
                data: () => ({ name: "Martin", photoUrls: ["https://cdn.test/m.jpg", "x"] }),
            },
            {
                id: "blockedB",
                exists: true,
                data: () => ({ name: "Nika", photoUrls: [] }),
            },
            { id: "goneC", exists: false, data: () => undefined },
        ]);

        await expect(
            getBlockedUsers({ auth: { uid: "callerUid" }, data: {} }),
        ).resolves.toEqual({
            blockedUsers: [
                { id: "blockedA", name: "Martin", imageUrl: "https://cdn.test/m.jpg" },
                { id: "blockedB", name: "Nika", imageUrl: null },
            ],
        });

        // Reads happen through the Admin SDK getAll (bypasses the self-only
        // Firestore read rule) against refs for each blocked id.
        expect(mockDb.getAll).toHaveBeenCalledWith(
            expect.objectContaining({ path: "users/blockedA" }),
            expect.objectContaining({ path: "users/blockedB" }),
            expect.objectContaining({ path: "users/goneC" }),
        );
    });

    it("falls back to 'Unknown User' when a blocked doc has no name", async () => {
        const { getBlockedUsers, requireAuth, checkRateLimit } = await loadCallable();
        requireAuth.mockReturnValue("callerUid");
        checkRateLimit.mockResolvedValue(undefined);
        stubUserDoc(["blockedA"]);
        mockDb.getAll.mockResolvedValue([
            { id: "blockedA", exists: true, data: () => ({ photoUrls: ["https://cdn.test/a.jpg"] }) },
        ]);

        await expect(
            getBlockedUsers({ auth: { uid: "callerUid" }, data: {} }),
        ).resolves.toEqual({
            blockedUsers: [
                { id: "blockedA", name: "Unknown User", imageUrl: "https://cdn.test/a.jpg" },
            ],
        });
    });
});
