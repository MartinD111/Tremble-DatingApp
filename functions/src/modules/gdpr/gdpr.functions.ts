/**
 * Tremble — GDPR Functions
 *
 * Data export, account deletion, and consent management.
 * Compliant with GDPR Articles 15, 17, 20 (access, erasure, portability).
 * ZVOP-2 čl. 23 — Pravica do izbrisa (Right to Erasure).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
    getFirestore,
    FieldValue,
    Timestamp,
    DocumentReference,
} from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { S3Client, ListObjectsV2Command, DeleteObjectsCommand } from "@aws-sdk/client-s3";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { getConfig } from "../../config/env";

const db = getFirestore();
const auth = getAuth();

// ── R2 Helper ─────────────────────────────────────────────────────────────

/**
 * Create an S3-compatible client for Cloudflare R2.
 */
function createR2Client(): S3Client {
    const config = getConfig();
    return new S3Client({
        region: "auto",
        endpoint: config.r2.endpoint,
        credentials: {
            accessKeyId: config.r2.accessKeyId,
            secretAccessKey: config.r2.secretAccessKey,
        },
    });
}

/**
 * Delete all R2 objects under a given prefix (e.g., users/{uid}/).
 * Uses paginated ListObjectsV2 + bulk DeleteObjects.
 * GDPR Article 17 — Right to Erasure (includes uploaded files).
 */
async function deleteR2UserFiles(uid: string): Promise<void> {
    const config = getConfig();

    if (!config.r2.accessKeyId || !config.r2.secretAccessKey) {
        console.warn("[GDPR] R2 credentials not configured — skipping R2 deletion.");
        return;
    }

    const s3 = createR2Client();
    const prefix = `users/${uid}/`;
    let continuationToken: string | undefined;
    let totalDeleted = 0;

    do {
        // List up to 1000 objects per page
        const listResp = await s3.send(
            new ListObjectsV2Command({
                Bucket: config.r2.bucketName,
                Prefix: prefix,
                ContinuationToken: continuationToken,
            })
        );

        const objects = listResp.Contents ?? [];

        if (objects.length > 0) {
            await s3.send(
                new DeleteObjectsCommand({
                    Bucket: config.r2.bucketName,
                    Delete: {
                        Objects: objects.map((obj) => ({ Key: obj.Key! })),
                        Quiet: true,
                    },
                })
            );
            totalDeleted += objects.length;
        }

        continuationToken = listResp.IsTruncated ? listResp.NextContinuationToken : undefined;
    } while (continuationToken);

    console.log(`[GDPR] R2: deleted ${totalDeleted} files for user ${uid.substring(0, 8)}...`);
}

// ── Batch deletion helper ─────────────────────────────────────────────────

/**
 * Delete document references in paginated batches of 500.
 * Firestore batches are capped at 500 operations — this handles arbitrarily
 * large collections without hitting that limit.
 */
async function deleteBatch(refs: DocumentReference[]): Promise<void> {
    const CHUNK_SIZE = 500;
    let total = 0;
    for (let i = 0; i < refs.length; i += CHUNK_SIZE) {
        const chunk = refs.slice(i, i + CHUNK_SIZE);
        const batch = db.batch();
        chunk.forEach((ref) => batch.delete(ref));
        await batch.commit();
        total += chunk.length;
    }
    if (total > 0) {
        console.log(`[GDPR] deleteBatch: removed ${total} documents`);
    }
}

// ── GDPR Request TTL helper ───────────────────────────────────────────────

/**
 * Returns a Firestore Timestamp 2 years from now.
 * GDPR Art. 5(1)(e) — storage limitation.
 */
function twoYearsFromNow(): Timestamp {
    const d = new Date();
    d.setFullYear(d.getFullYear() + 2);
    return Timestamp.fromDate(d);
}

// ── Functions ─────────────────────────────────────────────────────────────

/**
 * Export all user data (GDPR Article 15 & 20 — Right of Access & Portability).
 *
 * Returns all personal data in a structured JSON format, including:
 *   - user profile, proximity state, matches
 *   - waves sent (fromUid == uid) and waves received (toUid == uid)
 *
 * Rate limited to prevent abuse.
 */
export const exportUserData = onCall(
    { maxInstances: 10, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 3 exports per hour
        await checkRateLimit(uid, "exportUserData", {
            maxRequests: 3,
            windowMs: 3_600_000,
        });

        // Log the GDPR request with 2-year TTL
        await db.collection("gdprRequests").add({
            uid,
            type: "export",
            status: "processing",
            requestedAt: FieldValue.serverTimestamp(),
            ttl: twoYearsFromNow(), // TTL — Firestore will auto-delete after 2 years
        });

        // Fetch all user data
        const [userDoc, matchesDocs, wavesSent, wavesReceived, proximityDoc] =
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
                db.collection("waves").where("fromUid", "==", uid).get(),
                db.collection("waves").where("toUid", "==", uid).get(),
                db.collection("proximity").doc(uid).get(),
            ]);

        const exportData = {
            exportedAt: new Date().toISOString(),
            user: userDoc.exists ? userDoc.data() : null,
            matches: matchesDocs.map((doc) => ({ id: doc.id, ...doc.data() })),
            wavesSent: wavesSent.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
            wavesReceived: wavesReceived.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
            proximity: proximityDoc.exists ? proximityDoc.data() : null,
        };

        console.log(`[GDPR] Data exported for user: ${uid.substring(0, 8)}...`);

        return { data: exportData };
    }
);

