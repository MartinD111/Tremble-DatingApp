/**
 * Tremble — Environment Configuration
 *
 * Centralizes all environment-dependent configuration.
 * Values are read from Firebase Functions config or environment variables.
 */

export interface AppConfig {
    /** Cloudflare R2 configuration */
    r2: {
        accountId: string;
        accessKeyId: string;
        secretAccessKey: string;
        bucketName: string;
        publicUrl: string;
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
 * Load configuration from environment.
 * In Cloud Functions, use `functions.config()` or `process.env`.
 */
export function getConfig(): AppConfig {
    const env = (process.env.TREMBLE_ENV as AppConfig["environment"]) || "dev";

    return {
        r2: {
            accountId: process.env.R2_ACCOUNT_ID || "",
            accessKeyId: process.env.R2_ACCESS_KEY_ID || "",
            secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || "",
            bucketName: process.env.R2_BUCKET_NAME || `tremble-uploads-${env}`,
            publicUrl: process.env.R2_PUBLIC_URL || "",
        },
        environment: env,
        rateLimits: {
            defaultWindowMs: 60_000, // 1 minute
            defaultMaxRequests: 30,
        },
    };
}
