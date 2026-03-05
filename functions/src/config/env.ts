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

const R2_ACCOUNT_ID = "8df0214c44c257654f7aa054a8ffb9dc";
const R2_BUCKET_NAME = "tremble-avatars";

/**
 * Load configuration from environment.
 * Secrets (API keys) come from Firebase Secret Manager via process.env.
 */
export function getConfig(): AppConfig {
    const env = (process.env.TREMBLE_ENV as AppConfig["environment"]) || "dev";

    return {
        r2: {
            accountId: process.env.R2_ACCOUNT_ID || R2_ACCOUNT_ID,
            accessKeyId: process.env.R2_ACCESS_KEY_ID || "",
            secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || "",
            bucketName: process.env.R2_BUCKET_NAME || R2_BUCKET_NAME,
            endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
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
