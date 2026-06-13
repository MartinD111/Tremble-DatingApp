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
import { Sentry } from "../../core/sentry";
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
                const theirNicotineFilter: string = candidateData.nicotineFilter ?? "any";
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

                        const bothPremium = safeA.isPremium === true && safeB.isPremium === true;
                        if (bothPremium) {
                            const aNicotineUse: string[] = safeA.nicotineUse ?? [];
                            const aNicotineFilter: string = safeA.nicotineFilter ?? "any";
                            const bNicotineUse: string[] = safeB.nicotineUse ?? [];
                            const bNicotineFilter: string = safeB.nicotineFilter ?? "any";

                            if (!nicotineCompatible(
                                aNicotineUse,
                                aNicotineFilter,
                                bNicotineUse,
                                bNicotineFilter,
                            )) {
                                await redis.del(pairKey);
                                continue;
                            }
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
                            const fcmTokens = [safeA.fcmToken, safeB.fcmToken].filter(
                                (token): token is string => typeof token === "string" && token.trim() !== ""
                            );
                            for (const token of fcmTokens) {
                                try {
                                    await messaging.send({
                                        token,
                                        data: {
                                            type: "SECOND_ENCOUNTER",
                                        },
                                        apns: {
                                            payload: {
                                                aps: {
                                                    contentAvailable: true,
                                                    "alert-title-loc-key": "notify_second_encounter_title",
                                                    "alert-body-loc-key": "notify_second_encounter_body",
                                                },
                                            },
                                        },
                                        android: {
                                            priority: "high",
                                        },
                                    });
                                } catch (e) {
                                    console.error(`[NEAR_MISS_2ND] Failed to send push to token ${token}`, e);
                                }
                            }
                        }

                        pairsNotified++;

                        const buildAge = (userData: FirebaseFirestore.DocumentData): number => {
                            if (!userData.dateOfBirth) return 0;
                            const dob = (userData.dateOfBirth as Timestamp).toDate();
                            const today = new Date();
                            let age = today.getFullYear() - dob.getFullYear();
                            const m = today.getMonth() - dob.getMonth();
                            if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) age--;
                            return age;
                        };

                        const sendCrossingPaths = async (
                            senderUid: string,
                            senderData: FirebaseFirestore.DocumentData,
                            recipientUid: string,
                            recipientData: FirebaseFirestore.DocumentData,
                        ): Promise<void> => {
                            const fcmToken = recipientData.fcmToken as string | undefined;
                            if (!fcmToken) return;

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

                            const isSilent = recipientData?.isRunModeActive === true
                                || !!recipientData?.activeGymId
                                || !!recipientData?.activeEventId;

                            const name = senderData.displayName || "Someone";
                            const photoUrl = (senderData.photoUrls as string[] | undefined)?.[0] ?? "";
                            const age = buildAge(senderData);

                            if (isSilent) {
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
                                            },
                                        },
                                    },
                                    android: {
                                        priority: "high",
                                    },
                                });
                            } else {
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
                            }

                            logStructured({
                                fn: "scanProximityPairs",
                                event: "notification_sent",
                                sender: senderUid.substring(0, 8),
                                recipient: recipientUid.substring(0, 8),
                            });
                        };

                        await Promise.allSettled([
                            sendCrossingPaths(a.uid, safeA, b.uid, safeB),
                            sendCrossingPaths(b.uid, safeB, a.uid, safeA),
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
                            imageUrl: photoA ?? undefined,
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
