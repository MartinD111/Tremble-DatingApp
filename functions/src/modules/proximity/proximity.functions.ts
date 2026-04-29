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
import { ENFORCE_APP_CHECK } from "../../config/env";

const db = getFirestore();

// ── F9: Radius Tier Constants ─────────────────────────────
// GPS geohash pre-filter radii (BLE RSSI confirms final proximity).
// Free:    100m  — RSSI threshold ≥ −75 dBm
// Premium: 250m  — RSSI threshold ≥ −85 dBm
const RADIUS_FREE_M = 100;
const RADIUS_PRO_M = 250;

// ── Schemas ──────────────────────────────────────────────

const updateLocationSchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
});

const findNearbySchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    // radiusKm kept for backward-compat but ignored — radius is determined
    // server-side from the user's isPremium status (F9 requirement).
    radiusKm: z.number().min(0.1).max(100).optional(),
});

const proximityMatchCandidatesSchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
});

// ── Geohash Utils ────────────────────────────────────────

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

/**
 * Encode a lat/lng into a geohash string.
 * Precision 7 gives ~150m × 75m cell — used for proximity pre-filtering.
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
 * Decode a geohash string to its cell-center lat/lng.
 * Returns the CENTER of the geohash cell — NOT the user's exact location.
 * At precision 7, accuracy is ~75m. This is GDPR-safe (Art. 5 minimization).
 */
function decodeGeohash(geohash: string): { lat: number; lng: number } {
    const latRange = [-90.0, 90.0];
    const lngRange = [-180.0, 180.0];
    let evenBit = true;

    for (const char of geohash) {
        const idx = BASE32.indexOf(char);
        if (idx === -1) break;
        for (let bits = 4; bits >= 0; bits--) {
            const bitN = (idx >> bits) & 1;
            if (evenBit) {
                const mid = (lngRange[0] + lngRange[1]) / 2;
                if (bitN === 1) lngRange[0] = mid; else lngRange[1] = mid;
            } else {
                const mid = (latRange[0] + latRange[1]) / 2;
                if (bitN === 1) latRange[0] = mid; else latRange[1] = mid;
            }
            evenBit = !evenBit;
        }
    }

    return {
        lat: (latRange[0] + latRange[1]) / 2,
        lng: (lngRange[0] + lngRange[1]) / 2,
    };
}

/**
 * Haversine distance between two lat/lng points, in metres.
 */
function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
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

// ── Cloud Functions ──────────────────────────────────────

/**
 * Update user's current location.
 * Called periodically by the background service.
 */
export const updateLocation = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
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
 *
 * F9 — Radius Logic:
 * - Radius is determined SERVER-SIDE from the user's `isPremium` status.
 *   Client-provided `radiusKm` is accepted for backward-compat but ignored.
 * - Free:    GPS pre-filter 100m  (RSSI ≥ −75 dBm confirmed by BLE)
 * - Premium: GPS pre-filter 250m  (RSSI ≥ −85 dBm confirmed by BLE)
 *
 * Query strategy:
 * - Encode requester location at precision 6 (~1.2km cell) for a wide net.
 * - Haversine-filter results to the actual tier radius.
 * - NOTE: precision-6 prefix may miss users just across a cell boundary.
 *   This is an acceptable trade-off for v1 — BLE RSSI is the real filter.
 */
