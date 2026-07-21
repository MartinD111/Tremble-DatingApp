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
import { apnsExpirationHeaders, NOTIFICATION_TTL_MILLIS } from "../../core/notification_expiry";
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
import { Sentry } from "../../core/sentry";
import { calculateCompatibilityScore } from "../compatibility/compatibility_calculator";
import { computeBearing, distanceBucket } from "./bearing";

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

const findNearbySchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    radiusKm: z.number().min(0.1).max(100).optional(),
});

const proximityMatchCandidatesSchema = z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
});

// ── Geohash Utils ────────────────────────────────────────

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

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

/**
 * FEATURE-RADAR-SONAR Phase B — turn-to-find bearing.
 *
 * When two in-range proximity users have an ACTIVE mutual-wave match
 * (`status: "pending"`, not expired), write each user's bearing-to-partner
 * (0-359° from north) plus a coarse distance bucket onto the match doc. The
 * client combines `bearingFor[myUid]` with its device compass heading to swing
 * the radar dot toward the partner.
 *
 * Privacy: only the derived bearing + coarse bucket are written — never the
 * partner's coordinates or geohash. Best-effort: any failure is swallowed so it
 * can never break the proximity scan (mirrors the crossing-paths tolerance).
 */
async function updateActiveMatchBearing(
    aUid: string,
    bUid: string,
    aCenter: { lat: number; lng: number },
    bCenter: { lat: number; lng: number },
    distanceMeters: number,
): Promise<void> {
    try {
        const uids = [aUid, bUid].sort();
        const matchId = `${uids[0]}_${uids[1]}`;
        const matchRef = db.collection("matches").doc(matchId);
        const snap = await matchRef.get();
        if (!snap.exists) return;

        const data = snap.data();
        if (data?.status !== "pending") return;

        // Duck-typed expiry: real Firestore Timestamps expose toMillis()/
        // toDate(); a plain Date exposes getTime(). Avoids `instanceof` so it
        // works against both the Admin SDK and test doubles.
        const expiresAtRaw = data?.expiresAt as
            | { toMillis?: () => number; toDate?: () => Date }
            | Date
            | undefined;
        const expiresMs =
            typeof (expiresAtRaw as { toMillis?: () => number })?.toMillis === "function"
                ? (expiresAtRaw as { toMillis: () => number }).toMillis()
                : typeof (expiresAtRaw as { toDate?: () => Date })?.toDate === "function"
                    ? (expiresAtRaw as { toDate: () => Date }).toDate().getTime()
                    : expiresAtRaw instanceof Date
                        ? expiresAtRaw.getTime()
                        : 0;
        if (expiresMs <= Date.now()) return; // window already over

        await matchRef.update({
            bearingFor: {
                [aUid]: Math.round(computeBearing(aCenter, bCenter)),
                [bUid]: Math.round(computeBearing(bCenter, aCenter)),
            },
            distanceBucket: distanceBucket(distanceMeters),
            bearingUpdatedAt: FieldValue.serverTimestamp(),
        });
    } catch (error) {
        logStructured({
            fn: "updateActiveMatchBearing",
            event: "error",
            error: errorMessage(error),
        });
    }
}

// ── Server-side notification i18n ─────────────────────────
// Founder decision (path a, plan 20260712-fix-crossing-paths-visibility):
// FCM notification title/body are localized here from recipient's
// `appLanguage` field (fallback `language`, then `en`). We no longer rely on
// APNs `alert-body-loc-key` — that path required a native Localizable.strings
// bundle that does not exist. All strings live here so tests can pin them.

export type NotificationLocale = "en" | "sl";

export const CROSSING_PATHS_STRINGS: Record<
    NotificationLocale,
    { title: string; body: (name: string, age: number) => string }
> = {
    en: {
        title: "Someone nearby 👀",
        body: (name, age) => (age > 0
            ? `${name}, ${age} is nearby. Want to send a wave?`
            : `${name} is nearby. Want to send a wave?`),
    },
    sl: {
        title: "Nekdo v bližini 👀",
        body: (name, age) => (age > 0
            ? `${name}, ${age} je v bližini. Boš pomahal-a?`
            : `${name} je v bližini. Boš pomahal-a?`),
    },
};

