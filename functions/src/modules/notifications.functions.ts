import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const db = getFirestore();

function chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
        chunks.push(array.slice(i, i + size));
    }
    return chunks;
}

export const monthlyNearMissRecap = onSchedule(
    { schedule: "0 9 1 * *", region: "europe-west1" },
    async () => {
        const startedAt = Date.now();
        console.log(`[NEAR_MISS_RECAP] Scheduled function start`);

        try {
            const usersSnapshot = await db.collection("users")
                .where("isPremium", "==", false)
                .get();

            const freeUsers = usersSnapshot.docs.filter((doc) => {
                const data = doc.data();
                return data && typeof data.fcmToken === "string" && data.fcmToken.trim() !== "";
            });

            console.log(`[NEAR_MISS_RECAP] Found ${freeUsers.length} free users with FCM tokens`);

            const chunks = chunkArray(freeUsers, 10);
            const messaging = getMessaging();
            const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
            const timestampThreshold = Timestamp.fromDate(thirtyDaysAgo);

            let processedCount = 0;
            let notifiedCount = 0;

            for (const chunk of chunks) {
                await Promise.all(
                    chunk.map(async (userDoc) => {
                        const userId = userDoc.id;
                        const data = userDoc.data();
                        const fcmToken = data.fcmToken as string;

                        try {
                            const [fromCountSnap, toCountSnap] = await Promise.all([
                                db.collection("proximity_events")
                                    .where("fromUid", "==", userId)
                                    .where("timestamp", ">=", timestampThreshold)
                                    .count()
                                    .get(),
                                db.collection("proximity_events")
                                    .where("toUid", "==", userId)
                                    .where("timestamp", ">=", timestampThreshold)
                                    .count()
                                    .get(),
                            ]);

                            const totalCount = fromCountSnap.data().count + toCountSnap.data().count;

                            if (totalCount > 0) {
                                await messaging.send({
                                    token: fcmToken,
                                    data: {
                                        type: "NEAR_MISS_MONTHLY_RECAP",
                                        count: String(totalCount),
                                    },
                                    apns: {
                                        payload: {
                                            aps: {
                                                contentAvailable: true,
                                            },
                                        },
                                    },
                                    android: {
                                        priority: "high",
                                    },
                                });
                                notifiedCount++;
                            }
                        } catch (err) {
                            console.error(`[NEAR_MISS_RECAP] Error processing user ${userId}:`, err);
                        } finally {
                            processedCount++;
                        }
                    })
                );
            }

            console.log(
                `[NEAR_MISS_RECAP] Finished. Processed: ${processedCount}/${freeUsers.length}, Notified: ${notifiedCount}, Duration: ${Date.now() - startedAt}ms`
            );
        } catch (err) {
            console.error(`[NEAR_MISS_RECAP] Scheduled function fatal error:`, err);
        }
    }
);
