/**
 * Tremble — Auth Functions
 *
 * Server-side auth logic: onboarding completion, user creation hooks.
 * All writes go through these functions — never directly from client.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { OAuth2Client } from "google-auth-library";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import { completeOnboardingSchema, googleAuthSchema } from "./auth.schema";
import { sendWelcomeEmail } from "../email/email.functions";
import { ENFORCE_APP_CHECK } from "../../config/env";

const db = getFirestore();
const googleClient = new OAuth2Client();

/**
 * Firestore trigger — runs when a new user document is created.
 * NOTE: Two creation paths exist:
 *   1. Email/password sign-up — client writes the initial /users/{uid} doc.
 *   2. Google sign-in — completeOnboarding creates the doc server-side with
 *      isOnboarded: true (no client-side initial doc).
 *
 * Idempotency: field-level guards. Never overwrite fields that are already
 * present — in particular, never downgrade isOnboarded from true to false.
 * Alternative to beforeUserCreated (which requires GCIP / Identity Platform).
 */
export const onUserDocCreated = onDocumentCreated(
    { document: "users/{uid}", region: "europe-west1" },
    async (event) => {
    const snap = event.data;
    const uid = event.params.uid;

    if (!snap) {
        console.warn(`[AUTH] onUserDocCreated: No data for ${uid}`);
        return;
    }

    try {
        const updates: Record<string, unknown> = {
            updatedAt: FieldValue.serverTimestamp(),
        };

        if (snap.get('isOnboarded') === undefined) {
            updates.isOnboarded = false;
        }
        if (snap.get('isPremium') === undefined) {
            updates.isPremium = false;
        }
        if (snap.get('isAdmin') === undefined) {
            updates.isAdmin = false;
        }
        if (snap.get('createdAt') === undefined) {
            updates.createdAt = FieldValue.serverTimestamp();
        }

        await snap.ref.set(updates, { merge: true });

        console.log(`[AUTH] User doc enriched: ${uid.substring(0, 8)}...`);
    } catch (error) {
        console.error(`[AUTH] Failed to enrich user doc for ${uid}:`, error);
        throw error; // Let Cloud Functions retry on error
    }
});

/**
 * Complete onboarding — called after the user finishes registration flow.
 * Validates all profile data server-side and writes to Firestore.
 */
export const completeOnboarding = onCall(
    { maxInstances: 50, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 5 onboarding attempts per minute
        await checkRateLimit(uid, "completeOnboarding", {
            maxRequests: 5,
            windowMs: 60_000,
        });

        // Validate input
        const data = validateRequest(completeOnboardingSchema, request.data);
        const rawNicotine = data.nicotineUse;
        const nicotineUse = Array.isArray(rawNicotine)
            ? rawNicotine
            : rawNicotine != null ? [rawNicotine] : [];

        // Calculate age from birthDate
        const birthDate = new Date(data.birthDate);
        const age = Math.floor(
            (Date.now() - birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000)
        );

        if (age < 18) {
            throw new HttpsError(
                "permission-denied",
                "Tremble is available to users 18 and older."
            );
        }

        // Read existing doc first — Google sign-in flow may not have an
        // initial /users/{uid} document, so we need to know whether to seed
        // createdAt ourselves. Not a transaction: concurrent onboarding calls
        // for the same uid are already rate-limited and would converge on the
        // same merged value.
        const userRef = db.collection("users").doc(uid);
        const existingDoc = await userRef.get();
        const existingData = existingDoc.data();
        const hasCreatedAt = existingData?.createdAt !== undefined;

        // Write validated profile data
        await userRef.set(
            {
                name: data.name,
                age,
                birthDate: birthDate,
                gender: data.gender,
                interestedIn: data.interestedIn,
                height: data.height || null,
                location: data.location || null,
                photoUrls: data.photoUrls,
                isSmoker: data.isSmoker ?? null,
                nicotineUse,
                partnerSmokingPreference: data.partnerSmokingPreference || null,
                drinkingHabit: data.drinkingHabit || null,
                exerciseHabit: data.exerciseHabit || null,
                sleepSchedule: data.sleepSchedule || null,
                petPreference: data.petPreference || null,
                childrenPreference: data.childrenPreference || null,
                introvertScale: data.introvertScale ?? null,
                occupation: data.occupation || null,
                religion: data.religion || null,
                ethnicity: data.ethnicity || null,
                hairColor: data.hairColor || null,
                politicalAffiliation: data.politicalAffiliation || null,
                lookingFor: data.lookingFor,
                languages: data.languages,
                hobbies: data.hobbies,
                prompts: data.prompts,
                appLanguage: data.appLanguage,
                isDarkMode: data.isDarkMode,
                isPrideMode: data.isPrideMode,
                showPingAnimation: data.showPingAnimation,
                ageRangeStart: data.ageRangeStart,
                ageRangeEnd: data.ageRangeEnd,
                jobStatus: data.jobStatus || null,
                consentGivenAt: FieldValue.serverTimestamp(),
                ageConfirmed: true,
                ageConfirmedAt: FieldValue.serverTimestamp(),
                isOnboarded: true,
                ...(hasCreatedAt ? {} : { createdAt: FieldValue.serverTimestamp() }),
                updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
        );

        console.log(`[AUTH] Onboarding completed: ${uid.substring(0, 8)}...`);

        // Send welcome email — fire and forget (don't block response)
        const email = existingData?.email as string | undefined;
        if (email && data.name) {
            sendWelcomeEmail(email, data.name).catch((err) =>
                console.error(`[AUTH] Welcome email failed for ${uid.substring(0, 8)}...:`, err)
            );
        }

        return { success: true };
    }
);

/**
 * Verify Google ID Token — specifically used for secure backend verification
 * as requested in the security audit.
 */
export const verifyGoogleToken = onCall(
    { maxInstances: 50, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
    async (request) => {
        // Rate limit: max 10 verification attempts per minute
        await checkRateLimit(request.rawRequest.ip || "anon", "verifyGoogleToken", {
            maxRequests: 10,
            windowMs: 60_000,
        });

        const data = validateRequest(googleAuthSchema, request.data);
        const webClientId = process.env.GOOGLE_WEB_CLIENT_ID;

        if (!webClientId) {
            console.error("[AUTH] GOOGLE_WEB_CLIENT_ID not set in environment.");
            throw new HttpsError("internal", "Server configuration error");
        }

        try {
            const ticket = await googleClient.verifyIdToken({
                idToken: data.idToken,
                audience: webClientId,
            });
            const payload = ticket.getPayload();

            if (!payload || !payload.email) {
                throw new HttpsError("unauthenticated", "Invalid token payload");
            }

            return {
                verified: true,
                email: payload.email,
                uid: payload.sub,
                name: payload.name,
            };
        } catch (error) {
            console.error("[AUTH] Google verification failed:", error);
            if (error instanceof HttpsError) {
                throw error;
            }
            throw new HttpsError("unauthenticated", "Invalid Google token");
        }
    }
);
