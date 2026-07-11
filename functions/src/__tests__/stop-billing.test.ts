/**
 * stopBilling unit tests.
 *
 * Covers the three critical paths from KORAK 43:
 *   (a) sub-threshold      → no billing call
 *   (b) over-threshold     → updateProjectBillingInfo called with cleared account
 *   (c) missing/broken data → no crash, no billing call
 */

import { describe, it, expect, jest, beforeEach } from "@jest/globals";

jest.mock("firebase-functions/v2/pubsub", () => ({
    onMessagePublished: jest.fn((_opts: unknown, handler: unknown) => handler),
}));

jest.mock("firebase-functions/v2", () => ({
    logger: {
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    },
}));

jest.mock("@google-cloud/billing", () => ({
    CloudBillingClient: jest.fn(),
}));

import {
    decodeBudgetMessage,
    resolveThreshold,
    handleBudgetNotification,
} from "../scripts/stop-billing";

const PROJECT_ID = "am---dating-app";

function makeBillingClient(overrides?: {
    billingEnabled?: boolean;
}) {
    const getProjectBillingInfo = jest.fn(() =>
        Promise.resolve([
            { billingEnabled: overrides?.billingEnabled ?? true },
        ]),
    );
    const updateProjectBillingInfo = jest.fn(() =>
        Promise.resolve([{ billingEnabled: false }]),
    );
    return {
        getProjectBillingInfo,
        updateProjectBillingInfo,
    } as unknown as Parameters<typeof handleBudgetNotification>[2] & {
        getProjectBillingInfo: jest.Mock;
        updateProjectBillingInfo: jest.Mock;
    };
}

function encodePayload(obj: unknown): string {
    return Buffer.from(JSON.stringify(obj), "utf-8").toString("base64");
}

describe("decodeBudgetMessage", () => {
    it("returns null when raw payload is undefined", () => {
        expect(decodeBudgetMessage(undefined)).toBeNull();
    });

    it("returns null when raw payload is empty string", () => {
        expect(decodeBudgetMessage("")).toBeNull();
    });

    it("returns null when payload is not valid base64 JSON", () => {
        expect(decodeBudgetMessage("!!!not-base64-json!!!")).toBeNull();
    });

    it("decodes a valid base64-encoded JSON payload", () => {
        const payload = {
            budgetDisplayName: "test",
            costAmount: 5,
            budgetAmount: 10,
            currencyCode: "EUR",
        };
        const result = decodeBudgetMessage(encodePayload(payload));
        expect(result).toEqual(payload);
    });
});

describe("resolveThreshold", () => {
    it("prefers a positive env override over the budgetAmount", () => {
        expect(resolveThreshold(10, "25")).toBe(25);
    });

    it("falls back to budgetAmount when env is unset", () => {
        expect(resolveThreshold(10, undefined)).toBe(10);
    });

    it("falls back to budgetAmount when env is empty string", () => {
        expect(resolveThreshold(10, "")).toBe(10);
    });

    it("ignores non-numeric env override", () => {
        expect(resolveThreshold(10, "not-a-number")).toBe(10);
    });

    it("ignores zero or negative env override", () => {
        expect(resolveThreshold(10, "0")).toBe(10);
        expect(resolveThreshold(10, "-5")).toBe(10);
    });

    it("returns null when neither env nor budgetAmount is usable", () => {
        expect(resolveThreshold(undefined, undefined)).toBeNull();
        expect(resolveThreshold(undefined, "")).toBeNull();
    });
});

describe("handleBudgetNotification", () => {
    let billing: ReturnType<typeof makeBillingClient>;

    beforeEach(() => {
        billing = makeBillingClient();
    });

    it("(c) missing data: no-op, no crash, no billing call", async () => {
        await expect(
            handleBudgetNotification(null, PROJECT_ID, billing, undefined),
        ).resolves.toBeUndefined();

        expect(billing.getProjectBillingInfo).not.toHaveBeenCalled();
        expect(billing.updateProjectBillingInfo).not.toHaveBeenCalled();
    });

    it("(a) sub-threshold: does not touch billing", async () => {
        const notification = {
            budgetDisplayName: "monthly-cap",
            costAmount: 3.5,
            budgetAmount: 10,
            currencyCode: "EUR",
        };

        await handleBudgetNotification(
            notification,
            PROJECT_ID,
            billing,
            undefined,
        );

        expect(billing.getProjectBillingInfo).not.toHaveBeenCalled();
        expect(billing.updateProjectBillingInfo).not.toHaveBeenCalled();
    });

    it("(a) at-threshold (equal): does not touch billing", async () => {
        const notification = {
            budgetDisplayName: "monthly-cap",
            costAmount: 10,
            budgetAmount: 10,
            currencyCode: "EUR",
        };

        await handleBudgetNotification(
            notification,
            PROJECT_ID,
            billing,
            undefined,
        );

        expect(billing.getProjectBillingInfo).not.toHaveBeenCalled();
        expect(billing.updateProjectBillingInfo).not.toHaveBeenCalled();
    });

    it("(b) over-threshold with billingEnabled: disables billing", async () => {
        const notification = {
            budgetDisplayName: "monthly-cap",
            costAmount: 12.34,
            budgetAmount: 10,
            currencyCode: "EUR",
        };

        await handleBudgetNotification(
            notification,
            PROJECT_ID,
            billing,
            undefined,
        );

        expect(billing.getProjectBillingInfo).toHaveBeenCalledWith({
            name: `projects/${PROJECT_ID}`,
        });
        expect(billing.updateProjectBillingInfo).toHaveBeenCalledWith({
            name: `projects/${PROJECT_ID}`,
            projectBillingInfo: { billingAccountName: "" },
        });
    });

    it("(b) over-threshold but billing already disabled: skips update", async () => {
        billing = makeBillingClient({ billingEnabled: false });

        const notification = {
            budgetDisplayName: "monthly-cap",
            costAmount: 50,
            budgetAmount: 10,
            currencyCode: "EUR",
        };

        await handleBudgetNotification(
            notification,
            PROJECT_ID,
            billing,
            undefined,
        );

        expect(billing.getProjectBillingInfo).toHaveBeenCalledTimes(1);
        expect(billing.updateProjectBillingInfo).not.toHaveBeenCalled();
    });

    it("env override raises the threshold and prevents disable", async () => {
        const notification = {
            budgetDisplayName: "monthly-cap",
            costAmount: 15,
            budgetAmount: 10,
            currencyCode: "EUR",
        };

        await handleBudgetNotification(notification, PROJECT_ID, billing, "25");

        expect(billing.updateProjectBillingInfo).not.toHaveBeenCalled();
    });

    it("env override lowers the threshold and triggers disable", async () => {
        const notification = {
            budgetDisplayName: "monthly-cap",
            costAmount: 6,
            budgetAmount: 10,
            currencyCode: "EUR",
        };

        await handleBudgetNotification(notification, PROJECT_ID, billing, "5");

        expect(billing.updateProjectBillingInfo).toHaveBeenCalledTimes(1);
    });

    it("(c) missing costAmount: no-op", async () => {
        const notification = {
            budgetDisplayName: "monthly-cap",
            budgetAmount: 10,
            currencyCode: "EUR",
        };

        await handleBudgetNotification(
            notification,
            PROJECT_ID,
            billing,
            undefined,
        );

        expect(billing.getProjectBillingInfo).not.toHaveBeenCalled();
    });
});
