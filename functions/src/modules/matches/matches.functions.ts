/**
 * Tremble — Matches Functions
 *
 * Server-side match logic: greeting, acceptance, match creation.
 * Replaces the fully mocked client-side match system.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import {
    sendGreetingSchema,
    respondToGreetingSchema,
} from "./matches.schema";
import { sendMatchNotificationEmail } from "../email/email.functions";

const db = getFirestore();

/**
 * Send a greeting to another user — the first step of matching.
 * Creates a greeting document; the other user can then accept/decline.
 */
export const sendGreeting = onCall(
    { maxInstances: 50, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 10 greetings per minute
        await checkRateLimit(uid, "sendGreeting", {
            maxRequests: 10,
            windowMs: 60_000,
        });

        const data = validateRequest(sendGreetingSchema, request.data);

        // Prevent self-greeting
        if (data.toUserId === uid) {
            throw new HttpsError("invalid-argument", "Cannot greet yourself.");
        }

        // Check if target user exists
        const targetUser = await db.collection("users").doc(data.toUserId).get();
        if (!targetUser.exists) {
            throw new HttpsError("not-found", "User not found.");
        }

        // Check for existing pending greeting in either direction
        const existingGreeting = await db
            .collection("greetings")
            .where("fromUid", "==", uid)
            .where("toUid", "==", data.toUserId)
            .where("status", "==", "pending")
            .limit(1)
            .get();

        if (!existingGreeting.empty) {
            throw new HttpsError(
                "already-exists",
                "You already have a pending greeting to this user."
            );
        }

        // Check if they already greeted us — auto-match!
        const reverseGreeting = await db
            .collection("greetings")
            .where("fromUid", "==", data.toUserId)
            .where("toUid", "==", uid)
            .where("status", "==", "pending")
            .limit(1)
            .get();

        if (!reverseGreeting.empty) {
            // Mutual interest — create a match!
            const greetingDoc = reverseGreeting.docs[0];

            const batch = db.batch();

            // Update the existing greeting to accepted
            batch.update(greetingDoc.ref, {
                status: "accepted",
                respondedAt: FieldValue.serverTimestamp(),
            });

            // Create the match
            batch.set(db.collection("matches").doc(), {
                userA: uid,
                userB: data.toUserId,
                status: "accepted",
                createdAt: FieldValue.serverTimestamp(),
            });

            await batch.commit();

            // Notify both users via email — fire and forget
            const [userADoc, userBDoc] = await Promise.all([
                db.collection("users").doc(uid).get(),
                db.collection("users").doc(data.toUserId).get(),
            ]);
            const userAEmail = userADoc.data()?.email as string | undefined;
            const userBEmail = userBDoc.data()?.email as string | undefined;
            const userAName = userADoc.data()?.name as string | undefined;
            const userBName = userBDoc.data()?.name as string | undefined;

            if (userAEmail && userBName)
                sendMatchNotificationEmail(userAEmail, userBName).catch(() => null);
            if (userBEmail && userAName)
                sendMatchNotificationEmail(userBEmail, userAName).catch(() => null);

            console.log(`[MATCHES] Auto-match: ${uid} ↔ ${data.toUserId}`);
            return { success: true, matched: true };
        }

        // No reverse greeting — create a new greeting
        await db.collection("greetings").add({
            fromUid: uid,
            toUid: data.toUserId,
            message: data.message || null,
            status: "pending",
            sentAt: FieldValue.serverTimestamp(),
        });

        console.log(`[MATCHES] Greeting sent: ${uid} → ${data.toUserId}`);
        return { success: true, matched: false };
    }
);

/**
 * Respond to a greeting — accept or decline.
 * If accepted, creates a match document.
 */
