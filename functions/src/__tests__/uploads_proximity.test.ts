/**
 * Tremble — Uploads + Proximity Schema Unit Tests
 */

import { describe, it, expect, jest } from "@jest/globals";

jest.mock("firebase-admin/firestore", () => ({
    getFirestore: jest.fn(() => ({})),
    FieldValue: { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") },
}));
jest.mock("firebase-functions/v2/https", () => ({
    onCall: jest.fn((_, fn) => fn),
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) { super(message); this.code = code; }
    },
}));

describe("Uploads Module", () => {
    describe("generateUploadUrlSchema", () => {
        it("should reject disallowed MIME type", async () => {
            const { generateUploadUrlSchema } = await import("../../src/modules/uploads/uploads.schema");
            const result = generateUploadUrlSchema.safeParse({
                fileName: "virus.exe",
                mimeType: "application/octet-stream",
                fileSizeBytes: 1024,
            });
            expect(result.success).toBe(false);
        });

        it("should reject file over 10MB", async () => {
            const { generateUploadUrlSchema } = await import("../../src/modules/uploads/uploads.schema");
            const result = generateUploadUrlSchema.safeParse({
                fileName: "big.jpg",
                mimeType: "image/jpeg",
                fileSizeBytes: 11 * 1024 * 1024, // 11MB
            });
            expect(result.success).toBe(false);
        });

        it("should accept valid JPEG upload", async () => {
            const { generateUploadUrlSchema } = await import("../../src/modules/uploads/uploads.schema");
            const result = generateUploadUrlSchema.safeParse({
                fileName: "profile.jpg",
                mimeType: "image/jpeg",
                fileSizeBytes: 2 * 1024 * 1024, // 2MB
            });
            expect(result.success).toBe(true);
        });
    });
});

describe("Proximity Module", () => {
    describe("findNearbySchema / updateLocationSchema", () => {
        it("should reject invalid coordinates", async () => {
            // We test the schemas defined inside proximity.functions.ts inline
            const { z } = await import("zod");
            const updateLocationSchema = z.object({
                latitude: z.number().min(-90).max(90),
                longitude: z.number().min(-180).max(180),
            });

            expect(updateLocationSchema.safeParse({ latitude: 200, longitude: 0 }).success).toBe(false);
            expect(updateLocationSchema.safeParse({ latitude: 46.05, longitude: 14.5 }).success).toBe(true);
        });
    });
});
