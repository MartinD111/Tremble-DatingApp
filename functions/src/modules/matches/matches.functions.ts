/**
 * Tremble — Match Functions
 *
 * Interaction System v2.1:
 * - onWaveCreated handles INCOMING_WAVE (Rich Push: name + photo)
 *   and MUTUAL_WAVE (Match with deep link to /radar).
 * - No chat, no messages. Wave = one tap. Meet = in real life.
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging, Message } from "firebase-admin/messaging";
import { randomUUID } from "node:crypto";
import { requireAuth, requireAdmin, assertNotBanned } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { apnsExpirationHeaders, NOTIFICATION_TTL_MILLIS } from "../../core/notification_expiry";
import { assertValidDocumentId } from "../../middleware/validate";
import { sendMatchNotificationEmail } from "../email/email.functions";
import { getRedis, waveDedupKey, WAVE_DEDUP_SECS } from "../../core/redis";
import { ENFORCE_APP_CHECK } from "../../config/env";

const db = getFirestore();

function logStructured(fields: Record<string, unknown>): void {
    console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        ...fields,
    }));
}

function errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
}

function redactUid(uid: string): string {
    return `${uid.substring(0, 8)}...`;
}

const MUTUAL_WAVE_FREE_LIMIT = 5;
const MUTUAL_WAVE_PREMIUM_LIMIT = 20;
const MUTUAL_WAVE_COUNTER_TIME_ZONE = "Europe/Ljubljana";
const WAVE_DELIVERY_TTL_SECS = 24 * 60 * 60;
const WAVE_PROCESSING_TTL_SECS = 60;
const MAX_DELIVERY_ATTEMPTS = 3;

type DeliveryOutcome = {
    status: "accepted" | "terminal" | "failed";
    error?: unknown;
};

function waveDeliveryKey(waveId: string, suffix: string): string {
    return `wave-delivery:${waveId}:${suffix}`;
}

function deliveryErrorCode(error: unknown): string {
    if (error && typeof error === "object" && "code" in error) {
        const code = (error as { code?: unknown }).code;
        if (typeof code === "string" && code.trim() !== "") return code;
    }
    return "unknown";
}

function isPermanentDeliveryError(errorCode: string): boolean {
    return new Set([
        "messaging/invalid-argument",
        "messaging/invalid-recipient",
        "messaging/invalid-registration-token",
        "messaging/registration-token-not-registered",
        "messaging/invalid-package-name",
        "messaging/mismatched-credential",
        "messaging/authentication-error",
        "messaging/invalid-apns-credentials",
        "messaging/third-party-auth-error",
    ]).has(errorCode);
}

function birthDateValue(value: unknown): Date | null {
    if (typeof value === "string") {
        const dateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
        const dateTime = /^(\d{4})-(\d{2})-(\d{2})T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,9})?(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$/.exec(value);
        const components = dateOnly ?? dateTime;
        if (!components) return null;
        const year = Number(components[1]);
        const month = Number(components[2]);
        const day = Number(components[3]);
        const calendarCheck = new Date(Date.UTC(year, month - 1, day));
        if (
            calendarCheck.getUTCFullYear() !== year
            || calendarCheck.getUTCMonth() !== month - 1
            || calendarCheck.getUTCDate() !== day
        ) {
            return null;
        }
        if (dateOnly) return new Date(year, month - 1, day);
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }
    if (value && typeof value === "object" && "toDate" in value) {
        const toDate = (value as { toDate?: unknown }).toDate;
        if (typeof toDate === "function") {
            const parsed = toDate.call(value);
            return parsed instanceof Date && !Number.isNaN(parsed.getTime()) ? parsed : null;
        }
    }
    return null;
}

function notificationIdentity(userData: FirebaseFirestore.DocumentData | undefined): {
    name: string;
    age: number;
    photoUrl: string;
} {
    const canonicalName = typeof userData?.name === "string" && userData.name.trim() !== ""
        ? userData.name.trim()
        : "Someone";
    const numericAge = userData?.age;
    let age = typeof numericAge === "number" && Number.isFinite(numericAge) && numericAge >= 0
        ? Math.floor(numericAge)
        : 0;
    if (age === 0) {
        const dob = birthDateValue(userData?.birthDate);
        if (dob) {
            const today = new Date();
            age = today.getFullYear() - dob.getFullYear();
            const monthDelta = today.getMonth() - dob.getMonth();
            if (monthDelta < 0 || (monthDelta === 0 && today.getDate() < dob.getDate())) age--;
            if (age < 0) age = 0;
        }
    }
    const photoUrl = Array.isArray(userData?.photoUrls)
        && typeof userData.photoUrls[0] === "string"
        ? userData.photoUrls[0]
        : "";
    return { name: canonicalName, age, photoUrl };
}

export function mutualWaveCounterField(now = new Date()): string {
    const parts = new Intl.DateTimeFormat("en-CA", {
        timeZone: MUTUAL_WAVE_COUNTER_TIME_ZONE,
        year: "numeric",
        month: "2-digit",
    }).formatToParts(now);

    const year = parts.find((part) => part.type === "year")?.value;
    const month = parts.find((part) => part.type === "month")?.value;

    if (!year || !month) {
        throw new Error("Failed to compute mutual wave counter month");
    }

    return `mutualWaves_${year}_${month}`;
}

export function mutualWaveLimitForUser(userData: FirebaseFirestore.DocumentData | undefined): number {
    return userData?.isPremium === true
        ? MUTUAL_WAVE_PREMIUM_LIMIT
        : MUTUAL_WAVE_FREE_LIMIT;
}

export function mutualWaveCountForUser(
    userData: FirebaseFirestore.DocumentData | undefined,
    counterField: string
): number {
    const value = userData?.[counterField];
    return typeof value === "number" ? value : 0;
}

async function releaseProcessingClaim(
    redis: ReturnType<typeof getRedis>,
    processingKey: string,
    owner: string,
): Promise<void> {
    await redis.eval(
        "if redis.call('get', KEYS[1]) == ARGV[1] then "
            + "return redis.call('del', KEYS[1]) else return 0 end",
        [processingKey],
        [owner],
    );
}

async function transitionProcessingClaim(
    redis: ReturnType<typeof getRedis>,
    processingKey: string,
    owner: string,
    terminalState: string,
): Promise<void> {
    await redis.eval(
        "if redis.call('get', KEYS[1]) == ARGV[1] then "
            + "redis.call('set', KEYS[1], ARGV[2], 'EX', ARGV[3]); return 1 "
            + "else return 0 end",
        [processingKey],
        [owner, terminalState, WAVE_DEDUP_SECS.toString()],
    );
}

async function deliverWaveNotification(options: {
    redis: ReturnType<typeof getRedis>;
    waveId: string;
    recipientUid: string;
    message: Message;
    deliveryType: "incoming_wave" | "mutual_wave";
}): Promise<DeliveryOutcome> {
    const { redis, waveId, recipientUid, message, deliveryType } = options;
    const startedAt = Date.now();
    const recipientUidRedacted = redactUid(recipientUid);
    const recipientBase = waveDeliveryKey(waveId, `recipient:${recipientUid}`);
    const deliveredKey = `${recipientBase}:delivered`;
    const noTokenKey = `${recipientBase}:no-token`;
    const permanentFailureKey = `${recipientBase}:permanent-failure`;
    const attemptsKey = `${recipientBase}:attempts`;

    if (await redis.get(deliveredKey)) {
        logStructured({
            fn: "onWaveCreated",
            event: "dedup_skip",
            waveId,
            recipientUid: recipientUidRedacted,
            reason: "delivered",
            durationMs: Date.now() - startedAt,
        });
        return { status: "accepted" };
    }
    if (await redis.get(noTokenKey)) {
        logStructured({
            fn: "onWaveCreated",
            event: "dedup_skip",
            waveId,
            recipientUid: recipientUidRedacted,
            reason: "no_token",
            durationMs: Date.now() - startedAt,
        });
        return { status: "terminal" };
    }
    if (await redis.get(permanentFailureKey)) {
        logStructured({
            fn: "onWaveCreated",
            event: "dedup_skip",
            waveId,
            recipientUid: recipientUidRedacted,
            reason: "permanent_failure",
            durationMs: Date.now() - startedAt,
        });
        return { status: "terminal" };
    }
    if (!("token" in message) || typeof message.token !== "string" || message.token.trim() === "") {
        await redis.set(noTokenKey, "1", { ex: WAVE_DELIVERY_TTL_SECS });
        logStructured({
            fn: "onWaveCreated",
            event: "no_token",
            waveId,
            recipientUid: recipientUidRedacted,
            retryDisposition: "permanent",
            durationMs: Date.now() - startedAt,
        });
        return { status: "terminal" };
    }

    const attempt = await redis.incr(attemptsKey);
    if (attempt === 1) await redis.expire(attemptsKey, WAVE_DELIVERY_TTL_SECS);
    if (attempt > MAX_DELIVERY_ATTEMPTS) {
        logStructured({
            fn: "onWaveCreated",
            event: "dedup_skip",
            waveId,
            recipientUid: recipientUidRedacted,
            reason: "retry_exhausted",
            durationMs: Date.now() - startedAt,
        });
        return { status: "terminal" };
    }

    try {
        await getMessaging().send(message);
        await redis.set(deliveredKey, "1", { ex: WAVE_DELIVERY_TTL_SECS });
        logStructured({
            fn: "onWaveCreated",
            event: "delivery_success",
            waveId,
            recipientUid: recipientUidRedacted,
            deliveryType,
            attempt,
            durationMs: Date.now() - startedAt,
        });
        return { status: "accepted" };
    } catch (error) {
        const errorCode = deliveryErrorCode(error);
        const permanent = isPermanentDeliveryError(errorCode);
        if (permanent) {
            await redis.set(permanentFailureKey, "1", { ex: WAVE_DELIVERY_TTL_SECS });
        }
        const shouldRetry = !permanent && attempt < MAX_DELIVERY_ATTEMPTS;
        logStructured({
            fn: "onWaveCreated",
            event: "delivery_error",
            waveId,
            recipientUid: recipientUidRedacted,
            deliveryType,
            attempt,
            errorCode,
            retryDisposition: permanent ? "permanent" : shouldRetry ? "retry" : "exhausted",
            durationMs: Date.now() - startedAt,
        });
        return shouldRetry
            ? { status: "failed", error }
            : { status: "terminal" };
    }
}

/**
 * sendWave — Callable: wave submission with a soft DoS guard.
 * Writes to waves/ collection which triggers onWaveCreated.
 */
