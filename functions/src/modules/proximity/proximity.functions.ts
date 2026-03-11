/**
 * Tremble — Proximity Functions
 *
 * Handles location updates and nearby user discovery.
 * Uses geohash-based queries for efficient proximity filtering.
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
function encodeGeohash(
    lat: number,
    lng: number,
    precision: number = 7
): string {
    let idx = 0;
    let bit = 0;
    let evenBit = true;
    let geohash = "";

    const latRange = [-90.0, 90.0];
    const lngRange = [-180.0, 180.0];

    while (geohash.length < precision) {
        if (evenBit) {
            const mid = (lngRange[0] + lngRange[1]) / 2;
            if (lng >= mid) {
                idx = idx * 2 + 1;
                lngRange[0] = mid;
            } else {
                idx = idx * 2;
                lngRange[1] = mid;
            }
        } else {
            const mid = (latRange[0] + latRange[1]) / 2;
            if (lat >= mid) {
                idx = idx * 2 + 1;
                latRange[0] = mid;
            } else {
                idx = idx * 2;
                latRange[1] = mid;
            }
        }
        evenBit = !evenBit;

        if (++bit === 5) {
            geohash += BASE32[idx];
            bit = 0;
            idx = 0;
        }
    }

    return geohash;
}

/**
 * Get the geohash prefix for a given radius.
 * Shorter prefix = wider area.
 */
function geohashPrecisionForRadius(radiusKm: number): number {
    if (radiusKm <= 0.5) return 7;   // ~150m
    if (radiusKm <= 1) return 6;     // ~1.2km
    if (radiusKm <= 5) return 5;     // ~5km
    if (radiusKm <= 20) return 4;    // ~40km
    if (radiusKm <= 80) return 3;    // ~150km
    return 2;                         // ~600km
}

/**
 * Calculate distance between two lat/lng points (Haversine formula).
 */
function haversineDistance(
    lat1: number, lng1: number,
    lat2: number, lng2: number
): number {
    const R = 6371; // Earth radius in km
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
    { maxInstances: 100 },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 60 location updates per minute (once per second max)
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
    { maxInstances: 100 },
    async (request) => {
        const uid = requireAuth(request);

        await checkRateLimit(uid, "findNearby", {
            maxRequests: 20,
            windowMs: 60_000,
        });

        const data = validateRequest(findNearbySchema, request.data);

        // Fetch the requesting user's profile to get their matching preferences
        const requesterDoc = await db.collection("users").doc(uid).get();
        const requesterData = requesterDoc.data();
        if (!requesterData) {
            console.log(`[PROXIMITY] Requester data not found: ${uid}`);
            return { nearby: [] };
        }

        const myGender = requesterData.gender; // e.g. "Moški", "Ženska"
        const myInterest = requesterData.interestedIn; // e.g. "Moški", "Ženska", "Oba", "Both"
        const myAge = requesterData.age;
        const myMinAge = requesterData.ageRangeStart ?? 18;
        const myMaxAge = requesterData.ageRangeEnd ?? 100;
        const blockedUsers = requesterData.blockedUserIds || [];

        // Get the geohash prefix for the search radius
        const precision = geohashPrecisionForRadius(data.radiusKm ?? 5);
        const centerGeohash = encodeGeohash(
            data.latitude,
            data.longitude,
            precision
        );

        // Query by geohash prefix (Firestore range query)
        const snapshot = await db
            .collection("proximity")
            .where("isActive", "==", true)
            .where("geohash", ">=", centerGeohash)
            .where("geohash", "<=", centerGeohash + "\uf8ff")
            .limit(100)
            .get();

        // Filter by actual distance (geohash is approximate)
        const candidates: Array<{ id: string; distance: number }> = [];

        for (const doc of snapshot.docs) {
            if (doc.id === uid) continue; // Skip self
            if (blockedUsers.includes(doc.id)) continue; // Filter out blocked users

            const docData = doc.data();
            const distance = haversineDistance(
                data.latitude,
                data.longitude,
                docData.lat,
                docData.lng
            );

            if (distance <= (data.radiusKm ?? 5)) {
                candidates.push({ id: doc.id, distance });
            }
        }

        // Fetch user profiles for the candidates to apply gender/preference filters
        const nearbyUsers: Array<{
            userId: string;
            distanceKm: number;
        }> = [];

        // Concurrently fetch profile data for distance-validated candidates
        const userDocs = await Promise.all(
            candidates.map(c => db.collection("users").doc(c.id).get())
        );

        for (let i = 0; i < userDocs.length; i++) {
            const candidateDoc = userDocs[i];
            const candidateData = candidateDoc.data();
            if (!candidateData) continue;

            const theirGender = candidateData.gender;
            const theirInterest = candidateData.interestedIn;
            const theirAge = candidateData.age;
            const theirMinAge = candidateData.ageRangeStart ?? 18;
            const theirMaxAge = candidateData.ageRangeEnd ?? 100;

            // Match logic (Orientation)
            // 1) I must be interested in their gender (or Oba/Both)
            const iMatchThem = myInterest === "Oba" || myInterest === "Both" || myInterest === theirGender;
            // 2) They must receive my gender (or Oba/Both)
            const theyMatchMe = theirInterest === "Oba" || theirInterest === "Both" || theirInterest === myGender;

            // Match logic (Age gating)
            const ageMatchesMe = !theirAge || (theirAge >= myMinAge && theirAge <= myMaxAge);
            const ageMatchesThem = !myAge || (myAge >= theirMinAge && myAge <= theirMaxAge);

            if (iMatchThem && theyMatchMe && ageMatchesMe && ageMatchesThem) {
                nearbyUsers.push({
                    userId: candidates[i].id,
                    distanceKm: Math.round(candidates[i].distance * 10) / 10,
                });
            }
        }

        // Sort by distance
        nearbyUsers.sort((a, b) => a.distanceKm - b.distanceKm);

        console.log(
            `[PROXIMITY] ${uid}: ${nearbyUsers.length} users within ${data.radiusKm}km`
        );

        return { nearby: nearbyUsers };
    }
);

