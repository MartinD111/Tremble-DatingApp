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
import { getMessaging } from "firebase-admin/messaging";
import { requireAuth, requireAdmin, assertNotBanned } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
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

const MUTUAL_WAVE_FREE_LIMIT = 5;
const MUTUAL_WAVE_PREMIUM_LIMIT = 20;
const MUTUAL_WAVE_COUNTER_TIME_ZONE = "Europe/Ljubljana";

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

/**
 * sendWave — Callable: wave submission with a soft DoS guard.
 * Writes to waves/ collection which triggers onWaveCreated.
 */
export const sendWave = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        const startedAt = Date.now();
        logStructured({ fn: "sendWave", event: "entry", uid });

        try {
        const targetUid = assertValidDocumentId(request.data?.targetUid, "targetUid");
        if (uid === targetUid) {
            throw new HttpsError("invalid-argument", "Cannot wave at yourself");
        }

        // Read profile for ban status; sent waves are not product-limited.
        const userDoc = await db.collection("users").doc(uid).get();
        const userData = userDoc.data();

        assertNotBanned(userData);

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

        logStructured({ fn: "sendWave", event: "success", uid, targetUid, durationMs: Date.now() - startedAt });
        return { success: true };
        } catch (error) {
            logStructured({ fn: "sendWave", event: "error", uid, error: errorMessage(error), durationMs: Date.now() - startedAt });
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
    { document: "waves/{waveId}", region: "europe-west1" },
    async (event) => {
        const startedAt = Date.now();
        logStructured({ fn: "onWaveCreated", event: "entry", uid: "system", waveId: event.params.waveId });

        try {
        const snapshot = event.data;
        if (!snapshot) return;

        const waveData = snapshot.data();
        const fromUid = waveData.fromUid as string;
        const toUid = waveData.toUid as string;

        if (!fromUid || !toUid) return;
        logStructured({ fn: "onWaveCreated", event: "entry", uid: fromUid, waveId: event.params.waveId });

        // ── Wave deduplication (Redis, 5-min TTL) ─────────────────
        //    Prevents INCOMING_WAVE spam from rapid double-taps or
        //    duplicate Firestore trigger retries.
        const redis = getRedis();
        const dedupKey = waveDedupKey(fromUid, toUid);
        const dedupSet = await redis.set(dedupKey, "1", {
            ex: WAVE_DEDUP_SECS,
            nx: true, // Only set if key doesn't exist
        });

        if (dedupSet === null) {
            console.log(`[WAVE] Dedup: wave ${fromUid}→${toUid} already processed — skipping`);
            return;
        }

        // Fetch both user profiles upfront (needed for both branches)
        const [senderDoc, receiverDoc] = await Promise.all([
            db.collection("users").doc(fromUid).get(),
            db.collection("users").doc(toUid).get(),
        ]);

        const senderName = (senderDoc.data()?.name as string | undefined) ?? "Nekdo";
        const senderPhoto = (senderDoc.data()?.photoUrls as string[] | undefined)?.[0] ?? "";
        const receiverName = (receiverDoc.data()?.name as string | undefined) ?? "Nekdo";
        const receiverPhoto = (receiverDoc.data()?.photoUrls as string[] | undefined)?.[0] ?? "";
        const receiverToken = receiverDoc.data()?.fcmToken as string | undefined;
        const senderToken = senderDoc.data()?.fcmToken as string | undefined;

        let senderAge = 0;
        const dob = senderDoc.data()?.dateOfBirth;
        if (dob) {
            const dobDate = dob.toDate();
            const today = new Date();
            senderAge = today.getFullYear() - dobDate.getFullYear();
            const m = today.getMonth() - dobDate.getMonth();
            if (m < 0 || (m === 0 && today.getDate() < dobDate.getDate())) {
                senderAge--;
            }
        }

        // Check for reciprocal wave (mutual match)
        const reciprocalQuery = await db
            .collection("waves")
            .where("fromUid", "==", toUid)
            .where("toUid", "==", fromUid)
            .limit(1)
            .get();

        const messaging = getMessaging();

        if (!reciprocalQuery.empty) {
            // ── MUTUAL_WAVE: Create match + notify both ───

            const uids = [fromUid, toUid].sort();
            const matchId = `${uids[0]}_${uids[1]}`;

            const userARef = db.collection("users").doc(uids[0]);
            const userBRef = db.collection("users").doc(uids[1]);
            const matchRef = db.collection("matches").doc(matchId);
            const reciprocalWaveRef = reciprocalQuery.docs[0].ref;
            const counterField = mutualWaveCounterField();

            await db.runTransaction(async (transaction) => {
                const [matchDoc, userADoc, userBDoc] = await Promise.all([
                    transaction.get(matchRef),
                    transaction.get(userARef),
                    transaction.get(userBRef),
                ]);

                if (matchDoc.exists) {
                    console.log(`[WAVE] Match ${matchId} already exists — skipping duplicate trigger`);
                    return;
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
                    createdAt: FieldValue.serverTimestamp(),
                    expiresAt: new Date(Date.now() + 30 * 60 * 1000),
                    status: "pending",
                    seenBy: [fromUid],
                });

                transaction.update(userARef, {
                    [counterField]: FieldValue.increment(1),
                });

                transaction.update(userBRef, {
                    [counterField]: FieldValue.increment(1),
                });

                transaction.delete(snapshot.ref);
                transaction.delete(reciprocalWaveRef);
            });

            console.log(`[WAVE] Mutual wave → match created: ${matchId}`);

            // Send "Odpremo radar?" to both users
            const notifications: Promise<string>[] = [];

            if (receiverToken) {
                notifications.push(
                    messaging.send({
                        token: receiverToken,
                        notification: {
                            title: `${senderName} ti je pomahal-a nazaj!`,
                            body: "Odpremo radar?",
                            imageUrl: senderPhoto || undefined,
                        },
                        data: {
                            type: "MUTUAL_WAVE",
                            matchId,
                            path: "/radar",
                        },
                        apns: {
                            payload: {
                                aps: {
                                    sound: "default",
                                    "mutable-content": 1,
                                },
                            },
                        },
                        android: { priority: "high" },
                    })
                );
            }

            if (senderToken) {
                notifications.push(
                    messaging.send({
                        token: senderToken,
                        notification: {
                            title: `${receiverName} ti je pomahal-a nazaj!`,
                            body: "Odpremo radar?",
                            imageUrl: receiverPhoto || undefined,
                        },
                        data: {
                            type: "MUTUAL_WAVE",
                            matchId,
                            path: "/radar",
                        },
                        apns: {
                            payload: {
                                aps: {
                                    sound: "default",
                                    "mutable-content": 1,
                                },
                            },
                        },
                        android: { priority: "high" },
                    })
                );
            }

            await Promise.allSettled(notifications);
            logStructured({ fn: "onWaveCreated", event: "success", uid: fromUid, matchId, result: "mutual_wave", durationMs: Date.now() - startedAt });

            // Also send match email (fire-and-forget)
            const senderEmail = senderDoc.data()?.email as string | undefined;
            const receiverEmail = receiverDoc.data()?.email as string | undefined;
            if (senderEmail && receiverName) sendMatchNotificationEmail(senderEmail, receiverName).catch(() => null);
            if (receiverEmail && senderName) sendMatchNotificationEmail(receiverEmail, senderName).catch(() => null);

        } else {
            // ── INCOMING_WAVE: Rich Push to receiver ──────

            if (!receiverToken) {
                console.log(`[WAVE] No FCM token for receiver ${toUid}`);
                return;
            }

            const recipientData = receiverDoc.data();
            const isSilent = recipientData?.isRunModeActive === true 
                || !!recipientData?.activeGymId 
                || !!recipientData?.activeEventId;

            if (isSilent) {
                await messaging.send({
                    token: receiverToken,
                    data: {
                        type: "INCOMING_WAVE",
                        senderId: fromUid,
                        senderName,
                        senderAge: senderAge.toString(),
                        senderPhotoUrl: senderPhoto,
                        // WAVE_BACK_ACTION is handled silently in background by Flutter
                        click_action: "WAVE_BACK_ACTION",
                    },
                    apns: {
                        payload: {
                            aps: {
                                contentAvailable: true,
                            },
                        },
                    },
                    android: { priority: "high" },
                });
            } else {
                await messaging.send({
                    token: receiverToken,
                    data: {
                        type: "INCOMING_WAVE",
                        senderId: fromUid,
                        senderName,
                        senderAge: senderAge.toString(),
                        senderPhotoUrl: senderPhoto,
                        // WAVE_BACK_ACTION is handled silently in background by Flutter
                        click_action: "WAVE_BACK_ACTION",
                    },
                    apns: {
                        payload: {
                            aps: {
                                contentAvailable: true,
                                // WAVE_CATEGORY enables action buttons on iOS
                                category: "WAVE_CATEGORY",
                                "mutable-content": 1,
                            },
                        },
                    },
                    android: { priority: "high" },
                });
            }

            console.log(`[WAVE] INCOMING_WAVE sent: ${fromUid} → ${toUid}`);
            logStructured({ fn: "onWaveCreated", event: "success", uid: fromUid, result: "incoming_wave", durationMs: Date.now() - startedAt });
        }
        } catch (error) {
            logStructured({ fn: "onWaveCreated", event: "error", uid: "system", error: errorMessage(error), durationMs: Date.now() - startedAt });
            throw error;
        }
    }
);

export const getMatches = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "getMatches", { maxRequests: 60, windowMs: 60000 });
        const userDoc = await db.collection("users").doc(uid).get();
        const blockedUsers = userDoc.data()?.blockedUserIds || [];

        const matchesQuery = await db
            .collection("matches")
            .where("userIds", "array-contains", uid)
            .orderBy("createdAt", "desc")
            .limit(50)
            .get();

        const profiles = await Promise.all(
            matchesQuery.docs.map(async (doc) => {
                const matchData = doc.data();
                const partnerId = matchData.userA === uid ? matchData.userB : matchData.userA;

                if (blockedUsers.includes(partnerId)) return null;

                const profileDoc = await db.collection("users").doc(partnerId).get();
                if (!profileDoc.exists) return null;
                const pData = profileDoc.data()!;

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
                };
            })
        );

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
