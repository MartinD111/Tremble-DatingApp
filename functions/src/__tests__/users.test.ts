/**
 * Tremble — Users Functions Unit Tests
 */

import { describe, it, expect } from "@jest/globals";

describe("Users Module", () => {
    describe("updateProfileSchema", () => {
        it("should accept Flutter interestedIn list payload", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                interestedIn: ["male", "female"],
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.interestedIn).toEqual(["male", "female"]);
            }
        });
    });
});
