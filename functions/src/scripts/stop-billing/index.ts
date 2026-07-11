/**
 * stopBilling — GCP budget kill-switch.
 *
 * Triggered by Cloud Billing budget alerts published to Pub/Sub topic
 * `budget-limit-reached`. When actual cost exceeds the configured budget
 * amount, disables billing on the project by clearing its billing account
 * association. This is a hard stop that halts all billable resources.
 *
 * Threshold override: set STOP_BILLING_THRESHOLD_EUR to force a specific
 * cutoff (default: use the budgetAmount from the Pub/Sub payload).
 */

import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { logger } from "firebase-functions/v2";
import { CloudBillingClient } from "@google-cloud/billing";

const PUBSUB_TOPIC = "budget-limit-reached";

interface BudgetNotification {
    budgetDisplayName?: string;
    costAmount?: number;
    budgetAmount?: number;
    currencyCode?: string;
    alertThresholdExceeded?: number;
    costIntervalStart?: string;
}

/**
 * Decode the raw base64 Pub/Sub payload into a BudgetNotification.
 * Returns null if payload is missing or unparseable — caller must no-op.
 */
export function decodeBudgetMessage(
    rawBase64: string | undefined,
): BudgetNotification | null {
    if (!rawBase64) return null;
    try {
        const json = Buffer.from(rawBase64, "base64").toString("utf-8");
        return JSON.parse(json) as BudgetNotification;
    } catch (err) {
        logger.warn("stopBilling: failed to decode budget message", {
            error: err instanceof Error ? err.message : String(err),
        });
        return null;
    }
}

/**
 * Resolve the effective cutoff threshold. Env var STOP_BILLING_THRESHOLD_EUR
 * wins if set to a positive finite number; otherwise fall back to the
 * budgetAmount from the notification.
 */
export function resolveThreshold(
    budgetAmount: number | undefined,
    envValue: string | undefined,
): number | null {
    if (envValue !== undefined && envValue !== "") {
        const parsed = Number(envValue);
        if (Number.isFinite(parsed) && parsed > 0) return parsed;
    }
    if (typeof budgetAmount === "number" && Number.isFinite(budgetAmount)) {
        return budgetAmount;
    }
    return null;
}

/**
 * Core kill-switch decision + action. Extracted so tests can drive it
 * without spinning up a full CloudEvent envelope.
 */
export async function handleBudgetNotification(
    notification: BudgetNotification | null,
    projectId: string,
    billingClient: Pick<
        CloudBillingClient,
        "getProjectBillingInfo" | "updateProjectBillingInfo"
    >,
    envThreshold: string | undefined,
): Promise<void> {
    if (!notification) {
        logger.info("stopBilling: empty payload, no-op");
        return;
    }

    const costAmount = notification.costAmount;
    const threshold = resolveThreshold(notification.budgetAmount, envThreshold);

    logger.info("stopBilling: budget alert received", {
        budget: notification.budgetDisplayName,
        cost: costAmount,
        budgetAmount: notification.budgetAmount,
        threshold,
        currency: notification.currencyCode,
    });

    if (typeof costAmount !== "number" || !Number.isFinite(costAmount)) {
        logger.warn("stopBilling: missing costAmount, no-op");
        return;
    }
    if (threshold === null) {
        logger.warn("stopBilling: no threshold resolvable, no-op");
        return;
    }
    if (costAmount <= threshold) {
        logger.info("stopBilling: under threshold, no-op", {
            costAmount,
            threshold,
        });
        return;
    }

    const projectName = `projects/${projectId}`;
    const [info] = await billingClient.getProjectBillingInfo({
        name: projectName,
    });

    if (!info?.billingEnabled) {
        logger.info("stopBilling: billing already disabled, no-op", {
            projectId,
        });
        return;
    }

    logger.error("stopBilling: disabling billing on project", {
        projectId,
        costAmount,
        threshold,
        currency: notification.currencyCode,
    });

    await billingClient.updateProjectBillingInfo({
        name: projectName,
        projectBillingInfo: { billingAccountName: "" },
    });

    logger.error("stopBilling: billing disabled", { projectId });
}

let cachedClient: CloudBillingClient | null = null;
function getBillingClient(): CloudBillingClient {
    if (!cachedClient) cachedClient = new CloudBillingClient();
    return cachedClient;
}

export const stopBilling = onMessagePublished(
    { topic: PUBSUB_TOPIC, region: "europe-west1" },
    async (event) => {
        const rawBase64 = event.data?.message?.data;
        const notification = decodeBudgetMessage(rawBase64);
        const projectId =
            process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? "";

        if (!projectId) {
            logger.warn("stopBilling: no projectId in env, no-op");
            return;
        }

        await handleBudgetNotification(
            notification,
            projectId,
            getBillingClient(),
            process.env.STOP_BILLING_THRESHOLD_EUR,
        );
    },
);
