/**
 * Tremble — Matches Schemas
 *
 * Zod schemas for match-related operations.
 */

import { z } from "zod";

/** Schema for sending a greeting / match request */
export const sendGreetingSchema = z.object({
    toUserId: z.string().min(1, "Target user ID required"),
    message: z
        .string()
        .max(200, "Greeting message too long")
        .optional(),
});

export type SendGreetingData = z.infer<typeof sendGreetingSchema>;

/** Schema for responding to a greeting */
export const respondToGreetingSchema = z.object({
    greetingId: z.string().min(1, "Greeting ID required"),
    accept: z.boolean(),
});

export type RespondToGreetingData = z.infer<typeof respondToGreetingSchema>;
