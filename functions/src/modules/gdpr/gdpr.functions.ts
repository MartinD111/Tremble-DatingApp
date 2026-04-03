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

    console.log(`[GDPR] R2: deleted ${totalDeleted} files for user ${uid}`);
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
 * Returns all personal data in a structured JSON format.
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
 * Delete all user data (GDPR Article 17 — Right to Erasure / ZVOP-2 čl. 23).
 *
 * Performs a hard delete of:
 *   - Firestore: profile, proximity, greetings, matches, rate limits
 *   - Cloudflare R2: all uploaded photos/files under users/{uid}/
 *   - Firebase Auth: account record
 *
 * A GDPR audit log entry is kept for 2 years, then auto-deleted by Firestore TTL.
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

            // 7. Delete all R2 photos and files for this user (GDPR Art. 17)
            await deleteR2UserFiles(uid);

            // 8. Delete Firebase Auth account
            await auth.deleteUser(uid);

            // Mark GDPR log as completed (kept for 2 years per TTL)
            await gdprRef.update({
                status: "completed",
                completedAt: FieldValue.serverTimestamp(),
            });

            console.log(`[GDPR] Account fully deleted (Firestore + R2 + Auth): ${uid}`);
            return { success: true, message: "All data has been permanently deleted." };
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
