/**
 * One-off migration: strip the string `"cannabis"` from every
 * `users/{uid}.nicotineUse` array.
 *
 * Why: cannabis was removed from the product entirely (founder decision,
 * independent of the pending Art. 9 vs Art. 10 GDPR legal opinion) to avoid
 * Art. 10 "criminal offense data" exposure in jurisdictions where cannabis
 * use is a criminal offense and consent is not a valid legal basis for a
 * private company. The nicotineUse Zod schema is now an enum that rejects
 * "cannabis" at the API boundary; this script cleans legacy Firestore state
 * so existing users' saves do not 400 on the new schema.
 *
 * Field shape: `nicotineUse` is a `List<String>` (multi-select). Only the
 * literal `"cannabis"` entry is removed — other selections (cigarettes,
 * vape, iqos, zyn, shisha) are preserved. Uses `FieldValue.arrayRemove` so
 * the write is idempotent and safe against concurrent updates.
 *
 * Safety:
 *   - Not a deployable Cloud Function. Runs as a one-off Node script.
 *   - Two modes: `--dry-run` (default) and `--apply`.
 *   - Only touches documents whose nicotineUse array actually contains
 *     "cannabis".
 *   - Never logs field VALUES — only counts.
 *   - Batches writes at 400 per commit (safely under the 500 write cap).
 *
 * Usage:
 *   # from repo root, targeting tremble-dev
 *   cd functions
 *   npm run build
 *   node ./lib/scripts/remove_cannabis.js --project=tremble-dev --dry-run
 *   node ./lib/scripts/remove_cannabis.js --project=tremble-dev --apply
 *
 *   # PROD: requires explicit --project=am---dating-app AND --i-know-this-is-prod
 *   node ./lib/scripts/remove_cannabis.js \
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

const TARGET_VALUE = "cannabis";
const FIELD = "nicotineUse";
const PROD_PROJECT_ID = "am---dating-app";
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
        `[migration] scanning users collection for ` +
            `${FIELD} entries equal to "${TARGET_VALUE}"`
    );

    // arrayContains lets Firestore filter server-side so we only download
    // documents that actually need touching.
    const snap = await db
        .collection("users")
        .where(FIELD, "array-contains", TARGET_VALUE)
        .get();

    console.log(
        `[migration] ${snap.size} documents carry "${TARGET_VALUE}" in ${FIELD}`
    );

    if (!apply) {
        console.log(
            "[migration] DRY-RUN complete. Re-run with --apply to commit."
        );
        return;
    }

    let processed = 0;
    const docs = snap.docs;
    for (let start = 0; start < docs.length; start += BATCH_LIMIT) {
        const chunk = docs.slice(start, start + BATCH_LIMIT);
        const batch = db.batch();
        for (const doc of chunk) {
            batch.update(doc.ref, {
                [FIELD]: admin.firestore.FieldValue.arrayRemove(TARGET_VALUE),
            });
        }
        await batch.commit();
        processed += chunk.length;
        console.log(
            `[migration] committed batch ${processed}/${docs.length}`
        );
    }

    console.log(
        `[migration] APPLY complete. Modified ${processed} documents.`
    );
}

main().catch((err) => {
    console.error("[migration] fatal error:", err);
    process.exit(1);
});
