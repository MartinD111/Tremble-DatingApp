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
import { getRedis } from "../../core/redis";
import { requireAuth } from "../../middleware/authGuard";
import { logger } from "firebase-functions";

const INTERCEPT_TTL_SECS = 600; // 10 minutes

/**
 * Request a Pulse Intercept (Phone or Photo).
 * Triggers a push notification to the recipient.
 */
export const requestPulseIntercept = onCall(async (request: CallableRequest) => {
  const senderUid = requireAuth(request);
  const { targetUid, type, data } = request.data;

  if (!targetUid || !type) {
    throw new HttpsError("invalid-argument", "Target UID and type are required.");
  }

  if (type !== "phone" && type !== "photo") {
    throw new HttpsError("invalid-argument", "Invalid intercept type.");
  }

  // 1. Verify Match exists and is active
  const matchId = [senderUid, targetUid].sort().join("_");
  const matchDoc = await admin.firestore().collection("matches").doc(matchId).get();

  if (!matchDoc.exists) {
    throw new HttpsError("permission-denied", "No active match found between users.");
  }

  const matchData = matchDoc.data();
  // Ensure the match hasn't expired or been closed
  if (matchData?.status === "expired" || matchData?.status === "closed") {
    throw new HttpsError("permission-denied", "Match has expired or is closed.");
  }

  // 2. Fetch sender data if phone
  let payloadData = data;
  if (type === "phone") {
    const senderDoc = await admin.firestore().collection("users").doc(senderUid).get();
    const senderPhone = senderDoc.data()?.phoneNumber;
    if (!senderPhone) {
      throw new HttpsError("failed-precondition", "You must provide your phone number in profile first.");
    }
    payloadData = senderPhone;
  }

  // 3. Store in Redis (Ephemeral)
  const redis = getRedis();
  const redisKey = `intercept:${targetUid}:${senderUid}`;
  
  await redis.set(redisKey, JSON.stringify({
    type,
    senderUid,
    data: payloadData,
    timestamp: Date.now(),
  }), { ex: INTERCEPT_TTL_SECS });

  // 4. Send Push Notification to target
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
      });
    } catch (e) {
      logger.error("Failed to send intercept notification", e);
    }
  }

  return { success: true, expiresAt: Date.now() + (INTERCEPT_TTL_SECS * 1000) };
});

/**
 * Retrieve a Pulse Intercept sent by a match.
 * Deletes from Redis if type is 'photo' (view-once).
 */
export const getPulseIntercept = onCall(async (request: CallableRequest) => {
  const myUid = requireAuth(request);
  const { senderUid } = request.data;

  if (!senderUid) {
    throw new HttpsError("invalid-argument", "Sender UID is required.");
  }

  const redis = getRedis();
  const redisKey = `intercept:${myUid}:${senderUid}`;
  
  const rawData = await redis.get<string>(redisKey);
  
  if (!rawData) {
    throw new HttpsError("not-found", "Intercept has expired or does not exist.");
  }

  const intercept = typeof rawData === 'string' ? JSON.parse(rawData) : rawData;

  // View-once enforcement for photos
  if (intercept.type === "photo") {
    await redis.del(redisKey);
  }

  return intercept;
});
