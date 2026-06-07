import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { requireAuth, assertNotBanned } from "../../middleware/authGuard";
import { assertValidDocumentId } from "../../middleware/validate";
import { ENFORCE_APP_CHECK } from "../../config/env";
import { checkRateLimit } from "../../middleware/rateLimit";

const db = getFirestore();

/** Hard limit for gym session duration. Auto-expire clears after this. */
const GYM_SESSION_HOURS = 2;

function haversine(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6_371_000;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * onGymModeActivate — manual check-in flow.
 *
 * Called when the user taps "Activate Gym Mode" and selects a gym.
 * Flutter fetches the current location via geolocator, then passes
 * gymId + lat/lng here. Backend validates proximity and sets the session.
 *
 * Firestore gym doc shape:
 *   gyms/{gymId}: { name, address, placeId, location: { lat, lng }, radiusMeters }
 *
 * User doc fields set: activeGymId, gymModeUntil (+2h hard limit)
 */
export const onGymModeActivate = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "onGymModeActivate", { maxRequests: 5, windowMs: 60000 });

        const userDoc = await db.collection("users").doc(uid).get();
        assertNotBanned(userDoc.data());

        const { gymId: rawGymId, latitude, longitude } = request.data;
        const gymId = assertValidDocumentId(rawGymId, "gymId");

        if (latitude === undefined || longitude === undefined) {
            throw new HttpsError("invalid-argument", "Missing gymId, latitude, or longitude");
        }

        const gymDoc = await db.collection("gyms").doc(gymId).get();
        if (!gymDoc.exists) {
            throw new HttpsError("not-found", "Gym not found");
        }

        const gymData = gymDoc.data()!;
        const gymLat = gymData.location?.lat as number | undefined;
        const gymLng = gymData.location?.lng as number | undefined;
        const radiusMeters = (gymData.radiusMeters as number | undefined) ?? 200;

        if (gymLat !== undefined && gymLng !== undefined) {
            const distance = haversine(latitude, longitude, gymLat, gymLng);
            if (distance > radiusMeters) {
                throw new HttpsError(
                    "failed-precondition",
                    `You are ${Math.round(distance)}m away from this gym (max ${radiusMeters}m).`
                );
            }
        }

        const gymModeUntil = Timestamp.fromDate(
            new Date(Date.now() + GYM_SESSION_HOURS * 60 * 60 * 1000)
        );

        await db.collection("users").doc(uid).update({
            activeGymId: gymId,
            gymModeUntil,
        });

        console.log(`[GYM] Activated gym mode for ${uid} at gym ${gymId}`);
        return { success: true, gymId, gymName: gymData.name as string };
    }
);

/**
 * onGymModeDeactivate — manual check-out.
 *
 * User taps deactivate in the gym mode sheet. Clears session immediately.
 */
export const onGymModeDeactivate = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "onGymModeDeactivate", { maxRequests: 5, windowMs: 60000 });

        const userDoc = await db.collection("users").doc(uid).get();
        assertNotBanned(userDoc.data());

        await db.collection("users").doc(uid).update({
            activeGymId: null,
            gymModeUntil: null,
        });

        console.log(`[GYM] Deactivated gym mode for ${uid}`);
        return { success: true };
    }
);

/**
 * expireGymSessions — scheduled hourly.
 *
 * Clears gymModeUntil + activeGymId for users whose session has expired.
 * Mirrors the events module's expireEventModes pattern.
 */
