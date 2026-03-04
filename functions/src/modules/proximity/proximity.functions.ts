/**
 * Tremble — Proximity Functions
 *
 * Handles location updates and nearby user discovery.
 * Uses geohash-based queries for efficient proximity filtering.
 */

import { onCall } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
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

    let latRange = [-90.0, 90.0];
    let lngRange = [-180.0, 180.0];

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
        const nearbyUsers: Array<{
            userId: string;
            distanceKm: number;
        }> = [];

        for (const doc of snapshot.docs) {
            if (doc.id === uid) continue; // Skip self

            const docData = doc.data();
            const distance = haversineDistance(
                data.latitude,
                data.longitude,
                docData.lat,
                docData.lng
            );

            if (distance <= (data.radiusKm ?? 5)) {
                nearbyUsers.push({
                    userId: doc.id,
                    distanceKm: Math.round(distance * 10) / 10,
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
