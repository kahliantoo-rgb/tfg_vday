#!/usr/bin/env node
/**
 * Backfill missing `companyRef` on tenant-scoped collections.
 *
 * Run before deploying tightened Firestore/Storage rules:
 *   npm run verify:company-ref:dry-run
 *   npm run backfill:company-ref:dry-run
 *   npm run backfill:company-ref
 *   npm run verify:company-ref -- --strict
 *
 * Usage:
 *   node scripts/backfill_company_ref.js --dry-run [--project tfg-sales-record]
 *   node scripts/backfill_company_ref.js --company-id lc3Dhfby8f35Md0E1vZC
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

const DEFAULT_COMPANY_ID = "lc3Dhfby8f35Md0E1vZC";

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
const companyId = readArg("--company-id", DEFAULT_COMPANY_ID);
const dryRun = argv.includes("--dry-run");
const batchSize = Math.min(
  500,
  Math.max(1, parseInt(readArg("--batch-size", "400"), 10) || 400),
);

let auth;
try {
  auth = initializeAdmin(projectId);
} catch (_) {
  console.error(credentialsHelp(projectId));
  process.exit(1);
}

const db = admin.firestore();
const companyRef = db.collection("Companies").doc(companyId);

async function ensureCompanyExists() {
  const snap = await companyRef.get();
  if (!snap.exists) {
    throw new Error(
      `Companies/${companyId} does not exist in ${projectId}. Pass --company-id.`,
    );
  }
  return snap.data()?.Company_name || companyId;
}

async function applyUpdates(report, buildPatch) {
  const docs = report.missing;
  if (docs.length === 0) {
    return 0;
  }

  if (dryRun) {
    console.log(`  [dry-run] would update ${docs.length} in ${report.collectionId}`);
    for (const item of docs.slice(0, 5)) {
      console.log(`    - ${item.path}`);
    }
    if (docs.length > 5) {
      console.log(`    ... and ${docs.length - 5} more`);
    }
    return docs.length;
  }

  let updated = 0;
  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = db.batch();
    const chunk = docs.slice(i, i + batchSize);
    for (const item of chunk) {
      batch.update(db.doc(item.path), buildPatch());
    }
    await batch.commit();
    updated += chunk.length;
  }
  return updated;
}

async function main() {
  console.log(`Project: ${projectId}`);
  console.log(`Company: Companies/${companyId}`);
  console.log(`Mode: ${dryRun ? "DRY RUN" : "WRITE"}`);
  console.log(`Auth: ${auth.mode}${auth.keyPath ? ` (${auth.keyPath})` : ""}`);

  const companyName = await ensureCompanyExists();
  console.log(`Company name: ${companyName}\n`);

  const reports = await scanAllCompanyRefGaps(db);
  let grandTotal = 0;

  for (const report of reports) {
    console.log(
      `${report.collectionId}: ${report.missing.length}/${report.total} missing companyRef`,
    );
    if (report.collectionId === "audit_logs") {
      grandTotal += await applyUpdates(report, () => ({
        companyRef,
        companyId,
      }));
    } else {
      grandTotal += await applyUpdates(report, () => ({
        companyRef,
      }));
    }
  }

  const summary = summarizeReports(reports);
  console.log(
    `\nDone. ${dryRun ? "Would update" : "Updated"} ${grandTotal} document(s).`,
  );
  if (summary.missingTotal > 0 && dryRun) {
    console.log(
      "Re-run without --dry-run, then: npm run verify:company-ref -- --strict",
    );
  } else if (summary.missingTotal === 0) {
    console.log("verify:company-ref --strict should pass — safe to deploy rules.");
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
