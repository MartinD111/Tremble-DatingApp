/**
 * Dev-only: send ONE proximity/wave push to a device on demand.
 *
 * Why this exists: the freeze fix (PR #60) and the tap→pill fix (PR #62) can
 * only be verified when a VISIBLE push lands while the app is foregrounded
 * (willPresentNotification → freeze path) or is tapped from background/killed
 * (onMessageOpenedApp / getInitialMessage → wave-pill path). Waiting for the
 * scheduled scanProximityPairs is unreliable: the 10-min global throttle and
 * per-pair cooldown mean the send almost never coincides with the app being
 * on-screen (2026-07-17: every foregrounded scan logged pairsNotified:0, and
 * the one real send at 22:32 hit locked phones). This fires the exact same
 * FCM payload directly, with no scan and no cooldown.
 *
 * The payloads mirror production byte-for-byte:
 *   - CROSSING_PATHS  → proximity.functions.ts sendCrossingPaths (~910)
 *   - INCOMING_WAVE   → matches.functions.ts onWaveCreated (~704)
 * Both reuse apnsExpirationHeaders / NOTIFICATION_TTL_MILLIS from core so they
 * cannot drift from the real senders.
 *
 * Test matrix (build 25 freeze fix / build 26 tap→pill fix):
 *   (a) app FOREGROUND + run this  → must present a banner/pill, NOT freeze.
 *   (b) app BACKGROUND + run, then tap → must open app + WavePill.
 *   (c) app KILLED + run, then tap → must cold-launch + WavePill (polls for
 *       auth/overlay readiness now; watch Sentry for "wave pill dropped: …").
 *
 * Auth: uses Application Default Credentials, same as the other scripts here —
 * run `firebase login` / `gcloud auth application-default login` first, or set
 * GOOGLE_APPLICATION_CREDENTIALS to a service-account key.
 *
 * Usage:
 *   cd functions && npm run build
 *
 *   # by recipient uid (reads users/{uid}.fcmToken)
 *   node ./lib/scripts/send_test_push.js --project=tremble-dev --uid=<uid>
 *
 *   # by raw token, INCOMING_WAVE variant, custom sender identity
 *   node ./lib/scripts/send_test_push.js --project=tremble-dev \
 *       --token=<fcmToken> --type=INCOMING_WAVE \
 *       --sender-name="Ana" --sender-age=27 --sender-photo=https://…/a.jpg
 *
 *   # silent (data-only) variant — no banner, exercises the background wake
 *   node ./lib/scripts/send_test_push.js --project=tremble-dev --uid=<uid> --silent
 *
 *   # PROD requires the explicit guard (device verification lane)
 *   node ./lib/scripts/send_test_push.js \
 *       --project=am---dating-app --i-know-this-is-prod --uid=<uid>
 */

import * as admin from "firebase-admin";
import {
    apnsExpirationHeaders,
    NOTIFICATION_TTL_MILLIS,
} from "../core/notification_expiry";

const PROD_PROJECT_ID = "am---dating-app";

type PushType = "CROSSING_PATHS" | "INCOMING_WAVE";

interface Args {
    project: string;
    uid: string;
    token: string;
    type: PushType;
    senderId: string;
    senderName: string;
    senderAge: string;
    senderPhoto: string;
    silent: boolean;
    isProdConfirmed: boolean;
}

function parseArgs(): Args {
    const args = process.argv.slice(2);
    let project = "";
    let uid = "";
    let token = "";
    let type: PushType = "CROSSING_PATHS";
    let senderId = "test-sender-uid";
    let senderName = "Test Sender";
    let senderAge = "28";
    let senderPhoto = "";
    let silent = false;
    let isProdConfirmed = false;

    for (const raw of args) {
        if (raw.startsWith("--project=")) project = raw.slice("--project=".length);
        else if (raw.startsWith("--uid=")) uid = raw.slice("--uid=".length);
        else if (raw.startsWith("--token=")) token = raw.slice("--token=".length);
        else if (raw.startsWith("--type=")) {
            const value = raw.slice("--type=".length);
            if (value !== "CROSSING_PATHS" && value !== "INCOMING_WAVE") {
                console.error(
                    "ERROR: --type must be CROSSING_PATHS or INCOMING_WAVE.",
                );
                process.exit(2);
            }
            type = value;
        } else if (raw.startsWith("--sender-id=")) {
            senderId = raw.slice("--sender-id=".length);
        } else if (raw.startsWith("--sender-name=")) {
            senderName = raw.slice("--sender-name=".length);
        } else if (raw.startsWith("--sender-age=")) {
            senderAge = raw.slice("--sender-age=".length);
        } else if (raw.startsWith("--sender-photo=")) {
            senderPhoto = raw.slice("--sender-photo=".length);
        } else if (raw === "--silent") {
            silent = true;
        } else if (raw === "--i-know-this-is-prod") {
            isProdConfirmed = true;
        }
    }

    if (!project) {
        console.error(
            "ERROR: --project=<projectId> is required (e.g. --project=tremble-dev).",
        );
        process.exit(2);
    }
    if (!uid && !token) {
        console.error("ERROR: one of --uid=<uid> or --token=<fcmToken> is required.");
        process.exit(2);
    }
    if (project === PROD_PROJECT_ID && !isProdConfirmed) {
        console.error(
            `ERROR: refusing to send to ${PROD_PROJECT_ID} without ` +
                "--i-know-this-is-prod.",
        );
        process.exit(2);
    }

    return {
        project,
        uid,
        token,
        type,
        senderId,
        senderName,
        senderAge,
        senderPhoto,
        silent,
        isProdConfirmed,
    };
}