export const sendWave = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        const startedAt = Date.now();
        logStructured({ fn: "sendWave", event: "entry", uid: redactUid(uid) });

        try {
        const targetUid = assertValidDocumentId(request.data?.targetUid, "targetUid");
        if (uid === targetUid) {
            throw new HttpsError("invalid-argument", "Cannot wave at yourself");
        }

        // Read profile for ban status; sent waves are not product-limited.
        const userDoc = await db.collection("users").doc(uid).get();
        const userData = userDoc.data();

        assertNotBanned(userData);

        const targetDoc = await db.collection("users").doc(targetUid).get();
        if (!targetDoc.exists) {
            throw new HttpsError("not-found", "User not found.");
        }

        const targetData = targetDoc.data();
        assertNotBanned(targetData);

        const targetBlockedIds: string[] = targetData?.blockedUserIds ?? [];
        if (targetBlockedIds.includes(uid)) {
            throw new HttpsError("permission-denied", "Cannot wave at this user.");
        }

        // Soft DoS guard only. This is not the product mutual-wave entitlement.
        await checkRateLimit(uid, "sendWave_dos", {
            maxRequests: 100,
            windowMs: 24 * 60 * 60 * 1000,
        });

        await db.collection("waves").add({
            fromUid: uid,
            toUid: targetUid,
            createdAt: FieldValue.serverTimestamp(),
            expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        });

        logStructured({
            fn: "sendWave",
            event: "success",
            uid: redactUid(uid),
            targetUid: redactUid(targetUid),
            durationMs: Date.now() - startedAt,
        });
        return { success: true };
        } catch (error) {
            logStructured({
                fn: "sendWave",
                event: "error",
                uid: redactUid(uid),
                error: errorMessage(error),
                durationMs: Date.now() - startedAt,
            });
            throw error;
        }
    }
);

