import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, GeoPoint, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { requireAuth, assertNotBanned } from "../../middleware/authGuard";
import { assertValidDocumentId } from "../../middleware/validate";
import { ENFORCE_APP_CHECK } from "../../config/env";
import { checkRateLimit } from "../../middleware/rateLimit";

const db = getFirestore();

// Haversine distance in meters
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

export const onEventModeActivate = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "onEventModeActivate", { maxRequests: 5, windowMs: 60000 });

        const userDoc = await db.collection('users').doc(uid).get();
        assertNotBanned(userDoc.data());

        const { eventId: rawEventId, latitude, longitude } = request.data;
        const eventId = assertValidDocumentId(rawEventId, "eventId");

        if (latitude === undefined || longitude === undefined) {
            throw new HttpsError('invalid-argument', 'Missing eventId, latitude, or longitude');
        }

        const eventDoc = await db.collection('events').doc(eventId).get();
        if (!eventDoc.exists) {
            throw new HttpsError('not-found', 'Event not found');
        }

        const eventData = eventDoc.data()!;
        if (!eventData.active) {
            throw new HttpsError('failed-precondition', 'Event is not active');
        }

        const now = Timestamp.now();
        if (eventData.startsAt && eventData.startsAt.toMillis() > now.toMillis()) {
            throw new HttpsError('failed-precondition', 'Event has not started yet');
        }

        if (eventData.endsAt && eventData.endsAt.toMillis() < now.toMillis()) {
            throw new HttpsError('failed-precondition', 'Event has already ended');
        }

        // Verify user is within radius.
        //
        // KORAK 3.5 migration: `location` is now a Firestore GeoPoint on newly
        // seeded documents. Legacy `{lat, lng}` map shape is still accepted so
        // any dev-seeded doc from before the migration keeps validating —
        // seed_events.ts always writes a GeoPoint going forward.
        const rawLocation = eventData.location;
        let eventLat: number | undefined;
        let eventLng: number | undefined;
        if (rawLocation instanceof GeoPoint) {
            eventLat = rawLocation.latitude;
            eventLng = rawLocation.longitude;
        } else if (rawLocation && typeof rawLocation === "object") {
            eventLat = rawLocation.lat;
            eventLng = rawLocation.lng;
        }
        const radiusMeters = eventData.radiusMeters ?? 500;

        if (eventLat !== undefined && eventLng !== undefined) {
            const distance = haversine(latitude, longitude, eventLat, eventLng);
            if (distance > radiusMeters) {
                throw new HttpsError('failed-precondition', 'Not at event location');
            }
        }

        // Activate event mode for user
        await db.collection('users').doc(uid).update({
            activeEventId: eventId,
            eventModeUntil: eventData.endsAt
        });

        return { success: true, eventId };
    }
);

/**
 * onEventModeDeactivate — manual deactivation.
 *
 * User taps deactivate in the event mode section. Clears session immediately.
 */
export const onEventModeDeactivate = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "onEventModeDeactivate", { maxRequests: 5, windowMs: 60000 });

        const userDoc = await db.collection('users').doc(uid).get();
        assertNotBanned(userDoc.data());

        await db.collection('users').doc(uid).update({
            activeEventId: null,
            eventModeUntil: null,
        });

        console.log(`[EVENTS] Deactivated event mode for ${uid}`);
        return { success: true };
    }
);

// Scheduled — expire event modes every hour
export const expireEventModes = onSchedule(
    { schedule: 'every 60 minutes', region: "europe-west1" },
    async (_event) => {
        const expired = await db.collection('users')
            .where('eventModeUntil', '<', Timestamp.now())
            .get();

        if (expired.empty) return;

        const batch = db.batch();
        let count = 0;
        const recapPushes: Array<{ uid: string; token: string }> = [];

        expired.docs.forEach(doc => {
            const data = doc.data();
            // Only update if activeEventId is set to avoid unnecessary writes
            if (data.activeEventId) {
                batch.update(doc.ref, { activeEventId: null, eventModeUntil: null });
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
                        data: { type: "EVENT_SESSION_RECAP" },
                        apns: { payload: { aps: { contentAvailable: true } } },
                        android: { priority: "high" },
                    });
                } catch (error) {
                    console.error(`[EVENTS] Failed to send recap push for ${push.uid}`, error);
                }
            }

            console.log(`[EVENTS] Expired event modes for ${count} users.`);
        }
    }
);
