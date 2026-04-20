/**
 * Tremble — Proximity Functions
 *
 * Handles location updates and nearby user discovery.
 * Uses geohash-based queries for efficient proximity filtering.
 *
 * Interaction System v2.1:
 * - onBleProximity sends a fully anonymous CROSSING_PATHS notification.
 * - Anti-spam: Redis-backed 30-min pair cooldown + global 10-min throttle.
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
import {
    getRedis,
    proximityCooldownKey,
    globalThrottleKey,
    PROXIMITY_COOLDOWN_SECS,
    GLOBAL_THROTTLE_SECS,
    GLOBAL_THROTTLE_MAX,
} from "../../core/redis";

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
            console.log(`[PROXIMITY] Requester data not found: ${uid.substring(0, 8)}...`);
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
        console.log(`[PROXIMITY] ${uid.substring(0, 8)}...: ${nearbyUsers.length} users within ${data.radiusKm}km`);

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

// ── BLE Proximity Trigger ─────────────────────────────────────────

/**
 * onBleProximity — Interaction System v2.1: CROSSING_PATHS
 *
 * Sends a fully anonymous CROSSING_PATHS notification.
 * No name, no photo, no identity revealed at this stage.
 *
 * Anti-spam (Redis-backed, production-grade):
 *   1. Pair cooldown:    30 min per user pair (prox_cooldown:{a_b}).
 *      Uses SET NX EX — atomic, O(1), no Firestore reads.
 *   2. Global throttle:  max 3 CROSSING_PATHS per recipient per 10 min.
 *      Enforces "Stoic/Solid" brand — stays silent in dense crowds.
 *
 * Security: onDocumentCreated receives data written by authenticated,
 * App-Check-verified clients. Input is trusted.
 *
 * Privacy: proximity_events TTL = 10 min (Firestore TTL policy on `ttl`).
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

        // ── Skip if already matched ───────────────────────────────
        const matchId = [fromUid, toUid].sort().join("_");
        const existingMatch = await db.collection("matches").doc(matchId).get();
        if (existingMatch.exists) {
            console.log(`[BLE] Match already exists (${matchId}) — skipping`);
            return;
        }

        // ── Fetch target user (needed for FCM token + block list) ─
        const toUserDoc = await db.collection("users").doc(toUid).get();
        const fcmToken = toUserDoc.data()?.fcmToken as string | undefined;
        const blockedIds: string[] = toUserDoc.data()?.blockedUserIds ?? [];

        // ── Skip if sender is blocked by recipient ────────────────
        if (blockedIds.includes(fromUid)) {
            console.log(`[BLE] ${fromUid.substring(0, 8)}... blocked by ${toUid.substring(0, 8)}... — skipping`);
            return;
        }

        const redis = getRedis();

        // ── 1. Pair cooldown (Redis, 30-min TTL) ──────────────────
        //    Atomic SET NX EX — only sets if key doesn't already exist.
        //    If key exists → cooldown active → skip without extra reads.
        const pairKey = proximityCooldownKey(fromUid, toUid);
        const pairSet = await redis.set(pairKey, "1", {
            ex: PROXIMITY_COOLDOWN_SECS,
            nx: true,
        });

        if (pairSet === null) {
            // nx failed — key already exists, cooldown active
            console.log(`[BLE] Pair cooldown active: ${pairKey}`);
            return;
        }

        // ── 2. Global throttle (Redis INCR + EXPIRE) ──────────────
        //    Sliding counter: max GLOBAL_THROTTLE_MAX pings per 10 min.
        //    Ensures Tremble stays "Stoic" even at events or busy places.
        const throttleKey = globalThrottleKey(toUid);
        const currentCount = await redis.incr(throttleKey);

        if (currentCount === 1) {
            // First notification this window — attach the TTL now
            await redis.expire(throttleKey, GLOBAL_THROTTLE_SECS);
        }

        if (currentCount > GLOBAL_THROTTLE_MAX) {
            console.log(
                `[BLE] Global throttle: ${toUid.substring(0, 8)}... at ${currentCount}/${GLOBAL_THROTTLE_MAX} — suppressing`
            );
            // Roll back pair cooldown so a later attempt in a quieter window succeeds
            await redis.del(pairKey);
            return;
        }

        // ── Send anonymous CROSSING_PATHS notification ────────────
        if (!fcmToken) {
            console.log(`[BLE] No FCM token for ${toUid.substring(0, 8)}...`);
            return;
        }

        await getMessaging().send({
            token: fcmToken,
            notification: {
                title: "Tremble",
                // ANONYMOUS — no name, no photo, no identity at this stage.
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

        console.log(
            `[BLE] CROSSING_PATHS → ${toUid.substring(0, 8)}... (throttle ${currentCount}/${GLOBAL_THROTTLE_MAX})`
        );
    }
);