export const respondToGreeting = onCall(
    { maxInstances: 50, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        await checkRateLimit(uid, "respondToGreeting", {
            maxRequests: 30,
            windowMs: 60_000,
        });

        const data = validateRequest(respondToGreetingSchema, request.data);

        const greetingRef = db.collection("greetings").doc(data.greetingId);
        const greeting = await greetingRef.get();

        if (!greeting.exists) {
            throw new HttpsError("not-found", "Greeting not found.");
        }

        const greetingData = greeting.data()!;

        // Only the recipient can respond
        if (greetingData.toUid !== uid) {
            throw new HttpsError("permission-denied", "Not your greeting.");
        }

        if (greetingData.status !== "pending") {
            throw new HttpsError(
                "failed-precondition",
                "This greeting has already been responded to."
            );
        }

        const batch = db.batch();

        batch.update(greetingRef, {
            status: data.accept ? "accepted" : "declined",
            respondedAt: FieldValue.serverTimestamp(),
        });

        if (data.accept) {
            // Create match
            batch.set(db.collection("matches").doc(), {
                userA: greetingData.fromUid,
                userB: uid,
                status: "accepted",
                createdAt: FieldValue.serverTimestamp(),
            });
        }

        await batch.commit();

        if (data.accept) {
            // Notify both users via email on acceptance — fire and forget
            const [senderDoc, recipientDoc] = await Promise.all([
                db.collection("users").doc(greetingData.fromUid).get(),
                db.collection("users").doc(uid).get(),
            ]);
            const senderEmail = senderDoc.data()?.email as string | undefined;
            const recipientEmail = recipientDoc.data()?.email as string | undefined;
            const senderName = senderDoc.data()?.name as string | undefined;
            const recipientName = recipientDoc.data()?.name as string | undefined;
            if (senderEmail && recipientName)
                sendMatchNotificationEmail(senderEmail, recipientName).catch(() => null);
            if (recipientEmail && senderName)
                sendMatchNotificationEmail(recipientEmail, senderName).catch(() => null);
        }

        console.log(
            `[MATCHES] Greeting ${data.greetingId}: ${data.accept ? "accepted" : "declined"}`
        );
        return { success: true };
    }
);

/**
 * Get all matches for the authenticated user.
 * Returns profiles of matched users with limited fields.
 */
export const getMatches = onCall(
    { maxInstances: 100, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        const userDoc = await db.collection("users").doc(uid).get();
        const blockedUsers = userDoc.data()?.blockedUserIds || [];

        // Query where user is userA OR userB
        const [asA, asB] = await Promise.all([
            db
                .collection("matches")
                .where("userA", "==", uid)
                .where("status", "==", "accepted")
                .orderBy("createdAt", "desc")
                .limit(50)
                .get(),
            db
                .collection("matches")
                .where("userB", "==", uid)
                .where("status", "==", "accepted")
                .orderBy("createdAt", "desc")
                .limit(50)
                .get(),
        ]);

        const matchedUserIds = new Set<string>();
        const allDocs = [...asA.docs, ...asB.docs];

        for (const doc of allDocs) {
            const data = doc.data();
            const partnerId = data.userA === uid ? data.userB : data.userA;
            if (blockedUsers.includes(partnerId)) continue; // Do not return blocked matches
            matchedUserIds.add(partnerId);
        }

        // Fetch matched user profiles (public fields only)
        const profiles = await Promise.all(
            Array.from(matchedUserIds).map(async (userId) => {
                const userDoc = await db.collection("users").doc(userId).get();
                if (!userDoc.exists) return null;
                const data = userDoc.data()!;
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

        return {
            matches: profiles.filter(Boolean),
        };
    }
);

/**
 * Get pending greetings for the authenticated user.
 */
export const getPendingGreetings = onCall(
    { maxInstances: 100, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        const [received, sent] = await Promise.all([
            db
                .collection("greetings")
                .where("toUid", "==", uid)
                .where("status", "==", "pending")
                .orderBy("sentAt", "desc")
                .limit(20)
                .get(),
            db
                .collection("greetings")
                .where("fromUid", "==", uid)
                .where("status", "==", "pending")
                .orderBy("sentAt", "desc")
                .limit(20)
                .get(),
        ]);

        return {
            received: received.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
            })),
            sent: sent.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
            })),
        };
    }
);
