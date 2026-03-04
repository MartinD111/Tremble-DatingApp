/**
 * Tremble — Uploads Functions
 *
 * Generates presigned URLs for Cloudflare R2 uploads.
 * Photos are uploaded directly from client → R2 using presigned URLs.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { requireAuth } from "../../middleware/authGuard";
import { checkRateLimit } from "../../middleware/rateLimit";
import { validateRequest } from "../../middleware/validate";
import { generateUploadUrlSchema } from "./uploads.schema";
import { getConfig } from "../../config/env";

/**
 * Generate a presigned upload URL for Cloudflare R2.
 *
 * Flow:
 *   1. Client calls this function with filename, mimeType, fileSize
 *   2. Server validates + generates a 5-minute presigned PUT URL
 *   3. Client uploads directly to R2 using the presigned URL (HTTP PUT)
 *   4. Client saves the returned publicUrl to their profile via updateProfile
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
        if (!config.r2.accountId || !config.r2.accessKeyId || !config.r2.secretAccessKey) {
            console.error("[UPLOADS] R2 configuration missing");
            throw new HttpsError("internal", "Upload service not configured.");
        }

        // Build a secure, unique object key scoped to the user
        const timestamp = Date.now();
        const objectKey = `users/${uid}/photos/${timestamp}_${data.fileName}`;

        // R2 is S3-compatible — use the AWS SDK
        const s3Client = new S3Client({
            region: "auto",
            endpoint: `https://${config.r2.accountId}.r2.cloudflarestorage.com`,
            credentials: {
                accessKeyId: config.r2.accessKeyId,
                secretAccessKey: config.r2.secretAccessKey,
            },
        });

        const command = new PutObjectCommand({
            Bucket: config.r2.bucketName,
            Key: objectKey,
            ContentType: data.mimeType,
            ContentLength: data.fileSizeBytes,
            // Metadata stored with the object
            Metadata: {
                uploader: uid,
                originalName: data.fileName,
            },
        });

        const uploadUrl = await getSignedUrl(s3Client, command, {
            expiresIn: 300, // 5-minute window
        });

        const publicUrl = `${config.r2.publicUrl}/${objectKey}`;

        console.log(`[UPLOADS] Presigned URL generated for ${uid}: ${objectKey}`);

        return {
            uploadUrl,   // PUT to this URL directly from the client
            publicUrl,   // Final accessible URL after upload completes
            objectKey,
            expiresIn: 300,
        };
    }
);
