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
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { requireAuth, assertNotBanned } from "../../middleware/authGuard";
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
import { calculateCompatibilityScore } from "../compatibility/compatibility_calculator";

const db = getFirestore();

// ── F9: Radius Tier Constants ─────────────────────────────
// GPS geohash pre-filter radii (BLE RSSI confirms final proximity).
// Free:    100m  — RSSI threshold ≥ −75 dBm
// Premium: 250m  — RSSI threshold ≥ −85 dBm
const RADIUS_FREE_M = 100;
const RADIUS_PRO_M = 250;

function logStructured(fields: Record<string, unknown>): void {
    console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        ...fields,
    }));
}

function errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
}

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

// ── F11: Nicotine Compatibility Helpers ─────────────────────

/**
 * Returns true if the user's nicotineUse indicates active nicotine usage
 * (i.e., the array is non-empty and not exclusively ['none']).
 */
function userSmokes(nicotineUse: string[]): boolean {
    if (nicotineUse.length === 0) return false;
    return nicotineUse.some(u => u !== "none");
}

/**
 * Returns false when a hard nicotine incompatibility exists.
 *
 * Filter value 'none_only' is the only hard-exclude value.
 * 'any' and 'no_preference' (and missing/null) are both permissive.
 */
function nicotineCompatible(
    requesterUse: string[], requesterFilter: string,
    candidateUse: string[], candidateFilter: string,
): boolean {
    if (requesterFilter === "none_only" && userSmokes(candidateUse)) return false;
    if (candidateFilter === "none_only" && userSmokes(requesterUse)) return false;
    return true;
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
        const startedAt = Date.now();
        logStructured({ fn: "updateLocation", event: "entry", uid });

        try {
            await checkRateLimit(uid, "updateLocation", {
                maxRequests: 60,
                windowMs: 60_000,
            });

            const data = validateRequest(updateLocationSchema, request.data);

            const userDoc = await db.collection("users").doc(uid).get();
            assertNotBanned(userDoc.data());

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

            logStructured({ fn: "updateLocation", event: "success", uid, geohash, durationMs: Date.now() - startedAt });

            return { success: true, geohash };
        } catch (error) {
            logStructured({ fn: "updateLocation", event: "error", uid, error: errorMessage(error), durationMs: Date.now() - startedAt });
            throw error;
        }
    }
);

