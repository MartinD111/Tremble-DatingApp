/**
 * One-off migration: strip `politicalAffiliation` and
 * `politicalAffiliationPreference` from every `users/{uid}` document.
 *
 * Why: the field was removed from the product entirely (Play Store review and
 * GDPR Art. 5(1)(c) data minimization). Existing user documents may still
 * carry the field; this script clears it so the wire schema and Firestore
 * data agree.
 *
 * Safety:
 *   - Not a deployable Cloud Function. Runs as a one-off Node script.
 *   - Two modes: `--dry-run` (default) and `--apply`.
 *   - Only touches documents that actually have the field.
 *   - Never logs field VALUES — only counts and doc IDs when needed.
 *   - Batches writes at 400 per commit (safely under the 500 write cap).
 *
 * Usage:
 *   # from repo root, targeting tremble-dev
 *   cd functions
 *   npm run build
 *   node ./lib/scripts/remove_political_affiliation.js --project=tremble-dev --dry-run
 *   node ./lib/scripts/remove_political_affiliation.js --project=tremble-dev --apply
 *
 *   # PROD: requires explicit --project=am---dating-app AND --i-know-this-is-prod
 *   node ./lib/scripts/remove_political_affiliation.js \
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

const FIELDS_TO_REMOVE = [
    "politicalAffiliation",
    "politicalAffiliationPreference",
] as const;

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
        `[migration] scanning users collection for fields: ` +
            `${FIELDS_TO_REMOVE.join(", ")}`
    );

    const snap = await db.collection("users").get();
    console.log(`[migration] scanned ${snap.size} user documents`);

    // Build the list of docs that need cleanup — either field present.
    const docsToUpdate: FirebaseFirestore.QueryDocumentSnapshot[] = [];
    for (const doc of snap.docs) {
        const data = doc.data();
        const hasAny = FIELDS_TO_REMOVE.some(
            (f) => Object.prototype.hasOwnProperty.call(data, f)
        );
        if (hasAny) docsToUpdate.push(doc);
    }

    console.log(
        `[migration] ${docsToUpdate.length} documents carry one or both ` +
            "target fields"
    );

    if (!apply) {
        console.log(
            "[migration] DRY-RUN complete. Re-run with --apply to commit."
        );
        return;
    }

    let processed = 0;
    for (let start = 0; start < docsToUpdate.length; start += BATCH_LIMIT) {
        const chunk = docsToUpdate.slice(start, start + BATCH_LIMIT);
        const batch = db.batch();
        for (const doc of chunk) {
            const update: Record<string, unknown> = {};
            for (const field of FIELDS_TO_REMOVE) {
                update[field] = admin.firestore.FieldValue.delete();
            }
            batch.update(doc.ref, update);
        }
        await batch.commit();
        processed += chunk.length;
        console.log(
            `[migration] committed batch ` +
                `${processed}/${docsToUpdate.length}`
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
