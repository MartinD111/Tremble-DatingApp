/**
 * Tremble — Auth Schemas
 *
 * Zod validation schemas for auth-related operations.
 */

import { z } from "zod";

const interestedInValueSchema = z.enum(["male", "female", "non_binary"]);

const interestedInSchema = z.preprocess((value) => {
    if (value === "both") return ["male", "female"];
    if (typeof value === "string") return [value];
    return value;
}, z.array(interestedInValueSchema).min(1).max(3));

const nicotineUseSchema = z.array(z.string().max(50)).max(10);

// Optional fields use `.nullish()` (T | null | undefined) because the Dart
// client serializes unset values as JSON `null`, which `.optional()` rejects.
// Required fields kept strict: name, birthDate, gender, interestedIn,
// photoUrls, consentGiven.

/** Schema for completing the onboarding profile */
export const completeOnboardingSchema = z.object({
    name: z
        .string()
        .min(1, "Name is required")
        .max(50, "Name too long")
        .trim(),
    birthDate: z.string().refine(
        (val) => {
            const date = new Date(val);
            const age = Math.floor(
                (Date.now() - date.getTime()) / (365.25 * 24 * 60 * 60 * 1000)
            );
            return age >= 18 && age <= 120;
        },
        { message: "Must be between 18 and 120 years old" }
    ),
    gender: z.enum(["male", "female", "non_binary"]),
    interestedIn: interestedInSchema,
    height: z.number().int().min(100).max(250).nullish(),
    heightRangeStart: z.number().int().min(100).max(250).nullish(),
    heightRangeEnd: z.number().int().min(100).max(250).nullish(),
    location: z.enum(["Ljubljana", "Koper", "Zagreb", "Other"]).nullish(),
    photoUrls: z.array(z.string().url()).min(1).max(6),
    isSmoker: z.boolean().nullish(),
    nicotineUse: nicotineUseSchema.nullish(),
    nicotineFilter: z.string().max(50).nullish(),
    partnerSmokingPreference: z.string().max(50).nullish(),
    drinkingHabit: z.string().max(50).nullish(),
    exerciseHabit: z.string().max(50).nullish(),
    sleepSchedule: z.string().max(50).nullish(),
    petPreference: z.string().max(50).nullish(),
    childrenPreference: z.string().max(50).nullish(),
    introvertScale: z.number().int().min(0).max(100).nullish(),
    selfIntrovertMin: z.number().int().min(0).max(100).nullish(),
    selfIntrovertMax: z.number().int().min(0).max(100).nullish(),
    occupation: z.string().max(100).nullish(),
    school: z.string().max(100).nullish(),
    religion: z.string().max(50).nullish(),
    ethnicity: z.string().max(50).nullish(),
    hairColor: z.string().max(50).nullish(),
    politicalAffiliation: z.string().max(50).nullish(),
    partnerDrinkingHabit: z.string().max(500).nullish(),
    partnerExerciseHabit: z.string().max(500).nullish(),
    partnerSleepSchedule: z.string().max(500).nullish(),

    hasChildren: z.boolean().nullish(),
    lookingForNewJob: z.boolean().nullish(),
    isTraveler: z.boolean().nullish(),
    lookingFor: z
        .array(z.string().max(50))
        .max(5)
        .nullish()
        .transform((v) => v ?? []),
    languages: z
        .array(z.string().max(50))
        .max(5)
        .nullish()
        .transform((v) => v ?? []),
    hobbies: z
        .array(z.string().max(50))
        .max(20)
        .nullish()
        .transform((v) => v ?? []),
    prompts: z
        .record(z.string().max(50), z.string().max(300))
        .default({}),
    appLanguage: z.string().length(2).default("en"),
    isDarkMode: z.boolean().default(false),
    isPrideMode: z.boolean().default(false),
    showPingAnimation: z.boolean().default(true),
    ageRangeStart: z.number().int().min(18).max(100).default(18),
    ageRangeEnd: z.number().int().min(18).max(100).default(100),
    jobStatus: z.string().max(50).nullish(),
    consentGiven: z.boolean().refine((val) => val === true, {
        message: "GDPR consent is required",
    }),
});

export type CompleteOnboardingData = z.infer<typeof completeOnboardingSchema>;

/** Schema for Google ID Token verification */
export const googleAuthSchema = z.object({
    idToken: z.string().min(1, "ID Token is required"),
});