/**
 * Find nearby users based on geohash proximity.
 *
 * Primary identity resolution path for both iOS and Android.
 * BLE advertisement now signals presence via Tremble service UUID only — no UID in advertisement.
 * Caller's identity (uid from auth) + location resolves who is physically nearby.
 * iOS CoreBluetooth ignores custom manufacturer data in background; this function is the
 * correct resolution mechanism for all platforms.
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
        const startedAt = Date.now();
        logStructured({ fn: "findNearby", event: "entry", uid });

        try {
        await checkRateLimit(uid, "findNearby", {
            maxRequests: 20,
            windowMs: 60_000,
        });

        const data = validateRequest(findNearbySchema, request.data);

        const requesterDoc = await db.collection("users").doc(uid).get();
        const requesterData = requesterDoc.data();
        if (!requesterData) {
            console.log(`[PROXIMITY] Requester data not found: ${uid.substring(0, 8)}...`);
            logStructured({ fn: "findNearby", event: "success", uid, matchCount: 0, radiusM: RADIUS_FREE_M, radiusTier: "free", durationMs: Date.now() - startedAt });
            return { nearby: [], radiusTier: "free", radiusM: RADIUS_FREE_M };
        }

        assertNotBanned(requesterData);

        const myGender = requesterData.gender;
        const myInterest = requesterData.interestedIn;
        const myAge = requesterData.age;
        const myMinAge = requesterData.ageRangeStart ?? 18;
        const myMaxAge = requesterData.ageRangeEnd ?? 100;
        const blockedUsers: string[] = requesterData.blockedUserIds ?? [];
        const blockedGeohashes: string[] = requesterData.blockedGeohashes ?? [];

        // F9: radius is server-determined from isPremium — never trust the client
        const isPremium = requesterData.isPremium === true;
        const radiusM = isPremium ? RADIUS_PRO_M : RADIUS_FREE_M;
        const radiusTier = isPremium ? "pro" : "free";

        // F11: Nicotine preferences — filter only active for Premium users
        const myNicotineUse: string[] = requesterData.nicotineUse ?? [];
        const myNicotineFilter: string = isPremium ? (requesterData.nicotineFilter ?? "any") : "any";

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

            // F13: Geofencing Safe Zones (Backend Geohash check)
            if (blockedGeohashes.some(bg => geohash.startsWith(bg))) continue;

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
            if (candidateData.flaggedForReview === true) continue;

            const theirGender = candidateData.gender;
            const theirInterest = candidateData.interestedIn;
            const theirAge = candidateData.age;
            const theirMinAge = candidateData.ageRangeStart ?? 18;
            const theirMaxAge = candidateData.ageRangeEnd ?? 100;

            // F11: Nicotine hard filter — skip immediately if incompatible
            const theirNicotineUse: string[] = candidateData.nicotineUse ?? [];
            const theirNicotineFilter: string = candidateData.nicotineFilter ?? "any";
            if (!nicotineCompatible(myNicotineUse, myNicotineFilter, theirNicotineUse, theirNicotineFilter)) {
                continue;
            }

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

            // Compatibility score — interni signal, nikoli se ne shrani ali vrne v UI
            // KRITIČNO: nearbyUsers.push() spodaj ne sme vsebovati score polja
            let score = 0.0;
            if (iMatchThem && theyMatchMe && ageMatchesMe && ageMatchesThem) {
                score = calculateCompatibilityScore(
                    {
                        uid,
                        hobbies: requesterData.hobbies ?? [],
                        introvertScale: requesterData.introvertScale,
                        nicotineUse: requesterData.nicotineUse ?? [],
                        nicotineFilter: requesterData.nicotineFilter ?? "any",
                        drinkingHabit: requesterData.drinkingHabit,
                        partnerDrinkingHabit: requesterData.partnerDrinkingHabit,
                        exerciseHabit: requesterData.exerciseHabit,
                        sleepSchedule: requesterData.sleepSchedule,
                        religion: requesterData.religion,
                        religionPreference: requesterData.religionPreference,
                        lookingFor: requesterData.lookingFor ?? [],
                        isPremium: requesterData.isPremium ?? false,
                    },
                    {
                        uid: candidates[i].id,
                        hobbies: candidateData.hobbies ?? [],
                        introvertScale: candidateData.introvertScale,
                        nicotineUse: candidateData.nicotineUse ?? [],
                        nicotineFilter: candidateData.nicotineFilter ?? "any",
                        drinkingHabit: candidateData.drinkingHabit,
                        partnerDrinkingHabit: candidateData.partnerDrinkingHabit,
                        exerciseHabit: candidateData.exerciseHabit,
                        sleepSchedule: candidateData.sleepSchedule,
                        religion: candidateData.religion,
                        religionPreference: candidateData.religionPreference,
                        lookingFor: candidateData.lookingFor ?? [],
                        isPremium: candidateData.isPremium ?? false,
                    }
                );
            } else if (iMatchThem && theyMatchMe) {
                // Age mismatch — nižji baseline, ne 0 ker je gender match validen
                score = 0.45;
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
        logStructured({ fn: "findNearby", event: "success", uid, matchCount: nearbyUsers.length, radiusM, radiusTier, durationMs: Date.now() - startedAt });

        return { nearby: nearbyUsers, radiusTier, radiusM };
        } catch (error) {
            logStructured({ fn: "findNearby", event: "error", uid, error: errorMessage(error), durationMs: Date.now() - startedAt });
            throw error;
        }
    }
);

/**
 * Mark user as inactive (called when app goes to background).
 */
