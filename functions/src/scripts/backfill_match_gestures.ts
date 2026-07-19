/**
 * One-off migration: seed the `gestures` map on legacy mutual match docs.
 *
 * Why: from Session 52, a mutual proximity/run wave seeds
 * `gestures.{uidA}=true` + `gestures.{uidB}=true` at match creation so
 * `hasMutualWave` (ADR-007 §1) is true and the pair renders in colour in the
 * matches history. Matches created BEFORE that change have no `gestures`, so a
 * genuine matched pair renders greyscale (nonMutual). This backfills them.
 *
 * Scope / safety:
 *   - Near-miss ('activity') encounters are NOT mutual matches — skipped, so
 *     the ADR-007 / LEGAL-005 premium gate is untouched.
 *   - Only docs with exactly 2 userIds and fewer than 2 gestures are written.
 *   - Idempotent: dot-path updates merge, already-mutual docs are skipped.
 *   - Never logs field values — only counts. Batches at 400 per commit.
 *   - Two modes: `--dry-run` (default) and `--apply`.
 *   - Not a deployable Cloud Function; runs as a one-off Node script.
 *
 * Usage:
 *   cd functions
 *   npm run build
 *   node ./lib/scripts/backfill_match_gestures.js --project=tremble-dev --dry-run
 *   node ./lib/scripts/backfill_match_gestures.js --project=tremble-dev --apply
 *
 *   # PROD: requires explicit --project=am---dating-app AND --i-know-this-is-prod
 *   node ./lib/scripts/backfill_match_gestures.js \
 *       --project=am---dating-app --i-know-this-is-prod --apply
 *
 * Founder rule: do NOT run --apply against am---dating-app without approval.
 */

import * as admin from "firebase-admin";

interface Args {
    project: string;
    apply: boolean;
    isProdConfirmed: boolean;
}

const PROD_PROJECT_ID = "am---dating-app";
const NEAR_MISS_TYPE = "activity";
const BATCH_LIMIT = 400;

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

/** True when a match doc is a genuine mutual match still missing its gestures. */
function needsBackfill(data: FirebaseFirestore.DocumentData): boolean {
    if (data.matchType === NEAR_MISS_TYPE) return false;
    const userIds = (data.userIds as string[] | undefined) ?? [];
    if (userIds.length !== 2) return false;
    const gestures =
        (data.gestures as Record<string, boolean> | undefined) ?? {};
    return Object.keys(gestures).length < 2;
}

async function main(): Promise<void> {
    const {project, apply, isProdConfirmed} = parseArgs();

    admin.initializeApp({projectId: project});
    const db = admin.firestore();

    const mode = apply ? "APPLY" : "DRY-RUN";
    console.log(
        `[migration] project=${project} mode=${mode} ` +
            `prodConfirmed=${isProdConfirmed}`
    );
    console.log(
        "[migration] scanning matches collection for legacy mutual matches " +
            "missing the gestures map"
    );

    const snap = await db.collection("matches").get();
    const targets = snap.docs.filter((doc) => needsBackfill(doc.data()));

    console.log(
        `[migration] ${snap.size} match docs; ${targets.length} need gestures ` +
            "seeded (excludes near-miss + already-mutual)"
    );

    if (!apply) {
        console.log(
            "[migration] DRY-RUN complete. Re-run with --apply to commit."
        );
        return;
    }

    let processed = 0;
    for (let start = 0; start < targets.length; start += BATCH_LIMIT) {
        const chunk = targets.slice(start, start + BATCH_LIMIT);
        const batch = db.batch();
        for (const doc of chunk) {
            const userIds = doc.data().userIds as string[];
            batch.update(doc.ref, {
                [`gestures.${userIds[0]}`]: true,
                [`gestures.${userIds[1]}`]: true,
            });
        }
        await batch.commit();
        processed += chunk.length;
        console.log(
            `[migration] committed batch ${processed}/${targets.length}`
        );
    }

    console.log(
        `[migration] APPLY complete. Seeded gestures on ${processed} matches.`
    );
}

main().catch((err) => {
    console.error("[migration] fatal error:", err);
    process.exit(1);
});
