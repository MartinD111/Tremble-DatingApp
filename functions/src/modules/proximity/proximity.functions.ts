/**
 * Tremble — Proximity Functions
 *
 * Handles location updates and nearby user discovery.
 * Uses geohash-based queries for efficient proximity filtering.
 *
 * Interaction System v2.1:
 * - onBleProximity sends a fully anonymous CROSSING_PATHS notification.
 * - Anti-spam: 15-minute cooldown between notifications per user pair.
 * - No name, no photo revealed at this stage.
 */

import { onCall } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { z } from "zod";
import { validateRequest } from "../../middleware/validate";

const db = getFirestore();

// ── Schemas ──────────────────────────────────────────────

const updateLocationSchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
});

const findNearbySchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    radiusKm: z.number().min(0.1).max(100).default(5),
});

// ── Geohash Utils ────────────────────────────────────────

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

/**
 * Encode a lat/lng into a geohash string.
 * Precision 7 gives ~150m accuracy — good for proximity matching.
 */
function encodeGeohash(lat: number, lng: number, precision: number = 7): string {
    let idx = 0;
    let bit = 0;
    let evenBit = true;
    let geohash = "";

    const latRange = [-90.0, 90.0];
    const lngRange = [-180.0, 180.0];

    while (geohash.length < precision) {
        if (evenBit) {
            const mid = (lngRange[0] + lngRange[1]) / 2;
            if (lng >= mid) { idx = idx * 2 + 1; lngRange[0] = mid; }
            else { idx = idx * 2; lngRange[1] = mid; }
        } else {
            const mid = (latRange[0] + latRange[1]) / 2;
            if (lat >= mid) { idx = idx * 2 + 1; latRange[0] = mid; }
            else { idx = idx * 2; latRange[1] = mid; }
        }
        evenBit = !evenBit;
        if (++bit === 5) { geohash += BASE32[idx]; bit = 0; idx = 0; }
    }

    return geohash;
}

/**
 * Get the geohash prefix for a given radius.
 * Shorter prefix = wider area.
 */
function geohashPrecisionForRadius(radiusKm: number): number {
    if (radiusKm <= 0.5) return 7;
    if (radiusKm <= 1) return 6;
    if (radiusKm <= 5) return 5;
    if (radiusKm <= 20) return 4;
    if (radiusKm <= 80) return 3;
    return 2;
}

/**
 * Calculate distance between two lat/lng points (Haversine formula).
 */
function haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ── Cloud Functions ──────────────────────────────────────

/**
 * Update user's current location.
 * Called periodically by the background service.
 */
export const updateLocation = onCall(
    { maxInstances: 100, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        await checkRateLimit(uid, "updateLocation", {
            maxRequests: 60,
            windowMs: 60_000,
        });

        const data = validateRequest(updateLocationSchema, request.data);
        const geohash = encodeGeohash(data.latitude, data.longitude);

        await db
            .collection("proximity")
            .doc(uid)
            .set(
                {
                    geohash,
                    lat: data.latitude,
                    lng: data.longitude,
                    lastSeen: FieldValue.serverTimestamp(),
                    isActive: true,
                },
                { merge: true }
            );

        return { success: true, geohash };
    }
);

/**
 * Find nearby users based on geohash proximity.
 * Returns users within the specified radius.
 */
export const findNearby = onCall(
    { maxInstances: 100, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        await checkRateLimit(uid, "findNearby", {
            maxRequests: 20,
            windowMs: 60_000,
        });

        const data = validateRequest(findNearbySchema, request.data);

        const requesterDoc = await db.collection("users").doc(uid).get();
        const requesterData = requesterDoc.data();
        if (!requesterData) {
            console.log(`[PROXIMITY] Requester data not found: ${uid}`);
            return { nearby: [] };
        }

        const myGender = requesterData.gender;
        const myInterest = requesterData.interestedIn;
        const myAge = requesterData.age;
        const myMinAge = requesterData.ageRangeStart ?? 18;
        const myMaxAge = requesterData.ageRangeEnd ?? 100;
        const blockedUsers = requesterData.blockedUserIds || [];

        const precision = geohashPrecisionForRadius(data.radiusKm ?? 5);
        const centerGeohash = encodeGeohash(data.latitude, data.longitude, precision);

        const snapshot = await db
            .collection("proximity")
            .where("isActive", "==", true)
            .where("geohash", ">=", centerGeohash)
            .where("geohash", "<=", centerGeohash + "\uf8ff")
            .limit(100)
            .get();

        const candidates: Array<{ id: string; distance: number }> = [];

        for (const doc of snapshot.docs) {
            if (doc.id === uid) continue;
            if (blockedUsers.includes(doc.id)) continue;

            const docData = doc.data();
            const distance = haversineDistance(
                data.latitude, data.longitude,
                docData.lat, docData.lng
            );

            if (distance <= (data.radiusKm ?? 5)) {
                candidates.push({ id: doc.id, distance });
            }
        }

        const nearbyUsers: Array<{ userId: string; distanceKm: number }> = [];
        const userDocs = await Promise.all(candidates.map(c => db.collection("users").doc(c.id).get()));

        for (let i = 0; i < userDocs.length; i++) {
            const candidateDoc = userDocs[i];
            const candidateData = candidateDoc.data();
            if (!candidateData) continue;

            const theirGender = candidateData.gender;
            const theirInterest = candidateData.interestedIn;
            const theirAge = candidateData.age;
            const theirMinAge = candidateData.ageRangeStart ?? 18;
            const theirMaxAge = candidateData.ageRangeEnd ?? 100;

            const iMatchThem = myInterest === "Oba" || myInterest === "Both" || myInterest === theirGender;
            const theyMatchMe = theirInterest === "Oba" || theirInterest === "Both" || theirInterest === myGender;
            const ageMatchesMe = !theirAge || (theirAge >= myMinAge && theirAge <= myMaxAge);
            const ageMatchesThem = !myAge || (myAge >= theirMinAge && myAge <= theirMaxAge);

            if (iMatchThem && theyMatchMe && ageMatchesMe && ageMatchesThem) {
                nearbyUsers.push({
                    userId: candidates[i].id,
                    distanceKm: Math.round(candidates[i].distance * 10) / 10,
                });
            }
        }

        nearbyUsers.sort((a, b) => a.distanceKm - b.distanceKm);
        console.log(`[PROXIMITY] ${uid}: ${nearbyUsers.length} users within ${data.radiusKm}km`);

        return { nearby: nearbyUsers };
    }
);

