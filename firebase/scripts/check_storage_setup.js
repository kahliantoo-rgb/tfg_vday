#!/usr/bin/env node
/**
 * Verify Firebase Storage default bucket exists (required for photo uploads).
 *
 *   node scripts/check_storage_setup.js --project tfg-vday-record-staging
 */
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
} = require("./admin_init");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId =
  argValue("--project") || process.env.FIREBASE_PROJECT || "tfg-vday-record-staging";

try {
  initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

async function main() {
  const bucketName = `${projectId}.firebasestorage.app`;
  const bucket = admin.storage().bucket(bucketName);
  const [exists] = await bucket.exists();

  if (exists) {
    console.log(`Storage OK: gs://${bucketName}`);
    return;
  }

  console.error("");
  console.error(`Storage NOT set up for project "${projectId}".`);
  console.error("Photo uploads will fail until Storage is enabled.");
  console.error("");
  console.error("Fix:");
  console.error(
    `  1. Open https://console.firebase.google.com/project/${projectId}/storage`,
  );
  console.error("  2. Click \"Get started\" and accept defaults");
  console.error("  3. Deploy rules:");
  console.error("       npm run deploy:storage:staging");
  console.error("");
  process.exit(1);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
