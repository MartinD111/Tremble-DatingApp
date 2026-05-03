/**
 * Tremble — Users Schemas
 *
 * Zod validation schemas for user profile operations.
 */

import { z } from "zod";

/** Schema for partial profile updates (settings/preferences) */
export const updateProfileSchema = z
    .object({
        name: z.string().min(1).max(50).trim().optional(),
        age: z.number().int().min(18).max(100).optional(),
        birthDate: z.string().optional(),
        gender: z.string().max(50).optional(),
        location: z.string().max(100).optional(),
        photoUrls: z.array(z.string().url()).min(1).max(6).optional(),
        height: z.number().int().min(100).max(250).optional(),
        isSmoker: z.boolean().optional(),
        hasChildren: z.boolean().optional(),
        partnerSmokingPreference: z.string().max(50).optional(),
        drinkingHabit: z.string().max(50).optional(),
        partnerDrinkingHabit: z.string().max(50).optional(),
        exerciseHabit: z.string().max(50).optional(),
        partnerExerciseHabit: z.string().max(50).optional(),
        sleepSchedule: z.string().max(50).optional(),
        partnerSleepSchedule: z.string().max(50).optional(),
        petPreference: z.string().max(50).optional(),
        partnerPetPreference: z.string().max(50).optional(),
        childrenPreference: z.string().max(50).optional(),
        partnerChildrenPreference: z.string().max(50).optional(),
        introvertScale: z.number().int().min(0).max(100).optional(),
        partnerIntrovertPreference: z.string().max(50).optional(),
        partnerIntrovertMin: z.number().int().min(0).max(100).optional(),
        partnerIntrovertMax: z.number().int().min(0).max(100).optional(),
        occupation: z.string().max(100).optional(),
        company: z.string().max(100).optional(),
        school: z.string().max(100).optional(),
        jobStatus: z.string().max(50).optional(),
        religion: z.string().max(50).optional(),
        religionPreference: z.string().max(50).optional(),
        ethnicity: z.string().max(50).optional(),
        ethnicityPreference: z.string().max(50).optional(),
        hairColor: z.string().max(50).optional(),
        hairColorPreference: z.string().max(50).optional(),
        politicalAffiliation: z.string().max(50).optional(),
        politicalAffiliationPreference: z.string().max(50).optional(),
        partnerPoliticalMin: z.number().int().min(1).max(5).optional(),
        partnerPoliticalMax: z.number().int().min(1).max(5).optional(),
        partnerHeightPreference: z.string().max(50).optional(),
        interestedIn: z.enum(["male", "female", "both", "non_binary"]).optional(),
        lookingFor: z.array(z.string().max(50)).max(5).optional(),
        languages: z.array(z.string().max(50)).max(5).optional(),
        hobbies: z.array(z.string().max(50)).max(20).optional(),
        prompts: z.record(z.string().max(50), z.string().max(300)).optional(),
        appLanguage: z.string().length(2).optional(),
        isDarkMode: z.boolean().optional(),
        isPrideMode: z.boolean().optional(),
        isClassicAppearance: z.boolean().optional(),
        isGenderBasedColor: z.boolean().optional(),
        showPingAnimation: z.boolean().optional(),
        isPingVibrationEnabled: z.boolean().optional(),
        ageRangeStart: z.number().int().min(18).max(100).optional(),
        ageRangeEnd: z.number().int().min(18).max(100).optional(),
        heightRangeStart: z.number().int().min(100).max(250).optional(),
        heightRangeEnd: z.number().int().min(100).max(250).optional(),
        maxDistance: z.number().int().min(1).max(500).optional(),
        isTraveler: z.boolean().optional(),
    })
    .strict(); // Reject unknown fields — prevents injection of isAdmin/isPremium

export type UpdateProfileData = z.infer<typeof updateProfileSchema>;
