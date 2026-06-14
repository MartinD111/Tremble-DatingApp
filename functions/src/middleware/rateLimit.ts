/**
 * Tremble — Rate Limiting Middleware
 *
 * Uses Firestore TTL documents for rate limiting.
 * Designed as swappable interface — Redis can replace Firestore later.
 */

import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

interface RateLimitConfig {
    /** Maximum number of requests in the window */
    maxRequests: number;
    /** Window duration in milliseconds */
    windowMs: number;
}

const DEFAULT_CONFIG: RateLimitConfig = {
    maxRequests: 30,
    windowMs: 60_000, // 1 minute
};

/**
 * Check and enforce rate limits for a given user + endpoint.
 *
 * Uses Firestore documents with TTL for automatic cleanup.
 * Document path: rateLimits/{uid}:{endpoint}
 *
 * @param uid - The user's UID
 * @param endpoint - The endpoint/function identifier
 * @param config - Optional rate limit configuration
 * @throws HttpsError with RESOURCE_EXHAUSTED if rate limit exceeded
 */
export async function checkRateLimit(
    uid: string,
    endpoint: string,
    config: Partial<RateLimitConfig> = {}
): Promise<void> {
    const { maxRequests, windowMs } = { ...DEFAULT_CONFIG, ...config };
    const db = getFirestore();
    const docId = `${uid}:${endpoint}`;
    const docRef = db.collection("rateLimits").doc(docId);

    const now = Date.now();

    await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(docRef);

        if (!doc.exists) {
            // First request — create the rate limit document
            transaction.set(docRef, {
                count: 1,
                windowStart: now,
                ttl: new Date(now + windowMs), // Firestore TTL
            });
            return;
        }

        const data = doc.data()!;
        const windowStart = data.windowStart as number;
        const count = data.count as number;

        if (now - windowStart > windowMs) {
            // Window expired — reset
            transaction.set(docRef, {
                count: 1,
                windowStart: now,
                ttl: new Date(now + windowMs),
            });
            return;
        }

        if (count >= maxRequests) {
            const retryAfterMs = windowMs - (now - windowStart);
            throw new HttpsError(
                "resource-exhausted",
                `Rate limit exceeded. Try again in ${Math.ceil(retryAfterMs / 1000)} seconds.`
            );
        }

        // Increment counter
        transaction.update(docRef, {
            count: FieldValue.increment(1),
        });
    });
}
