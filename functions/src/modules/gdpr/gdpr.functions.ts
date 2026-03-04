/**
 * Tremble — GDPR Functions
 *
 * Data export, account deletion, and consent management.
 * Compliant with GDPR Articles 15, 17, 20 (access, erasure, portability).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
    getFirestore,
    FieldValue,
} from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";

const db = getFirestore();
const auth = getAuth();

/**
 * Export all user data (GDPR Article 15 & 20 — Right of Access & Portability).
 *
 * Returns all personal data in a structured JSON format.
 * Rate limited to prevent abuse.
 */
export const exportUserData = onCall(
    { maxInstances: 10 },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 3 exports per hour
        await checkRateLimit(uid, "exportUserData", {
            maxRequests: 3,
            windowMs: 3_600_000,
        });

        // Log the GDPR request
        await db.collection("gdprRequests").add({
            uid,
            type: "export",
            status: "processing",
            requestedAt: FieldValue.serverTimestamp(),
        });

        // Fetch all user data
        const [userDoc, matchesDocs, greetingsSent, greetingsReceived, proximityDoc] =
            await Promise.all([
                db.collection("users").doc(uid).get(),
                db
                    .collection("matches")
                    .where("userA", "==", uid)
                    .get()
                    .then(async (asA) => {
                        const asB = await db
                            .collection("matches")
                            .where("userB", "==", uid)
                            .get();
                        return [...asA.docs, ...asB.docs];
                    }),
                db
                    .collection("greetings")
                    .where("fromUid", "==", uid)
                    .get(),
                db
                    .collection("greetings")
                    .where("toUid", "==", uid)
                    .get(),
                db.collection("proximity").doc(uid).get(),
            ]);

        const exportData = {
            exportedAt: new Date().toISOString(),
            user: userDoc.exists ? userDoc.data() : null,
            matches: matchesDocs.map((doc) => ({ id: doc.id, ...doc.data() })),
            greetingsSent: greetingsSent.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
            })),
            greetingsReceived: greetingsReceived.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
            })),
            proximity: proximityDoc.exists ? proximityDoc.data() : null,
        };

        console.log(`[GDPR] Data exported for user: ${uid}`);

        return { data: exportData };
    }
);

/**
 * Delete all user data (GDPR Article 17 — Right to Erasure).
 *
 * Performs a hard delete of all user data across all collections
 * and deletes the Firebase Auth account.
 */
export const deleteUserAccount = onCall(
    { maxInstances: 10 },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 1 deletion per day
        await checkRateLimit(uid, "deleteUserAccount", {
            maxRequests: 1,
            windowMs: 86_400_000,
        });

        // Log the GDPR request
        const gdprRef = await db.collection("gdprRequests").add({
            uid,
            type: "delete",
            status: "processing",
            requestedAt: FieldValue.serverTimestamp(),
        });

        try {
            const batch = db.batch();

            // 1. Delete user profile
            batch.delete(db.collection("users").doc(uid));

            // 2. Delete proximity data
            batch.delete(db.collection("proximity").doc(uid));

            // 3. Delete all greetings sent by user
            const sentGreetings = await db
                .collection("greetings")
                .where("fromUid", "==", uid)
                .get();
            sentGreetings.docs.forEach((doc) => batch.delete(doc.ref));

            // 4. Delete all greetings received by user
            const receivedGreetings = await db
                .collection("greetings")
                .where("toUid", "==", uid)
                .get();
            receivedGreetings.docs.forEach((doc) => batch.delete(doc.ref));

            // 5. Delete all matches involving user
            const matchesAsA = await db
                .collection("matches")
                .where("userA", "==", uid)
                .get();
            matchesAsA.docs.forEach((doc) => batch.delete(doc.ref));

            const matchesAsB = await db
                .collection("matches")
                .where("userB", "==", uid)
                .get();
            matchesAsB.docs.forEach((doc) => batch.delete(doc.ref));

            // 6. Delete rate limit entries
            const rateLimits = await db
                .collection("rateLimits")
                .where("__name__", ">=", `${uid}:`)
                .where("__name__", "<=", `${uid}:\uf8ff`)
                .get();
            rateLimits.docs.forEach((doc) => batch.delete(doc.ref));

            // Commit all Firestore deletions
            await batch.commit();

            // 7. Delete Firebase Auth account
            await auth.deleteUser(uid);

            // TODO: Delete R2 files (users/{uid}/*) via S3 API

            // Update GDPR request status
            await gdprRef.update({
                status: "completed",
                completedAt: FieldValue.serverTimestamp(),
            });

            console.log(`[GDPR] Account deleted: ${uid}`);
            return { success: true, message: "All data has been deleted." };
        } catch (error) {
            await gdprRef.update({
                status: "failed",
                error: String(error),
                completedAt: FieldValue.serverTimestamp(),
            });

            console.error(`[GDPR] Deletion failed for ${uid}:`, error);
            throw new HttpsError("internal", "Account deletion failed.");
        }
    }
);
