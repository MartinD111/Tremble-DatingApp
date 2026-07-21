/**
 * Pure geo helpers for the radar turn-to-find sonar (FEATURE-RADAR-SONAR
 * Phase B). Kept dependency-free and side-effect-free so they are unit-testable
 * without the Firestore/Redis mock machinery.
 *
 * Privacy: these operate on geohash-7 decoded centers (~75m fuzz — privacy by
 * existing design). The server returns only the derived `bearing` (0-359°) and
 * a coarse `distanceBucket` to the client; the partner's raw coordinates /
 * geohash never leave the backend.
 */

export interface LatLng {
    lat: number;
    lng: number;
}

export type DistanceBucket = "close" | "~50m" | "~150m" | "far";

const toRad = (deg: number): number => (deg * Math.PI) / 180;
const toDeg = (rad: number): number => (rad * 180) / Math.PI;

/**
 * Forward azimuth (initial great-circle bearing) from `a` to `b`, in degrees
 * clockwise from true north, normalized to `[0, 360)`.
 */
export function computeBearing(a: LatLng, b: LatLng): number {
    const lat1 = toRad(a.lat);
    const lat2 = toRad(b.lat);
    const dLng = toRad(b.lng - a.lng);

    const y = Math.sin(dLng) * Math.cos(lat2);
    const x =
        Math.cos(lat1) * Math.sin(lat2) -
        Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);

    const bearing = toDeg(Math.atan2(y, x));
    return (bearing + 360) % 360;
}

/**
 * Coarse distance band for the approach stage of the sonar. Thresholds align
 * with the radar tiers (Free 100m / Pro 250m): the dot uses the bucket while
 * far, then hands off to live BLE RSSI warmth in the final meters.
 */
export function distanceBucket(meters: number): DistanceBucket {
    if (meters <= 25) return "close";
    if (meters <= 75) return "~50m";
    if (meters <= 200) return "~150m";
    return "far";
}