export const expireGymSessions = onSchedule(
    { schedule: "every 60 minutes", region: "europe-west1" },
    async () => {
        const expired = await db.collection("users")
            .where("gymModeUntil", "<", Timestamp.now())
            .get();

        if (expired.empty) return;

        const batch = db.batch();
        let count = 0;
        const recapPushes: Array<{ uid: string; token: string }> = [];

        expired.docs.forEach((doc) => {
            const data = doc.data();
            if (data.activeGymId) {
                batch.update(doc.ref, { activeGymId: null, gymModeUntil: null });
                if (typeof data.fcmToken === "string" && data.fcmToken.trim() !== "") {
                    recapPushes.push({ uid: doc.id, token: data.fcmToken });
                }
                count++;
            }
        });

        if (count > 0) {
            await batch.commit();

            const messaging = getMessaging();
            for (const push of recapPushes) {
                try {
                    await messaging.send({
                        token: push.token,
                        data: { type: "GYM_SESSION_RECAP" },
                        apns: { payload: { aps: { contentAvailable: true } } },
                        android: { priority: "high" },
                    });
                } catch (error) {
                    console.error(`[GYM] Failed to send recap push for ${push.uid}`, error);
                }
            }

            console.log(`[GYM] Expired gym sessions for ${count} users.`);
        }
    }
);

/** Hard limit for run mode session duration. Auto-expire clears after this. */
const RUN_SESSION_HOURS = 4;

/**
 * onRunModeActivate — manual activation.
 *
 * Called when the user taps "Activate Run Mode" in My Run section or via radar.
 * No location validation needed (unlike gym mode). Sets isRunModeActive and
 * runModeUntil (+4h hard limit) on the user doc.
 */
export const onRunModeActivate = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "onRunModeActivate", { maxRequests: 5, windowMs: 60000 });

        const userDoc = await db.collection("users").doc(uid).get();
        assertNotBanned(userDoc.data());

        const runModeUntil = Timestamp.fromDate(
            new Date(Date.now() + RUN_SESSION_HOURS * 60 * 60 * 1000)
        );

        await db.collection("users").doc(uid).update({
            isRunModeActive: true,
            runModeUntil,
        });

        console.log(`[RUN] Activated run mode for ${uid}`);
        return { success: true };
    }
);

/**
 * onRunModeDeactivate — manual deactivation.
 *
 * User taps deactivate in the run mode section. Clears session immediately.
 */
export const onRunModeDeactivate = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "onRunModeDeactivate", { maxRequests: 5, windowMs: 60000 });

        const userDoc = await db.collection("users").doc(uid).get();
        assertNotBanned(userDoc.data());

        await db.collection("users").doc(uid).update({
            isRunModeActive: false,
            runModeUntil: null,
        });

        console.log(`[RUN] Deactivated run mode for ${uid}`);
        return { success: true };
    }
);

/**
 * expireRunModes — scheduled hourly.
 *
 * Clears runModeUntil + isRunModeActive for users whose session has expired.
 * Mirrors the events module's expireEventModes pattern.
 */
export const expireRunModes = onSchedule(
    { schedule: "every 60 minutes", region: "europe-west1" },
    async () => {
        const expired = await db.collection("users")
            .where("runModeUntil", "<", Timestamp.now())
            .get();

        if (expired.empty) return;

        const batch = db.batch();
        let count = 0;
        const recapPushes: Array<{ uid: string; token: string }> = [];

        expired.docs.forEach((doc) => {
            const data = doc.data();
            if (data.isRunModeActive) {
                batch.update(doc.ref, { isRunModeActive: false, runModeUntil: null });
                if (typeof data.fcmToken === "string" && data.fcmToken.trim() !== "") {
                    recapPushes.push({ uid: doc.id, token: data.fcmToken });
                }
                count++;
            }
        });

        if (count > 0) {
            await batch.commit();

            const messaging = getMessaging();
            for (const push of recapPushes) {
                try {
                    await messaging.send({
                        token: push.token,
                        data: { type: "RUN_SESSION_RECAP" },
                        apns: { payload: { aps: { contentAvailable: true } } },
                        android: { priority: "high" },
                    });
                } catch (error) {
                    console.error(`[RUN] Failed to send recap push for ${push.uid}`, error);
                }
            }

            console.log(`[RUN] Expired run modes for ${count} users.`);
        }
    }
);