export const SECOND_ENCOUNTER_STRINGS: Record<
    NotificationLocale,
    { title: string; body: string }
> = {
    en: {
        title: "Crossed paths twice ✨",
        body: "You've been near each other twice. Coincidence?",
    },
    sl: {
        title: "Že drugič skupaj ✨",
        body: "Že drugič ste blizu drug drugega. Naključje?",
    },
};

export function resolveNotificationLocale(
    userData: FirebaseFirestore.DocumentData | undefined,
): NotificationLocale {
    const raw = userData?.appLanguage ?? userData?.language;
    if (typeof raw !== "string") return "en";
    const code = raw.slice(0, 2).toLowerCase();
    return code === "sl" ? "sl" : "en";
}

function birthDateValue(value: unknown): Date | null {
    if (typeof value === "string") {
        const dateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
        const dateTime = /^(\d{4})-(\d{2})-(\d{2})T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,9})?(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$/.exec(value);
        const components = dateOnly ?? dateTime;
        if (!components) return null;
        const year = Number(components[1]);
        const month = Number(components[2]);
        const day = Number(components[3]);
        const calendarCheck = new Date(Date.UTC(year, month - 1, day));
        if (
            calendarCheck.getUTCFullYear() !== year
            || calendarCheck.getUTCMonth() !== month - 1
            || calendarCheck.getUTCDate() !== day
        ) {
            return null;
        }
        if (dateOnly) return new Date(year, month - 1, day);
        const parsed = new Date(value);
        return Number.isNaN(parsed.getTime()) ? null : parsed;
    }
    if (value && typeof value === "object" && "toDate" in value) {
        const toDate = (value as { toDate?: unknown }).toDate;
        if (typeof toDate === "function") {
            const parsed = toDate.call(value);
            return parsed instanceof Date && !Number.isNaN(parsed.getTime()) ? parsed : null;
        }
    }
    return null;
}

function notificationIdentity(userData: FirebaseFirestore.DocumentData): {
    name: string;
    age: number;
    photoUrl: string;
} {
    const canonicalName = typeof userData.name === "string" && userData.name.trim() !== ""
        ? userData.name.trim()
        : "Someone";
    const numericAge = userData.age;
    let age = typeof numericAge === "number" && Number.isFinite(numericAge) && numericAge >= 0
        ? Math.floor(numericAge)
        : 0;
    if (age === 0) {
        const dob = birthDateValue(userData.birthDate);
        if (dob) {
            const today = new Date();
            age = today.getFullYear() - dob.getFullYear();
            const monthDelta = today.getMonth() - dob.getMonth();
            if (monthDelta < 0 || (monthDelta === 0 && today.getDate() < dob.getDate())) age--;
            if (age < 0) age = 0;
        }
    }
    const photoUrl = Array.isArray(userData.photoUrls)
        && typeof userData.photoUrls[0] === "string"
        ? userData.photoUrls[0]
        : "";
    return { name: canonicalName, age, photoUrl };
}

// ── F11: Nicotine Compatibility Helpers ─────────────────────

function userSmokes(nicotineUse: string[]): boolean {
    if (nicotineUse.length === 0) return false;
    return nicotineUse.some(u => u !== "none");
}

function nicotineCompatible(
    requesterUse: string[], requesterFilter: string,
    candidateUse: string[], candidateFilter: string,
): boolean {
    if (requesterFilter === "none_only" && userSmokes(candidateUse)) return false;
    if (candidateFilter === "none_only" && userSmokes(requesterUse)) return false;
    return true;
}

