/**
 * Tremble — Auth Schemas
 *
 * Zod validation schemas for auth-related operations.
 */

import { z } from "zod";

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
    interestedIn: z.enum(["male", "female", "both", "non_binary"]),
    height: z.number().int().min(100).max(250).optional(),
    location: z.string().max(100).optional(),
    photoUrls: z.array(z.string().url()).min(1).max(6),
    isSmoker: z.boolean().optional(),
    partnerSmokingPreference: z.string().max(50).optional(),
    drinkingHabit: z.string().max(50).optional(),
    exerciseHabit: z.string().max(50).optional(),
    sleepSchedule: z.string().max(50).optional(),
    petPreference: z.string().max(50).optional(),
    childrenPreference: z.string().max(50).optional(),
    introvertScale: z.number().int().min(0).max(100).optional(),
    occupation: z.string().max(100).optional(),
    religion: z.string().max(50).optional(),
    ethnicity: z.string().max(50).optional(),
    hairColor: z.string().max(50).optional(),
    politicalAffiliation: z.string().max(50).optional(),
    lookingFor: z.array(z.string().max(50)).max(5).default([]),
    languages: z.array(z.string().max(50)).max(5).default([]),
    hobbies: z.array(z.string().max(50)).max(20).default([]),
    prompts: z
        .record(z.string().max(50), z.string().max(300))
        .default({}),
    appLanguage: z.string().length(2).default("en"),
    isDarkMode: z.boolean().default(false),
    isPrideMode: z.boolean().default(false),
    showPingAnimation: z.boolean().default(true),
    ageRangeStart: z.number().int().min(18).max(100).default(18),
    ageRangeEnd: z.number().int().min(18).max(100).default(100),
    maxDistance: z.number().int().min(1).max(500).default(50),
    consentGiven: z.boolean().refine((val) => val === true, {
        message: "GDPR consent is required",
    }),
});

export type CompleteOnboardingData = z.infer<typeof completeOnboardingSchema>;

/** Schema for Google ID Token verification */
export const googleAuthSchema = z.object({
    idToken: z.string().min(1, "ID Token is required"),
});
