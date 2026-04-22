/**
 * Tremble — Users Functions
 *
 * Profile CRUD operations — all writes are server-side only.
 */

import { onCall } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireAuth, requireVerifiedEmail } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import { updateProfileSchema } from "./users.schema";
import { ENFORCE_APP_CHECK } from "../../config/env";

const db = getFirestore();

/**
 * Update user profile — called from Settings/Edit Profile.
 * Only allows whitelisted fields (no isAdmin/isPremium injection).
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

        // Only write the fields that were actually provided
        const updateData: Record<string, unknown> = {
            updatedAt: FieldValue.serverTimestamp(),
        };

        for (const [key, value] of Object.entries(data)) {
            if (value !== undefined) {
                updateData[key] = value;
            }
        }

        await db.collection("users").doc(uid).update(updateData);

        console.log(`[USERS] Profile updated: ${uid.substring(0, 8)}...`);
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

        const doc = await db.collection("users").doc(uid).get();

        if (!doc.exists) {
            return { profile: null, status: "not_created" };
        }

        return { profile: { id: uid, ...doc.data() }, status: "created" };
    }
);

/**
 * Get another user's public profile — limited fields only.
 * Requires verified email.
 */
export const getPublicProfile = onCall(
    { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        requireVerifiedEmail(request);

        const { userId } = request.data as { userId: string };
        if (!userId || typeof userId !== "string") {
            throw new Error("userId is required");
        }

        const doc = await db.collection("users").doc(userId).get();
        if (!doc.exists) {
            return { profile: null };
        }

        const data = doc.data()!;

        // Return only public fields — never expose email, admin status, etc.
        return {
            profile: {
                id: userId,
                name: data.name,
                age: data.age,
                gender: data.gender,
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
                religion: data.religion,
                ethnicity: data.ethnicity,
                hairColor: data.hairColor,
                politicalAffiliation: data.politicalAffiliation,
                occupation: data.occupation,
            },
        };
    }
);
