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

        it("should accept nicotine fields", async () => {
            const { updateProfileSchema } = await import(
                "../../src/modules/users/users.schema"
            );

            const result = updateProfileSchema.safeParse({
                nicotineUse: "vaping",
                nicotineFilter: "no_smoking",
            });

            expect(result.success).toBe(true);
            if (result.success) {
                expect(result.data.nicotineUse).toBe("vaping");
                expect(result.data.nicotineFilter).toBe("no_smoking");
            }
        });
    });
});