/**
 * Load a match document and assert the caller participates in it.
 *
 * The /matches collection is backend-authoritative: firestore.rules only lets
 * a client change `seenBy`. Every other match-state mutation goes through a
 * callable so the participant check runs server-side with the Admin SDK.
 */
async function loadParticipantMatch(matchId: string, uid: string) {
    const matchRef = db.collection("matches").doc(matchId);
    const snapshot = await matchRef.get();
    if (!snapshot.exists) {
        throw new HttpsError("not-found", "Match not found.");
    }
    const userIds = (snapshot.data()?.userIds as string[] | undefined) ?? [];
    if (!userIds.includes(uid)) {
        throw new HttpsError("permission-denied", "Not a participant in this match.");
    }
    return matchRef;
}

/**
 * markMatchFound — participant ends the trembling window ("we found each
 * other"). Sets the match to found and stamps the caller's `lastWaveFoundAt`
 * so the 30-minute free-tier cooldown applies. Idempotent.
 */
export const markMatchFound = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        const startedAt = Date.now();
        logStructured({ fn: "markMatchFound", event: "entry", uid: redactUid(uid) });

        try {
            const matchId = assertValidDocumentId(request.data?.matchId, "matchId");
            const matchRef = await loadParticipantMatch(matchId, uid);

            await matchRef.update({
                status: "found",
                isFound: true,
                foundAt: FieldValue.serverTimestamp(),
            });
            await db.collection("users").doc(uid).update({
                lastWaveFoundAt: FieldValue.serverTimestamp(),
            });

            logStructured({
                fn: "markMatchFound",
                event: "success",
                uid: redactUid(uid),
                durationMs: Date.now() - startedAt,
            });
            return { success: true };
        } catch (error) {
            logStructured({
                fn: "markMatchFound",
                event: "error",
                uid: redactUid(uid),
                error: errorMessage(error),
                durationMs: Date.now() - startedAt,
            });
            throw error;
        }
    }
);

