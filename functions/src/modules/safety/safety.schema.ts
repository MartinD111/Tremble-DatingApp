/**
 * Tremble — Safety Schemas
 *
 * Zod validation schemas for safety-related operations (block, unblock, report).
 */

import { z } from "zod";

export const REPORT_REASONS = [
    "harassment",
    "fake_profile",
    "underage",
    "inappropriate_content",
    "spam",
] as const;

const documentIdSchema = z.string().min(1).max(128).refine(
    (value) => !value.includes("/"),
    "Invalid ID"
);

export const blockUserSchema = z.object({
    targetUid: documentIdSchema,
});

export const unblockUserSchema = z.object({
    targetUid: documentIdSchema,
});

export const reportUserSchema = z.object({
    reportedUid: documentIdSchema,
    reasons: z.array(z.enum(REPORT_REASONS)).min(1).max(10),
    explanation: z.string().max(500).optional(),
});

export const checkAnonymitySchema = z.object({
    hashedContacts: z.array(z.string()).max(10000), // Protect against overly large payloads
});

export type BlockUserData = z.infer<typeof blockUserSchema>;
export type UnblockUserData = z.infer<typeof unblockUserSchema>;
export type ReportUserData = z.infer<typeof reportUserSchema>;
export type CheckAnonymityData = z.infer<typeof checkAnonymitySchema>;
