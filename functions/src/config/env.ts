/**
 * Tremble — Environment Configuration
 *
 * Centralizes all environment-dependent configuration.
 * Secrets are loaded from Firebase Secret Manager (process.env).
 */

export interface AppConfig {
    /** Cloudflare R2 configuration */
    r2: {
        accountId: string;
        accessKeyId: string;
        secretAccessKey: string;
        bucketName: string;
        endpoint: string;    // Full S3-compatible endpoint
        publicUrl: string;
    };
    /** Resend (transactional email) */
    resend: {
        apiKey: string;
        fromEmail: string;
    };
    /** Environment identifier */
    environment: "dev" | "staging" | "prod";
    /** Rate limiting defaults */
    rateLimits: {
        defaultWindowMs: number;
        defaultMaxRequests: number;
    };
}

/**
 * True only when running against the production Firebase project (am---dating-app).
 * Used to gate App Check enforcement so iOS simulator / dev builds aren't blocked.
 */
export const ENFORCE_APP_CHECK = process.env.TREMBLE_ENV === "prod";

/**
 * Load configuration from environment.
 * Secrets (API keys) come from Firebase Secret Manager via process.env.
 */
export function getConfig(): AppConfig {
    const env = (process.env.TREMBLE_ENV as AppConfig["environment"]) || "dev";
    
    // We expect these to be populated by Firebase Secret Manager in production.
    // In local emulator, these should be loaded from .env.local
    const r2AccountId = process.env.R2_ACCOUNT_ID || "missing_account_id";
    const r2BucketName = process.env.R2_BUCKET_NAME || "missing_bucket_name";

    return {
        r2: {
            accountId: r2AccountId,
            accessKeyId: process.env.R2_ACCESS_KEY_ID || "",
            secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || "",
            bucketName: r2BucketName,
            endpoint: `https://${r2AccountId}.r2.cloudflarestorage.com`,
            publicUrl: process.env.R2_PUBLIC_URL || "",
        },
        resend: {
            apiKey: process.env.RESEND_API_KEY || "",
            fromEmail: process.env.RESEND_FROM_EMAIL || "noreply@trembledating.com",
        },
        environment: env,
        rateLimits: {
            defaultWindowMs: 60_000, // 1 minute
            defaultMaxRequests: 30,
        },
    };
}
