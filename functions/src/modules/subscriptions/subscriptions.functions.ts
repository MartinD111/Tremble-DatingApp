import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
    DocumentData,
    getFirestore,
    QueryDocumentSnapshot,
    Timestamp,
} from "firebase-admin/firestore";
import { DateTime } from "luxon";
import { ENFORCE_APP_CHECK } from "../../config/env";
import { Sentry } from "../../core/sentry";
import { requireAuth, assertNotBanned } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { assertValidDocumentId } from "../../middleware/validate";
import { getNextWeekendWindow, isInWeekendWindow } from "../../utils/weekend-window";

const db = getFirestore();
const DEFAULT_TIMEZONE = "Europe/Ljubljana";
const MAX_BATCH_WRITES = 500;

function userTimezone(userData: DocumentData | undefined): string {
    const timezone = userData?.timezone;
    return typeof timezone === "string" && timezone.trim() !== ""
        ? timezone
        : DEFAULT_TIMEZONE;
}

async function updateUsersInBatches(
    docs: QueryDocumentSnapshot<DocumentData>[],
    data: Record<string, unknown>
): Promise<number> {
    let updated = 0;

    for (let i = 0; i < docs.length; i += MAX_BATCH_WRITES) {
        const batch = db.batch();
        const chunk = docs.slice(i, i + MAX_BATCH_WRITES);

        chunk.forEach((doc) => {
            batch.update(doc.ref, data);
        });

        await batch.commit();
        updated += chunk.length;
    }

    return updated;
}

export const activateWeekendPass = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const callerUid = requireAuth(request);
        await checkRateLimit(callerUid, "activateWeekendPass", {
            maxRequests: 5,
            windowMs: 60_000,
        });

        const { uid: rawUid } = request.data as { uid?: unknown };
        const uid = assertValidDocumentId(rawUid, "uid");

        if (uid !== callerUid) {
            throw new HttpsError("permission-denied", "Cannot activate a pass for another user.");
        }

        const userRef = db.collection("users").doc(uid);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            throw new HttpsError("not-found", "User not found.");
        }

        const userData = userDoc.data();
        assertNotBanned(userData);

        const timezone = userTimezone(userData);
        const window = getNextWeekendWindow(timezone);
        const weekendPassStatus = isInWeekendWindow(timezone) ? "active" : "pending";

        await userRef.update({
            weekendPassStatus,
            weekendPassActivatesAt: Timestamp.fromDate(window.activatesAt),
            weekendPassExpiresAt: Timestamp.fromDate(window.expiresAt),
        });

        return {
            success: true,
            weekendPassStatus,
            weekendPassActivatesAt: window.activatesAt.toISOString(),
            weekendPassExpiresAt: window.expiresAt.toISOString(),
        };
    }
);

// ToS §7: Weekend Getaway window runs Fri 19:00 → Sun 19:00 Europe/Ljubljana.
// The enforcement anchor is always the default timezone — user-timezone drift only
// affects when a specific user's activation/expiry timestamps were computed at
// activateWeekendPass time; the *window itself* is anchored to Ljubljana.
export const processWeekendPasses = onSchedule(
    { schedule: "0 * * * *", region: "europe-west1", timeZone: DEFAULT_TIMEZONE },
    async () => {
        const startedAt = Date.now();
        const now = Timestamp.now();
        const anchor = DateTime.now().setZone(DEFAULT_TIMEZONE);
        const inWindow = isInWeekendWindow(DEFAULT_TIMEZONE);

        try {
            const [pendingSnapshot, activeSnapshot] = await Promise.all([
                db.collection("users")
                    .where("weekendPassStatus", "==", "pending")
                    .where("weekendPassActivatesAt", "<=", now)
                    .get(),
                db.collection("users")
                    .where("weekendPassStatus", "==", "active")
                    .where("weekendPassExpiresAt", "<=", now)
                    .get(),
            ]);

            const activated = await updateUsersInBatches(pendingSnapshot.docs, {
                weekendPassStatus: "active",
            });

            const expired = await updateUsersInBatches(activeSnapshot.docs, {
                weekendPassStatus: null,
                weekendPassActivatesAt: null,
                weekendPassExpiresAt: null,
            });

            console.log(
                JSON.stringify({
                    fn: "processWeekendPasses",
                    event: "complete",
                    timezone: DEFAULT_TIMEZONE,
                    nowLjubljana: anchor.toISO(),
                    inWindow,
                    activated,
                    expired,
                    durationMs: Date.now() - startedAt,
                })
            );
        } catch (err) {
            Sentry.captureException(err);
            await Sentry.flush(2000);
            throw err;
        }
    }
);