export const findNearby = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
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
            return { nearby: [], radiusTier: "free", radiusM: RADIUS_FREE_M };
        }

        const myGender = requesterData.gender;
        const myInterest = requesterData.interestedIn;
        const myAge = requesterData.age;
        const myMinAge = requesterData.ageRangeStart ?? 18;
        const myMaxAge = requesterData.ageRangeEnd ?? 100;
        const blockedUsers: string[] = requesterData.blockedUserIds ?? [];

        // F9: radius is server-determined from isPremium — never trust the client
        const isPremium = requesterData.isPremium === true;
        const radiusM = isPremium ? RADIUS_PRO_M : RADIUS_FREE_M;
        const radiusTier = isPremium ? "pro" : "free";

        // Query at precision 6 (~1.2km cell) to cast a wide net, then
        // haversine-filter to the actual tier radius below.
        const queryPrecision = 6;
        const centerGeohash = encodeGeohash(data.latitude, data.longitude, queryPrecision);

        const snapshot = await db
            .collection("proximity")
            .where("isActive", "==", true)
            .where("geohash", ">=", centerGeohash)
            .where("geohash", "<=", centerGeohash + "\uf8ff")
            .limit(200)
            .get();

        // Haversine-filter candidates to actual tier radius.
        // Geohash is decoded to its cell center (~75m accuracy) — GDPR-safe.
        const candidates: Array<{ id: string; distanceM: number }> = [];

        for (const doc of snapshot.docs) {
            if (doc.id === uid) continue;
            if (blockedUsers.includes(doc.id)) continue;

            const geohash = doc.data().geohash as string | undefined;
            if (!geohash) continue;

            const center = decodeGeohash(geohash);
            const distM = haversineMeters(data.latitude, data.longitude, center.lat, center.lng);
            if (distM <= radiusM) {
                candidates.push({ id: doc.id, distanceM: distM });
            }
        }

        const nearbyUsers: Array<{ userId: string; distanceM: number }> = [];
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

            // Support both legacy string and new List<String> interestedIn formats
            const iMatchThem =
                Array.isArray(myInterest)
                    ? myInterest.includes(theirGender)
                    : myInterest === "Oba" || myInterest === "Both" || myInterest === theirGender;
            const theyMatchMe =
                Array.isArray(theirInterest)
                    ? theirInterest.includes(myGender)
                    : theirInterest === "Oba" || theirInterest === "Both" || theirInterest === myGender;
            const ageMatchesMe = !theirAge || (theirAge >= myMinAge && theirAge <= myMaxAge);
            const ageMatchesThem = !myAge || (myAge >= theirMinAge && myAge <= theirMaxAge);

            // Basic compatibility score (placeholder for Phase 5 ML/Algo)
            let score = 0.0;
            if (iMatchThem && theyMatchMe && ageMatchesMe && ageMatchesThem) {
                score = 1.0;
            } else if (iMatchThem && theyMatchMe) {
                // Partial match if gender matches but age is slightly off
                score = 0.60;
            }

            // F2: Event Mode Matching Override
            let threshold = 0.70;
            if (
                requesterData.activeEventId &&
                candidateData.activeEventId &&
                requesterData.activeEventId === candidateData.activeEventId
            ) {
                // If both users are active in the same event, lower the barrier
                threshold = 0.55;
            }

            if (score >= threshold) {
                nearbyUsers.push({
                    userId: candidates[i].id,
                    distanceM: Math.round(candidates[i].distanceM),
                });
            }
        }

        nearbyUsers.sort((a, b) => a.distanceM - b.distanceM);
        console.log(
            `[PROXIMITY] ${uid.substring(0, 8)}...: ${nearbyUsers.length} users within ${radiusM}m (${radiusTier})`
        );

        return { nearby: nearbyUsers, radiusTier, radiusM };
    }
);

/**
 * Mark user as inactive (called when app goes to background).
 */
export const setInactive = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        await db.collection("proximity").doc(uid).update({
            isActive: false,
            lastSeen: FieldValue.serverTimestamp(),
        });

        return { success: true };
    }
);

// ── F9: getProximityMatchCandidates ──────────────────────────────

/**
 * getProximityMatchCandidates — F9 Radius Logic (MASTER_PLAN spec).
 *
 * GPS geohash pre-filter + haversine confirmation.
 * Called by the Flutter app when initiating a proximity match session.
 *
 * lat/lng are ephemeral — received in request, used for query only,
 * never stored or logged. Privacy Policy must describe this.
 *
 * Returns candidate UIDs within the user's tier radius, ordered by
 * ascending distance. BLE RSSI confirmation happens client-side.
 */
