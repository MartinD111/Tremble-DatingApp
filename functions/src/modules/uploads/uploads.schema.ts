/**
 * Tremble — Uploads Schemas
 */

import { z } from "zod";

/** Allowed MIME types for photo uploads */
const ALLOWED_MIME_TYPES = [
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
] as const;

export const generateUploadUrlSchema = z.object({
    fileName: z
        .string()
        .min(1)
        .max(200)
        .regex(
            /^[a-zA-Z0-9_-]+\.[a-zA-Z0-9]+$/,
            "Invalid filename. Use only alphanumeric characters, dashes, and underscores."
        ),
    mimeType: z.enum(ALLOWED_MIME_TYPES, {
        errorMap: () => ({
            message: `Allowed types: ${ALLOWED_MIME_TYPES.join(", ")}`,
        }),
    }),
    fileSizeBytes: z
        .number()
        .int()
        .min(1)
        .max(10 * 1024 * 1024, "File too large. Maximum 10MB."),
});

export type GenerateUploadUrlData = z.infer<typeof generateUploadUrlSchema>;