/**
 * sendMatchGesture — participant performs a Greet/Accept gesture on the match.
 * Writes only the caller's own gesture flag.
 */
export const sendMatchGesture = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        const startedAt = Date.now();
        logStructured({ fn: "sendMatchGesture", event: "entry", uid: redactUid(uid) });

        try {
            const matchId = assertValidDocumentId(request.data?.matchId, "matchId");
            const matchRef = await loadParticipantMatch(matchId, uid);

            await matchRef.update({
                [`gestures.${uid}`]: true,
                lastUpdatedAt: FieldValue.serverTimestamp(),
            });

            logStructured({
                fn: "sendMatchGesture",
                event: "success",
                uid: redactUid(uid),
                durationMs: Date.now() - startedAt,
            });
            return { success: true };
        } catch (error) {
            logStructured({
                fn: "sendMatchGesture",
                event: "error",
                uid: redactUid(uid),
                error: errorMessage(error),
                durationMs: Date.now() - startedAt,
            });
            throw error;
        }
    }
);

/**
 * onWaveCreated — Firestore trigger on waves/{waveId}
 *
 * Two states:
 *
 * 1. INCOMING_WAVE (first wave from A → B):
 *    Sends Rich Push to B with sender's name and photoUrl.
 *    iOS: category "WAVE_CATEGORY" enables "Pomahaj nazaj" action button.
 *    No text, no message. One wave. That's it.
 *
 * 2. MUTUAL_WAVE (B already waved to A, now A waves back):
 *    Creates match document. Sends "Odpremo radar?" notification to both
 *    with deep link payload {type: MUTUAL_WAVE, path: /radar, matchId}.
 */
