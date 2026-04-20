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

export const blockUserSchema = z.object({
    targetUid: z.string().min(1).max(128),
});

export const unblockUserSchema = z.object({
    targetUid: z.string().min(1).max(128),
});

export const reportUserSchema = z.object({
    reportedUid: z.string().min(1).max(128),
    reasons: z.array(z.enum(REPORT_REASONS)).min(1).max(10),
    explanation: z.string().max(500).optional(),
});

export type BlockUserData = z.infer<typeof blockUserSchema>;
export type UnblockUserData = z.infer<typeof unblockUserSchema>;
export type ReportUserData = z.infer<typeof reportUserSchema>;
