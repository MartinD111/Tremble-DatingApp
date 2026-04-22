/**
 * Tremble — Match Functions
 *
 * Interaction System v2.1:
 * - onWaveCreated handles INCOMING_WAVE (Rich Push: name + photo)
 *   and MUTUAL_WAVE (Match with deep link to /radar).
 * - No chat, no messages. Wave = one tap. Meet = in real life.
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { requireAuth } from "../../middleware/authGuard";
import { sendMatchNotificationEmail } from "../email/email.functions";
import { getRedis, waveDedupKey, WAVE_DEDUP_SECS } from "../../core/redis";
import { ENFORCE_APP_CHECK } from "../../config/env";

const db = getFirestore();

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
        const snapshot = event.data;
        if (!snapshot) return;

        const waveData = snapshot.data();
        const fromUid = waveData.fromUid as string;
        const toUid = waveData.toUid as string;

        if (!fromUid || !toUid) return;

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

            // Dedup guard: if match already exists this trigger fired twice — skip
            const existingMatch = await db.collection("matches").doc(matchId).get();
            if (existingMatch.exists) {
                console.log(`[WAVE] Match ${matchId} already exists — skipping duplicate trigger`);
                return;
            }

            const batch = db.batch();

            batch.set(db.collection("matches").doc(matchId), {
                userA: uids[0],
                userB: uids[1],
                userIds: uids,
                createdAt: FieldValue.serverTimestamp(),
                expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30 minutes from now
                status: 'pending',
                seenBy: [fromUid],
                // No lastMessage — Tremble has no in-app chat.
            });

            batch.delete(snapshot.ref);
            batch.delete(reciprocalQuery.docs[0].ref);
            await batch.commit();

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

            await messaging.send({
                token: receiverToken,
                notification: {
                    title: `${senderName} ti je pomahal-a`,
                    body: "Pomahaš nazaj?",
                    // imageUrl requires iOS Notification Service Extension for display.
                    // Android renders it natively.
                    imageUrl: senderPhoto || undefined,
                },
                data: {
                    type: "INCOMING_WAVE",
                    senderId: fromUid,
                    senderName,
                    // WAVE_BACK_ACTION is handled silently in background by Flutter
                    click_action: "WAVE_BACK_ACTION",
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            // WAVE_CATEGORY enables action buttons on iOS
                            category: "WAVE_CATEGORY",
                            "mutable-content": 1,
                        },
                    },
                },
                android: { priority: "high" },
            });

            console.log(`[WAVE] INCOMING_WAVE sent: ${fromUid} → ${toUid}`);
        }
    }
);

export const getMatches = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        const userDoc = await db.collection("users").doc(uid).get();
        const blockedUsers = userDoc.data()?.blockedUserIds || [];

        const matchesQuery = await db
            .collection("matches")
            .where("userIds", "array-contains", uid)
            .orderBy("createdAt", "desc")
            .limit(50)
            .get();

        const matchedUserIds = new Set<string>();

        for (const doc of matchesQuery.docs) {
            const data = doc.data();
            const partnerId = data.userA === uid ? data.userB : data.userA;
            if (blockedUsers.includes(partnerId)) continue;
            matchedUserIds.add(partnerId);
        }

        const profiles = await Promise.all(
            Array.from(matchedUserIds).map(async (userId) => {
                const profileDoc = await db.collection("users").doc(userId).get();
                if (!profileDoc.exists) return null;
                const data = profileDoc.data()!;
                return {
                    id: userId,
                    name: data.name,
                    age: data.age,
                    photoUrls: data.photoUrls,
                    hobbies: data.hobbies,
                    lookingFor: data.lookingFor,
                };
            })
        );

        return { matches: profiles.filter(Boolean) };
    }
);