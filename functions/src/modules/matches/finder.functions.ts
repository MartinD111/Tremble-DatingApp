import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { z } from "zod";
import { ENFORCE_APP_CHECK } from "../../config/env";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import { computeBearing, haversineMeters } from "../proximity/bearing";

const db = getFirestore();
const FINDER_TTL_MS = 120_000;
const PARTNER_FRESHNESS_MS = 10_000;
const MAX_ACCURACY_METERS = 30;

const updateFinderLocationSchema = z.object({
    matchId: z.string().min(1).max(128).regex(/^[a-zA-Z0-9_-]+$/),
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180),
    accuracy: z.number().min(0),
    optIn: z.boolean(),
}).strict();

type FinderResponse =
    | { partnerSharing: false; reason?: "window_over" | "partner_not_opted" | "partner_stale" | "poor_accuracy" }
    | { partnerSharing: true; bearing: number; distanceM: number };

function millis(value: unknown): number | null {
    if (value instanceof Date) {
        const result = value.getTime();
        return Number.isFinite(result) ? result : null;
    }
    if (value && typeof value === "object" && "toMillis" in value) {
        const toMillis = (value as { toMillis?: unknown }).toMillis;
        if (typeof toMillis === "function") {
            const result = toMillis.call(value);
            return typeof result === "number" && Number.isFinite(result) ? result : null;
        }
    }
    if (value && typeof value === "object" && "toDate" in value) {
        const toDate = (value as { toDate?: unknown }).toDate;
        if (typeof toDate === "function") {
            const result = toDate.call(value);
            if (!(result instanceof Date)) return null;
            const resultMillis = result.getTime();
            return Number.isFinite(resultMillis) ? resultMillis : null;
        }
    }
    return null;
}

export const updateFinderLocation = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request): Promise<FinderResponse> => {
        const callerUid = requireAuth(request);
        await checkRateLimit(callerUid, "updateFinderLocation", {
            maxRequests: 30,
            windowMs: 60_000,
        });
        const data = validateRequest(updateFinderLocationSchema, request.data);
        const matchRef = db.collection("matches").doc(data.matchId);
        const callerFinderRef = matchRef.collection("finder").doc(callerUid);

        return db.runTransaction(async (transaction): Promise<FinderResponse> => {
            const now = Date.now();
            const matchSnapshot = await transaction.get(matchRef);
            if (!matchSnapshot.exists) {
                throw new HttpsError("not-found", "Match not found.");
            }

            const match = matchSnapshot.data();
            const userIds = Array.isArray(match?.userIds)
                ? match.userIds.filter((uid): uid is string => typeof uid === "string")
                : [];
            if (!userIds.includes(callerUid)) {
                throw new HttpsError("permission-denied", "Not a participant in this match.");
            }

            if (!data.optIn) {
                transaction.update(matchRef, {
                    [`finderOptIn.${callerUid}`]: FieldValue.delete(),
                });
                transaction.delete(callerFinderRef);
                return { partnerSharing: false };
            }

            const expiresAtMs = millis(match?.expiresAt);
            if (match?.status !== "pending" || expiresAtMs === null || expiresAtMs <= now) {
                return { partnerSharing: false, reason: "window_over" };
            }

            const optInUpdate = { [`finderOptIn.${callerUid}`]: true };
            if (data.accuracy > MAX_ACCURACY_METERS) {
                transaction.update(matchRef, optInUpdate);
                return { partnerSharing: false, reason: "poor_accuracy" };
            }

            const partnerUid = userIds.find((uid) => uid !== callerUid);
            if (!partnerUid) {
                throw new HttpsError("failed-precondition", "Match partner not found.");
            }

            const partnerOptedIn = match?.finderOptIn?.[partnerUid] === true;
            if (!partnerOptedIn) {
                transaction.update(matchRef, optInUpdate);
                transaction.set(callerFinderRef, {
                    lat: data.lat,
                    lng: data.lng,
                    accuracy: data.accuracy,
                    updatedAt: FieldValue.serverTimestamp(),
                    expireAt: Timestamp.fromMillis(now + FINDER_TTL_MS),
                });
                return { partnerSharing: false, reason: "partner_not_opted" };
            }

            const partnerFinderRef = matchRef.collection("finder").doc(partnerUid);
            const partnerSnapshot = await transaction.get(partnerFinderRef);

            transaction.update(matchRef, optInUpdate);
            transaction.set(callerFinderRef, {
                lat: data.lat,
                lng: data.lng,
                accuracy: data.accuracy,
                updatedAt: FieldValue.serverTimestamp(),
                expireAt: Timestamp.fromMillis(now + FINDER_TTL_MS),
            });

            const partner = partnerSnapshot.data();
            if (!partnerSnapshot.exists) {
                return { partnerSharing: false, reason: "partner_stale" };
            }
            if (
                typeof partner?.accuracy !== "number"
                || !Number.isFinite(partner.accuracy)
                || partner.accuracy < 0
                || partner.accuracy > MAX_ACCURACY_METERS
            ) {
                return { partnerSharing: false, reason: "poor_accuracy" };
            }

            const partnerUpdatedAtMs = millis(partner.updatedAt);
            const partnerAgeMs = partnerUpdatedAtMs === null ? null : now - partnerUpdatedAtMs;
            if (
                partnerAgeMs === null
                || partnerAgeMs < 0
                || partnerAgeMs > PARTNER_FRESHNESS_MS
            ) {
                return { partnerSharing: false, reason: "partner_stale" };
            }
            if (
                typeof partner.lat !== "number"
                || !Number.isFinite(partner.lat)
                || partner.lat < -90
                || partner.lat > 90
                || typeof partner.lng !== "number"
                || !Number.isFinite(partner.lng)
                || partner.lng < -180
                || partner.lng > 180
            ) {
                return { partnerSharing: false, reason: "partner_stale" };
            }

            return {
                partnerSharing: true,
                bearing: Math.round(computeBearing(
                    { lat: data.lat, lng: data.lng },
                    { lat: partner.lat, lng: partner.lng },
                )) % 360,
                distanceM: Math.round(haversineMeters(
                    data.lat,
                    data.lng,
                    partner.lat,
                    partner.lng,
                )),
            };
        });
    },
);
