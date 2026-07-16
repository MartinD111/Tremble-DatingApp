/**
 * Tremble — Match Functions Unit Tests
 */

import { describe, it, expect, jest, beforeEach, afterEach } from "@jest/globals";

const mockDb = {
    collection: jest.fn(),
    batch: jest.fn(),
    getAll: jest.fn<(...refs: unknown[]) => Promise<unknown[]>>(),
    runTransaction: jest.fn(),
};
const mockMessagingSend = jest.fn<(message: unknown) => Promise<string>>();
const mockSendMatchNotificationEmail = jest.fn<() => Promise<void>>();
const mockTransactionSet = jest.fn();
const mockOnDocumentCreated = jest.fn((_: unknown, handler: unknown) => handler);
const mockRedisValues = new Map<string, string>();
const mockRedis = {
    set: jest.fn(async (key: string, value: string, options?: { nx?: boolean }) => {
        if (options?.nx && mockRedisValues.has(key)) return null;
        mockRedisValues.set(key, value);
        return "OK";
    }),
    get: jest.fn(async (key: string) => mockRedisValues.get(key) ?? null),
    incr: jest.fn(async (key: string) => {
        const next = Number(mockRedisValues.get(key) ?? "0") + 1;
        mockRedisValues.set(key, next.toString());
        return next;
    }),
    expire: jest.fn(async () => 1),
    eval: jest.fn(async (_script: string, keys: string[], args: unknown[]) => {
        const key = keys[0];
        if (mockRedisValues.get(key) !== String(args[0])) return 0;
        if (args.length >= 2) {
            mockRedisValues.set(key, String(args[1]));
            return 1;
        }
        mockRedisValues.delete(key);
        return 1;
    }),
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
        send: mockMessagingSend,
    })),
}));

jest.mock("firebase-functions/v2/firestore", () => ({
    onDocumentCreated: mockOnDocumentCreated,
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
    sendMatchNotificationEmail: mockSendMatchNotificationEmail,
}));

jest.mock("../../src/core/redis", () => ({
    getRedis: jest.fn(() => mockRedis),
    waveDedupKey: jest.fn((fromUid: string, toUid: string) => `wave:${fromUid}:${toUid}`),
    WAVE_DEDUP_SECS: 300,
}));

jest.mock("../../src/config/env", () => ({
    ENFORCE_APP_CHECK: false,
}));

type WaveProfile = Record<string, unknown>;

const defaultSender: WaveProfile = {
    name: "User Alpha",
    displayName: "Legacy Alpha",
    age: 31,
    birthDate: "1990-01-01T00:00:00.000Z",
    photoUrls: ["https://media.example.test/user-alpha.jpg"],
    fcmToken: "fcm-alpha",
};

const defaultReceiver: WaveProfile = {
    name: "User Beta",
    displayName: "Legacy Beta",
    age: 29,
    birthDate: { toDate: () => new Date("1997-05-01T00:00:00.000Z") },
    photoUrls: ["https://media.example.test/user-beta.jpg"],
    fcmToken: "fcm-beta",
};