export const setInactive = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "setInactive", { maxRequests: 15, windowMs: 60000 });
        const startedAt = Date.now();
        logStructured({ fn: "setInactive", event: "entry", uid });

        try {
            await db.collection("proximity").doc(uid).update({
                isActive: false,
                lastSeen: FieldValue.serverTimestamp(),
            });

            logStructured({ fn: "setInactive", event: "success", uid, durationMs: Date.now() - startedAt });
            return { success: true };
        } catch (error) {
            logStructured({ fn: "setInactive", event: "error", uid, error: errorMessage(error), durationMs: Date.now() - startedAt });
            throw error;
        }
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
        const startedAt = Date.now();
        logStructured({ fn: "getProximityMatchCandidates", event: "entry", uid });

        try {
        await checkRateLimit(uid, "getProximityMatchCandidates", {
            maxRequests: 30,
            windowMs: 60_000,
        });

        const data = validateRequest(proximityMatchCandidatesSchema, request.data);

        // Read requester profile for ban check + tier + preference filtering
        const requesterDoc = await db.collection("users").doc(uid).get();
        const requesterData = requesterDoc.data();
        if (!requesterData) {
            logStructured({ fn: "getProximityMatchCandidates", event: "success", uid, matchCount: 0, radiusM: RADIUS_FREE_M, radiusTier: "free", durationMs: Date.now() - startedAt });
            return { candidates: [], radiusTier: "free", radiusM: RADIUS_FREE_M };
        }

        assertNotBanned(requesterData);

        const isPremium = requesterData.isPremium === true;
        const radiusM = isPremium ? RADIUS_PRO_M : RADIUS_FREE_M;
        const radiusTier = isPremium ? "pro" : "free";
        const blockedUsers: string[] = requesterData.blockedUserIds ?? [];
        const blockedGeohashes: string[] = requesterData.blockedGeohashes ?? [];

        // F11: Nicotine preferences — filter only active for Premium users
        const myNicotineUse: string[] = requesterData.nicotineUse ?? [];
        const myNicotineFilter: string = isPremium ? (requesterData.nicotineFilter ?? "any") : "any";

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

            // F13: Geofencing Safe Zones (Backend Geohash check)
            if (blockedGeohashes.some(bg => geohash.startsWith(bg))) continue;

            // Decode geohash to cell center for haversine.
            // lat/lng is NEVER stored — computed transiently for this query.
            const center = decodeGeohash(geohash);
            const distM = haversineMeters(data.latitude, data.longitude, center.lat, center.lng);

            if (distM <= radiusM) {
                candidates.push({ uid: doc.id, distanceM: Math.round(distM) });
            }
        }

        // F11: Batch-fetch user profiles to apply nicotine filter
        const userDocs = await Promise.all(
            candidates.map(c => db.collection("users").doc(c.uid).get())
        );

        const filteredCandidates: Array<{ uid: string; distanceM: number }> = [];
        for (let i = 0; i < candidates.length; i++) {
            const candidateData = userDocs[i].data();
            if (!candidateData) continue;
            if (candidateData.flaggedForReview === true) continue;

            const theirNicotineUse: string[] = candidateData.nicotineUse ?? [];
            const theirNicotineFilter: string = candidateData.nicotineFilter ?? "any";
            if (!nicotineCompatible(myNicotineUse, myNicotineFilter, theirNicotineUse, theirNicotineFilter)) {
                continue;
            }
            filteredCandidates.push(candidates[i]);
        }

        filteredCandidates.sort((a, b) => a.distanceM - b.distanceM);

        console.log(
            `[PROXIMITY] getProximityMatchCandidates: ${uid.substring(0, 8)}... → ` +
            `${filteredCandidates.length} candidates within ${radiusM}m (${radiusTier}) ` +
            `[nicotine filter: ${myNicotineFilter}]`
        );
        logStructured({ fn: "getProximityMatchCandidates", event: "success", uid, matchCount: filteredCandidates.length, radiusM, radiusTier, durationMs: Date.now() - startedAt });

        return { candidates: filteredCandidates, radiusTier, radiusM };
        } catch (error) {
            logStructured({ fn: "getProximityMatchCandidates", event: "error", uid, error: errorMessage(error), durationMs: Date.now() - startedAt });
            throw error;
        }
    }
);

// ── Scheduled Geohash-Based Encounter Detection ───────────────────

/**
 * scanProximityPairs — Scheduled encounter detection.
 *
 * Replaces the dead onBleProximity + onRunEncounter Firestore triggers.
 *
 * Background: BLE was redesigned to presence-only advertising (iOS does not
 * expose manufacturer data or custom UUIDs in background scans). Identity
 * resolution via toDeviceId was no longer possible client-side. The old
 * triggers fired on proximity_events/{eventId} docs that the client was
 * supposed to write — those docs were never written because the BLE redesign
 * removed the toDeviceId field from the write path.
 *
 * New approach: Server-side geohash grouping. Every active user's geohash
 * cell (precision 6 = ~1.2km) is known from proximity/{uid}. Users in the
 * same cell are candidates; haversine confirms actual radius. Redis 30-min
 * pair cooldown prevents duplicate notifications.
 *
 * Flow per invocation:
 *   1. Query proximity/{uid} where isActive=true AND updatedAt >= now-2min
 *   2. Group by geohash[:6] (~1.2km cell)
 *   3. Evaluate all unique pairs per group:
 *      a. Haversine distance ≤ effective radius (pro=250m, free=100m)
 *      b. Redis pair cooldown check (30-min NX SET)
 *      c. Fetch user profiles — skip blocked/flagged pairs
 *   4. For qualifying pairs: write proximity_events doc, send CROSSING_PATHS
 *      to both users (global throttle: max 3 per recipient per 10 min)
 */
