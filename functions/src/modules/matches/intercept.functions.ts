/**
 * Tremble — Pulse Intercept Module (F12)
 *
 * Ephemeral contact and media sharing between mutual matches.
 * Strictly adheres to privacy-by-architecture:
 * - No data stored in persistent databases (Firestore/SQL).
 * - 10-minute TTL via Redis.
 * - View-once enforcement for media.
 */

import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { getRedis } from "../../core/redis";
import { requireAuth, assertNotBanned } from "../../middleware/authGuard";
import { assertValidDocumentId } from "../../middleware/validate";
import { ENFORCE_APP_CHECK } from "../../config/env";
import { checkRateLimit } from "../../middleware/rateLimit";

const INTERCEPT_TTL_SECS = 600; // 10 minutes

function logStructured(fields: Record<string, unknown>): void {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    ...fields,
  }));
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

/**
 * Request a Pulse Intercept (Phone or Photo).
 * Triggers a push notification to the recipient.
 */
export const requestPulseIntercept = onCall(
  { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
  async (request: CallableRequest) => {
    const senderUid = requireAuth(request);
    await checkRateLimit(senderUid, "requestPulseIntercept", { maxRequests: 5, windowMs: 60000 });
    const startedAt = Date.now();
    logStructured({ fn: "requestPulseIntercept", event: "entry", uid: senderUid });

    try {
      // Ban check — fetch once for ban + use below for match verification.
      const senderDoc = await admin.firestore().collection("users").doc(senderUid).get();
      assertNotBanned(senderDoc.data());

      const { targetUid: rawTargetUid, type, data } = request.data;
      const targetUid = assertValidDocumentId(rawTargetUid, "targetUid");

      if (!type) {
        throw new HttpsError("invalid-argument", "Target UID and type are required.");
      }

      if (type !== "phone" && type !== "photo") {
        throw new HttpsError("invalid-argument", "Invalid intercept type.");
      }

      const matchId = [senderUid, targetUid].sort().join("_");
      const matchDoc = await admin.firestore().collection("matches").doc(matchId).get();

      if (!matchDoc.exists) {
        throw new HttpsError("permission-denied", "No active match found between users.");
      }

      const matchData = matchDoc.data();
      if (matchData?.status === "expired" || matchData?.status === "closed") {
        throw new HttpsError("permission-denied", "Match has expired or is closed.");
      }

      let payloadData = data;
      if (type === "phone") {
        const freshSenderDoc = await admin.firestore().collection("users").doc(senderUid).get();
        const senderPhone = freshSenderDoc.data()?.phoneNumber;
        if (!senderPhone) {
          throw new HttpsError("failed-precondition", "You must provide your phone number in profile first.");
        }
        payloadData = senderPhone;
      }

      const redis = getRedis();
      const redisKey = `intercept:${targetUid}:${senderUid}`;

      await redis.set(redisKey, JSON.stringify({
        type,
        senderUid,
        data: payloadData,
        timestamp: Date.now(),
      }), { ex: INTERCEPT_TTL_SECS });

      const targetDoc = await admin.firestore().collection("users").doc(targetUid).get();
      const fcmToken = targetDoc.data()?.fcmToken;

      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "Pulse Intercept!",
              body: type === "phone"
                ? "Your match shared their contact info. Available for 10 mins."
                : "Your match sent a view-once photo to help you find them.",
            },
            data: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              type: "PULSE_INTERCEPT",
              senderId: senderUid,
              interceptType: type,
            },
            apns: {
              payload: {
                aps: {
                  contentAvailable: true,
                  sound: "default",
                  "mutable-content": 1,
                },
              },
            },
            android: { priority: "high" },
          });
        } catch (e) {
          logger.error("Failed to send intercept notification", e);
        }
      }

      logStructured({
        fn: "requestPulseIntercept",
        event: "success",
        uid: senderUid,
        targetUid,
        interceptType: type,
        durationMs: Date.now() - startedAt,
      });
      return { success: true, expiresAt: Date.now() + (INTERCEPT_TTL_SECS * 1000) };
    } catch (error) {
      logStructured({
        fn: "requestPulseIntercept",
        event: "error",
        uid: senderUid,
        error: errorMessage(error),
        durationMs: Date.now() - startedAt,
      });
      throw error;
    }
  }
);

/**
 * Retrieve a Pulse Intercept sent by a match.
 * Deletes from Redis if type is 'photo' (view-once).
 */
export const getPulseIntercept = onCall(
  { maxInstances: 100, enforceAppCheck: ENFORCE_APP_CHECK, region: "europe-west1" },
  async (request: CallableRequest) => {
    const myUid = requireAuth(request);
    await checkRateLimit(myUid, "getPulseIntercept", { maxRequests: 5, windowMs: 60000 });
    const startedAt = Date.now();
    logStructured({ fn: "getPulseIntercept", event: "entry", uid: myUid });

    try {
      const { senderUid: rawSenderUid } = request.data;
      const senderUid = assertValidDocumentId(rawSenderUid, "senderUid");

      const redis = getRedis();
      const redisKey = `intercept:${myUid}:${senderUid}`;

      const rawData = await redis.get<string>(redisKey);

      if (!rawData) {
        throw new HttpsError("not-found", "Intercept has expired or does not exist.");
      }

      const intercept = typeof rawData === "string" ? JSON.parse(rawData) : rawData;

      if (intercept.type === "photo") {
        await redis.del(redisKey);
      }

      logStructured({
        fn: "getPulseIntercept",
        event: "success",
        uid: myUid,
        interceptType: intercept.type,
        durationMs: Date.now() - startedAt,
      });
      return intercept;
    } catch (error) {
      logStructured({
        fn: "getPulseIntercept",
        event: "error",
        uid: myUid,
        error: errorMessage(error),
        durationMs: Date.now() - startedAt,
      });
      throw error;
    }
  }
);
