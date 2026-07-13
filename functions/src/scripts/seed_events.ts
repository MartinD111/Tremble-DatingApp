/**
 * One-off seed script: create the initial set of Tremble Event Mode venues in
 * the `events` Firestore collection.
 *
 * Why: PLAN_03_APP_CODE.md KORAK 3.5 moves event locations out of a hardcoded
 * `_eventLocations` map in `tremble_map_screen.dart` (dev-only) into
 * Firestore documents so pins appear in production without a code push
 * (Apple 2.1 App Completeness risk). This script seeds the three Ljubljana
 * launch venues previously hardcoded on the client.
 *
 * Document shape written here matches what the client (TrembleEvent.fromFirestore)
 * and CF (onEventModeActivate) both expect after the KORAK 3.5 migration:
 *   {
 *     name: string,
 *     active: boolean,               // filter on read
 *     location: GeoPoint,            // canonical shape post-KORAK 3.5
 *     radiusMeters: number,          // geofence radius for enter/exit + CF gate
 *     locationLabel: string,         // human-facing venue label (localized copy stays on client)
 *     startsAt: Timestamp,           // gate: CF rejects activation before this
 *     endsAt: Timestamp,             // gate: read query filters by endsAt > now
 *     createdAt: Timestamp,          // audit trail
 *     seededBy: string,              // script identifier — never a user UID
 *   }
 *
 * Safety:
 *   - Not a deployable Cloud Function. Runs as a one-off Node script.
 *   - Two modes: `--dry-run` (default) and `--apply`.
 *   - Refuses to touch prod without `--i-know-this-is-prod`, matching the
 *     existing migration scripts (remove_cannabis.ts, remove_political_affiliation.ts).
 *   - Skips any document whose ID already exists — never overwrites live data.
 *     Re-running is a safe no-op on already-seeded envs.
 *   - Never logs coordinates in a way that would leak private venue data
 *     (public venue names only).
 *
 * Usage:
 *   # from repo root, targeting tremble-dev
 *   cd functions
 *   npm run build
 *   node ./lib/scripts/seed_events.js --project=tremble-dev --dry-run
 *   node ./lib/scripts/seed_events.js --project=tremble-dev --apply
 *
 *   # PROD: requires explicit --project=am---dating-app AND --i-know-this-is-prod
 *   node ./lib/scripts/seed_events.js \
 *       --project=am---dating-app --i-know-this-is-prod --apply
 *
 * Founder rule: do NOT run against am---dating-app without explicit approval.
 */

import * as admin from "firebase-admin";

interface Args {
    project: string;
    apply: boolean;
    isProdConfirmed: boolean;
}

interface SeedEvent {
    id: string;
    name: string;
    locationLabel: string;
    lat: number;
    lng: number;
    radiusMeters: number;
    /** Hours from `now` at seed time — dev-friendly so seeded envs stay live for testing. */
    startsInHours: number;
    endsInHours: number;
}

const PROD_PROJECT_ID = "am---dating-app";
const SCRIPT_ID = "seed_events.ts";

/**
 * Canonical Ljubljana launch venues. Coordinates match the retired
 * `_eventLocations` map in `tremble_map_screen.dart` to keep the launch UX
 * identical after the Firestore migration.
 *
 * Times: seeded live (starts 15 min ago, ends 6 h from now) so testers see
 * pins immediately after seeding a fresh dev project.
 */
const EVENTS: readonly SeedEvent[] = [
    {
        id: "club_monokel",
        name: "Klub Monokel",
        locationLabel: "Metelkova, Ljubljana",
        lat: 46.0514,
        lng: 14.5058,
        radiusMeters: 150,
        startsInHours: -0.25,
        endsInHours: 6,
    },
    {
        id: "labaratorij",
        name: "Laboratorij",
        locationLabel: "Metelkova, Ljubljana",
        lat: 46.054,
        lng: 14.512,
        radiusMeters: 150,
        startsInHours: -0.25,
        endsInHours: 6,
    },
    {
        id: "metelkova",
        name: "Metelkova mesto",
        locationLabel: "Metelkova, Ljubljana",
        lat: 46.056,
        lng: 14.5097,
        radiusMeters: 250,
        startsInHours: -0.25,
        endsInHours: 6,
    },
];

function parseArgs(): Args {
    const args = process.argv.slice(2);
    let project = "";
    let apply = false;
    let isProdConfirmed = false;

    for (const raw of args) {
        if (raw.startsWith("--project=")) {
            project = raw.slice("--project=".length);
        } else if (raw === "--apply") {
            apply = true;
        } else if (raw === "--dry-run") {
            apply = false;
        } else if (raw === "--i-know-this-is-prod") {
            isProdConfirmed = true;
        }
    }

    if (!project) {
        console.error(
            "ERROR: --project=<projectId> is required " +
                "(e.g. --project=tremble-dev)."
        );
        process.exit(2);
    }

    if (project === PROD_PROJECT_ID && !isProdConfirmed) {
        console.error(
            `ERROR: refusing to touch ${PROD_PROJECT_ID} without ` +
                "--i-know-this-is-prod. Founder approval required."
        );
        process.exit(2);
    }

    return {project, apply, isProdConfirmed};
}

function hoursFromNow(hours: number): admin.firestore.Timestamp {
    const millis = Date.now() + hours * 60 * 60 * 1000;
    return admin.firestore.Timestamp.fromMillis(millis);
}

async function main(): Promise<void> {
    const {project, apply, isProdConfirmed} = parseArgs();

    admin.initializeApp({projectId: project});
    const db = admin.firestore();

    const mode = apply ? "APPLY" : "DRY-RUN";
    console.log(
        `[seed] project=${project} mode=${mode} ` +
            `prodConfirmed=${isProdConfirmed}`
    );
    console.log(
        `[seed] preparing ${EVENTS.length} event documents in 'events'`
    );

    const now = admin.firestore.Timestamp.now();
    let created = 0;
    let skipped = 0;

    for (const event of EVENTS) {
        const ref = db.collection("events").doc(event.id);
        const snap = await ref.get();
        if (snap.exists) {
            skipped++;
            console.log(`[seed] skip existing: ${event.id} (${event.name})`);
            continue;
        }

        console.log(
            `[seed] would create: ${event.id} (${event.name}, ` +
                `radius ${event.radiusMeters}m)`
        );

        if (!apply) continue;

        await ref.set({
            name: event.name,
            active: true,
            location: new admin.firestore.GeoPoint(event.lat, event.lng),
            radiusMeters: event.radiusMeters,
            locationLabel: event.locationLabel,
            startsAt: hoursFromNow(event.startsInHours),
            endsAt: hoursFromNow(event.endsInHours),
            createdAt: now,
            seededBy: SCRIPT_ID,
        });
        created++;
    }

    console.log(
        `[seed] complete — created=${created} skipped=${skipped} ` +
            `mode=${mode}`
    );
    if (!apply) {
        console.log("[seed] DRY-RUN — re-run with --apply to commit.");
    }
}

main().catch((err) => {
    console.error("[seed] fatal error:", err);
    process.exit(1);
});
