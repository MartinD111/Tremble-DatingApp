/**
 * Tremble — Uploads Functions
 *
 * Generates presigned URLs for Cloudflare R2 uploads.
 * Photos are uploaded directly from client → R2 using presigned URLs.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import { generateUploadUrlSchema } from "./uploads.schema";
import { getConfig } from "../../config/env";

// NOTE: The actual R2 presigned URL generation requires the @aws-sdk/client-s3
// and @aws-sdk/s3-request-presigner packages (R2 is S3-compatible).
// Uncomment the imports below after running:
//   npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
//
// import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
// import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

/**
 * Generate a presigned upload URL for Cloudflare R2.
 *
 * Flow:
 *   1. Client calls this function with filename, mimeType, fileSize
 *   2. Server validates + generates presigned URL
 *   3. Client uploads directly to R2 using the presigned URL
 *   4. Client updates profile photoUrls with the final R2 URL
 */
export const generateUploadUrl = onCall(
    { maxInstances: 50 },
    async (request) => {
        const uid = requireAuth(request);

        // Rate limit: max 20 uploads per minute
        await checkRateLimit(uid, "generateUploadUrl", {
            maxRequests: 20,
            windowMs: 60_000,
        });

        const data = validateRequest(generateUploadUrlSchema, request.data);
        const config = getConfig();

        // Validate R2 config is present
        if (!config.r2.accountId || !config.r2.accessKeyId) {
            console.error("[UPLOADS] R2 configuration missing");
            throw new HttpsError(
                "internal",
                "Upload service not configured."
            );
        }

        // Build a secure, unique object key
        const timestamp = Date.now();
        const objectKey = `users/${uid}/photos/${timestamp}_${data.fileName}`;

        // TODO: Uncomment when @aws-sdk/client-s3 is installed
        //
        // const s3Client = new S3Client({
        //   region: "auto",
        //   endpoint: `https://${config.r2.accountId}.r2.cloudflarestorage.com`,
        //   credentials: {
        //     accessKeyId: config.r2.accessKeyId,
        //     secretAccessKey: config.r2.secretAccessKey,
        //   },
        // });
        //
        // const command = new PutObjectCommand({
        //   Bucket: config.r2.bucketName,
        //   Key: objectKey,
        //   ContentType: data.mimeType,
        //   ContentLength: data.fileSizeBytes,
        // });
        //
        // const uploadUrl = await getSignedUrl(s3Client, command, {
        //   expiresIn: 300, // 5 minutes
        // });

        // Placeholder until R2 SDK is installed
        const uploadUrl = `https://${config.r2.publicUrl}/${objectKey}`;

        const publicUrl = `${config.r2.publicUrl}/${objectKey}`;

        console.log(`[UPLOADS] URL generated for ${uid}: ${objectKey}`);

        return {
            uploadUrl,
            publicUrl,
            objectKey,
            expiresIn: 300,
        };
    }
);