export const onWaveCreated = onDocumentCreated(
    { document: "waves/{waveId}", region: "europe-west1", retry: true },
    async (event) => {
        const startedAt = Date.now();
        const waveId = event.params.waveId;
        const redis = getRedis();
        const processingKey = waveDeliveryKey(waveId, "processing");
        const processingOwner = randomUUID();
        const claimed = await redis.set(processingKey, processingOwner, {
            ex: WAVE_PROCESSING_TTL_SECS,
            nx: true,
        });
        if (claimed === null) {
            logStructured({
                fn: "onWaveCreated",
                event: "dedup_skip",
                waveId,
                reason: "processing",
                durationMs: Date.now() - startedAt,
            });
            return;
        }
        let directionalClaim: { key: string; owner: string } | null = null;

        try {
        const snapshot = event.data;
        if (!snapshot) return;

        const waveData = snapshot.data();
        const fromUid = waveData.fromUid as string;
        const toUid = waveData.toUid as string;

        if (!fromUid || !toUid) return;
        const redactedFromUid = redactUid(fromUid);
        const redactedToUid = redactUid(toUid);

        const dedupKey = waveDedupKey(fromUid, toUid);
        const directionalOwner = `processing:${waveId}:${processingOwner}`;
        const directionalClaimed = await redis.set(dedupKey, directionalOwner, {
            ex: WAVE_DEDUP_SECS,
            nx: true,
        });
        if (directionalClaimed === null) {
            logStructured({
                fn: "onWaveCreated",
                event: "dedup_skip",
                waveId,
                senderUid: redactedFromUid,
                recipientUid: redactedToUid,
                reason: "pair_cooldown",
                durationMs: Date.now() - startedAt,
            });
            return;
        }
        directionalClaim = { key: dedupKey, owner: directionalOwner };

        // Fetch both user profiles upfront (needed for both branches)
        const [senderDoc, receiverDoc] = await Promise.all([
            db.collection("users").doc(fromUid).get(),
            db.collection("users").doc(toUid).get(),
        ]);

        const senderIdentity = notificationIdentity(senderDoc.data());
        const receiverIdentity = notificationIdentity(receiverDoc.data());
        const senderName = senderIdentity.name;
        const senderPhoto = senderIdentity.photoUrl;
        const receiverName = receiverIdentity.name;
        const receiverPhoto = receiverIdentity.photoUrl;
        const receiverToken = receiverDoc.data()?.fcmToken as string | undefined;
        const senderToken = senderDoc.data()?.fcmToken as string | undefined;
        const senderAge = senderIdentity.age;

        // Check for reciprocal wave (mutual match)
        const reciprocalQuery = await db
            .collection("waves")
            .where("fromUid", "==", toUid)
            .where("toUid", "==", fromUid)
            .limit(1)
            .get();

        const branchKey = waveDeliveryKey(waveId, "branch");
        let branch = await redis.get<"incoming" | "mutual">(branchKey);
        if (!branch) {
            const detectedBranch = reciprocalQuery.empty ? "incoming" : "mutual";
            await redis.set(branchKey, detectedBranch, {
                ex: WAVE_DELIVERY_TTL_SECS,
                nx: true,
            });
            branch = await redis.get<"incoming" | "mutual">(branchKey) ?? detectedBranch;
        }

        if (branch === "mutual") {
            // ── MUTUAL_WAVE: Create match + notify both ───

            const uids = [fromUid, toUid].sort();
            const matchId = `${uids[0]}_${uids[1]}`;

            const userARef = db.collection("users").doc(uids[0]);
            const userBRef = db.collection("users").doc(uids[1]);
            const matchRef = db.collection("matches").doc(matchId);
            const reciprocalWaveRef = reciprocalQuery.docs[0]?.ref;
            const counterField = mutualWaveCounterField();

            const ownsNotifications = await db.runTransaction(async (transaction) => {
                const [matchDoc, userADoc, userBDoc] = await Promise.all([
                    transaction.get(matchRef),
                    transaction.get(userARef),
                    transaction.get(userBRef),
                ]);

                if (matchDoc.exists) {
                    const existing = matchDoc.data();
                    // This exact wave already owns the current window (a
                    // reprocess of the same event) — re-notify, don't restart.
                    if (existing?.notificationOwnerWaveId === waveId) {
                        transaction.delete(snapshot.ref);
                        return true;
                    }
                    // Only restart when the previous window is POSITIVELY over:
                    // a terminal status, or a known createdAt older than the
                    // 30-min window. Unknown state (no status/createdAt) is
                    // treated as in-flight — including the reciprocal wave of
                    // the same mutual burst — and must NOT reset or re-notify.
                    const status = existing?.status;
                    const createdAtMs =
                        existing?.createdAt?.toDate?.()?.getTime?.();
                    const expired =
                        createdAtMs !== undefined &&
                        Date.now() - createdAtMs > 30 * 60 * 1000;
                    const windowOver =
                        status === "found" || status === "expired" || expired;
                    if (!windowOver) {
                        transaction.delete(snapshot.ref);
                        return false;
                    }
                    // Genuine re-engagement: restart the trembling window for
                    // BOTH users (seenBy cleared → both get the reveal again)
                    // and claim notification ownership for this wave.
                    transaction.update(matchRef, {
                        createdAt: FieldValue.serverTimestamp(),
                        expiresAt: new Date(Date.now() + 30 * 60 * 1000),
                        status: "pending",
                        seenBy: [],
                        isFound: FieldValue.delete(),
                        foundAt: FieldValue.delete(),
                        notificationOwnerWaveId: waveId,
                    });
                    transaction.delete(snapshot.ref);
                    if (reciprocalWaveRef) transaction.delete(reciprocalWaveRef);
                    return true;
                }

                const userAData = userADoc.data();
                const userBData = userBDoc.data();

                const userACount = mutualWaveCountForUser(userAData, counterField);
                const userBCount = mutualWaveCountForUser(userBData, counterField);
                const userALimit = mutualWaveLimitForUser(userAData);
                const userBLimit = mutualWaveLimitForUser(userBData);

                if (userACount >= userALimit || userBCount >= userBLimit) {
                    throw new HttpsError(
                        "resource-exhausted",
                        "Monthly mutual wave limit reached."
                    );
                }

                const userAEvent = userAData?.activeEventId;
                const userBEvent = userBData?.activeEventId;
                const userAGym = userAData?.activeGymId;
                const userBGym = userBData?.activeGymId;

                let matchType = "standard";
                let matchContext: Record<string, unknown> | null = null;

                if (userAEvent && userBEvent && userAEvent === userBEvent) {
                    matchType = "event";
                    matchContext = { eventId: userAEvent };
                } else if (userAGym && userBGym && userAGym === userBGym) {
                    matchType = "gym";
                    matchContext = { gymId: userAGym };
                }

                transaction.set(matchRef, {
                    userA: uids[0],
                    userB: uids[1],
                    userIds: uids,
                    matchType,
                    matchContext,
                    // A mutual proximity wave IS the mutual gesture — seed both
                    // sides so `hasMutualWave` (ADR-007 §1) is true immediately.
                    // Without this the pair renders greyscale (nonMutual) in
                    // history until each user separately calls sendMatchGesture.
                    // Free users still only get the colour basic card (mutualFree
                    // → upsell); the premium full-card gate is unchanged.
                    gestures: { [uids[0]]: true, [uids[1]]: true },
                    createdAt: FieldValue.serverTimestamp(),
                    expiresAt: new Date(Date.now() + 30 * 60 * 1000),
                    status: "pending",
                    // Both users must get the "We have a match" reveal. Do NOT
                    // pre-mark the sender (the wave-back completer) as seen, or
                    // their reveal listener never fires (TREMBLE asymmetry bug).
                    seenBy: [],
                    notificationOwnerWaveId: waveId,
                });

                transaction.update(userARef, {
                    [counterField]: FieldValue.increment(1),
                });

                transaction.update(userBRef, {
                    [counterField]: FieldValue.increment(1),
                });

                transaction.delete(snapshot.ref);
                if (reciprocalWaveRef) transaction.delete(reciprocalWaveRef);
                return true;
            });

            if (!ownsNotifications) {
                await transitionProcessingClaim(
                    redis,
                    dedupKey,
                    directionalOwner,
                    `terminal:${waveId}`,
                );
                directionalClaim = null;
                logStructured({
                    fn: "onWaveCreated",
                    event: "dedup_skip",
                    waveId,
                    senderUid: redactedFromUid,
                    recipientUid: redactedToUid,
                    reason: "mutual_non_owner",
                    durationMs: Date.now() - startedAt,
                });
                return;
            }

            // Send "Odpremo radar?" to both users
            const notifications: Array<{
                recipientUid: string;
                promise: Promise<DeliveryOutcome>;
            }> = [
                {
                    recipientUid: toUid,
                    promise: deliverWaveNotification({
                        redis,
                        waveId,
                        recipientUid: toUid,
                        deliveryType: "mutual_wave",
                        message: {
                            token: receiverToken ?? "",
                            notification: {
                                title: `${senderName} ti je pomahal-a nazaj!`,
                                body: "Odpremo radar?",
                                imageUrl: senderPhoto || undefined,
                            },
                            data: {
                                type: "MUTUAL_WAVE",
                                waveId,
                                matchId,
                                path: "/radar",
                            },
                            apns: {
                                payload: {
                                    aps: {
                                        contentAvailable: true,
                                        sound: "default",
                                        "mutable-content": 1,
                                    },
                                },
                            },
                            android: { priority: "high" },
                        },
                    }),
                },
                {
                    recipientUid: fromUid,
                    promise: deliverWaveNotification({
                        redis,
                        waveId,
                        recipientUid: fromUid,
                        deliveryType: "mutual_wave",
                        message: {
                            token: senderToken ?? "",
                            notification: {
                                title: `${receiverName} ti je pomahal-a nazaj!`,
                                body: "Odpremo radar?",
                                imageUrl: receiverPhoto || undefined,
                            },
                            data: {
                                type: "MUTUAL_WAVE",
                                waveId,
                                matchId,
                                path: "/radar",
                            },
                            apns: {
                                payload: {
                                    aps: {
                                        contentAvailable: true,
                                        sound: "default",
                                        "mutable-content": 1,
                                    },
                                },
                            },
                            android: { priority: "high" },
                        },
                    }),
                },
            ];

            const notificationResults = await Promise.allSettled(
                notifications.map((notification) => notification.promise)
            );
            let retryError: unknown;
            let hasTerminalOutcome = false;
            for (let index = 0; index < notificationResults.length; index++) {
                const result = notificationResults[index];
                if (result.status === "rejected") {
                    retryError ??= result.reason;
                    logStructured({
                        fn: "onWaveCreated",
                        event: "delivery_error",
                        waveId,
                        recipientUid: redactUid(notifications[index].recipientUid),
                        errorCode: deliveryErrorCode(result.reason),
                        retryDisposition: "retry",
                        durationMs: Date.now() - startedAt,
                    });
                } else if (result.value.status === "failed") {
                    retryError ??= result.value.error;
                } else if (result.value.status === "terminal") {
                    hasTerminalOutcome = true;
                }
            }
            if (retryError) throw retryError;
            await transitionProcessingClaim(
                redis,
                dedupKey,
                directionalOwner,
                hasTerminalOutcome ? `terminal:${waveId}` : `delivered:${waveId}`,
            );
            directionalClaim = null;

            // Also send match email (fire-and-forget)
            const senderEmail = senderDoc.data()?.email as string | undefined;
            const receiverEmail = receiverDoc.data()?.email as string | undefined;
            if (senderEmail && receiverName) sendMatchNotificationEmail(senderEmail, receiverName).catch(() => null);
            if (receiverEmail && senderName) sendMatchNotificationEmail(receiverEmail, senderName).catch(() => null);

        } else {
            // ── INCOMING_WAVE: Rich Push to receiver ──────
            const recipientData = receiverDoc.data();
            const isSilent = recipientData?.isRunModeActive === true
                || !!recipientData?.activeGymId
                || !!recipientData?.activeEventId;
            const data = {
                type: "INCOMING_WAVE",
                waveId,
                senderId: fromUid,
                senderName,
                senderAge: senderAge.toString(),
                senderPhotoUrl: senderPhoto,
            };
            const message: Message = isSilent
                ? {
                    token: receiverToken ?? "",
                    data,
                    apns: {
                        headers: apnsExpirationHeaders(),
                        payload: { aps: { contentAvailable: true } },
                    },
                    android: { priority: "high", ttl: NOTIFICATION_TTL_MILLIS },
                }
                : {
                    token: receiverToken ?? "",
                    notification: {
                        title: `${senderName} waved`,
                        body: "Wave back?",
                        imageUrl: senderPhoto || undefined,
                    },
                    data,
                    apns: {
                        headers: apnsExpirationHeaders(),
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
                        ttl: NOTIFICATION_TTL_MILLIS,
                        notification: {
                            channelId: "tremble_wave",
                            sound: "default",
                        },
                    },
                };
            const result = await deliverWaveNotification({
                redis,
                waveId,
                recipientUid: toUid,
                message,
                deliveryType: "incoming_wave",
            });
            if (result.status === "failed") throw result.error;
            await transitionProcessingClaim(
                redis,
                dedupKey,
                directionalOwner,
                result.status === "terminal" ? `terminal:${waveId}` : `delivered:${waveId}`,
            );
            directionalClaim = null;
        }
        } catch (error) {
            if (directionalClaim) {
                try {
                    await releaseProcessingClaim(
                        redis,
                        directionalClaim.key,
                        directionalClaim.owner,
                    );
                } catch {
                    // Directional processing state has a bounded TTL.
                }
            }
            throw error;
        } finally {
            try {
                await releaseProcessingClaim(redis, processingKey, processingOwner);
            } catch {
                // The ownership lease expires quickly; never mask the delivery result.
            }
        }
    }
);