function setupWaveTriggerDb(options: {
    sender?: WaveProfile;
    receiver?: WaveProfile;
    reciprocal?: () => boolean;
    profileGate?: Promise<void>;
    existingMatchOwnerWaveId?: string;
} = {}): void {
    const sender = options.sender ?? defaultSender;
    const receiver = options.receiver ?? defaultReceiver;
    const reciprocalRef = { kind: "reciprocal", path: "waves/reciprocal-wave" };
    const matchRef = { kind: "match", path: "matches/senderUid_receiverUid" };
    const senderRef = { kind: "user", uid: "senderUid", path: "users/senderUid" };
    const receiverRef = { kind: "user", uid: "receiverUid", path: "users/receiverUid" };
    let matchOwnerWaveId = options.existingMatchOwnerWaveId;
    mockTransactionSet.mockImplementation((_ref: unknown, rawData: unknown) => {
        const data = rawData as Record<string, unknown>;
        if (typeof data.notificationOwnerWaveId === "string") {
            matchOwnerWaveId = data.notificationOwnerWaveId;
        }
    });

    mockDb.collection.mockImplementation((collectionName: unknown) => {
        if (collectionName === "users") {
            return {
                doc: jest.fn((uid: string) => {
                    const ref = uid === "senderUid" ? senderRef : receiverRef;
                    const data = uid === "senderUid" ? sender : receiver;
                    return {
                        ...ref,
                        get: jest.fn(async () => {
                            await options.profileGate;
                            return { exists: true, data: () => data };
                        }),
                    };
                }),
            };
        }
        if (collectionName === "waves") {
            const query = {
                where: jest.fn(),
                limit: jest.fn(),
                get: jest.fn(async () => options.reciprocal?.() === true
                    ? { empty: false, docs: [{ ref: reciprocalRef }] }
                    : { empty: true, docs: [] }),
            };
            query.where.mockReturnValue(query);
            query.limit.mockReturnValue(query);
            return query;
        }
        if (collectionName === "matches") {
            return { doc: jest.fn(() => matchRef) };
        }
        throw new Error(`Unexpected collection: ${String(collectionName)}`);
    });

    mockDb.runTransaction.mockImplementation(async (callback: unknown) => {
        const transaction = {
            get: jest.fn(async (ref: { kind?: string; uid?: string }) => {
                if (ref.kind === "match") {
                    return matchOwnerWaveId
                        ? {
                            exists: true,
                            data: () => ({
                                notificationOwnerWaveId: matchOwnerWaveId,
                            }),
                        }
                        : { exists: false, data: () => undefined };
                }
                if (ref.uid === "senderUid") return { exists: true, data: () => sender };
                return { exists: true, data: () => receiver };
            }),
            set: mockTransactionSet,
            update: jest.fn(),
            delete: jest.fn(),
        };
        return (callback as (transaction: unknown) => Promise<unknown>)(transaction);
    });
}

async function invokeWaveTrigger(waveId = "wave-event-1"): Promise<void> {
    const { onWaveCreated } = await import("../../src/modules/matches/matches.functions");
    const trigger = onWaveCreated as unknown as (event: unknown) => Promise<void>;
    await trigger({
        id: `event-${waveId}`,
        params: { waveId },
        data: {
            ref: { path: `waves/${waveId}` },
            data: () => ({ fromUid: "senderUid", toUid: "receiverUid" }),
        },
    });
}

function structuredLogs(logSpy: jest.SpiedFunction<typeof console.log>): Array<Record<string, unknown>> {
    return logSpy.mock.calls
        .map(([message]) => {
            if (typeof message !== "string" || !message.startsWith("{")) return null;
            return JSON.parse(message) as Record<string, unknown>;
        })
        .filter((entry): entry is Record<string, unknown> => entry !== null);
}

