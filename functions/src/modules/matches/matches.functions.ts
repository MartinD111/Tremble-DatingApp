import { onCall } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { requireAuth } from "../../middleware/authGuard";
import { sendMatchNotificationEmail } from "../email/email.functions";

const db = getFirestore();

export const onWaveCreated = onDocumentCreated(
    { document: "waves/{waveId}", region: "europe-west1" },
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) return;

        const waveData = snapshot.data();
        const fromUid = waveData.fromUid;
        const toUid = waveData.toUid;

        const reciprocalQuery = await db
            .collection("waves")
            .where("fromUid", "==", toUid)
            .where("toUid", "==", fromUid)
            .limit(1)
            .get();

        if (!reciprocalQuery.empty) {
            const uids = [fromUid, toUid].sort();
            const matchId = `${uids[0]}_${uids[1]}`;
            const batch = db.batch();

            batch.set(db.collection("matches").doc(matchId), {
                userA: uids[0],
                userB: uids[1],
                userIds: uids,
                createdAt: FieldValue.serverTimestamp(),
                seenBy: [fromUid],
                lastMessage: null,
            });

            batch.delete(snapshot.ref);
            batch.delete(reciprocalQuery.docs[0].ref);

            await batch.commit();

            const [userADoc, userBDoc] = await Promise.all([
                db.collection("users").doc(fromUid).get(),
                db.collection("users").doc(toUid).get(),
            ]);

            const userAEmail = userADoc.data()?.email as string | undefined;
            const userBEmail = userBDoc.data()?.email as string | undefined;
            const userAName = userADoc.data()?.name as string | undefined;
            const userBName = userBDoc.data()?.name as string | undefined;

            if (userAEmail && userBName)
                sendMatchNotificationEmail(userAEmail, userBName).catch(() => null);
            if (userBEmail && userAName)
                sendMatchNotificationEmail(userBEmail, userAName).catch(() => null);
        }
    }
);

export const getMatches = onCall(
    { maxInstances: 100, enforceAppCheck: true, region: "europe-west1" },
    async (request) => {
        const uid = requireAuth(request);
        const userDoc = await db.collection("users").doc(uid).get();
        const blockedUsers = userDoc.data()?.blockedUserIds || [];

        const matchesQuery = await db
            .collection("matches")
            .where("userIds", "array-contains", uid)
            .orderBy("createdAt", "desc")
            .limit(50)
            .get();

        const matchedUserIds = new Set<string>();

        for (const doc of matchesQuery.docs) {
            const data = doc.data();
            const partnerId = data.userA === uid ? data.userB : data.userA;

            if (blockedUsers.includes(partnerId)) continue;
            matchedUserIds.add(partnerId);
        }

        const profiles = await Promise.all(
            Array.from(matchedUserIds).map(async (userId) => {
                const profileDoc = await db.collection("users").doc(userId).get();
                if (!profileDoc.exists) return null;
                const data = profileDoc.data()!;
                return {
                    id: userId,
                    name: data.name,
                    age: data.age,
                    photoUrls: data.photoUrls,
                    hobbies: data.hobbies,
                    lookingFor: data.lookingFor,
                };
            })
        );

        return { matches: profiles.filter(Boolean) };
    }
);