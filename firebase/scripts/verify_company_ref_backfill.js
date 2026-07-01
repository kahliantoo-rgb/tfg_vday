#!/usr/bin/env node
/**
 * Verify tenant docs have companyRef before deploying tightened Firestore rules.
 *
 * Usage:
 *   node scripts/verify_company_ref_backfill.js --strict
 *   node scripts/verify_company_ref_backfill.js --project tfg-vday-record-staging --company-id staging_company --strict
 *   node scripts/verify_company_ref_backfill.js --json
 *
 * Exit codes:
 *   0 — no missing companyRef (safe to deploy tightened rules)
 *   1 — missing docs found (--strict) or credentials error
 *   2 — company doc missing
 */
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
} = require("./admin_init");
const {
  scanAllCompanyRefGaps,
  summarizeReports,
} = require("./company_ref_scan");

const argv = process.argv.slice(2);

function readArg(name, fallback) {
  const index = argv.indexOf(name);
  if (index === -1 || index + 1 >= argv.length) {
    return fallback;
  }
  return argv[index + 1];
}

const projectId =
  readArg("--project", process.env.FIREBASE_PROJECT) || "tfg-sales-record";
const companyId = readArg("--company-id", null);
const strict = argv.includes("--strict");
const asJson = argv.includes("--json");

let auth;
try {
  auth = initializeAdmin(projectId);
} catch (_) {
  console.error(credentialsHelp(projectId));
  process.exit(1);
}

const db = admin.firestore();

async function resolveCompanyId() {
  if (companyId) {
    return companyId;
  }
  const snap = await db
    .collection("Companies")
    .where("is_active", "==", true)
    .limit(1)
    .get();
  if (!snap.empty) {
    return snap.docs[0].id;
  }
  return "lc3Dhfby8f35Md0E1vZC";
}

async function main() {
  const resolvedCompanyId = await resolveCompanyId();
  const companySnap = await db
    .collection("Companies")
    .doc(resolvedCompanyId)
    .get();
  if (!companySnap.exists) {
    const message = `Companies/${resolvedCompanyId} not found in ${projectId}`;
    if (asJson) {
      console.log(JSON.stringify({ ok: false, error: message }, null, 2));
    } else {
      console.error(message);
    }
    process.exit(2);
  }

  const reports = await scanAllCompanyRefGaps(db);
  const summary = summarizeReports(reports);

  const payload = {
    ok: summary.missingTotal === 0,
    projectId,
    companyId: resolvedCompanyId,
    auth: auth.mode,
    missingTotal: summary.missingTotal,
    missingByCollection: summary.missingByCollection,
    hint:
      summary.missingTotal > 0
        ? "Run: npm run backfill:company-ref:dry-run then npm run backfill:company-ref"
        : "Ready for tightened tenant rules deploy",
  };

  if (asJson) {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    console.log(`Project: ${projectId}`);
    console.log(`Company: Companies/${resolvedCompanyId}`);
    console.log(`Missing companyRef/companyId: ${summary.missingTotal}`);
    for (const row of summary.missingByCollection) {
      console.log(
        `  ${row.collection}: ${row.count}/${row.total} missing (e.g. ${row.samplePaths.join(", ")})`,
      );
    }
    console.log(payload.hint);
  }

  if (strict && summary.missingTotal > 0) {
    process.exit(1);
  }
}

main().catch((err) => {
  if (isCredentialsError(err)) {
    console.error(credentialsHelp(projectId));
  } else {
    console.error(err);
  }
  process.exit(1);
});