export const scanProximityPairs = onSchedule(
    {
        schedule: "every 1 minutes",
        region: "europe-west1",
        timeoutSeconds: 540,
        memory: "256MiB",
    },
    async () => {
        const startedAt = Date.now();
        logStructured({ fn: "scanProximityPairs", event: "start" });

        // 1. Query active users with a fresh proximity update (last 2 minutes)
        const cutoff = Timestamp.fromDate(new Date(Date.now() - 2 * 60 * 1000));
        const snapshot = await db
            .collection("proximity")
            .where("isActive", "==", true)
            .where("updatedAt", ">=", cutoff)
            .get();

        if (snapshot.empty) {
            logStructured({ fn: "scanProximityPairs", event: "complete", activeUsers: 0, durationMs: Date.now() - startedAt });
            return;
        }

        logStructured({ fn: "scanProximityPairs", event: "query", activeUsers: snapshot.size });

        // 2. Group by geohash prefix (precision 6 = ~1.2km cell)
        type ProximityEntry = { uid: string; geohash: string; radiusTier: string };
        const groups = new Map<string, ProximityEntry[]>();

        for (const doc of snapshot.docs) {
            const data = doc.data();
            const geohash = data.geohash as string | undefined;
            if (!geohash || geohash.length < 6) continue;

            const prefix = geohash.substring(0, 6);
            if (!groups.has(prefix)) groups.set(prefix, []);
            groups.get(prefix)!.push({
                uid: doc.id,
                geohash,
                radiusTier: (data.radiusTier as string | undefined) ?? "free",
            });
        }

        const redis = getRedis();
        const messaging = getMessaging();
        let pairsEvaluated = 0;
        let pairsNotified = 0;

        // 3. Evaluate all unique pairs within each geohash cell
        for (const [, members] of groups) {
            if (members.length < 2) continue;

            for (let i = 0; i < members.length; i++) {
                for (let j = i + 1; j < members.length; j++) {
                    const a = members[i];
                    const b = members[j];
                    pairsEvaluated++;

                    // Effective radius: if either user is pro → 250m; both free → 100m (conservative)
                    const radiusM = (a.radiusTier === "pro" || b.radiusTier === "pro")
                        ? RADIUS_PRO_M
                        : RADIUS_FREE_M;

                    // Haversine from geohash cell centers — GDPR-safe (≥75m accuracy)
                    const aCenter = decodeGeohash(a.geohash);
                    const bCenter = decodeGeohash(b.geohash);
                    const distM = haversineMeters(aCenter.lat, aCenter.lng, bCenter.lat, bCenter.lng);
                    if (distM > radiusM) continue;

                    // Redis pair cooldown — skip if already notified within 30 min
                    const pairKey = proximityCooldownKey(a.uid, b.uid);
                    const pairSet = await redis.set(pairKey, "1", {
                        ex: PROXIMITY_COOLDOWN_SECS,
                        nx: true,
                    });
                    if (pairSet === null) continue; // cooldown active

                    // Fetch user profiles for block/flag checks and notification payload
                    const [aUserDoc, bUserDoc] = await Promise.all([
                        db.collection("users").doc(a.uid).get(),
                        db.collection("users").doc(b.uid).get(),
                    ]);

                    const aData = aUserDoc.data();
                    const bData = bUserDoc.data();

                    if (!aData || !bData) {
                        // Roll back — don't hold a cooldown for unresolvable UIDs
                        await redis.del(pairKey);
                        continue;
                    }

                    if (aData.flaggedForReview === true || bData.flaggedForReview === true) {
                        await redis.del(pairKey);
                        continue;
                    }

                    const aBlocked: string[] = aData.blockedUserIds ?? [];
                    const bBlocked: string[] = bData.blockedUserIds ?? [];
                    if (aBlocked.includes(b.uid) || bBlocked.includes(a.uid)) {
                        await redis.del(pairKey);
                        continue;
                    }

                    // 4. Write proximity_events document (TTL via Firestore TTL policy on expiresAt)
                    const expiresAt = Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000));
                    await db.collection("proximity_events").add({
                        fromUid: a.uid,
                        toUid: b.uid,
                        geohash: a.geohash,
                        timestamp: FieldValue.serverTimestamp(),
                        expiresAt,
                    });

                    pairsNotified++;

                    // Build sender age from dateOfBirth Timestamp
                    const buildAge = (userData: FirebaseFirestore.DocumentData): number => {
                        if (!userData.dateOfBirth) return 0;
                        const dob = (userData.dateOfBirth as Timestamp).toDate();
                        const today = new Date();
                        let age = today.getFullYear() - dob.getFullYear();
                        const m = today.getMonth() - dob.getMonth();
                        if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) age--;
                        return age;
                    };

                    // Send CROSSING_PATHS to one recipient about one sender
                    const sendCrossingPaths = async (
                        senderUid: string,
                        senderData: FirebaseFirestore.DocumentData,
                        recipientUid: string,
                        recipientData: FirebaseFirestore.DocumentData,
                    ): Promise<void> => {
                        const fcmToken = recipientData.fcmToken as string | undefined;
                        if (!fcmToken) return;

                        // Global throttle: max GLOBAL_THROTTLE_MAX pings per 10-min window
                        const throttleKey = globalThrottleKey(recipientUid);
                        const count = await redis.incr(throttleKey);
                        if (count === 1) await redis.expire(throttleKey, GLOBAL_THROTTLE_SECS);
                        if (count > GLOBAL_THROTTLE_MAX) {
                            logStructured({
                                fn: "scanProximityPairs",
                                event: "throttled",
                                recipient: recipientUid.substring(0, 8),
                                count,
                            });
                            return;
                        }

                        const name = senderData.displayName || "Someone";
                        const photoUrl = (senderData.photoUrls as string[] | undefined)?.[0] ?? "";
                        const age = buildAge(senderData);

                        await messaging.send({
                            token: fcmToken,
                            data: {
                                type: "CROSSING_PATHS",
                                fromUid: senderUid,
                                senderId: senderUid,
                                senderName: name,
                                senderAge: age.toString(),
                                senderPhotoUrl: photoUrl,
                            },
                            apns: {
                                payload: {
                                    aps: {
                                        contentAvailable: true,
                                        category: "NEARBY_CATEGORY",
                                        "alert-body-loc-key": "notify_nearby_body_rich",
                                        "alert-body-loc-args": [name, age.toString()],
                                    },
                                },
                            },
                            android: {
                                priority: "high",
                            },
                        });

                        logStructured({
                            fn: "scanProximityPairs",
                            event: "notification_sent",
                            sender: senderUid.substring(0, 8),
                            recipient: recipientUid.substring(0, 8),
                        });
                    };

                    // Notify both directions concurrently
                    await Promise.allSettled([
                        sendCrossingPaths(a.uid, aData, b.uid, bData),
                        sendCrossingPaths(b.uid, bData, a.uid, aData),
                    ]);
                }
            }
        }

        logStructured({
            fn: "scanProximityPairs",
            event: "complete",
            activeUsers: snapshot.size,
            pairsEvaluated,
            pairsNotified,
            durationMs: Date.now() - startedAt,
        });
    }
);