export const getMatches = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "getMatches", { maxRequests: 30, windowMs: 60000 });
        const userDoc = await db.collection("users").doc(uid).get();
        const blockedUsers = userDoc.data()?.blockedUserIds || [];

        const matchesQuery = await db
            .collection("matches")
            .where("userIds", "array-contains", uid)
            .orderBy("createdAt", "desc")
            .limit(50)
            .get();

        const matchEntries = matchesQuery.docs
            .map((doc) => {
                const matchData = doc.data();
                const partnerId = matchData.userA === uid ? matchData.userB : matchData.userA;

                if (blockedUsers.includes(partnerId)) return null;

                return {
                    matchData,
                    partnerId,
                    partnerRef: db.collection("users").doc(partnerId),
                };
            })
            .filter((entry): entry is NonNullable<typeof entry> => entry !== null);

        const partnerDocs = matchEntries.length
            ? await db.getAll(...matchEntries.map((entry) => entry.partnerRef))
            : [];

        const profiles = partnerDocs.map((profileDoc, index) => {
            const { matchData, partnerId } = matchEntries[index];

            if (!profileDoc.exists) return null;
            const pData = profileDoc.data()!;

            // ADR-007 §1 — mutual-wave predicate. `gestures` is a
            // client-written map on the match doc (`{uid: true}`);
            // mutual = both userIds have waved. Clients that predate
            // this field render everything as non-mutual, which is
            // the safe default.
            const gestures = (matchData.gestures as Record<string, boolean> | undefined) ?? {};
            const hasMutualWave = Object.keys(gestures).length >= 2;

            return {
                id: partnerId,
                name: pData.name,
                age: pData.age,
                photoUrls: pData.photoUrls ?? [],
                hobbies: pData.hobbies ?? [],
                lookingFor: pData.lookingFor ?? [],
                // F3 — match categorisation fields from the match document
                matchType: (matchData.matchType as string | undefined) ?? "standard",
                matchContext: (matchData.matchContext as Record<string, unknown> | undefined) ?? null,
                matchedAt: matchData.createdAt != null
                    ? (matchData.createdAt as FirebaseFirestore.Timestamp).toDate().toISOString()
                    : null,
                isTraveler: (pData.isTraveler as boolean | undefined) ?? false,
                hasMutualWave,
            };
        });

        return { matches: profiles.filter(Boolean) };
    }
);

