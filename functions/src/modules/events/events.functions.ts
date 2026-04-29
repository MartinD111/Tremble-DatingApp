import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { requireAuth } from "../../middleware/authGuard";
import { ENFORCE_APP_CHECK } from "../../config/env";

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
        const { eventId, latitude, longitude } = request.data;

        if (!eventId || latitude === undefined || longitude === undefined) {
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

        // Verify user is within radius
        const eventLat = eventData.location?.lat;
        const eventLng = eventData.location?.lng;
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

// Scheduled — expire event modes every hour
export const expireEventModes = onSchedule(
    { schedule: 'every 60 minutes', region: "europe-west1" },
    async (event) => {
        const expired = await db.collection('users')
            .where('eventModeUntil', '<', Timestamp.now())
            .get();

        if (expired.empty) return;

        const batch = db.batch();
        let count = 0;

        expired.docs.forEach(doc => {
            // Only update if activeEventId is set to avoid unnecessary writes
            if (doc.data().activeEventId) {
                batch.update(doc.ref, { activeEventId: null, eventModeUntil: null });
                count++;
            }
        });

        if (count > 0) {
            await batch.commit();
            console.log(`[EVENTS] Expired event modes for ${count} users.`);
        }
    }
);
