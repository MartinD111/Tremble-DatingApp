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
        location: z.enum(["Ljubljana", "Koper", "Zagreb", "Other"]).nullish(),
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