/** Resolve the delivery token: explicit --token wins, else users/{uid}.fcmToken. */
async function resolveToken(
    db: admin.firestore.Firestore,
    args: Args,
): Promise<string> {
    if (args.token) return args.token;

    const snap = await db.collection("users").doc(args.uid).get();
    if (!snap.exists) {
        console.error(`ERROR: users/${args.uid} does not exist.`);
        process.exit(1);
    }
    const fcmToken = snap.data()?.fcmToken as string | undefined;
    if (!fcmToken) {
        console.error(
            `ERROR: users/${args.uid} has no fcmToken. Open the app on the ` +
                "device and sign in so NotificationService.saveToken() runs.",
        );
        process.exit(1);
    }
    return fcmToken;
}

/** Build the exact production FCM payload for the requested type. */
function buildMessage(token: string, args: Args): admin.messaging.Message {
    const data: Record<string, string> = {
        type: args.type,
        senderId: args.senderId,
        senderName: args.senderName,
        senderAge: args.senderAge,
        senderPhotoUrl: args.senderPhoto,
    };
    // CROSSING_PATHS carries fromUid; INCOMING_WAVE carries waveId. Match both.
    if (args.type === "CROSSING_PATHS") {
        data.fromUid = args.senderId;
    } else {
        data.waveId = `test-wave-${Date.now()}`;
    }

    if (args.silent) {
        return {
            token,
            data,
            apns: {
                headers: apnsExpirationHeaders(),
                payload: { aps: { contentAvailable: true } },
            },
            android: { priority: "high", ttl: NOTIFICATION_TTL_MILLIS },
        };
    }

    const isWave = args.type === "INCOMING_WAVE";
    const title = isWave
        ? `${args.senderName} waved`
        : `${args.senderName} is nearby`;
    const body = isWave ? "Wave back?" : "Your paths just crossed.";

    return {
        token,
        notification: {
            title,
            body,
            imageUrl: isWave && args.senderPhoto ? args.senderPhoto : undefined,
        },
        data,
        apns: {
            headers: apnsExpirationHeaders(),
            payload: {
                aps: {
                    contentAvailable: true,
                    category: isWave ? "WAVE_CATEGORY" : "NEARBY_CATEGORY",
                    sound: "default",
                    ...(isWave ? { "mutable-content": 1 } : {}),
                },
            },
        },
        android: {
            priority: "high",
            ttl: NOTIFICATION_TTL_MILLIS,
            notification: {
                channelId: isWave ? "tremble_wave" : "tremble_proximity",
                sound: "default",
            },
        },
    };
}

async function main(): Promise<void> {
    const args = parseArgs();

    admin.initializeApp({ projectId: args.project });
    const db = admin.firestore();

    const token = await resolveToken(db, args);
    const message = buildMessage(token, args);

    console.log(
        `[send_test_push] project=${args.project} type=${args.type} ` +
            `silent=${args.silent} target=${args.uid || "(raw token)"} ` +
            `token=…${token.slice(-8)}`,
    );

    const messageId = await admin.messaging().send(message);
    console.log(`[send_test_push] sent OK. FCM messageId=${messageId}`);
    console.log(
        "[send_test_push] Now check the device: foreground=banner (no freeze), " +
            "background/killed tap=WavePill. Watch Sentry for " +
            '"wave pill dropped: …" if the pill does not appear.',
    );
}

main().catch((err) => {
    console.error("[send_test_push] fatal error:", err);
    process.exit(1);
});
