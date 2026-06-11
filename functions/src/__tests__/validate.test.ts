import { describe, it, expect, jest } from "@jest/globals";

jest.mock("firebase-functions/v2/https", () => ({
    HttpsError: class HttpsError extends Error {
        code: string;
        constructor(code: string, message: string) {
            super(message);
            this.code = code;
        }
    },
}));

describe("Validation Middleware", () => {
    describe("assertValidDocumentId", () => {
        it("accepts alphanumeric IDs with underscores and hyphens up to 128 chars", async () => {
            const { assertValidDocumentId } = await import("../../src/middleware/validate");
            const validId = `${"a".repeat(126)}_-`;

            expect(assertValidDocumentId(validId, "userId")).toBe(validId);
        });

        it("rejects IDs longer than 128 chars", async () => {
            const { assertValidDocumentId } = await import("../../src/middleware/validate");
            const tooLongId = "a".repeat(129);

            expect(() => assertValidDocumentId(tooLongId, "userId")).toThrow(
                "Invalid userId"
            );
        });

        it("rejects IDs with non-alphanumeric characters except underscore and hyphen", async () => {
            const { assertValidDocumentId } = await import("../../src/middleware/validate");

            expect(() => assertValidDocumentId("user.name", "userId")).toThrow(
                "Invalid userId"
            );
            expect(() => assertValidDocumentId("user name", "userId")).toThrow(
                "Invalid userId"
            );
        });
    });
});