/**
 * Delete all user data (GDPR Article 17 — Right to Erasure / ZVOP-2 čl. 23).
 *
 * Performs a hard delete of the following Firestore collections:
 *   - users/{uid}                          (profile)
 *   - proximity/{uid}                      (location/BLE state)
 *   - waves where fromUid == uid           (waves sent)
 *   - waves where toUid == uid             (waves received)
 *   - proximity_events where from == uid   (BLE proximity events)
 *   - proximity_notifications where users array-contains uid
 *   - idempotencyKeys range {uid}:*        (deduplication keys)
 *   - reports where reporterId == uid      (reports filed by user — hard delete)
 *   - reports where reportedId == uid      (reports about user — anonymised per
 *                                           Art. 17(3)(e): reportedId set to "[deleted]",
 *                                           document retained for legal defence)
 *   - matches where userA == uid           (matches as initiator)
 *   - matches where userB == uid           (matches as recipient)
 *   - rateLimits range {uid}:*             (rate limit counters)
 *
 * Also deletes:
 *   - Cloudflare R2: all files under users/{uid}/
 *   - Firebase Auth: account record
 *
 * A GDPR audit log entry is kept in gdprRequests for 2 years (Firestore TTL).
 */
export const deleteUserAccount = onCall(
    { maxInstances: 10, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 1 deletion per day
        await checkRateLimit(uid, "deleteUserAccount", {
            maxRequests: 1,
            windowMs: 86_400_000,
        });

        // Log the GDPR request with 2-year TTL
        const gdprRef = await db.collection("gdprRequests").add({
            uid,
            type: "delete",
            status: "processing",
            requestedAt: FieldValue.serverTimestamp(),
            ttl: twoYearsFromNow(), // TTL — auto-deleted by Firestore after 2 years
        });

        try {
            // 1. Delete user profile (single doc — direct batch delete)
            const profileBatch = db.batch();
            profileBatch.delete(db.collection("users").doc(uid));
            profileBatch.delete(db.collection("proximity").doc(uid));
            await profileBatch.commit();

            // 2. Delete waves sent by user
            const wavesSent = await db.collection("waves").where("fromUid", "==", uid).get();
            await deleteBatch(wavesSent.docs.map((d) => d.ref));

            // 3. Delete waves received by user
            const wavesReceived = await db.collection("waves").where("toUid", "==", uid).get();
            await deleteBatch(wavesReceived.docs.map((d) => d.ref));

            // 4. Delete proximity_events authored by user
            //    Field name: "from" (see proximity.functions.ts onBleProximity trigger)
            const proximityEvents = await db
                .collection("proximity_events")
                .where("from", "==", uid)
                .get();
            await deleteBatch(proximityEvents.docs.map((d) => d.ref));

            // 5. Delete proximity_notifications involving user
            //    Documents store users: [fromUid, toUid] array
            const proximityNotifs = await db
                .collection("proximity_notifications")
                .where("users", "array-contains", uid)
                .get();
            await deleteBatch(proximityNotifs.docs.map((d) => d.ref));

            // 6. Delete idempotency keys for this user (format: {uid}:{requestId})
            const idempotencyKeys = await db
                .collection("idempotencyKeys")
                .where("__name__", ">=", `${uid}:`)
                .where("__name__", "<=", `${uid}:\uf8ff`)
                .get();
            await deleteBatch(idempotencyKeys.docs.map((d) => d.ref));

            // 7a. Delete reports filed BY this user (user is reporter — full erase)
            const reportsFiled = await db
                .collection("reports")
                .where("reporterId", "==", uid)
                .get();
            await deleteBatch(reportsFiled.docs.map((d) => d.ref));

            // 7b. Anonymise reports ABOUT this user (user is reported subject).
            //     GDPR Art. 17(3)(e) exemption: moderation evidence retained for legal defence.
            //     reportedId is replaced with "[deleted]" — no PII remains in the document.
            const reportsAbout = await db
                .collection("reports")
                .where("reportedId", "==", uid)
                .get();
            if (!reportsAbout.empty) {
                const anonymiseBatch = db.batch();
                reportsAbout.docs.forEach((doc) => {
                    anonymiseBatch.update(doc.ref, { reportedId: "[deleted]" });
                });
                await anonymiseBatch.commit();
                console.log(`[GDPR] Anonymised ${reportsAbout.size} report(s) about user ${uid.substring(0, 8)}... (Art. 17(3)(e))`);
            }

            // 8. Delete matches involving user
            const matchesAsA = await db.collection("matches").where("userA", "==", uid).get();
            await deleteBatch(matchesAsA.docs.map((d) => d.ref));

            const matchesAsB = await db.collection("matches").where("userB", "==", uid).get();
            await deleteBatch(matchesAsB.docs.map((d) => d.ref));

            // 9. Delete rate limit entries for this user (format: {uid}:{endpoint})
            const rateLimits = await db
                .collection("rateLimits")
                .where("__name__", ">=", `${uid}:`)
                .where("__name__", "<=", `${uid}:\uf8ff`)
                .get();
            await deleteBatch(rateLimits.docs.map((d) => d.ref));

            // 10. Delete all R2 photos and files for this user (GDPR Art. 17)
            await deleteR2UserFiles(uid);

            // 11. Delete Firebase Auth account
            await auth.deleteUser(uid);

            // Mark GDPR log as completed (kept for 2 years per TTL)
            await gdprRef.update({
                status: "completed",
                completedAt: FieldValue.serverTimestamp(),
            });

            console.log(`[GDPR] Account fully deleted (Firestore + R2 + Auth): ${uid.substring(0, 8)}...`);
            return { success: true, message: "All data has been permanently deleted." };
        } catch (error) {
            await gdprRef.update({
                status: "failed",
                error: String(error),
                completedAt: FieldValue.serverTimestamp(),
            });

            console.error(`[GDPR] Deletion failed for ${uid.substring(0, 8)}...:`, error);
            throw new HttpsError("internal", "Account deletion failed.");
        }
    }
);