// ── Cloud Functions ──────────────────────────────────────

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

            const isPremium = requesterData.isPremium === true;
            const radiusM = isPremium ? RADIUS_PRO_M : RADIUS_FREE_M;
            const radiusTier = isPremium ? "pro" : "free";

            const myNicotineUse: string[] = requesterData.nicotineUse ?? [];
            const myNicotineFilter: string = isPremium ? (requesterData.nicotineFilter ?? "any") : "any";

            const queryPrecision = 6;
            const centerGeohash = encodeGeohash(data.latitude, data.longitude, queryPrecision);

            const snapshot = await db
                .collection("proximity")
                .where("isActive", "==", true)
                .where("geohash", ">=", centerGeohash)
                .where("geohash", "<=", centerGeohash + "\uf8ff")
                .limit(200)
                .get();

            const candidates: Array<{ id: string; distanceM: number }> = [];

            for (const doc of snapshot.docs) {
                if (doc.id === uid) continue;
                if (blockedUsers.includes(doc.id)) continue;

                const geohash = doc.data().geohash as string | undefined;
                if (!geohash) continue;

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

                const theirNicotineUse: string[] = candidateData.nicotineUse ?? [];
                const theirNicotineFilter: string = candidateData.isPremium ? (candidateData.nicotineFilter ?? "any") : "any";
                if (!nicotineCompatible(myNicotineUse, myNicotineFilter, theirNicotineUse, theirNicotineFilter)) {
                    continue;
                }

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

                let score = 0.0;
                if (iMatchThem && theyMatchMe && ageMatchesMe && ageMatchesThem) {
                    score = calculateCompatibilityScore(
                        {
                            uid,
                            hobbies: requesterData.hobbies ?? [],
                            introvertScale: requesterData.introvertScale,
                            nicotineUse: requesterData.nicotineUse ?? [],
                            nicotineFilter: myNicotineFilter,
                            drinkingHabit: requesterData.drinkingHabit,
                            partnerDrinkingHabit: requesterData.partnerDrinkingHabit,
                            exerciseHabit: requesterData.exerciseHabit,
                            sleepSchedule: requesterData.sleepSchedule,
                            religion: requesterData.religion,
                            religionPreference: requesterData.religionPreference,
                            ethnicity: requesterData.ethnicity,
                            ethnicityPreference: requesterData.ethnicityPreference,
                            lookingFor: requesterData.lookingFor ?? [],
                            isPremium: requesterData.isPremium ?? false,
                            religionConsent: requesterData.religionConsent,
                            ethnicityConsent: requesterData.ethnicityConsent,
                        },
                        {
                            uid: candidates[i].id,
                            hobbies: candidateData.hobbies ?? [],
                            introvertScale: candidateData.introvertScale,
                            nicotineUse: candidateData.nicotineUse ?? [],
                            nicotineFilter: theirNicotineFilter,
                            drinkingHabit: candidateData.drinkingHabit,
                            partnerDrinkingHabit: candidateData.partnerDrinkingHabit,
                            exerciseHabit: candidateData.exerciseHabit,
                            sleepSchedule: candidateData.sleepSchedule,
                            religion: candidateData.religion,
                            religionPreference: candidateData.religionPreference,
                            ethnicity: candidateData.ethnicity,
                            ethnicityPreference: candidateData.ethnicityPreference,
                            lookingFor: candidateData.lookingFor ?? [],
                            isPremium: candidateData.isPremium ?? false,
                            religionConsent: candidateData.religionConsent,
                            ethnicityConsent: candidateData.ethnicityConsent,
                        }
                    );
                } else if (iMatchThem && theyMatchMe) {
                    score = 0.45;
                }

                let threshold = 0.70;
                if (
                    requesterData.activeEventId &&
                    candidateData.activeEventId &&
                    requesterData.activeEventId === candidateData.activeEventId
                ) {
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

            const myNicotineUse: string[] = requesterData.nicotineUse ?? [];
            const myNicotineFilter: string = isPremium ? (requesterData.nicotineFilter ?? "any") : "any";

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

                if (blockedGeohashes.some(bg => geohash.startsWith(bg))) continue;

                const center = decodeGeohash(geohash);
                const distM = haversineMeters(data.latitude, data.longitude, center.lat, center.lng);

                if (distM <= radiusM) {
                    candidates.push({ uid: doc.id, distanceM: Math.round(distM) });
                }
            }

            const userDocs = await Promise.all(
                candidates.map(c => db.collection("users").doc(c.uid).get())
            );

            const filteredCandidates: Array<{ uid: string; distanceM: number }> = [];
            for (let i = 0; i < candidates.length; i++) {
                const candidateData = userDocs[i].data();
                if (!candidateData) continue;
                if (candidateData.flaggedForReview === true) continue;

                const theirNicotineUse: string[] = candidateData.nicotineUse ?? [];
                const theirNicotineFilter: string = candidateData.isPremium ? (candidateData.nicotineFilter ?? "any") : "any";
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

export const scanProximityPairs = onSchedule(
    {
        schedule: "every 1 minutes",
        region: "europe-west1",
        timeoutSeconds: 540,
        memory: "256MiB",
    },
    async () => {
        try {
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
                if (typeof data.geohash !== 'string' || data.geohash.length < 6) continue;
                const geohash: string = data.geohash;

                const prefix = geohash.substring(0, 6);
                if (!groups.has(prefix)) groups.set(prefix, []);
                groups.get(prefix)!.push({
                    uid: doc.id,
                    geohash: geohash as string,
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

                const pairCount = (members.length * (members.length - 1)) / 2;
                if (pairCount > 100) {
                    console.warn(`[scanProximityPairs] High pair count: ${pairCount} pairs in bucket — add per-scan cap before scaling`);
                }

                for (let i = 0; i < members.length; i++) {
                    for (let j = i + 1; j < members.length; j++) {
                        const a = members[i];
                        const b = members[j];
                        pairsEvaluated++;

                        const radiusM = (a.radiusTier === "pro" || b.radiusTier === "pro")
                            ? RADIUS_PRO_M
                            : RADIUS_FREE_M;

                        const aCenter = decodeGeohash(a.geohash!);
                        const bCenter = decodeGeohash(b.geohash!);
                        const distM = haversineMeters(aCenter.lat, aCenter.lng, bCenter.lat, bCenter.lng);
                        if (distM > radiusM) continue;

                        // Radar turn-to-find: refresh the bearing on an active
                        // mutual-wave window. Runs BEFORE the crossing-paths
                        // cooldown so the hunting dot keeps updating; no-ops
                        // (one cheap read) when the pair has no active match.
                        await updateActiveMatchBearing(a.uid, b.uid, aCenter, bCenter, distM);

                        const pairKey = proximityCooldownKey(a.uid, b.uid);
                        const pairSet = await redis.set(pairKey, "1", {
                            ex: PROXIMITY_COOLDOWN_SECS,
                            nx: true,
                        });
                        if (pairSet === null) continue;

                        const [aUserDoc, bUserDoc] = await Promise.all([
                            db.collection("users").doc(a.uid).get(),
                            db.collection("users").doc(b.uid).get(),
                        ]);

                        const aData = aUserDoc.data();
                        const bData = bUserDoc.data();

                        if (!aData || !bData) {
                            await redis.del(pairKey);
                            continue;
                        }

                        const safeA = aData as FirebaseFirestore.DocumentData;
                        const safeB = bData as FirebaseFirestore.DocumentData;

                        if (safeA.flaggedForReview === true || safeB.flaggedForReview === true) {
                            await redis.del(pairKey);
                            continue;
                        }

                        const aBlocked: string[] = safeA.blockedUserIds ?? [];
                        const bBlocked: string[] = safeB.blockedUserIds ?? [];
                        if (aBlocked.includes(b.uid) || bBlocked.includes(a.uid)) {
                            await redis.del(pairKey);
                            continue;
                        }

                        // Mutual gender preference — mirrors findNearby:246-253.
                        // CHEAP: reads fields already loaded; no Firestore I/O.
                        const aGender = safeA.gender;
                        const aInterest = safeA.interestedIn;
                        const bGender = safeB.gender;
                        const bInterest = safeB.interestedIn;

                        const aMatchesB =
                            Array.isArray(aInterest)
                                ? aInterest.includes(bGender)
                                : aInterest === "Oba" || aInterest === "Both" || aInterest === bGender;
                        const bMatchesA =
                            Array.isArray(bInterest)
                                ? bInterest.includes(aGender)
                                : bInterest === "Oba" || bInterest === "Both" || bInterest === aGender;

                        if (!aMatchesB || !bMatchesA) {
                            await redis.del(pairKey);
                            continue;
                        }

                        // Mutual age range — mirrors findNearby:254-255.
                        // CHEAP: reads already-loaded fields; falsy age passes (matches findNearby semantics).
                        const aAge = safeA.age;
                        const bAge = safeB.age;
                        const aMinAge = safeA.ageRangeStart ?? 18;
                        const aMaxAge = safeA.ageRangeEnd ?? 100;
                        const bMinAge = safeB.ageRangeStart ?? 18;
                        const bMaxAge = safeB.ageRangeEnd ?? 100;

                        const bAgeMatchesA = !bAge || (bAge >= aMinAge && bAge <= aMaxAge);
                        const aAgeMatchesB = !aAge || (aAge >= bMinAge && aAge <= bMaxAge);

                        if (!bAgeMatchesA || !aAgeMatchesB) {
                            await redis.del(pairKey);
                            continue;
                        }

                        const aNicotineUse: string[] = safeA.nicotineUse ?? [];
                        const aNicotineFilter: string = safeA.isPremium ? (safeA.nicotineFilter ?? "any") : "any";
                        const bNicotineUse: string[] = safeB.nicotineUse ?? [];
                        const bNicotineFilter: string = safeB.isPremium ? (safeB.nicotineFilter ?? "any") : "any";

                            if (!nicotineCompatible(
                                aNicotineUse,
                                aNicotineFilter,
                                bNicotineUse,
                                bNicotineFilter,
                            )) {
                                await redis.del(pairKey);
                                continue;
                            }

                        // Compatibility score — mirrors findNearby:259-304.
                        // EXPENSIVE: only runs after gender + age + nicotine gates pass.
                        const compatibilityScore = calculateCompatibilityScore(
                            {
                                uid: a.uid,
                                hobbies: safeA.hobbies ?? [],
                                introvertScale: safeA.introvertScale,
                                nicotineUse: safeA.nicotineUse ?? [],
                                nicotineFilter: aNicotineFilter,
                                drinkingHabit: safeA.drinkingHabit,
                                partnerDrinkingHabit: safeA.partnerDrinkingHabit,
                                exerciseHabit: safeA.exerciseHabit,
                                sleepSchedule: safeA.sleepSchedule,
                                religion: safeA.religion,
                                religionPreference: safeA.religionPreference,
                                ethnicity: safeA.ethnicity,
                                ethnicityPreference: safeA.ethnicityPreference,
                                lookingFor: safeA.lookingFor ?? [],
                                isPremium: safeA.isPremium ?? false,
                                religionConsent: safeA.religionConsent,
                                ethnicityConsent: safeA.ethnicityConsent,
                            },
                            {
                                uid: b.uid,
                                hobbies: safeB.hobbies ?? [],
                                introvertScale: safeB.introvertScale,
                                nicotineUse: safeB.nicotineUse ?? [],
                                nicotineFilter: bNicotineFilter,
                                drinkingHabit: safeB.drinkingHabit,
                                partnerDrinkingHabit: safeB.partnerDrinkingHabit,
                                exerciseHabit: safeB.exerciseHabit,
                                sleepSchedule: safeB.sleepSchedule,
                                religion: safeB.religion,
                                religionPreference: safeB.religionPreference,
                                ethnicity: safeB.ethnicity,
                                ethnicityPreference: safeB.ethnicityPreference,
                                lookingFor: safeB.lookingFor ?? [],
                                isPremium: safeB.isPremium ?? false,
                                religionConsent: safeB.religionConsent,
                                ethnicityConsent: safeB.ethnicityConsent,
                            },
                        );

                        // Special social contexts lower the threshold to 0.55:
                        //   - shared active event (both users at the same event)
                        //   - either user in Run Club mode
                        //   - either user in a gym session
                        // Rationale: in these contexts the user is actively open to socializing.
                        const sharedEvent =
                            safeA.activeEventId &&
                            safeB.activeEventId &&
                            safeA.activeEventId === safeB.activeEventId;
                        const aInRun = safeA.isRunModeActive === true;
                        const bInRun = safeB.isRunModeActive === true;
                        const aInGym = safeA.activeGymId != null;
                        const bInGym = safeB.activeGymId != null;
                        const sharedContext = sharedEvent || aInRun || bInRun || aInGym || bInGym;
                        const scoreThreshold = sharedContext ? 0.55 : 0.70;

                        if (compatibilityScore < scoreThreshold) {
                            await redis.del(pairKey);
                            continue;
                        }

                        const bothRunMode = safeA.isRunModeActive === true && safeB.isRunModeActive === true;

                        if (bothRunMode) {
                            const crossId = [a.uid, b.uid].sort().join("_");
                            const existingCross = await db.collection("active_run_crosses").doc(crossId).get();
                            if (!existingCross.exists || existingCross.data()?.status !== "pending") {
                                await db.collection("active_run_crosses").doc(crossId).set({
                                    userIds: [a.uid, b.uid].sort(),
                                    signals: {},
                                    dismissedBy: [],
                                    status: "pending",
                                    expiresAt: Timestamp.fromDate(new Date(Date.now() + 30 * 60 * 1000)),
                                    timestamp: FieldValue.serverTimestamp(),
                                });
                                logStructured({ fn: "scanProximityPairs", event: "run_cross_created", crossId });
                            }
                        }

                        // 4. Write proximity_events document
                        const expiresAt = Timestamp.fromDate(new Date(Date.now() + 10 * 60 * 1000));
                        await db.collection("proximity_events").add({
                            fromUid: a.uid,
                            toUid: b.uid,
                            geohash: a.geohash,
                            timestamp: FieldValue.serverTimestamp(),
                            expiresAt,
                        });

                        const encounterCountKey = `encounter_count:${[a.uid, b.uid].sort().join("_")}`;
                        const encounterCount = await redis.incr(encounterCountKey);
                        if (encounterCount === 1) {
                            await redis.expire(encounterCountKey, 7776000);
                        }
                        if (encounterCount === 2) {
                            const secondEncounterRecipients: Array<{
                                token: string;
                                data: FirebaseFirestore.DocumentData;
                            }> = [];
                            if (typeof safeA.fcmToken === "string" && safeA.fcmToken.trim() !== "") {
                                secondEncounterRecipients.push({ token: safeA.fcmToken, data: safeA });
                            }
                            if (typeof safeB.fcmToken === "string" && safeB.fcmToken.trim() !== "") {
                                secondEncounterRecipients.push({ token: safeB.fcmToken, data: safeB });
                            }
                            for (const { token, data: recipientData } of secondEncounterRecipients) {
                                const locale = resolveNotificationLocale(recipientData);
                                const strings = SECOND_ENCOUNTER_STRINGS[locale];
                                try {
                                    await messaging.send({
                                        token,
                                        notification: {
                                            title: strings.title,
                                            body: strings.body,
                                        },
                                        data: {
                                            type: "SECOND_ENCOUNTER",
                                        },
                                        apns: {
                                            payload: {
                                                aps: {
                                                    contentAvailable: true,
                                                    sound: "default",
                                                },
                                            },
                                        },
                                        android: {
                                            priority: "high",
                                            notification: {
                                                channelId: "tremble_proximity",
                                                sound: "default",
                                            },
                                        },
                                    });
                                } catch (e) {
                                    logStructured({
                                        fn: "scanProximityPairs",
                                        event: "second_encounter_send_failed",
                                        error: errorMessage(e),
                                    });
                                }
                            }
                        }


                        // Result semantics (plan 20260712-fix-crossing-paths-visibility):
                        // `sent: true` means messaging.send() succeeded AND the recipient
                        // received a user-visible notification. Silent-mode wakes and
                        // no-token/throttled/error paths return sent: false with a reason,
                        // so pairsNotified reflects real visible deliveries.
                        const sendCrossingPaths = async (
                            senderUid: string,
                            senderData: FirebaseFirestore.DocumentData,
                            recipientUid: string,
                            recipientData: FirebaseFirestore.DocumentData,
                        ): Promise<{ sent: boolean; skipped?: string }> => {
                            const fcmToken = recipientData.fcmToken as string | undefined;
                            if (!fcmToken) return { sent: false, skipped: "no_token" };

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
                                return { sent: false, skipped: "throttled" };
                            }

                            const isSilent = recipientData?.isRunModeActive === true
                                || !!recipientData?.activeGymId
                                || !!recipientData?.activeEventId;

                            const { name, age, photoUrl } = notificationIdentity(senderData);

                            const dataPayload = {
                                type: "CROSSING_PATHS",
                                fromUid: senderUid,
                                senderId: senderUid,
                                senderName: name,
                                senderAge: age.toString(),
                                senderPhotoUrl: photoUrl,
                            };

                            if (isSilent) {
                                try {
                                    await messaging.send({
                                        token: fcmToken,
                                        data: dataPayload,
                                        apns: {
                                            headers: apnsExpirationHeaders(),
                                            payload: {
                                                aps: { contentAvailable: true },
                                            },
                                        },
                                        android: {
                                            priority: "high",
                                            ttl: NOTIFICATION_TTL_MILLIS,
                                        },
                                    });
                                    logStructured({
                                        fn: "scanProximityPairs",
                                        event: "notification_sent",
                                        mode: "silent",
                                        sender: senderUid.substring(0, 8),
                                        recipient: recipientUid.substring(0, 8),
                                    });
                                    return { sent: false, skipped: "silent" };
                                } catch (e) {
                                    logStructured({
                                        fn: "scanProximityPairs",
                                        event: "notification_error",
                                        mode: "silent",
                                        sender: senderUid.substring(0, 8),
                                        recipient: recipientUid.substring(0, 8),
                                        error: errorMessage(e),
                                    });
                                    return { sent: false, skipped: "error" };
                                }
                            }

                            const locale = resolveNotificationLocale(recipientData);
                            const strings = CROSSING_PATHS_STRINGS[locale];
                            const notificationTitle = strings.title;
                            const notificationBody = strings.body(name, age);

                            try {
                                await messaging.send({
                                    token: fcmToken,
                                    notification: {
                                        title: notificationTitle,
                                        body: notificationBody,
                                    },
                                    data: dataPayload,
                                    apns: {
                                        headers: apnsExpirationHeaders(),
                                        payload: {
                                            aps: {
                                                contentAvailable: true,
                                                category: "NEARBY_CATEGORY",
                                                sound: "default",
                                            },
                                        },
                                    },
                                    android: {
                                        priority: "high",
                                        ttl: NOTIFICATION_TTL_MILLIS,
                                        notification: {
                                            channelId: "tremble_proximity",
                                            sound: "default",
                                        },
                                    },
                                });
                                logStructured({
                                    fn: "scanProximityPairs",
                                    event: "notification_sent",
                                    mode: "visible",
                                    locale,
                                    sender: senderUid.substring(0, 8),
                                    recipient: recipientUid.substring(0, 8),
                                });
                                return { sent: true };
                            } catch (e) {
                                logStructured({
                                    fn: "scanProximityPairs",
                                    event: "notification_error",
                                    mode: "visible",
                                    locale,
                                    sender: senderUid.substring(0, 8),
                                    recipient: recipientUid.substring(0, 8),
                                    error: errorMessage(e),
                                });
                                return { sent: false, skipped: "error" };
                            }
                        };

                        const sendResults = await Promise.allSettled([
                            sendCrossingPaths(a.uid, safeA, b.uid, safeB),
                            sendCrossingPaths(b.uid, safeB, a.uid, safeA),
                        ]);
                        for (const result of sendResults) {
                            if (result.status === "fulfilled" && result.value.sent === true) {
                                pairsNotified++;
                            }
                        }
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
        } catch (err) {
            Sentry.captureException(err);
            await Sentry.flush(2000);
            throw err;
        }
    }
);

// ── DEPRECATED: onBleProximity ────────────────────────────────────

export const onBleProximity = onDocumentCreated(
    { document: "proximity_events/{eventId}", region: "europe-west1" },
    async (_event) => {
        return;
    }
);

// ── DEPRECATED: onRunEncounter ────────────────────────────────────

export const onRunEncounter = onDocumentCreated(
    { document: "run_encounters/{eventId}", region: "europe-west1" },
    async (_event) => {
        return;
    }
);

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

        if (userIds.length === 2 && signals[userIds[0]] === true && signals[userIds[1]] === true) {

            await snap.after.ref.update({ status: "matched" });

            const matchId = userIds.sort().join("_");
            const existingMatch = await db.collection("matches").doc(matchId).get();
            if (existingMatch.exists) {
                console.log(`[RUN_CLUB] Match ${matchId} already exists — skipping duplicate trigger`);
                return;
            }

            const batch = db.batch();
            batch.set(db.collection("matches").doc(matchId), {
                userA: userIds[0],
                userB: userIds[1],
                userIds: userIds,
                matchType: "run_club",
                matchContext: null,
                // Mutual run-club wave is the mutual gesture — seed both sides so
                // hasMutualWave (ADR-007 §1) is true and the pair shows in colour
                // (not greyscale) in history. Premium full-card gate unchanged.
                gestures: { [userIds[0]]: true, [userIds[1]]: true },
                createdAt: FieldValue.serverTimestamp(),
                expiresAt: new Date(Date.now() + 30 * 60 * 1000),
                status: "pending",
                seenBy: [],
            });
            await batch.commit();

            console.log(`[RUN_CLUB] Mutual wave! Match created: ${matchId}`);

            const [userADoc, userBDoc] = await Promise.all([
                db.collection("users").doc(userIds[0]).get(),
                db.collection("users").doc(userIds[1]).get(),
            ]);

            const userA = userADoc.data();
            const userB = userBDoc.data();

            if (!userA || !userB) return;

            const safeUserA = userA as FirebaseFirestore.DocumentData;
            const safeUserB = userB as FirebaseFirestore.DocumentData;
            const nameA = safeUserA.displayName || safeUserA.name || "Nekdo";
            const nameB = safeUserB.displayName || safeUserB.name || "Nekdo";
            const photoA = (safeUserA.photoUrls as string[] | undefined)?.[0] ?? "";
            const photoB = (safeUserB.photoUrls as string[] | undefined)?.[0] ?? "";
            const tokenA = safeUserA.fcmToken as string | undefined;
            const tokenB = safeUserB.fcmToken as string | undefined;

            const messaging = getMessaging();
            const notifications: Promise<string>[] = [];

            if (tokenA) {
                notifications.push(
                    messaging.send({
                        token: tokenA,
                        notification: {
                            title: `Ujeli smo se! 🏃‍♀️`,
                            body: `${nameB} ti je pomahal-a nazaj! Odpremo radar?`,
                            imageUrl: photoB ?? undefined,
                        },
                        data: {
                            type: "MUTUAL_WAVE",
                            matchId,
                            path: "/radar",
                        },
                        apns: {
                            payload: { aps: { contentAvailable: true, sound: "default", "mutable-content": 1 } },
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
                            imageUrl: photoA ?? undefined,
                        },
                        data: {
                            type: "MUTUAL_WAVE",
                            matchId,
                            path: "/radar",
                        },
                        apns: {
                            payload: { aps: { contentAvailable: true, sound: "default", "mutable-content": 1 } },
                        },
                        android: { priority: "high" },
                    })
                );
            }

            await Promise.allSettled(notifications);
        }
    }
);