/**
 * Mark user as inactive (called when app goes to background).
 */
export const setInactive = onCall(
    { maxInstances: 100 },
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
 * onBleProximity — Firestore trigger on proximity_events/{eventId}
 *
 * Validates mutual BLE detection: both A→B and B→A must exist within
 * a 5-minute window. On mutual detection:
 *  1. Creates a match candidate in `matches/` (status: "ble_candidate")
 *  2. Sends FCM notification to both users
 *  3. Proximity event auto-deletes after TTL (client-side) or is cleaned up here.
 *
 * Privacy: proximity_events has a 10-minute TTL. Firestore TTL policy
 * must be configured in Firebase console on the `ttl` field.
 */
export const onBleProximity = onDocumentCreated(
    "proximity_events/{eventId}",
    async (event) => {
        const data = event.data?.data();
        if (!data) return;

        const { from: fromUid, toDeviceId } = data as {
            from: string;
            toDeviceId: string;
            timestamp: Timestamp;
        };

        if (!fromUid || !toDeviceId) return;

        // Resolve toDeviceId → Tremble UID by looking up proximity collection
        // Devices store their deviceId in proximity/{uid}.deviceId on first scan
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

        // Prevent self-matching
        if (fromUid === toUid) return;

        // Check for existing match (prevent duplicates)
        const existingMatch = await db
            .collection("matches")
            .where("userA", "in", [fromUid, toUid])
            .where("userB", "in", [fromUid, toUid])
            .limit(1)
            .get();

        if (!existingMatch.empty) {
            console.log(`[BLE] Match already exists: ${fromUid} ↔ ${toUid}`);
            return;
        }

        // Look for the reverse event: toUid → fromUid within 5-minute window
        const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
        const reverseEvents = await db
            .collection("proximity_events")
            .where("from", "==", toUid)
            .where("toDeviceId", "==", fromUid) // fromUid used as deviceId proxy for now
            .where("timestamp", ">=", Timestamp.fromDate(fiveMinutesAgo))
            .limit(1)
            .get();

        if (reverseEvents.empty) {
            console.log(`[BLE] One-sided detection: ${fromUid} → ${toUid}. Waiting for reverse.`);
            return;
        }

        // ── Mutual detection confirmed ────────────────────
        console.log(`[BLE] Mutual detection: ${fromUid} ↔ ${toUid} — creating match candidate`);

        const matchRef = db.collection("matches").doc();
        await matchRef.set({
            userA: fromUid,
            userB: toUid,
            status: "ble_candidate",
            discoveryMethod: "ble",
            createdAt: FieldValue.serverTimestamp(),
        });

        // Fetch FCM tokens for both users
        const [userADoc, userBDoc] = await Promise.all([
            db.collection("users").doc(fromUid).get(),
            db.collection("users").doc(toUid).get(),
        ]);

        const userAToken = userADoc.data()?.fcmToken as string | undefined;
        const userBToken = userBDoc.data()?.fcmToken as string | undefined;
        const userAName = userADoc.data()?.name as string | undefined ?? "Someone";
        const userBName = userBDoc.data()?.name as string | undefined ?? "Someone";

        const messaging = getMessaging();
        const notifications = [];

        if (userAToken) {
            notifications.push(
                messaging.send({
                    token: userAToken,
                    notification: {
                        title: "Tremble 💫",
                        body: `${userBName} is nearby! Say hello.`,
                    },
                    data: { matchId: matchRef.id, type: "ble_match" },
                })
            );
        }

        if (userBToken) {
            notifications.push(
                messaging.send({
                    token: userBToken,
                    notification: {
                        title: "Tremble 💫",
                        body: `${userAName} is nearby! Say hello.`,
                    },
                    data: { matchId: matchRef.id, type: "ble_match" },
                })
            );
        }

        await Promise.allSettled(notifications);
        console.log(`[BLE] Match candidate ${matchRef.id} created and notifications sent.`);
    }
);
