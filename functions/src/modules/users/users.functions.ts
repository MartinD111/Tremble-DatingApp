/**
 * Tremble — Users Functions
 *
 * Profile CRUD operations — all writes are server-side only.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { assertValidDocumentId, validateRequest } from "../../middleware/validate";
import { updateProfileSchema, PublicProfile } from "./users.schema";
import { ENFORCE_APP_CHECK } from "../../config/env";

const db = getFirestore();

// Current Art. 9 consent version. Bump when the consent text materially
// changes; the backfill modal + settings tiles re-prompt on version drift.
const ART9_CONSENT_VERSION = "v1";

/**
 * Update user profile — called from Settings/Edit Profile.
 * Only allows whitelisted fields (no isAdmin/isPremium injection).
 *
 * Art. 9 write gate — a write of `gender`/`lookingFor`/`religion`/`ethnicity`
 * is rejected unless the effective (existing OR same-request) consent for that
 * category is === true. Same-request grants (client toggles consent on and
 * writes the field in the same call) are honoured. Same-request withdrawals
 * (consent flipped to false while writing the field) are rejected — withdrawal
 * must land as its own call and `FieldValue.delete()` the field.
 */
export const updateProfile = onCall(
    { maxInstances: 50, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 20 updates per minute
        await checkRateLimit(uid, "updateProfile", {
            maxRequests: 20,
            windowMs: 60_000,
        });

        // Validate — .strict() rejects unknown fields
        const data = validateRequest(updateProfileSchema, request.data);

        const userRef = db.collection("users").doc(uid);

        // Load current consent state so a same-request grant can unlock the
        // corresponding field write in one atomic call.
        const existingSnap = await userRef.get();
        const existing = existingSnap.data() ?? {};

        const effectiveConsent = (key: string): boolean => {
            const incoming = (data as Record<string, unknown>)[key];
            if (typeof incoming === "boolean") return incoming;
            return existing[key] === true;
        };

        const orientationTouched =
            data.gender !== undefined || data.lookingFor !== undefined;
        if (orientationTouched && !effectiveConsent("sexualOrientationConsent")) {
            throw new HttpsError(
                "permission-denied",
                "art9_orientation_consent_required"
            );
        }
        if (data.religion !== undefined && !effectiveConsent("religionConsent")) {
            throw new HttpsError(
                "permission-denied",
                "art9_religion_consent_required"
            );
        }
        if (data.ethnicity !== undefined && !effectiveConsent("ethnicityConsent")) {
            throw new HttpsError(
                "permission-denied",
                "art9_ethnicity_consent_required"
            );
        }

        // Only write the fields that were actually provided
        const updateData: Record<string, unknown> = {
            updatedAt: FieldValue.serverTimestamp(),
        };

        for (const [key, value] of Object.entries(data)) {
            if (value !== undefined) {
                updateData[key] = value;
            }
        }

        // Server-authoritative version + timestamp stamping on any consent
        // state transition (grant OR withdrawal). Timestamps are always
        // rewritten so withdrawal history is at least "last-change" traceable
        // via updatedAt + the per-category *ConsentAt.
        const stampConsent = (
            flagKey: string,
            versionKey: string,
            atKey: string
        ) => {
            const incoming = (data as Record<string, unknown>)[flagKey];
            if (typeof incoming === "boolean") {
                updateData[versionKey] = ART9_CONSENT_VERSION;
                updateData[atKey] = FieldValue.serverTimestamp();
            }
        };
        stampConsent(
            "sexualOrientationConsent",
            "sexualOrientationConsentVersion",
            "sexualOrientationConsentAt"
        );
        stampConsent(
            "religionConsent",
            "religionConsentVersion",
            "religionConsentAt"
        );
        stampConsent(
            "ethnicityConsent",
            "ethnicityConsentVersion",
            "ethnicityConsentAt"
        );

        await userRef.update(updateData);

        console.log(`[USERS] Profile updated: ${uid.substring(0, 8)}...`);
        return { success: true };
    }
);

/**
 * Withdraw a single Art. 9 consent — writes consent=false + version + timestamp
 * AND `FieldValue.delete()`s the corresponding Art. 9 field(s). Orientation
 * withdrawal deletes both `gender` and `lookingFor`.
 *
 * Split out from `updateProfile` because destructive deletes need their own
 * confirmation surface (settings withdrawal UX) and don't share the
 * `updateProfileSchema` write path.
 */
const withdrawableCategories = ["orientation", "religion", "ethnicity"] as const;
type WithdrawableCategory = (typeof withdrawableCategories)[number];