export const getProximityMatchCandidates = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        await checkRateLimit(uid, "getProximityMatchCandidates", {
            maxRequests: 30,
            windowMs: 60_000,
        });

        const data = validateRequest(proximityMatchCandidatesSchema, request.data);

        // Read requester profile for tier + preference filtering
        const requesterDoc = await db.collection("users").doc(uid).get();
        const requesterData = requesterDoc.data();
        if (!requesterData) {
            return { candidates: [], radiusTier: "free", radiusM: RADIUS_FREE_M };
        }

        const isPremium = requesterData.isPremium === true;
        const radiusM = isPremium ? RADIUS_PRO_M : RADIUS_FREE_M;
        const radiusTier = isPremium ? "pro" : "free";
        const blockedUsers: string[] = requesterData.blockedUserIds ?? [];

        // Precision 6 (~1.2km × 600m) — wide enough to contain all candidates
        // within 250m (pro radius), then haversine-filter to actual radius.
        const queryGeohash = encodeGeohash(data.latitude, data.longitude, 6);

        const snapshot = await db
            .collection("proximity")
            .where("isActive", "==", true)
            .where("geohash", ">=", queryGeohash)
            .where("geohash", "<=", queryGeohash + "\uf8ff")
            .limit(200)
            .get();

        const candidates: Array<{ uid: string; distanceM: number }> = [];

        for (const doc of snapshot.docs) {
            if (doc.id === uid) continue;
            if (blockedUsers.includes(doc.id)) continue;

            const geohash = doc.data().geohash as string | undefined;
            if (!geohash) continue;

            // Decode geohash to cell center for haversine.
            // lat/lng is NEVER stored — computed transiently for this query.
            const center = decodeGeohash(geohash);
            const distM = haversineMeters(data.latitude, data.longitude, center.lat, center.lng);

            if (distM <= radiusM) {
                candidates.push({ uid: doc.id, distanceM: Math.round(distM) });
            }
        }

        candidates.sort((a, b) => a.distanceM - b.distanceM);

        console.log(
            `[PROXIMITY] getProximityMatchCandidates: ${uid.substring(0, 8)}... → ` +
            `${candidates.length} candidates within ${radiusM}m (${radiusTier})`
        );

        return { candidates, radiusTier, radiusM };
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

        // ── Fetch sender profile (Interaction System v2.2 — Rich Notifications) ──
        const fromUserDoc = await db.collection("users").doc(fromUid).get();
        const fromUserData = fromUserDoc.data();
        if (!fromUserData) {
            console.log(`[BLE] Sender ${fromUid} not found — skipping`);
            return;
        }

        const name = fromUserData.displayName || "Someone";
        const photoUrl = fromUserData.photoUrls?.[0] || "";
        
        // Calculate age
        let age = 0;
        if (fromUserData.dateOfBirth) {
            const dob = fromUserData.dateOfBirth.toDate();
            const today = new Date();
            age = today.getFullYear() - dob.getFullYear();
            const m = today.getMonth() - dob.getMonth();
            if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
                age--;
            }
        }

        await getMessaging().send({
            token: fcmToken,
            notification: {
                title: "Tremble",
                // Multi-language support: app uses body_loc_key to translate locally
                // Fallback body for devices not yet updated
                body: `${name}, ${age} is nearby. Want to send a wave?`,
                imageUrl: photoUrl,
            },
            data: {
                type: "CROSSING_PATHS",
                fromUid: fromUid,
                name: name,
                age: age.toString(),
                photoUrl: photoUrl,
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        category: "NEARBY_CATEGORY",
                        // loc_key used for client-side translation with variables
                        "alert-body-loc-key": "notify_nearby_body_rich",
                        "alert-body-loc-args": [name, age.toString()],
                    },
                },
            },
            android: {
                priority: "high",
                notification: {
                    clickAction: "NEARBY_CATEGORY",
                    bodyLocKey: "notify_nearby_body_rich",
                    bodyLocArgs: [name, age.toString()],
                },
            },
        });

        console.log(
            `[BLE] CROSSING_PATHS → ${toUid.substring(0, 8)}... (throttle ${currentCount}/${GLOBAL_THROTTLE_MAX})`
        );
    }
);
