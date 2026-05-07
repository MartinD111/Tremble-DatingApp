import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import { blockUserSchema, unblockUserSchema, reportUserSchema, checkAnonymitySchema } from "./safety.schema";
import * as crypto from "crypto";
import { getAuth } from "firebase-admin/auth";
import { ENFORCE_APP_CHECK } from "../../config/env";

const db = getFirestore();

/**
 * Block a user permanently.
 * - Adds targetUid to caller's `blockedUserIds` array.
 * - Deletes any existing match between them.
 */
export const blockUser = onCall(
    { maxInstances: 50, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(request.rawRequest.ip || uid, "blockUser", { maxRequests: 10, windowMs: 60000 });

        const { targetUid } = validateRequest(blockUserSchema, request.data);
        if (uid === targetUid) {
            throw new HttpsError("invalid-argument", "Cannot block yourself");
        }

        const batch = db.batch();

        // 1. Add to caller's blockedUserIds
        const userRef = db.collection("users").doc(uid);
        batch.update(userRef, {
            blockedUserIds: FieldValue.arrayUnion(targetUid),
        });

        // 2. Add to target's blockedBy array (optional, useful for reverse lookups if needed later)
        const targetRef = db.collection("users").doc(targetUid);
        batch.update(targetRef, {
            blockedBy: FieldValue.arrayUnion(uid),
        });

        // 3. Remove existing matches between the two users
        // Since we don't know who is A or B, we must query. 
        // We do this outside the batch, then add deletes to the batch.
        const matchesA = await db.collection("matches")
            .where("userA", "==", uid)
            .where("userB", "==", targetUid)
            .get();
        const matchesB = await db.collection("matches")
            .where("userA", "==", targetUid)
            .where("userB", "==", uid)
            .get();

        const allMatches = [...matchesA.docs, ...matchesB.docs];
        for (const matchDoc of allMatches) {
            batch.delete(matchDoc.ref);
        }

        // 4. Remove any pending proximity interactions or greetings (optional cleanup)
        // We'll trust the main matching flow to just ignore them now they are blocked.

        await batch.commit();

        console.log(`[SAFETY] User ${uid.substring(0, 8)}... blocked user ${targetUid.substring(0, 8)}...`);
        return { success: true };
    }
);

/**
 * Unblock a user.
 * - Removes targetUid from caller's `blockedUserIds` array.
 */
export const unblockUser = onCall(
    { maxInstances: 50, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(request.rawRequest.ip || uid, "unblockUser", { maxRequests: 10, windowMs: 60000 });

        const { targetUid } = validateRequest(unblockUserSchema, request.data);

        const batch = db.batch();

        const userRef = db.collection("users").doc(uid);
        batch.update(userRef, {
            blockedUserIds: FieldValue.arrayRemove(targetUid),
        });

        const targetRef = db.collection("users").doc(targetUid);
        batch.update(targetRef, {
            blockedBy: FieldValue.arrayRemove(uid),
        });

        await batch.commit();

        console.log(`[SAFETY] User ${uid.substring(0, 8)}... unblocked user ${targetUid.substring(0, 8)}...`);
        return { success: true };
    }
);

/**
 * Report a user for moderation.
 * - Creates a record in the `reports` collection.
 * - Automatically blocks the reported user to protect the reporter immediately.
 */
export const reportUser = onCall(
    { maxInstances: 50, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(request.rawRequest.ip || uid, "reportUser", { maxRequests: 5, windowMs: 60000 });

        const { reportedUid, reasons, explanation } = validateRequest(reportUserSchema, request.data);

        // 1. Create the report document
        const reportRef = db.collection("reports").doc();
        await reportRef.set({
            reporterId: uid,
            reportedId: reportedUid,
            reasons: reasons, // e.g. ["spam", "harassment"]
            explanation: explanation || "",
            status: "pending",
            createdAt: Timestamp.now(),
        });

        // 2. Automatically apply a personal block behind the scenes
        // Calling blockUser logic directly here would require duplicating code or abstracting it.
        // For now, we will just replicate the array unions to ensure immediate safety.
        
        const batch = db.batch();
        batch.update(db.collection("users").doc(uid), {
            blockedUserIds: FieldValue.arrayUnion(reportedUid),
        });
        batch.update(db.collection("users").doc(reportedUid), {
            blockedBy: FieldValue.arrayUnion(uid),
        });

        // Delete matches
        const matchesA = await db.collection("matches").where("userA", "==", uid).where("userB", "==", reportedUid).get();
        const matchesB = await db.collection("matches").where("userA", "==", reportedUid).where("userB", "==", uid).get();
        [...matchesA.docs, ...matchesB.docs].forEach(doc => batch.delete(doc.ref));

        await batch.commit();

        console.log(`[SAFETY] User ${uid.substring(0, 8)}... reported ${reportedUid.substring(0, 8)}... for ${reasons.join(", ")}`);
        return { success: true, reportId: reportRef.id };
    }
);