export const migrateMatchTypes = onCall(
    { maxInstances: 10, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAdmin(request);
        await checkRateLimit(uid, "migrateMatchTypes", { maxRequests: 5, windowMs: 60000 });

        const matchesSnapshot = await db.collection("matches").get();
        let updatedCount = 0;

        let batch = db.batch();
        let batchCount = 0;

        for (const doc of matchesSnapshot.docs) {
            const data = doc.data();
            if (!data.matchType) {
                batch.update(doc.ref, {
                    matchType: "standard",
                    matchContext: null,
                });
                updatedCount++;
                batchCount++;

                if (batchCount === 490) {
                    await batch.commit();
                    batch = db.batch();
                    batchCount = 0;
                }
            }
        }

        if (batchCount > 0) {
            await batch.commit();
        }

        console.log(`[MIGRATION] migrateMatchTypes: admin ${uid.substring(0, 8)}... updated ${updatedCount} matches`);
        return { success: true, updatedCount };
    }
);

/**
 * backfillMatchGestures — one-shot admin migration.
 *
 * Matches created before the mutual-wave gestures seed (Session 52) have no
 * `gestures` map, so `hasMutualWave` is false and a genuine matched pair renders
 * greyscale (nonMutual) in history. This seeds `gestures.{uidA}=true` +
 * `gestures.{uidB}=true` on existing mutual matches so they show in colour.
 *
 * Near-miss ('activity') encounters are NOT mutual matches — skipped, their gate
 * is left untouched. Idempotent: already-mutual docs (>=2 gestures) are skipped,
 * and dot-path updates merge rather than overwrite.
 */