// ── DEPRECATED: onBleProximity ────────────────────────────────────

/**
 * @deprecated Replaced by scanProximityPairs (scheduled, 1-min interval).
 *
 * This trigger is dead. BLE was redesigned to presence-only advertising —
 * iOS does not expose manufacturer data or custom UUIDs in background scans.
 * The client no longer writes proximity_events docs with `from`/`toDeviceId`.
 * proximity_events docs are now written server-side by scanProximityPairs
 * using `fromUid`/`toUid`. Even if this trigger fires on a new doc, it exits
 * immediately because `from` and `toDeviceId` are absent from the new shape.
 *
 * Kept as a registered no-op to avoid breaking existing deployments.
 * Remove entirely in the next breaking deploy cycle.
 */
export const onBleProximity = onDocumentCreated(
    { document: "proximity_events/{eventId}", region: "europe-west1" },
    async (_event) => {
        // DEPRECATED: no-op. Encounter detection moved to scanProximityPairs.
        return;
    }
);

// ── DEPRECATED: onRunEncounter ────────────────────────────────────

/**
 * @deprecated Dead — same root cause as onBleProximity.
 *
 * The run_encounters collection is no longer written to by the client after
 * the BLE redesign removed the toDeviceId field. Run Club encounter detection
 * is now handled by scanProximityPairs via the standard geohash grouping path.
 * The active_run_crosses mutual wave flow (onRunCrossUpdated) remains active.
 *
 * Remove entirely in the next breaking deploy cycle.
 */
