/**
 * Tremble — Validation Middleware
 *
 * Uses Zod schemas for request validation.
 * Provides a generic wrapper that validates incoming data before processing.
 */

import { ZodSchema, ZodError } from "zod";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Validate request data against a Zod schema.
 *
 * @param schema - The Zod schema to validate against
 * @param data - The incoming request data
 * @returns The validated and parsed data (typed)
 * @throws HttpsError with INVALID_ARGUMENT if validation fails
 */
export function validateRequest<T>(schema: ZodSchema<T>, data: unknown): T {
    try {
        return schema.parse(data);
    } catch (error) {
        if (error instanceof ZodError) {
            const messages = error.errors.map(
                (e) => `${e.path.join(".")}: ${e.message}`
            );
            throw new HttpsError(
                "invalid-argument",
                `Validation failed: ${messages.join("; ")}`
            );
        }
        throw new HttpsError("internal", "Validation error.");
    }
}