/**
 * Mark user as inactive (called when app goes to background).
 */
export const setInactive = onCall(
    { maxInstances: 100, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        await db.collection("proximity").doc(uid).update({
            isActive: false,
            lastSeen: FieldValue.serverTimestamp(),
        });

        return { success: true };
    }
);

// ── BLE Proximity Trigger ─────────────────────────────────

/**
 * onBleProximity — Interaction System v2.1: CROSSING_PATHS
 *
 * Sends a fully anonymous push notification to the target user.
 * No name, no photo, no identity is revealed at this stage.
 *
 * Anti-spam: 15-minute cooldown per user pair enforced via
 * proximity_notifications/{uid_uid} documents.
 *
 * Privacy: proximity_events has a 10-minute TTL via Firestore TTL
 * policy on the `ttl` field (must be set in Firebase Console).
 */
export const onBleProximity = onDocumentCreated(
    { document: "proximity_events/{eventId}", region: "europe-west1" },
    async (event) => {
        const data = event.data?.data();
        if (!data) return;

        const { from: fromUid, toDeviceId } = data as {
            from: string;
            toDeviceId: string;
            timestamp: Timestamp;
        };

        if (!fromUid || !toDeviceId) return;

        // Resolve toDeviceId → Tremble UID
        const toUidSnapshot = await db
            .collection("proximity")
            .where("deviceId", "==", toDeviceId)
            .limit(1)
            .get();

        if (toUidSnapshot.empty) {
            console.log(`[BLE] Device ${toDeviceId} not registered — skipping`);
            return;
        }

        const toUid = toUidSnapshot.docs[0].id;
        if (fromUid === toUid) return;

        // ── 15-minute anti-spam cooldown ──────────────────
        const spamKey = [fromUid, toUid].sort().join("_");
        const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);

        const recentNotif = await db
            .collection("proximity_notifications")
            .doc(spamKey)
            .get();

        if (recentNotif.exists) {
            const sentAt = recentNotif.data()?.sentAt?.toDate() as Date | undefined;
            if (sentAt && sentAt > fifteenMinutesAgo) {
                console.log(`[BLE] Anti-spam: cooldown active for ${spamKey}`);
                return;
            }
        }

        // ── Skip if already matched ───────────────────────
        const matchId1 = [fromUid, toUid].sort().join("_");
        const existingMatch = await db.collection("matches").doc(matchId1).get();
        if (existingMatch.exists) {
            console.log(`[BLE] Match already exists for ${spamKey} — skipping`);
            return;
        }

        // ── Send anonymous CROSSING_PATHS notification ────
        const targetUserDoc = await db.collection("users").doc(toUid).get();
        const fcmToken = targetUserDoc.data()?.fcmToken as string | undefined;

        if (!fcmToken) {
            console.log(`[BLE] No FCM token for ${toUid}`);
            return;
        }

        await getMessaging().send({
            token: fcmToken,
            notification: {
                title: "Tremble",
                // ANONYMOUS — no name, no image, no identity at this stage.
                body: "Nekdo je blizu. Boš pomahal-a?",
            },
            data: {
                type: "CROSSING_PATHS",
            },
            apns: {
                payload: {
                    aps: { sound: "default" },
                },
            },
            android: {
                priority: "high",
            },
        });

        // Record send to enforce cooldown
        await db.collection("proximity_notifications").doc(spamKey).set({
            sentAt: FieldValue.serverTimestamp(),
            users: [fromUid, toUid],
        });

        console.log(`[BLE] CROSSING_PATHS sent anonymously to ${toUid}`);
    }
);