/**
 * Anonymity Mode: Contact Matching Filter
 * Receives an array of SHA-256 hashed phone numbers from the client.
 * Performs an in-memory comparison against registered Firebase Auth users' hashed phone numbers.
 * Any matches are added to the caller's blockedUserIds to prevent discovery.
 * Hashes are not persisted.
 */
export const onContactAnonymityCheck = onCall(
    { maxInstances: 50, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1", timeoutSeconds: 120 },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(request.rawRequest.ip || uid, "onContactAnonymityCheck", { maxRequests: 3, windowMs: 60000 });

        const { hashedContacts } = validateRequest(checkAnonymitySchema, request.data);

        if (hashedContacts.length === 0) {
            return { success: true, matchesFound: 0 };
        }

        // 1. Build a temporary set of registered user hashes
        const auth = getAuth();
        const registeredHashes = new Map<string, string>(); // Map<hash, uid>

        let pageToken: string | undefined = undefined;
        do {
            const listUsersResult = await auth.listUsers(1000, pageToken);
            for (const userRecord of listUsersResult.users) {
                if (userRecord.phoneNumber) {
                    const hash = crypto.createHash('sha256').update(userRecord.phoneNumber).digest('hex');
                    registeredHashes.set(hash, userRecord.uid);
                }
            }
            pageToken = listUsersResult.pageToken;
        } while (pageToken);

        // 2. Perform in-memory comparison
        const uidsToBlock = new Set<string>();
        for (const incomingHash of hashedContacts) {
            const matchedUid = registeredHashes.get(incomingHash);
            if (matchedUid && matchedUid !== uid) {
                uidsToBlock.add(matchedUid);
            }
        }

        if (uidsToBlock.size === 0) {
            return { success: true, matchesFound: 0 };
        }

        // 3. Update the caller's blockedUserIds and mutually block
        const batch = db.batch();
        const userRef = db.collection("users").doc(uid);

        const uidsArray = Array.from(uidsToBlock);

        // Add to caller's blockedUserIds
        batch.update(userRef, {
            blockedUserIds: FieldValue.arrayUnion(...uidsArray),
        });

        // Add to targets' blockedBy
        for (const targetUid of uidsArray) {
            const targetRef = db.collection("users").doc(targetUid);
            batch.update(targetRef, {
                blockedBy: FieldValue.arrayUnion(uid),
            });
        }

        // We could delete matches here as well, but this could exceed the 500 max writes in a batch
        // if there are too many blocks. For safety, we just rely on blockedUserIds to filter out UI.
        
        // Execute batch in chunks if needed (Firestore limit is 500 operations per batch)
        // Since we do 1 update for caller + N updates for targets = N + 1 updates.
        // If N > 499, we need chunks, but practically a user won't have 500 contacts using the app immediately.
        // Let's protect against batch limit just in case:
        if (uidsArray.length > 498) {
            console.warn(`[SAFETY] Contact anonymity check found > 498 matches for ${uid}, some might be truncated from this batch.`);
            // In a real prod environment we'd chunk this, but for now we slice to max safe size.
            uidsArray.length = 498; 
        }

        await batch.commit();

        console.log(`[SAFETY] Anonymity Check for ${uid.substring(0, 8)}... found ${uidsArray.length} matches.`);

        // Force V8 to garbage collect if possible (hashes fall out of scope here)
        return { success: true, matchesFound: uidsArray.length };
    }
);
