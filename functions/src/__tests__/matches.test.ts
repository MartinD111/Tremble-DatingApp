/**
 * Tremble — Match Functions Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

const mockDb = {
    collection: jest.fn(),
    batch: jest.fn(),
    getAll: jest.fn<(...refs: unknown[]) => Promise<unknown[]>>(),
    runTransaction: jest.fn(),
};

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => mockDb),
    FieldValue: {
        increment: jest.fn((value: number) => ({ increment: value })),
        serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
    },
}));

jest.mock("firebase-admin/messaging", () => ({
    getMessaging: jest.fn(() => ({
        send: jest.fn(),
    })),
}));

jest.mock("firebase-functions/v2/firestore", () => ({
    onDocumentCreated: jest.fn((_, handler) => handler),
}));

jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, handler) => handler),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));

jest.mock("../../src/middleware/authGuard", () => ({
    requireAuth: jest.fn(),
    requireAdmin: jest.fn(),
    assertNotBanned: jest.fn(),
}));

jest.mock("../../src/middleware/rateLimit", () => ({
    checkRateLimit: jest.fn(),
}));

jest.mock("../../src/middleware/validate", () => ({
    assertValidDocumentId: jest.fn(),
}));

jest.mock("../../src/modules/email/email.functions", () => ({
    sendMatchNotificationEmail: jest.fn(),
}));

jest.mock("../../src/core/redis", () => ({
    getRedis: jest.fn(),
    waveDedupKey: jest.fn(),
    WAVE_DEDUP_SECS: 300,
}));

jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: false,
}));

describe("Matches Module", () => {
    describe("getMatches", () => {
        it("uses the lower read endpoint rate limit", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const { getMatches } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("callerUid");
            jest.mocked(rateLimit.checkRateLimit).mockRejectedValue(new Error("rate limit stop"));

            const callableGetMatches = getMatches as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableGetMatches({
                auth: { uid: "callerUid", token: {} },
                data: {},
            })).rejects.toThrow("rate limit stop");

            expect(rateLimit.checkRateLimit).toHaveBeenCalledWith(
                "callerUid",
                "getMatches",
                { maxRequests: 30, windowMs: 60000 }
            );
        });

        it("batches partner profile reads with getAll while preserving match filtering and shape", async () => {
            jest.clearAllMocks();
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const { getMatches } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("callerUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);

            const matchedAt = {
                toDate: () => new Date("2026-06-14T08:30:00.000Z"),
            };
            const matchDocs = [
                {
                    data: () => ({
                        userA: "callerUid",
                        userB: "partnerUid",
                        matchType: "event",
                        matchContext: { eventId: "event-1" },
                        createdAt: matchedAt,
                    }),
                },
                {
                    data: () => ({
                        userA: "callerUid",
                        userB: "blockedUid",
                        createdAt: matchedAt,
                    }),
                },
                {
                    data: () => ({
                        userA: "missingUid",
                        userB: "callerUid",
                        createdAt: null,
                    }),
                },
            ];
            const partnerRef = { path: "users/partnerUid" };
            const blockedRef = { path: "users/blockedUid" };
            const missingRef = { path: "users/missingUid" };
            const partnerDoc = {
                exists: true,
                data: () => ({
                    name: "Nika",
                    age: 29,
                    photoUrls: ["https://example.test/nika.jpg"],
                    hobbies: ["running"],
                    lookingFor: ["dates"],
                    isTraveler: true,
                }),
            };
            const missingDoc = {
                exists: false,
                data: () => undefined,
            };
            const partnerGet = jest.fn(async () => partnerDoc);
            const missingGet = jest.fn(async () => missingDoc);

            const docMock = jest.fn((docId: unknown) => {
                if (docId === "callerUid") {
                    return {
                        get: jest.fn(async () => ({
                            data: () => ({ blockedUserIds: ["blockedUid"] }),
                        })),
                    };
                }
                if (docId === "partnerUid") {
                    return { ...partnerRef, get: partnerGet };
                }
                if (docId === "blockedUid") {
                    return blockedRef;
                }
                if (docId === "missingUid") {
                    return { ...missingRef, get: missingGet };
                }
                throw new Error(`Unexpected user doc: ${String(docId)}`);
            });

            const matchesGet = jest.fn(async () => ({ docs: matchDocs }));
            mockDb.collection.mockImplementation((collectionName: unknown) => {
                if (collectionName === "users") {
                    return { doc: docMock };
                }
                if (collectionName === "matches") {
                    return {
                        where: jest.fn(() => ({
                            orderBy: jest.fn(() => ({
                                limit: jest.fn(() => ({
                                    get: matchesGet,
                                })),
                            })),
                        })),
                    };
                }
                throw new Error(`Unexpected collection: ${collectionName}`);
            });
            mockDb.getAll.mockResolvedValue([partnerDoc, missingDoc]);

            const callableGetMatches = getMatches as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableGetMatches({
                auth: { uid: "callerUid", token: {} },
                data: {},
            })).resolves.toEqual({
                matches: [
                    {
                        id: "partnerUid",
                        name: "Nika",
                        age: 29,
                        photoUrls: ["https://example.test/nika.jpg"],
                        hobbies: ["running"],
                        lookingFor: ["dates"],
                        matchType: "event",
                        matchContext: { eventId: "event-1" },
                        matchedAt: "2026-06-14T08:30:00.000Z",
                        isTraveler: true,
                    },
                ],
            });

            expect(mockDb.getAll).toHaveBeenCalledWith(
                expect.objectContaining(partnerRef),
                expect.objectContaining(missingRef)
            );
            expect(partnerGet).not.toHaveBeenCalled();
            expect(missingGet).not.toHaveBeenCalled();
            expect(docMock).not.toHaveBeenCalledWith("blockedUid");
        });
    });

    describe("sendWave", () => {
        it("rejects with a generic permission error when the target has blocked the sender", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const rateLimit = await import("../../src/middleware/rateLimit");
            const validate = await import("../../src/middleware/validate");
            const { sendWave } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("senderUid");
            jest.mocked(authGuard.assertNotBanned).mockImplementation(() => undefined);
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("targetUid");
            jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);

            const getMock = jest.fn<() => Promise<{
                exists: boolean;
                data: () => Record<string, unknown>;
            }>>()
                .mockResolvedValueOnce({
                    exists: true,
                    data: () => ({ isBanned: false }),
                })
                .mockResolvedValueOnce({
                    exists: true,
                    data: () => ({ blockedUserIds: ["senderUid"] }),
                });
            const docMock = jest.fn(() => ({ get: getMock }));
            const addMock = jest.fn();

            mockDb.collection.mockImplementation((collectionName: unknown) => {
                if (collectionName === "users") {
                    return { doc: docMock };
                }
                if (collectionName === "waves") {
                    return { add: addMock };
                }
                throw new Error(`Unexpected collection: ${collectionName}`);
            });

            const callableSendWave = sendWave as unknown as (request: unknown) => Promise<unknown>;

            await expect(callableSendWave({
                auth: { uid: "senderUid", token: {} },
                data: { targetUid: "targetUid" },
            } as never)).rejects.toMatchObject({
                code: "permission-denied",
                message: "Cannot wave at this user.",
            });

            expect(addMock).not.toHaveBeenCalled();
            expect(rateLimit.checkRateLimit).not.toHaveBeenCalled();
        });
    });

    describe("mutual wave monthly counters", () => {
        it("uses a calendar-month users/{uid} counter field", async () => {
            const { mutualWaveCounterField } = await import(
                "../../src/modules/matches/matches.functions"
            );

            expect(mutualWaveCounterField(new Date("2026-06-02T12:00:00Z"))).toBe(
                "mutualWaves_2026_06"
            );
        });

        it("uses free and premium mutual wave limits", async () => {
            const { mutualWaveLimitForUser, mutualWaveCountForUser } = await import(
                "../../src/modules/matches/matches.functions"
            );

            expect(mutualWaveLimitForUser({ isPremium: false })).toBe(5);
            expect(mutualWaveLimitForUser({ isPremium: true })).toBe(20);
            expect(mutualWaveCountForUser({ mutualWaves_2026_06: 4 }, "mutualWaves_2026_06")).toBe(4);
            expect(mutualWaveCountForUser({}, "mutualWaves_2026_06")).toBe(0);
        });
    });
});
