/**
 * Tremble — Users Schemas
 *
 * Zod validation schemas for user profile operations.
 */

import { z } from "zod";

const interestedInValueSchema = z.enum(["male", "female", "non_binary"]);

const interestedInSchema = z.preprocess((value) => {
    if (value === "both") return ["male", "female"];
    if (typeof value === "string") return [value];
    return value;
}, z.array(interestedInValueSchema).min(1).max(3));

const nicotineUseValueSchema = z.enum([
    "cigarettes",
    "vape",
    "iqos",
    "zyn",
    "shisha",
]);

const nicotineUseSchema = z.array(nicotineUseValueSchema).max(10);

/** Schema for partial profile updates (settings/preferences) */
export const updateProfileSchema = z
    .object({
        name: z.string().min(1).max(50).trim().nullish(),
        age: z.number().int().min(18).max(100).nullish(),
        birthDate: z.string().nullish(),
        gender: z.string().max(50).nullish(),
        location: z.string().trim().min(1).max(80).nullish(),
        photoUrls: z.array(z.string().url()).min(1).max(6).nullish(),
        height: z.number().int().min(100).max(250).nullish(),
        isSmoker: z.boolean().nullish(),
        nicotineUse: nicotineUseSchema.nullish(),
        nicotineFilter: z.string().max(50).nullish(),
        hasChildren: z.boolean().nullish(),
        partnerSmokingPreference: z.string().max(50).nullish(),
        drinkingHabit: z.string().max(50).nullish(),
        partnerDrinkingHabit: z.string().max(50).nullish(),
        exerciseHabit: z.string().max(50).nullish(),
        partnerExerciseHabit: z.string().max(50).nullish(),
        sleepSchedule: z.string().max(50).nullish(),
        partnerSleepSchedule: z.string().max(50).nullish(),
        petPreference: z.string().max(50).nullish(),
        partnerPetPreference: z.string().max(50).nullish(),
        childrenPreference: z.string().max(50).nullish(),
        partnerChildrenPreference: z.string().max(50).nullish(),
        introvertScale: z.number().int().min(0).max(100).nullish(),
        selfIntrovertMin: z.number().int().min(0).max(100).nullish(),
        selfIntrovertMax: z.number().int().min(0).max(100).nullish(),

        occupation: z.string().max(100).nullish(),
        company: z.string().max(100).nullish(),
        school: z.string().max(100).nullish(),
        graduatedUniversity: z.string().max(100).nullish(),
        jobStatus: z.string().max(50).nullish(),
        lookingForNewJob: z.boolean().nullish(),
        religion: z.string().max(50).nullish(),
        religionPreference: z.string().max(50).nullish(),
        ethnicity: z.string().max(50).nullish(),
        ethnicityPreference: z.string().max(50).nullish(),
        hairColor: z.string().max(50).nullish(),
        hairColorPreference: z.string().max(50).nullish(),

        partnerHeightPreference: z.string().max(50).nullish(),
        interestedIn: interestedInSchema.nullish(),
        lookingFor: z.array(z.string().max(50)).max(5).nullish(),
        languages: z.array(z.string().max(50)).max(5).nullish(),
        hobbies: z.array(z.string().max(50)).max(20).nullish(),
        prompts: z.record(z.string().max(50), z.string().max(300)).nullish(),
        appLanguage: z.string().length(2).nullish(),
        isDarkMode: z.boolean().nullish(),
        isPrideMode: z.boolean().nullish(),
        isClassicAppearance: z.boolean().nullish(),
        isGenderBasedColor: z.boolean().nullish(),
        showPingAnimation: z.boolean().nullish(),
        isPingVibrationEnabled: z.boolean().nullish(),
        ageRangeStart: z.number().int().min(18).max(100).nullish(),
        ageRangeEnd: z.number().int().min(18).max(100).nullish(),
        heightRangeStart: z.number().int().min(100).max(250).nullish(),
        heightRangeEnd: z.number().int().min(100).max(250).nullish(),
        isTraveler: z.boolean().nullish(),
        onboardingCheckpoint: z.number().int().min(0).max(20).nullish(),
        gymNotificationsEnabled: z.boolean().nullish(),
        phoneNumber: z.string().max(30).nullish(),
    })
    .strict(); // Reject unknown fields — prevents injection of isAdmin/isPremium

export type UpdateProfileData = z.infer<typeof updateProfileSchema>;

/**
 * Whitelist of fields returned by `getPublicProfile`.
 *
 * IMPORTANT — DO NOT add sensitive attributes here:
 *   - `religion` and `ethnicity` are GDPR Art. 9 special-category data and must
 *     never leave the server surface (they are read internally for consented
 *     bilateral scoring in `compatibility_calculator.ts`, but that is a
 *     server→server read, not client-facing).
 *   - `gender` is intentionally omitted from the client-facing profile response
 *     as of PLAN-ID 20260709-strip-public-profile.
 *   - `politicalAffiliation` is not persisted at all (removed in PR #8).
 *
 * The `getPublicProfile` return literal is annotated with this interface so any
 * future edit that reintroduces a forbidden field triggers a TypeScript
 * excess-property error at build time, rather than silently regressing.
 */
export interface PublicProfile {
    id: string;
    name?: string;
    age?: number;
    photoUrls?: string[];
    height?: number;
    location?: string;
    hobbies?: string[];
    lookingFor?: string[];
    languages?: string[];
    prompts?: Record<string, string>;
    isSmoker?: boolean;
    drinkingHabit?: string;
    exerciseHabit?: string;
    sleepSchedule?: string;
    petPreference?: string;
    childrenPreference?: string;
    introvertScale?: number;
    hairColor?: string;
    occupation?: string;
}

