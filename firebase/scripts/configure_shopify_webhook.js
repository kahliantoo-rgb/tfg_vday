#!/usr/bin/env node
/**
 * Configure Shopify Cloud Function for staging or production.
 *
 * Staging company id (default): staging_company
 *   Created by: npm run bootstrap:staging
 *
 * Usage:
 *   node scripts/configure_shopify_webhook.js --env staging
 *   node scripts/configure_shopify_webhook.js --env staging --secret "shpss_..."
 *   node scripts/configure_shopify_webhook.js --env staging --verify-only
 *   node scripts/configure_shopify_webhook.js --env production --company-id lc3Dhfby8f35Md0E1vZC --secret "shpss_..."
 */
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const ROOT = path.resolve(__dirname, "..");
const STAGING_CONFIG_PATH = path.join(ROOT, "config", "shopify.staging.json");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

function loadStagingDefaults() {
  if (!fs.existsSync(STAGING_CONFIG_PATH)) {
    return {
      project: "tfg-vday-record-staging",
      firebase_alias: "staging",
      default_company_id: "staging_company",
    };
  }
  return JSON.parse(fs.readFileSync(STAGING_CONFIG_PATH, "utf8"));
}

async function verifyCompanyExists(projectId, companyId) {
  let admin;
  try {
    admin = require("firebase-admin");
  } catch {
    console.warn("firebase-admin not installed at firebase/ root — skip company verify");
    return null;
  }

  const { initializeAdmin } = require("./admin_init");
  let authCtx;
  try {
    authCtx = initializeAdmin(projectId);
  } catch (err) {
    console.warn("No service account — skip company verify.");
    console.warn("  Set GOOGLE_APPLICATION_CREDENTIALS to verify Companies doc.");
    return null;
  }

  const db = admin.firestore();
  const ref = db.collection("Companies").doc(companyId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new Error(
      `Companies/${companyId} not found in ${projectId}. ` +
        (projectId.includes("staging")
          ? "Run: npm run bootstrap:staging"
          : "Pass --company-id with a valid Companies document id."),
    );
  }
  return snap.data();
}

function runFirebaseConfigSet(firebaseAlias, companyId, secret) {
  const parts = [`shopify.default_company_id="${companyId}"`];
  if (secret) {
    parts.push(`shopify.webhook_secret="${secret}"`);
  }
  const cmd = `firebase functions:config:set ${parts.join(" ")} --project ${firebaseAlias}`;
  console.log(`Running: ${cmd.replace(secret || "", secret ? "***" : "")}`);
  execSync(cmd, { cwd: ROOT, stdio: "inherit", shell: true });
}

async function main() {
  const env = (argValue("--env") || "staging").toLowerCase();
  const verifyOnly = process.argv.includes("--verify-only");
  const secret = argValue("--secret");
  const stagingDefaults = loadStagingDefaults();

  let firebaseAlias;
  let projectId;
  let companyId;

  if (env === "staging") {
    firebaseAlias = stagingDefaults.firebase_alias || "staging";
    projectId = stagingDefaults.project || "tfg-vday-record-staging";
    companyId = argValue("--company-id") || stagingDefaults.default_company_id;
  } else if (env === "production") {
    firebaseAlias = "production";
    projectId = "tfg-sales-record";
    companyId = argValue("--company-id");
    if (!companyId) {
      console.error("Production requires --company-id (Firestore Companies doc id).");
      process.exit(1);
    }
  } else {
    console.error('Use --env staging or --env production');
    process.exit(1);
  }

  console.log(`Shopify webhook config (${env})`);
  console.log(`  Firebase alias: ${firebaseAlias}`);
  console.log(`  Project:        ${projectId}`);
  console.log(`  company id:     ${companyId}`);

  const companyData = await verifyCompanyExists(projectId, companyId);
  if (companyData) {
    const name = companyData.Company_name || companyData.company_name || "(unnamed)";
    console.log(`  company name:   ${name}`);
    console.log("  Companies doc:  OK");
  }

  if (verifyOnly) {
    console.log("\nVerify-only — no config written.");
    return;
  }

  if (!secret) {
    console.warn(
      "\nNo --secret provided. Only shopify.default_company_id will be set.",
    );
    console.warn(
      "Add webhook secret later:\n" +
        `  node scripts/configure_shopify_webhook.js --env ${env} --secret "shpss_..."`,
    );
  }

  runFirebaseConfigSet(firebaseAlias, companyId, secret);
  console.log("\nDone. Deploy function:");
  console.log(`  npm run deploy:functions:${env === "staging" ? "staging" : "production"}`);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
