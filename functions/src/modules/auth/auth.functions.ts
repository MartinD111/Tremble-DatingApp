/**
 * Tremble — Auth Functions
 *
 * Server-side auth logic: onboarding completion, user creation hooks.
 * All writes go through these functions — never directly from client.
 */

import { onCall } from "firebase-functions/v2/https";
import { beforeUserCreated } from "firebase-functions/v2/identity";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import { completeOnboardingSchema } from "./auth.schema";

const db = getFirestore();

/**
 * Identity Platform trigger — runs when a new user signs up.
 * Creates the initial user stub in Firestore.
 */
export const onUserCreated = beforeUserCreated(async (event) => {
    const user = event.data;

    await db
        .collection("users")
        .doc(user.uid)
        .set({
            email: user.email || null,
            isOnboarded: false,
            isPremium: true, // Free premium until 10k users
            isAdmin: false,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
        });

    console.log(`[AUTH] User created: ${user.uid}`);
});

/**
 * Complete onboarding — called after the user finishes registration flow.
 * Validates all profile data server-side and writes to Firestore.
 */
export const completeOnboarding = onCall(
    { maxInstances: 50 },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 5 onboarding attempts per minute
        await checkRateLimit(uid, "completeOnboarding", {
            maxRequests: 5,
            windowMs: 60_000,
        });

        // Validate input
        const data = validateRequest(completeOnboardingSchema, request.data);

        // Calculate age from birthDate
        const birthDate = new Date(data.birthDate);
        const age = Math.floor(
            (Date.now() - birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000)
        );

        // Write validated profile data
        await db
            .collection("users")
            .doc(uid)
            .set(
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
                    maxDistance: data.maxDistance,
                    consentGivenAt: FieldValue.serverTimestamp(),
                    isOnboarded: true,
                    updatedAt: FieldValue.serverTimestamp(),
                },
                { merge: true }
            );

        console.log(`[AUTH] Onboarding completed: ${uid}`);
        return { success: true };
    }
);