export const withdrawArt9Consent = onCall(
    { maxInstances: 20, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        await checkRateLimit(uid, "withdrawArt9Consent", {
            maxRequests: 10,
            windowMs: 60_000,
        });

        const raw = (request.data ?? {}) as { category?: unknown };
        if (
            typeof raw.category !== "string" ||
            !withdrawableCategories.includes(raw.category as WithdrawableCategory)
        ) {
            throw new HttpsError(
                "invalid-argument",
                "art9_withdraw_category_invalid"
            );
        }
        const category = raw.category as WithdrawableCategory;

        const updates: Record<string, unknown> = {
            updatedAt: FieldValue.serverTimestamp(),
        };

        if (category === "orientation") {
            updates.sexualOrientationConsent = false;
            updates.sexualOrientationConsentVersion = ART9_CONSENT_VERSION;
            updates.sexualOrientationConsentAt = FieldValue.serverTimestamp();
            updates.gender = FieldValue.delete();
            updates.lookingFor = FieldValue.delete();
        } else if (category === "religion") {
            updates.religionConsent = false;
            updates.religionConsentVersion = ART9_CONSENT_VERSION;
            updates.religionConsentAt = FieldValue.serverTimestamp();
            updates.religion = FieldValue.delete();
        } else {
            updates.ethnicityConsent = false;
            updates.ethnicityConsentVersion = ART9_CONSENT_VERSION;
            updates.ethnicityConsentAt = FieldValue.serverTimestamp();
            updates.ethnicity = FieldValue.delete();
        }

        await db.collection("users").doc(uid).update(updates);

        console.log(
            `[USERS] Art. 9 consent withdrawn (${category}): ${uid.substring(0, 8)}...`
        );
        return { success: true };
    }
);

/**
 * Get own profile — returns the authenticated user's full profile.
 *
 * Race condition fix: Returns explicit `status` field to distinguish between
 * "doc doesn't exist yet" (status: 'not_created') vs "doc exists but is empty" (status: 'created').
 * This allows the client router to make routing decisions based on profile existence.
 */
export const getProfile = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "getProfile", { maxRequests: 60, windowMs: 60000 });

        const doc = await db.collection("users").doc(uid).get();

        if (!doc.exists) {
            return { profile: null, status: "not_created" };
        }

        return { profile: { id: uid, ...doc.data() }, status: "created" };
    }
);

/**
 * Get another user's public profile — limited fields only.
 *
 * Requires authentication only (not a verified email). Access is already gated
 * on an existing mutual match between caller and target (see the match lookup
 * below), which is a stronger authorization signal than email verification —
 * an unverified but matched user must be able to see their match's reveal card.
 * Requiring `email_verified` here blocked the post-match reveal for legitimate
 * (unverified test/early) accounts (BLOCKER-POSTMATCH-PHOTO).
 */
export const getPublicProfile = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        await checkRateLimit(uid, "getPublicProfile", { maxRequests: 20, windowMs: 60000 });

        const { userId: rawUserId } = request.data as { userId: unknown };
        const userId = assertValidDocumentId(rawUserId, "userId");

        // TEMP DIAGNOSTIC (BLOCKER-POSTMATCH-PHOTO, Session 52) — surface which
        // branch nulls the reveal. Remove once the "?" root cause is confirmed.
        const logTag = `[USERS getPublicProfile] caller=${uid.substring(0, 8)} target=${userId.substring(0, 8)}`;

        const doc = await db.collection("users").doc(userId).get();
        if (!doc.exists) {
            console.log(`${logTag} → null (target user doc missing)`);
            return { profile: null };
        }

        const data = doc.data()!;
        const blockedBy: string[] = data.blockedBy ?? [];
        if (blockedBy.includes(uid)) {
            console.log(`${logTag} → null (caller in target.blockedBy)`);
            return { profile: null };
        }

        const matchId = [uid, userId].sort().join("_");
        const matchDoc = await db.collection("matches").doc(matchId).get();
        if (!matchDoc.exists) {
            console.log(`${logTag} → null (no match doc at ${matchId.substring(0, 20)})`);
            return { profile: null };
        }

        console.log(`${logTag} → OK (returning public profile)`);

        // Return only public fields — never expose email, admin status, etc.
        //
        // The explicit `PublicProfile` annotation enforces TypeScript's
        // excess-property check on the literal below. Any future edit that
        // adds `religion`, `ethnicity`, `gender`, or another forbidden field
        // will fail `npm run build` — see `PublicProfile` doc in users.schema.ts.
        const profile: PublicProfile = {
            id: userId,
            name: data.name,
            age: data.age,
            photoUrls: data.photoUrls,
            height: data.height,
            location: data.location,
            hobbies: data.hobbies,
            lookingFor: data.lookingFor,
            languages: data.languages,
            prompts: data.prompts,
            isSmoker: data.isSmoker,
            drinkingHabit: data.drinkingHabit,
            exerciseHabit: data.exerciseHabit,
            sleepSchedule: data.sleepSchedule,
            petPreference: data.petPreference,
            childrenPreference: data.childrenPreference,
            introvertScale: data.introvertScale,
            hairColor: data.hairColor,
            occupation: data.occupation,
        };
        return { profile };
    }
);