export const backfillMatchGestures = onCall(
    { maxInstances: 10, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAdmin(request);
        await checkRateLimit(uid, "backfillMatchGestures", { maxRequests: 5, windowMs: 60000 });

        const matchesSnapshot = await db.collection("matches").get();
        let updatedCount = 0;

        let batch = db.batch();
        let batchCount = 0;

        for (const doc of matchesSnapshot.docs) {
            const data = doc.data();

            // Near-miss encounters are not mutual matches — leave them alone.
            if (data.matchType === "activity") continue;

            const userIds = (data.userIds as string[] | undefined) ?? [];
            if (userIds.length !== 2) continue;

            const gestures = (data.gestures as Record<string, boolean> | undefined) ?? {};
            if (Object.keys(gestures).length >= 2) continue; // already mutual

            batch.update(doc.ref, {
                [`gestures.${userIds[0]}`]: true,
                [`gestures.${userIds[1]}`]: true,
            });
            updatedCount++;
            batchCount++;

            if (batchCount === 490) {
                await batch.commit();
                batch = db.batch();
                batchCount = 0;
            }
        }

        if (batchCount > 0) {
            await batch.commit();
        }

        console.log(`[MIGRATION] backfillMatchGestures: admin ${uid.substring(0, 8)}... updated ${updatedCount} matches`);
        return { success: true, updatedCount };
    }
);