describe("Matches Module", () => {
    describe("onWaveCreated delivery", () => {
        let logSpy: jest.SpiedFunction<typeof console.log>;

        beforeEach(() => {
            jest.resetModules();
            jest.useFakeTimers();
            jest.setSystemTime(new Date("2026-07-15T12:00:00.000Z"));
            jest.clearAllMocks();
            mockRedisValues.clear();
            mockMessagingSend.mockReset();
            mockSendMatchNotificationEmail.mockReset();
            mockTransactionSet.mockReset();
            logSpy = jest.spyOn(console, "log").mockImplementation(() => undefined);
        });

        afterEach(() => {
            logSpy.mockRestore();
            jest.useRealTimers();
        });

        it("configures Firestore retries and sends a visible canonical INCOMING_WAVE payload", async () => {
            setupWaveTriggerDb();
            mockMessagingSend.mockResolvedValue("message-id");

            await invokeWaveTrigger();

            expect(mockOnDocumentCreated).toHaveBeenCalledWith(
                expect.objectContaining({
                    document: "waves/{waveId}",
                    region: "europe-west1",
                    retry: true,
                }),
                expect.any(Function),
            );
            expect(mockMessagingSend).toHaveBeenCalledWith({
                token: "fcm-beta",
                notification: {
                    title: "User Alpha waved",
                    body: "Wave back?",
                    imageUrl: "https://media.example.test/user-alpha.jpg",
                },
                data: {
                    type: "INCOMING_WAVE",
                    waveId: "wave-event-1",
                    senderId: "senderUid",
                    senderName: "User Alpha",
                    senderAge: "31",
                    senderPhotoUrl: "https://media.example.test/user-alpha.jpg",
                },
                apns: {
                    payload: {
                        aps: {
                            contentAvailable: true,
                            category: "WAVE_CATEGORY",
                            sound: "default",
                            "mutable-content": 1,
                        },
                    },
                },
                android: {
                    priority: "high",
                    notification: {
                        channelId: "tremble_wave",
                        sound: "default",
                    },
                },
            });
            expect(JSON.stringify(mockMessagingSend.mock.calls)).not.toContain("click_action");
        });

        it("uses Timestamp-like and ISO birthDate fallbacks only when numeric age is absent", async () => {
            setupWaveTriggerDb({
                sender: {
                    ...defaultSender,
                    age: undefined,
                    birthDate: { toDate: () => new Date("1996-06-01T00:00:00.000Z") },
                },
            });
            mockMessagingSend.mockResolvedValue("message-id");
            await invokeWaveTrigger("timestamp-wave");
            expect((mockMessagingSend.mock.calls[0][0] as {
                data: Record<string, string>;
            }).data.senderAge).toBe("30");

            jest.resetModules();
            mockMessagingSend.mockClear();
            mockRedisValues.clear();
            setupWaveTriggerDb({
                sender: {
                    ...defaultSender,
                    age: undefined,
                    birthDate: "1998-08-01T00:00:00.000Z",
                },
            });
            await invokeWaveTrigger("iso-wave");
            expect((mockMessagingSend.mock.calls[0][0] as {
                data: Record<string, string>;
            }).data.senderAge).toBe("27");
        });

        it("does not derive sender age from locale or free-form birthDate strings", async () => {
            setupWaveTriggerDb({
                sender: {
                    ...defaultSender,
                    age: undefined,
                    birthDate: "June 1, 1996",
                },
            });
            mockMessagingSend.mockResolvedValue("message-id");

            await invokeWaveTrigger("free-form-birth-date-wave");

            expect((mockMessagingSend.mock.calls[0][0] as {
                data: Record<string, string>;
            }).data.senderAge).toBe("0");
        });

        it("releases only its processing claim after a failed incoming send and retries next invocation", async () => {
            let reciprocal = false;
            setupWaveTriggerDb({ reciprocal: () => reciprocal });
            const transientError = Object.assign(new Error("transient"), {
                code: "messaging/internal-error",
            });
            mockMessagingSend
                .mockRejectedValueOnce(transientError)
                .mockResolvedValueOnce("message-id");

            await expect(invokeWaveTrigger("retry-wave")).rejects.toMatchObject({
                code: "messaging/internal-error",
            });
            expect(mockRedisValues.has("wave-delivery:retry-wave:processing")).toBe(false);

            // The delivery branch is fixed per event even if reciprocal state changes.
            reciprocal = true;
            await expect(invokeWaveTrigger("retry-wave")).resolves.toBeUndefined();

            expect(mockMessagingSend).toHaveBeenCalledTimes(2);
            expect(mockMessagingSend).toHaveBeenLastCalledWith(
                expect.objectContaining({
                    data: expect.objectContaining({ type: "INCOMING_WAVE" }),
                }),
            );
            expect(mockRedisValues.get(
                "wave-delivery:retry-wave:recipient:receiverUid:delivered"
            )).toBe("1");
        });

        it("retains the delivered marker after accepted send and skips duplicate invocation", async () => {
            setupWaveTriggerDb();
            mockMessagingSend.mockResolvedValue("message-id");

            await invokeWaveTrigger("delivered-wave");
            await invokeWaveTrigger("delivered-wave");

            expect(mockMessagingSend).toHaveBeenCalledTimes(1);
            expect(mockRedisValues.get(
                "wave-delivery:delivered-wave:recipient:receiverUid:delivered"
            )).toBe("1");
            expect(structuredLogs(logSpy)).toEqual(expect.arrayContaining([
                expect.objectContaining({ event: "dedup_skip", recipientUid: "receiver..." }),
            ]));
        });

        it("bounds transient incoming delivery to three attempts per event", async () => {
            setupWaveTriggerDb();
            const transientError = Object.assign(new Error("transient"), {
                code: "messaging/internal-error",
            });
            mockMessagingSend.mockRejectedValue(transientError);

            await expect(invokeWaveTrigger("bounded-wave")).rejects.toBe(transientError);
            await expect(invokeWaveTrigger("bounded-wave")).rejects.toBe(transientError);
            await expect(invokeWaveTrigger("bounded-wave")).resolves.toBeUndefined();
            await expect(invokeWaveTrigger("bounded-wave")).resolves.toBeUndefined();

            expect(mockMessagingSend).toHaveBeenCalledTimes(3);
            expect(structuredLogs(logSpy)).toEqual(expect.arrayContaining([
                expect.objectContaining({
                    event: "delivery_error",
                    errorCode: "messaging/internal-error",
                    retryDisposition: "exhausted",
                }),
            ]));
        });

        it("does not retry permanent invalid-token delivery failures", async () => {
            setupWaveTriggerDb();
            const permanentError = Object.assign(new Error("invalid token"), {
                code: "messaging/registration-token-not-registered",
            });
            mockMessagingSend.mockRejectedValue(permanentError);

            await expect(invokeWaveTrigger("permanent-wave")).resolves.toBeUndefined();
            await expect(invokeWaveTrigger("permanent-wave")).resolves.toBeUndefined();

            expect(mockMessagingSend).toHaveBeenCalledTimes(1);
            expect(structuredLogs(logSpy)).toEqual(expect.arrayContaining([
                expect.objectContaining({
                    event: "delivery_error",
                    errorCode: "messaging/registration-token-not-registered",
                    retryDisposition: "permanent",
                }),
            ]));
        });

        it("does not retry permanent third-party authentication failures", async () => {
            setupWaveTriggerDb();
            const permanentError = Object.assign(new Error("APNs auth rejected"), {
                code: "messaging/third-party-auth-error",
            });
            mockMessagingSend.mockRejectedValue(permanentError);

            await expect(invokeWaveTrigger("third-party-auth-wave")).resolves.toBeUndefined();
            await expect(invokeWaveTrigger("third-party-auth-wave")).resolves.toBeUndefined();

            expect(mockMessagingSend).toHaveBeenCalledTimes(1);
            expect(structuredLogs(logSpy)).toEqual(expect.arrayContaining([
                expect.objectContaining({
                    event: "delivery_error",
                    errorCode: "messaging/third-party-auth-error",
                    retryDisposition: "permanent",
                }),
            ]));
        });

        it("atomically skips a concurrent same-direction event while the first owns processing", async () => {
            let releaseProfiles!: () => void;
            const profileGate = new Promise<void>((resolve) => {
                releaseProfiles = resolve;
            });
            setupWaveTriggerDb({ profileGate });
            mockMessagingSend.mockResolvedValue("message-id");

            const firstInvocation = invokeWaveTrigger("same-direction-owner");
            for (let turn = 0; turn < 20; turn++) {
                if (mockRedisValues.has("wave:senderUid:receiverUid")) break;
                await Promise.resolve();
            }
            const stateBeforeProfileRead = mockRedisValues.get("wave:senderUid:receiverUid");
            const contenderInvocation = invokeWaveTrigger("same-direction-contender");
            releaseProfiles();
            await expect(firstInvocation).resolves.toBeUndefined();
            await expect(contenderInvocation).resolves.toBeUndefined();

            expect(stateBeforeProfileRead).toMatch(/^processing:same-direction-owner:/);
            expect(mockMessagingSend).toHaveBeenCalledTimes(1);
            expect(mockRedisValues.get("wave:senderUid:receiverUid")).toBe(
                "delivered:same-direction-owner"
            );
        });

        it("marks a reciprocal non-owner trigger terminal without notification or email", async () => {
            setupWaveTriggerDb({
                reciprocal: () => true,
                existingMatchOwnerWaveId: "owner-wave",
                sender: { ...defaultSender, email: "alpha@example.test" },
                receiver: { ...defaultReceiver, email: "beta@example.test" },
            });
            mockMessagingSend.mockResolvedValue("message-id");
            mockSendMatchNotificationEmail.mockResolvedValue(undefined);

            await expect(invokeWaveTrigger("non-owner-wave")).resolves.toBeUndefined();

            expect(mockMessagingSend).not.toHaveBeenCalled();
            expect(mockSendMatchNotificationEmail).not.toHaveBeenCalled();
            expect(mockRedisValues.get("wave:senderUid:receiverUid")).toBe(
                "terminal:non-owner-wave"
            );
        });

        it("keeps mutual notification ownership and retries only the failed recipient", async () => {
            setupWaveTriggerDb({ reciprocal: () => true });
            const transientError = Object.assign(new Error("transient"), {
                code: "messaging/server-unavailable",
            });
            mockMessagingSend
                .mockResolvedValueOnce("receiver-message-id")
                .mockRejectedValueOnce(transientError)
                .mockResolvedValueOnce("sender-message-id");

            await expect(invokeWaveTrigger("mutual-owner-retry")).rejects.toBe(transientError);
            await expect(invokeWaveTrigger("mutual-owner-retry")).resolves.toBeUndefined();

            expect(mockTransactionSet).toHaveBeenCalledWith(
                expect.objectContaining({ kind: "match" }),
                expect.objectContaining({
                    notificationOwnerWaveId: "mutual-owner-retry",
                }),
            );
            const sentTokens = mockMessagingSend.mock.calls.map(([message]) =>
                (message as { token: string }).token
            );
            expect(sentTokens.filter((token) => token === "fcm-beta")).toHaveLength(1);
            expect(sentTokens.filter((token) => token === "fcm-alpha")).toHaveLength(2);
            expect(mockRedisValues.get("wave:senderUid:receiverUid")).toBe(
                "delivered:mutual-owner-retry"
            );
        });

        it("keeps silent Run/Gym/Event incoming delivery data-only with waveId", async () => {
            setupWaveTriggerDb({
                receiver: { ...defaultReceiver, isRunModeActive: true },
            });
            mockMessagingSend.mockResolvedValue("message-id");

            await invokeWaveTrigger("silent-wave");

            const payload = mockMessagingSend.mock.calls[0][0] as {
                notification?: unknown;
                data: Record<string, string>;
            };
            expect(payload.notification).toBeUndefined();
            expect(payload.data).toEqual(expect.objectContaining({
                type: "INCOMING_WAVE",
                waveId: "silent-wave",
            }));
        });

        it("logs mutual partial failure and does not report aggregate delivery success", async () => {
            setupWaveTriggerDb({ reciprocal: () => true });
            const transientError = Object.assign(new Error("transient"), {
                code: "messaging/server-unavailable",
            });
            mockMessagingSend
                .mockResolvedValueOnce("receiver-message-id")
                .mockRejectedValueOnce(transientError);

            await expect(invokeWaveTrigger("mutual-wave")).rejects.toBe(transientError);

            const logs = structuredLogs(logSpy);
            expect(logs).toEqual(expect.arrayContaining([
                expect.objectContaining({
                    event: "delivery_error",
                    errorCode: "messaging/server-unavailable",
                    retryDisposition: "retry",
                }),
            ]));
            expect(logs).not.toEqual(expect.arrayContaining([
                expect.objectContaining({
                    event: "delivery_success",
                    result: "mutual_wave",
                }),
            ]));
            expect(mockRedisValues.get(
                "wave-delivery:mutual-wave:recipient:receiverUid:delivered"
            )).toBe("1");
            expect(mockRedisValues.has(
                "wave-delivery:mutual-wave:recipient:senderUid:delivered"
            )).toBe(false);
        });
    });

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
                        // ADR-007 §1 — no gestures on the match doc, so
                        // hasMutualWave defaults to false.
                        hasMutualWave: false,
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

        // ADR-007 §1 — mutual-wave predicate pair-of-tests.
        // Server derives hasMutualWave from matchData.gestures (client-
        // written {uid: true} map on the match doc). Two waves in the
        // map => mutual; one or zero => non-mutual. This is the compound
        // gate that the client's three-state render pipeline depends on.
        describe("ADR-007 §1 hasMutualWave contract", () => {
            const buildGetMatchesForGestures = async (
                gestures: Record<string, boolean> | undefined,
            ): Promise<unknown> => {
                jest.clearAllMocks();
                const authGuard = await import("../../src/middleware/authGuard");
                const rateLimit = await import("../../src/middleware/rateLimit");
                const { getMatches } = await import(
                    "../../src/modules/matches/matches.functions"
                );

                jest.mocked(authGuard.requireAuth).mockReturnValue("callerUid");
                jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);

                const matchDocs = [{
                    data: () => ({
                        userA: "callerUid",
                        userB: "partnerUid",
                        matchType: "standard",
                        matchContext: null,
                        createdAt: null,
                        ...(gestures !== undefined ? { gestures } : {}),
                    }),
                }];
                const partnerRef = { path: "users/partnerUid" };
                const partnerDoc = {
                    exists: true,
                    data: () => ({
                        name: "Partner",
                        age: 30,
                        photoUrls: [],
                        hobbies: [],
                        lookingFor: [],
                        isTraveler: false,
                    }),
                };
                const docMock = jest.fn((docId: unknown) => {
                    if (docId === "callerUid") {
                        return {
                            get: jest.fn(async () => ({
                                data: () => ({ blockedUserIds: [] }),
                            })),
                        };
                    }
                    if (docId === "partnerUid") {
                        return { ...partnerRef, get: jest.fn() };
                    }
                    throw new Error(`Unexpected user doc: ${String(docId)}`);
                });

                mockDb.collection.mockImplementation((collectionName: unknown) => {
                    if (collectionName === "users") return { doc: docMock };
                    if (collectionName === "matches") {
                        return {
                            where: jest.fn(() => ({
                                orderBy: jest.fn(() => ({
                                    limit: jest.fn(() => ({
                                        get: jest.fn(async () => ({ docs: matchDocs })),
                                    })),
                                })),
                            })),
                        };
                    }
                    throw new Error(`Unexpected collection: ${collectionName}`);
                });
                mockDb.getAll.mockResolvedValue([partnerDoc]);

                const callable = getMatches as unknown as (
                    request: unknown,
                ) => Promise<{ matches: Array<{ hasMutualWave: boolean }> }>;
                return callable({ auth: { uid: "callerUid", token: {} }, data: {} });
            };

            it("returns hasMutualWave=true when both userIds appear in gestures (mutual)", async () => {
                const result = await buildGetMatchesForGestures({
                    callerUid: true,
                    partnerUid: true,
                });
                expect(
                    (result as { matches: Array<{ hasMutualWave: boolean }> }).matches[0].hasMutualWave,
                ).toBe(true);
            });

            it("returns hasMutualWave=false when only one user has waved (non-mutual)", async () => {
                const result = await buildGetMatchesForGestures({
                    callerUid: true,
                });
                expect(
                    (result as { matches: Array<{ hasMutualWave: boolean }> }).matches[0].hasMutualWave,
                ).toBe(false);
            });

            it("returns hasMutualWave=false when gestures is missing entirely (defensive default)", async () => {
                const result = await buildGetMatchesForGestures(undefined);
                expect(
                    (result as { matches: Array<{ hasMutualWave: boolean }> }).matches[0].hasMutualWave,
                ).toBe(false);
            });
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

        // ADR-007 §4 pair-of-tests — paywall premium_feature_mutual_waves_20.
        // The client-side `AuthUser.hasReachedWaveLimit` gate is covered
        // by `test/features/auth/auth_user_wave_limit_test.dart` (Free at
        // 5 = at limit, Premium at 5 = under, Premium at 20 = at limit).
        // These two server-side assertions mirror the client contract at
        // the `count >= limit` comparison in `onWaveCreated`
        // (matches.functions.ts:256) so a helper drift on either tier
        // cannot silently un-gate the rejection.
        it(
            "Free user at the monthly limit (count=5) satisfies the "
                + "`count >= limit` rejection predicate",
            async () => {
                const { mutualWaveLimitForUser, mutualWaveCountForUser } = await import(
                    "../../src/modules/matches/matches.functions"
                );

                const userData = { isPremium: false, mutualWaves_2026_06: 5 };
                const count = mutualWaveCountForUser(userData, "mutualWaves_2026_06");
                const limit = mutualWaveLimitForUser(userData);

                expect(count).toBe(5);
                expect(limit).toBe(5);
                expect(count >= limit).toBe(true);
            }
        );

        it(
            "Premium user at Free-tier count (count=5) does NOT satisfy the "
                + "rejection predicate, but the same user at Premium-tier count "
                + "(count=20) does",
            async () => {
                const { mutualWaveLimitForUser, mutualWaveCountForUser } = await import(
                    "../../src/modules/matches/matches.functions"
                );

                const premiumUnderLimit = { isPremium: true, mutualWaves_2026_06: 5 };
                const premiumAtLimit = { isPremium: true, mutualWaves_2026_06: 20 };

                const underCount = mutualWaveCountForUser(
                    premiumUnderLimit,
                    "mutualWaves_2026_06"
                );
                const atCount = mutualWaveCountForUser(
                    premiumAtLimit,
                    "mutualWaves_2026_06"
                );
                const premiumLimit = mutualWaveLimitForUser(premiumUnderLimit);

                expect(premiumLimit).toBe(20);
                expect(underCount >= premiumLimit).toBe(false);
                expect(atCount >= premiumLimit).toBe(true);
            }
        );
    });
});
