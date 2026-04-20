/**
 * Tremble — Redis Client (Upstash)
 *
 * Singleton factory for the Upstash Redis REST client.
 * Used for:
 *   - Proximity notification cooldowns (per user pair)
 *   - Global notification rate-limiting (per recipient)
 *   - Wave deduplication (per sender-receiver pair)
 *
 * Requires env vars:
 *   UPSTASH_REDIS_REST_URL
 *   UPSTASH_REDIS_REST_TOKEN
 *
 * The REST-based client (not TCP) works correctly in Cloud Functions
 * serverless environment — no persistent connections required.
 */

import { Redis } from "@upstash/redis";

let _client: Redis | null = null;

/**
 * Get or create the Redis client singleton.
 * Throws a descriptive error if env vars are missing.
 */
export function getRedis(): Redis {
    if (_client) return _client;

    const url = process.env.UPSTASH_REDIS_REST_URL;
    const token = process.env.UPSTASH_REDIS_REST_TOKEN;

    if (!url || !token) {
        throw new Error(
            "[REDIS] UPSTASH_REDIS_REST_URL or UPSTASH_REDIS_REST_TOKEN is missing. " +
            "Add them to functions/.env.dev and functions/.env.prod"
        );
    }

    _client = new Redis({ url, token });
    return _client;
}

// ── Redis Key Helpers ─────────────────────────────────────────────

/**
 * Cooldown key for a specific proximity pair (A ↔ B).
 * Sorted so A_B and B_A resolve to the same key.
 * TTL: 30 minutes
 */
export function proximityCooldownKey(uidA: string, uidB: string): string {
    const sorted = [uidA, uidB].sort().join("_");
    return `prox_cooldown:${sorted}`;
}

/**
 * Global notification throttle key for a single recipient.
 * Tracks how many proximity notifications they've received in the window.
 * TTL: 10 minutes
 */
export function globalThrottleKey(uid: string): string {
    return `global_throttle:${uid}`;
}

/**
 * Wave deduplication key — prevents INCOMING_WAVE spam
 * if a user taps wave rapidly.
 * TTL: 5 minutes
 */
export function waveDedupKey(fromUid: string, toUid: string): string {
    return `wave_dedup:${fromUid}_${toUid}`;
}

// ── TTL Constants (seconds) ───────────────────────────────────────

export const PROXIMITY_COOLDOWN_SECS = 30 * 60;      // 30 minutes
export const GLOBAL_THROTTLE_SECS    = 10 * 60;      // 10 minutes  
export const WAVE_DEDUP_SECS         = 5  * 60;      // 5 minutes
export const GLOBAL_THROTTLE_MAX     = 3;             // max pings per window
