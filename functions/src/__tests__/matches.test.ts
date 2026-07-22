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
const mockTransactionUpdate = jest.fn();
const mockTransactionDelete = jest.fn();
const mockOnDocumentCreated = jest.fn((_: unknown, handler: unknown) => handler);
const mockTimestampFromMillis = jest.fn((millis: number) => ({
    toMillis: () => millis,
}));
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
        delete: jest.fn(() => "DELETE_FIELD"),
    },
    Timestamp: {
        fromMillis: mockTimestampFromMillis,
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
        details?: unknown;
        constructor(code: string, message: string, details?: unknown) {
            super(message);
            this.code = code;
            this.details = details;
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

// The onWaveCreated suite pins the clock to 2026-07-15T12:00:00.000Z, so the
// absolute APNs deadline is deterministic: send time + 300s.
const EXPECTED_APNS_EXPIRATION = String(
    Math.floor(Date.parse("2026-07-15T12:00:00.000Z") / 1000) + 300,
);

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
    reciprocalCreatedAt?: Date;
    profileGate?: Promise<void>;
    existingMatchOwnerWaveId?: string;
    existingMatch?: {
        ownerWaveId?: string;
        status?: string;
        createdAt?: Date;
        finderOptIn?: Record<string, boolean>;
    };
} = {}): {
    where: jest.Mock;
    orderBy: jest.Mock;
    limit: jest.Mock;
} {
    const sender = options.sender ?? defaultSender;
    const receiver = options.receiver ?? defaultReceiver;
    const reciprocalRef = { kind: "reciprocal", path: "waves/reciprocal-wave" };
    const matchRef = {
        kind: "match",
        path: "matches/senderUid_receiverUid",
        collection: jest.fn((name: string) => ({
            doc: jest.fn((uid: string) => ({
                kind: name,
                uid,
                path: `matches/senderUid_receiverUid/${name}/${uid}`,
            })),
        })),
    };
    const senderRef = { kind: "user", uid: "senderUid", path: "users/senderUid" };
    const receiverRef = { kind: "user", uid: "receiverUid", path: "users/receiverUid" };
    const whereCalls: Array<[unknown, unknown, unknown]> = [];
    const wavesQuery = {
        where: jest.fn((...args: [unknown, unknown, unknown]) => {
            whereCalls.push(args);
            return wavesQuery;
        }),
        orderBy: jest.fn(),
        limit: jest.fn(),
        get: jest.fn(async () => {
            const recencyFilter = whereCalls.find(
                ([field, operator]) => field === "createdAt" && operator === ">=",
            );
            const cutoffMillis = (
                recencyFilter?.[2] as { toMillis?: () => number } | undefined
            )?.toMillis?.();
            const reciprocalIsRecent = options.reciprocalCreatedAt !== undefined
                && (cutoffMillis === undefined
                    || options.reciprocalCreatedAt.getTime() >= cutoffMillis);
            const hasReciprocal = options.reciprocal?.() === true
                || reciprocalIsRecent;
            return hasReciprocal
                ? { empty: false, docs: [{ ref: reciprocalRef }] }
                : { empty: true, docs: [] };
        }),
    };
    wavesQuery.orderBy.mockReturnValue(wavesQuery);
    wavesQuery.limit.mockReturnValue(wavesQuery);
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
            return wavesQuery;
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
                    if (options.existingMatch) {
                        return {
                            exists: true,
                            data: () => ({
                                userIds: ["senderUid", "receiverUid"],
                                notificationOwnerWaveId:
                                    options.existingMatch!.ownerWaveId,
                                status: options.existingMatch!.status,
                                finderOptIn: options.existingMatch!.finderOptIn,
                                createdAt: options.existingMatch!.createdAt
                                    ? { toDate: () => options.existingMatch!.createdAt }
                                    : undefined,
                            }),
                        };
                    }
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
            update: mockTransactionUpdate,
            delete: mockTransactionDelete,
        };
        return (callback as (transaction: unknown) => Promise<unknown>)(transaction);
    });

    return wavesQuery;
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
                    headers: { "apns-expiration": EXPECTED_APNS_EXPIRATION },
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
                    ttl: 300_000,
                    notification: {
                        channelId: "tremble_wave",
                        sound: "default",
                    },
                },
            });
            expect(JSON.stringify(mockMessagingSend.mock.calls)).not.toContain("click_action");
        });

        // ── Message expiry ───────────────────────────────────────────────────
        // "X waved at you" is only worth delivering while it is still true. If
        // the handset is offline, FCM must drop the wave rather than surface it
        // hours later. TTL bounds the delivery window only — it does not remove
        // a notification that already landed on the device.
        //
        // Android takes a relative duration in milliseconds; APNs takes an
        // absolute UNIX epoch in seconds, as a string header.
        describe("message expiry", () => {
            it("expires a silent INCOMING_WAVE wake on the same 5-minute window", async () => {
                setupWaveTriggerDb({
                    receiver: { ...defaultReceiver, isRunModeActive: true },
                });
                mockMessagingSend.mockResolvedValue("message-id");

                await invokeWaveTrigger();

                const sent = mockMessagingSend.mock.calls[0][0] as {
                    notification?: unknown;
                    android?: { ttl?: number };
                    apns?: { headers?: Record<string, string> };
                };
                expect(sent.notification).toBeUndefined();
                expect(sent.android?.ttl).toBe(300_000);
                expect(sent.apns?.headers?.["apns-expiration"]).toBe(EXPECTED_APNS_EXPIRATION);
            });

            it("derives the APNs deadline from send time, not a fixed constant", async () => {
                jest.setSystemTime(new Date("2026-07-15T12:30:00.000Z"));
                setupWaveTriggerDb();
                mockMessagingSend.mockResolvedValue("message-id");

                await invokeWaveTrigger();

                const sent = mockMessagingSend.mock.calls[0][0] as {
                    apns?: { headers?: Record<string, string> };
                };
                expect(sent.apns?.headers?.["apns-expiration"]).toBe(
                    String(Math.floor(Date.parse("2026-07-15T12:30:00.000Z") / 1000) + 300),
                );
            });
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

        it("treats a reciprocal wave older than 30 minutes as incoming", async () => {
            const reciprocalQuery = setupWaveTriggerDb({
                reciprocalCreatedAt: new Date("2026-07-15T11:29:59.999Z"),
            });
            mockMessagingSend.mockResolvedValue("message-id");

            await invokeWaveTrigger("stale-reciprocal-wave");

            expect(mockTimestampFromMillis).toHaveBeenCalledWith(
                Date.parse("2026-07-15T11:30:00.000Z"),
            );
            expect(reciprocalQuery.where).toHaveBeenCalledWith(
                "createdAt",
                ">=",
                expect.objectContaining({ toMillis: expect.any(Function) }),
            );
            expect(reciprocalQuery.orderBy).toHaveBeenCalledWith("createdAt", "desc");
            expect(reciprocalQuery.limit).toHaveBeenCalledWith(1);
            expect(mockTransactionSet).not.toHaveBeenCalled();
            expect(mockMessagingSend).toHaveBeenCalledTimes(1);
            expect(mockMessagingSend).toHaveBeenCalledWith(expect.objectContaining({
                data: expect.objectContaining({ type: "INCOMING_WAVE" }),
            }));
        });

        it("creates one mutual match for a reciprocal wave within 30 minutes", async () => {
            setupWaveTriggerDb({
                reciprocalCreatedAt: new Date("2026-07-15T11:45:00.000Z"),
            });
            mockMessagingSend.mockResolvedValue("message-id");

            await invokeWaveTrigger("recent-reciprocal-wave");

            expect(mockTransactionSet).toHaveBeenCalledTimes(1);
            expect(mockTransactionSet).toHaveBeenCalledWith(
                expect.anything(),
                expect.objectContaining({ status: "pending" }),
            );
            expect(mockMessagingSend).toHaveBeenCalledTimes(2);
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

        // Rule #105 defense-in-depth: one stale proximity doc must not make a
        // radar-off user wave-able (and thus matchable via wave-back).
        describe("target radar gate", () => {
            const wireSendWaveMocks = (proximityData: {
                exists: boolean;
                data: Record<string, unknown>;
            }) => {
                const usersGetMock = jest.fn<() => Promise<{
                    exists: boolean;
                    data: () => Record<string, unknown>;
                }>>()
                    .mockResolvedValueOnce({
                        exists: true,
                        data: () => ({ isBanned: false }),
                    })
                    .mockResolvedValueOnce({
                        exists: true,
                        data: () => ({ blockedUserIds: [] }),
                    });
                const proximityGetMock = jest.fn(async () => ({
                    exists: proximityData.exists,
                    data: () => proximityData.data,
                }));
                const addMock = jest.fn(async () => ({ id: "wave-id" }));

                mockDb.collection.mockImplementation((collectionName: unknown) => {
                    if (collectionName === "users") {
                        return { doc: jest.fn(() => ({ get: usersGetMock })) };
                    }
                    if (collectionName === "proximity") {
                        return { doc: jest.fn(() => ({ get: proximityGetMock })) };
                    }
                    if (collectionName === "waves") {
                        return { add: addMock };
                    }
                    throw new Error(`Unexpected collection: ${collectionName}`);
                });
                return { addMock };
            };

            const callSendWave = async () => {
                const authGuard = await import("../../src/middleware/authGuard");
                const rateLimit = await import("../../src/middleware/rateLimit");
                const validate = await import("../../src/middleware/validate");
                const { sendWave } = await import(
                    "../../src/modules/matches/matches.functions"
                );

                jest.mocked(authGuard.requireAuth).mockReturnValue("senderUid");
                jest.mocked(authGuard.assertNotBanned)
                    .mockImplementation(() => undefined);
                jest.mocked(validate.assertValidDocumentId)
                    .mockReturnValue("targetUid");
                jest.mocked(rateLimit.checkRateLimit).mockResolvedValue(undefined);

                const callable = sendWave as unknown as (
                    request: unknown
                ) => Promise<unknown>;
                return callable({
                    auth: { uid: "senderUid", token: {} },
                    data: { targetUid: "targetUid" },
                } as never);
            };

            it("rejects when the target's presence is stale", async () => {
                const { addMock } = wireSendWaveMocks({
                    exists: true,
                    data: {
                        radarActive: true,
                        isActive: true,
                        updatedAt: { toMillis: () => Date.now() - 10 * 60 * 1000 },
                    },
                });

                await expect(callSendWave()).rejects.toMatchObject({
                    code: "failed-precondition",
                    details: { reason: "target_radar_off" },
                });
                expect(addMock).not.toHaveBeenCalled();
            });

            it("rejects when the target's radarActive is false", async () => {
                const { addMock } = wireSendWaveMocks({
                    exists: true,
                    data: {
                        radarActive: false,
                        isActive: false,
                        updatedAt: { toMillis: () => Date.now() - 5_000 },
                    },
                });

                await expect(callSendWave()).rejects.toMatchObject({
                    code: "failed-precondition",
                    details: { reason: "target_radar_off" },
                });
                expect(addMock).not.toHaveBeenCalled();
            });

            it("rejects when the target has no proximity doc", async () => {
                const { addMock } = wireSendWaveMocks({
                    exists: false,
                    data: {},
                });

                await expect(callSendWave()).rejects.toMatchObject({
                    code: "failed-precondition",
                    details: { reason: "target_radar_off" },
                });
                expect(addMock).not.toHaveBeenCalled();
            });

            it("accepts a fresh, radar-active target", async () => {
                const { addMock } = wireSendWaveMocks({
                    exists: true,
                    data: {
                        radarActive: true,
                        isActive: true,
                        updatedAt: { toMillis: () => Date.now() - 30_000 },
                    },
                });

                await expect(callSendWave()).resolves.toEqual({ success: true });
                expect(addMock).toHaveBeenCalledTimes(1);
            });
        });

        it("expires a new wave five minutes after the reciprocity window", async () => {
            jest.useFakeTimers();
            jest.setSystemTime(new Date("2026-07-15T12:00:00.000Z"));

            try {
                const authGuard = await import("../../src/middleware/authGuard");
                const rateLimit = await import("../../src/middleware/rateLimit");
                const validate = await import("../../src/middleware/validate");
                const { sendWave } = await import(
                    "../../src/modules/matches/matches.functions"
                );

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
                        data: () => ({ blockedUserIds: [] }),
                    });
                const docMock = jest.fn(() => ({ get: getMock }));
                const addMock = jest.fn(async () => ({ id: "wave-id" }));
                const proximityGetMock = jest.fn(async () => ({
                    exists: true,
                    data: () => ({
                        radarActive: true,
                        isActive: true,
                        updatedAt: {
                            toMillis: () =>
                                new Date("2026-07-15T11:59:30.000Z").getTime(),
                        },
                    }),
                }));

                mockDb.collection.mockImplementation((collectionName: unknown) => {
                    if (collectionName === "users") {
                        return { doc: docMock };
                    }
                    if (collectionName === "proximity") {
                        return { doc: jest.fn(() => ({ get: proximityGetMock })) };
                    }
                    if (collectionName === "waves") {
                        return { add: addMock };
                    }
                    throw new Error(`Unexpected collection: ${collectionName}`);
                });

                const callableSendWave = sendWave as unknown as (
                    request: unknown
                ) => Promise<unknown>;

                await expect(callableSendWave({
                    auth: { uid: "senderUid", token: {} },
                    data: { targetUid: "targetUid" },
                } as never)).resolves.toEqual({ success: true });

                expect(addMock).toHaveBeenCalledWith(expect.objectContaining({
                    expiresAt: new Date("2026-07-15T12:35:00.000Z"),
                }));
            } finally {
                jest.useRealTimers();
            }
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

    // Symmetric reveal + window restart. A fresh mutual match must clear
    // seenBy so BOTH users get the reveal (the sender was previously
    // pre-marked seen and never saw it). A re-wave of a STALE match restarts
    // the window; an in-flight window (or the reciprocal wave of the same
    // burst) must not reset.
    describe("onWaveCreated mutual reveal + restart", () => {
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
            mockTransactionUpdate.mockReset();
            mockTransactionDelete.mockReset();
            logSpy = jest.spyOn(console, "log").mockImplementation(() => undefined);
        });

        afterEach(() => {
            logSpy.mockRestore();
            jest.useRealTimers();
        });

        it("clears seenBy on a fresh mutual match so both users get the reveal",
            async () => {
                setupWaveTriggerDb({ reciprocal: () => true });
                mockMessagingSend.mockResolvedValue("message-id");

                await invokeWaveTrigger();

                expect(mockTransactionSet).toHaveBeenCalledWith(
                    expect.anything(),
                    expect.objectContaining({ seenBy: [], status: "pending" }),
                );
            });

        it("seeds gestures for both users so a genuine mutual match reads as "
            + "hasMutualWave (colour, not greyscale, in history)",
            async () => {
                setupWaveTriggerDb({ reciprocal: () => true });
                mockMessagingSend.mockResolvedValue("message-id");

                await invokeWaveTrigger();

                expect(mockTransactionSet).toHaveBeenCalledWith(
                    expect.anything(),
                    expect.objectContaining({
                        gestures: { receiverUid: true, senderUid: true },
                    }),
                );
            });

        it("restarts the window when a stale (found) match is re-waved",
            async () => {
                setupWaveTriggerDb({
                    reciprocal: () => true,
                    existingMatch: { ownerWaveId: "old-wave", status: "found" },
                });
                mockMessagingSend.mockResolvedValue("message-id");

                await invokeWaveTrigger();

                expect(mockTransactionUpdate).toHaveBeenCalledWith(
                    expect.anything(),
                    expect.objectContaining({
                        status: "pending",
                        seenBy: [],
                        notificationOwnerWaveId: "wave-event-1",
                    }),
                );
                expect(mockMessagingSend).toHaveBeenCalled();
            });

        it("clears prior finder consent and coordinates on immediate re-engagement",
            async () => {
                setupWaveTriggerDb({
                    reciprocal: () => true,
                    existingMatch: {
                        ownerWaveId: "old-wave",
                        status: "found",
                        finderOptIn: { senderUid: true, receiverUid: true },
                    },
                });
                mockMessagingSend.mockResolvedValue("message-id");

                await invokeWaveTrigger();

                expect(mockTransactionUpdate).toHaveBeenCalledWith(
                    expect.anything(),
                    expect.objectContaining({ finderOptIn: "DELETE_FIELD" }),
                );
                expect(mockTransactionDelete).toHaveBeenCalledWith(
                    expect.objectContaining({
                        path: "matches/senderUid_receiverUid/finder/senderUid",
                    }),
                );
                expect(mockTransactionDelete).toHaveBeenCalledWith(
                    expect.objectContaining({
                        path: "matches/senderUid_receiverUid/finder/receiverUid",
                    }),
                );
            });

        it("does NOT restart an in-flight window (same-burst reciprocal wave)",
            async () => {
                setupWaveTriggerDb({
                    reciprocal: () => true,
                    existingMatch: {
                        ownerWaveId: "other-wave",
                        status: "pending",
                        createdAt: new Date("2026-07-15T12:00:00.000Z"),
                    },
                });
                mockMessagingSend.mockResolvedValue("message-id");

                await invokeWaveTrigger();

                expect(mockTransactionUpdate).not.toHaveBeenCalled();
            });
    });

    // Backend-authoritative match-state writes. The /matches collection is
    // locked in firestore.rules (update: hasOnly(['seenBy'])), so the client
    // cannot write status/isFound/foundAt or gestures directly — those writes
    // returned permission-denied and crashed the trembling window. These
    // callables perform the writes via the Admin SDK after a participant check.
    describe("markMatchFound", () => {
        function setupMarkFoundDb(options: {
            exists?: boolean;
            participant?: boolean;
            status?: string;
            transactionFailure?: Error;
        } = {}) {
            const finderRefs = [
                { kind: "finderDoc", path: "matches/userA_userB/finder/userA" },
                { kind: "finderDoc", path: "matches/userA_userB/finder/userB" },
                { kind: "finderDoc", path: "matches/userA_userB/finder/stale-extra-doc" },
            ];
            const matchSnapshot = {
                exists: options.exists ?? true,
                data: () => ({
                    userIds: options.participant === false
                        ? ["userB", "userC"]
                        : ["userA", "userB"],
                    status: options.status ?? "pending",
                }),
            };
            const finderSnapshot = {
                docs: finderRefs.map((ref) => ({ ref })),
            };
            const operationOrder: string[] = [];
            const queuedWrites: Array<Record<string, unknown>> = [];
            const committedWrites: Array<Record<string, unknown>> = [];

            const directMatchGet = jest.fn(async () => matchSnapshot);
            const directMatchUpdate = jest.fn(async () => undefined);
            const directFinderGet = jest.fn(async () => finderSnapshot);
            const directUserUpdate = jest.fn(async () => undefined);
            const finderQuery = {
                kind: "finderQuery",
                path: "matches/userA_userB/finder",
                get: directFinderGet,
            };
            const matchRef = {
                kind: "match",
                path: "matches/userA_userB",
                get: directMatchGet,
                update: directMatchUpdate,
                collection: jest.fn(() => finderQuery),
            };
            const userRef = {
                kind: "user",
                path: "users/userA",
                update: directUserUpdate,
            };
            const directBatch = {
                update: jest.fn(),
                delete: jest.fn(),
                commit: jest.fn(async () => undefined),
            };

            const transactionGet = jest.fn(async (ref: { kind: string }) => {
                operationOrder.push(`get:${ref.kind}`);
                if (ref.kind === "match") return matchSnapshot;
                if (ref.kind === "finderQuery") return finderSnapshot;
                throw new Error(`Unexpected transaction read: ${ref.kind}`);
            });
            const transactionUpdate = jest.fn((
                ref: { kind: string; path: string },
                data: Record<string, unknown>,
            ) => {
                operationOrder.push(`update:${ref.kind}`);
                queuedWrites.push({ type: "update", ref, data });
            });
            const transactionDelete = jest.fn((ref: { kind: string; path: string }) => {
                operationOrder.push(`delete:${ref.kind}`);
                queuedWrites.push({ type: "delete", ref });
            });

            mockDb.collection.mockImplementation((name: unknown) => {
                if (name === "matches") return { doc: jest.fn(() => matchRef) };
                if (name === "users") return { doc: jest.fn(() => userRef) };
                throw new Error(`Unexpected collection: ${String(name)}`);
            });
            mockDb.batch.mockReturnValue(directBatch);
            mockDb.runTransaction.mockImplementation(async (callback: unknown) => {
                const result = await (callback as (transaction: unknown) => Promise<unknown>)({
                    get: transactionGet,
                    update: transactionUpdate,
                    delete: transactionDelete,
                });
                if (options.transactionFailure) throw options.transactionFailure;
                committedWrites.push(...queuedWrites);
                return result;
            });

            return {
                committedWrites,
                directBatch,
                directMatchGet,
                directMatchUpdate,
                directUserUpdate,
                finderRefs,
                matchRef,
                operationOrder,
                queuedWrites,
                transactionDelete,
                transactionGet,
                transactionUpdate,
                userRef,
            };
        }

        beforeEach(() => {
            jest.clearAllMocks();
            mockDb.batch.mockReset();
            mockDb.runTransaction.mockReset();
        });

        it("commits status, all finder cleanup, and cooldown in one transaction", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const validate = await import("../../src/middleware/validate");
            const { markMatchFound } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("userA");
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("userA_userB");
            const harness = setupMarkFoundDb();

            const callable = markMatchFound as unknown as (r: unknown) => Promise<unknown>;
            const result = await callable({
                auth: { uid: "userA", token: {} },
                data: { matchId: "userA_userB" },
            } as never);

            expect(result).toEqual({ success: true });
            expect(mockDb.runTransaction).toHaveBeenCalledTimes(1);
            expect(harness.operationOrder.slice(0, 2)).toEqual([
                "get:match",
                "get:finderQuery",
            ]);
            expect(harness.transactionUpdate).toHaveBeenNthCalledWith(
                1,
                harness.matchRef,
                {
                    status: "found",
                    isFound: true,
                    foundAt: "SERVER_TIMESTAMP",
                    finderOptIn: "DELETE_FIELD",
                },
            );
            expect(harness.transactionDelete.mock.calls.map(([ref]) => ref)).toEqual(
                harness.finderRefs,
            );
            expect(harness.transactionUpdate).toHaveBeenNthCalledWith(
                2,
                harness.userRef,
                { lastWaveFoundAt: "SERVER_TIMESTAMP" },
            );
            expect(harness.committedWrites).toHaveLength(5);
            expect(harness.directMatchUpdate).not.toHaveBeenCalled();
            expect(harness.directBatch.commit).not.toHaveBeenCalled();
            expect(harness.directUserUpdate).not.toHaveBeenCalled();
        });

        it("commits none of status, purge, or cooldown when the transaction fails", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const validate = await import("../../src/middleware/validate");
            const { markMatchFound } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("userA");
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("userA_userB");
            const transactionFailure = new Error("transaction commit failed");
            const harness = setupMarkFoundDb({ transactionFailure });

            const callable = markMatchFound as unknown as (r: unknown) => Promise<unknown>;
            await expect(callable({
                auth: { uid: "userA", token: {} },
                data: { matchId: "userA_userB" },
            } as never)).rejects.toBe(transactionFailure);

            expect(harness.queuedWrites).toHaveLength(5);
            expect(harness.committedWrites).toEqual([]);
            expect(harness.directMatchUpdate).not.toHaveBeenCalled();
            expect(harness.directBatch.commit).not.toHaveBeenCalled();
            expect(harness.directUserUpdate).not.toHaveBeenCalled();
        });

        it("queues no transaction writes for a non-participant", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const validate = await import("../../src/middleware/validate");
            const { markMatchFound } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("intruder");
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("userA_userB");
            const harness = setupMarkFoundDb({ participant: false });

            const callable = markMatchFound as unknown as (r: unknown) => Promise<unknown>;
            await expect(callable({
                auth: { uid: "intruder", token: {} },
                data: { matchId: "userA_userB" },
            } as never)).rejects.toMatchObject({ code: "permission-denied" });

            expect(mockDb.runTransaction).toHaveBeenCalledTimes(1);
            expect(harness.transactionGet).toHaveBeenCalledTimes(1);
            expect(harness.queuedWrites).toEqual([]);
            expect(harness.committedWrites).toEqual([]);
            expect(harness.directMatchUpdate).not.toHaveBeenCalled();
            expect(harness.directUserUpdate).not.toHaveBeenCalled();
        });

        it("still purges finder data when an already-found call is retried", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const validate = await import("../../src/middleware/validate");
            const { markMatchFound } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("userA");
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("userA_userB");
            const harness = setupMarkFoundDb({ status: "found" });

            const callable = markMatchFound as unknown as (r: unknown) => Promise<unknown>;
            await expect(callable({
                auth: { uid: "userA", token: {} },
                data: { matchId: "userA_userB" },
            } as never)).resolves.toEqual({ success: true });

            expect(harness.transactionDelete.mock.calls.map(([ref]) => ref)).toEqual(
                harness.finderRefs,
            );
            expect(harness.transactionUpdate).toHaveBeenNthCalledWith(
                1,
                harness.matchRef,
                expect.objectContaining({ finderOptIn: "DELETE_FIELD" }),
            );
            expect(harness.committedWrites).toHaveLength(5);
        });

        it("rejects with not-found when the match document does not exist", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const validate = await import("../../src/middleware/validate");
            const { markMatchFound } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("userA");
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("userA_userB");
            const harness = setupMarkFoundDb({ exists: false });

            const callable = markMatchFound as unknown as (r: unknown) => Promise<unknown>;
            await expect(callable({
                auth: { uid: "userA", token: {} },
                data: { matchId: "userA_userB" },
            } as never)).rejects.toMatchObject({ code: "not-found" });

            expect(harness.transactionGet).toHaveBeenCalledTimes(1);
            expect(harness.queuedWrites).toEqual([]);
            expect(harness.committedWrites).toEqual([]);
        });
    });

    describe("sendMatchGesture", () => {
        it("sets the caller's gesture flag when a participant", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const validate = await import("../../src/middleware/validate");
            const { sendMatchGesture } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("userB");
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("userA_userB");

            const matchUpdate = jest.fn(async () => undefined);
            const matchGet = jest.fn(async () => ({
                exists: true,
                data: () => ({ userIds: ["userA", "userB"] }),
            }));

            mockDb.collection.mockImplementation((name: unknown) => {
                if (name === "matches") {
                    return { doc: jest.fn(() => ({ get: matchGet, update: matchUpdate })) };
                }
                throw new Error(`Unexpected collection: ${String(name)}`);
            });

            const callable = sendMatchGesture as unknown as (r: unknown) => Promise<unknown>;
            const result = await callable({
                auth: { uid: "userB", token: {} },
                data: { matchId: "userA_userB" },
            } as never);

            expect(result).toMatchObject({ success: true });
            expect(matchUpdate).toHaveBeenCalledWith(expect.objectContaining({
                "gestures.userB": true,
                lastUpdatedAt: "SERVER_TIMESTAMP",
            }));
        });

        it("rejects a non-participant with permission-denied and writes nothing", async () => {
            const authGuard = await import("../../src/middleware/authGuard");
            const validate = await import("../../src/middleware/validate");
            const { sendMatchGesture } = await import("../../src/modules/matches/matches.functions");

            jest.mocked(authGuard.requireAuth).mockReturnValue("intruder");
            jest.mocked(validate.assertValidDocumentId).mockReturnValue("userA_userB");

            const matchUpdate = jest.fn();
            const matchGet = jest.fn(async () => ({
                exists: true,
                data: () => ({ userIds: ["userA", "userB"] }),
            }));

            mockDb.collection.mockImplementation((name: unknown) => {
                if (name === "matches") {
                    return { doc: jest.fn(() => ({ get: matchGet, update: matchUpdate })) };
                }
                throw new Error(`Unexpected collection: ${String(name)}`);
            });

            const callable = sendMatchGesture as unknown as (r: unknown) => Promise<unknown>;
            await expect(callable({
                auth: { uid: "intruder", token: {} },
                data: { matchId: "userA_userB" },
            } as never)).rejects.toMatchObject({ code: "permission-denied" });

            expect(matchUpdate).not.toHaveBeenCalled();
        });
    });
});