export const onRunEncounter = onDocumentCreated(
    { document: "run_encounters/{eventId}", region: "europe-west1" },
    async (_event) => {
        // DEPRECATED: no-op. Encounter detection moved to scanProximityPairs.
        return;
    }
);

/**
 * onRunCrossUpdated — Firestore trigger on active_run_crosses/{crossId}
 * 
 * Listens for mutual signal events in a Run Club encounter.
 * If both users wave (signals[uid] === true) and status is "pending",
 * creates a standard match and notifies both users.
 */
export const onRunCrossUpdated = onDocumentUpdated(
    { document: "active_run_crosses/{crossId}", region: "europe-west1" },
    async (event) => {
        const snap = event.data;
        if (!snap) return;

        const data = snap.after.data();
        const prevData = snap.before.data();

        if (data.status !== "pending" || prevData.status !== "pending") return;

        const signals = data.signals as Record<string, boolean>;
        const userIds = data.userIds as string[];

        // Check if both users sent a wave
        if (userIds.length === 2 && signals[userIds[0]] === true && signals[userIds[1]] === true) {
            
            // Mark as matched to prevent duplicate triggers
            await snap.after.ref.update({ status: "matched" });

            const matchId = userIds.sort().join("_");
            const existingMatch = await db.collection("matches").doc(matchId).get();
            if (existingMatch.exists) {
                console.log(`[RUN_CLUB] Match ${matchId} already exists — skipping duplicate trigger`);
                return;
            }

            // Create match
            const batch = db.batch();
            batch.set(db.collection("matches").doc(matchId), {
                userA: userIds[0],
                userB: userIds[1],
                userIds: userIds,
                matchType: "run_club", // Special match type for filtering UI later
                matchContext: null,
                createdAt: FieldValue.serverTimestamp(),
                expiresAt: new Date(Date.now() + 30 * 60 * 1000), // Standard match TTL
                status: "pending",
                seenBy: [],
            });
            await batch.commit();

            console.log(`[RUN_CLUB] Mutual wave! Match created: ${matchId}`);

            // Fetch profiles to send rich push
            const [userADoc, userBDoc] = await Promise.all([
                db.collection("users").doc(userIds[0]).get(),
                db.collection("users").doc(userIds[1]).get(),
            ]);

            const userA = userADoc.data();
            const userB = userBDoc.data();

            if (!userA || !userB) return;

            const nameA = userA.displayName || userA.name || "Nekdo";
            const nameB = userB.displayName || userB.name || "Nekdo";
            const photoA = (userA.photoUrls as string[] | undefined)?.[0] ?? "";
            const photoB = (userB.photoUrls as string[] | undefined)?.[0] ?? "";
            const tokenA = userA.fcmToken as string | undefined;
            const tokenB = userB.fcmToken as string | undefined;

            const messaging = getMessaging();
            const notifications: Promise<string>[] = [];

            if (tokenA) {
                notifications.push(
                    messaging.send({
                        token: tokenA,
                        notification: {
                            title: `Ujeli smo se! 🏃‍♀️`,
                            body: `${nameB} ti je pomahal-a nazaj! Odpremo radar?`,
                            imageUrl: photoB || undefined,
                        },
                        data: {
                            type: "MUTUAL_WAVE",
                            matchId,
                            path: "/radar",
                        },
                        apns: {
                            payload: { aps: { sound: "default", "mutable-content": 1 } },
                        },
                        android: { priority: "high" },
                    })
                );
            }

            if (tokenB) {
                notifications.push(
                    messaging.send({
                        token: tokenB,
                        notification: {
                            title: `Ujeli smo se! 🏃‍♀️`,
                            body: `${nameA} ti je pomahal-a nazaj! Odpremo radar?`,
                            imageUrl: photoA || undefined,
                        },
                        data: {
                            type: "MUTUAL_WAVE",
                            matchId,
                            path: "/radar",
                        },
                        apns: {
                            payload: { aps: { sound: "default", "mutable-content": 1 } },
                        },
                        android: { priority: "high" },
                    })
                );
            }

            await Promise.allSettled(notifications);
        }
    }
);
