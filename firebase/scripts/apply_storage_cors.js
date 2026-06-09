#!/usr/bin/env node
/**
 * Apply CORS to Firebase Storage buckets (required for Flutter Web image loading).
 *
 *   node scripts/apply_storage_cors.js --project tfg-sales-record
 *   node scripts/apply_storage_cors.js --project tfg-vday-record-staging
 */
const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId =
  argValue("--project") ||
  process.env.FIREBASE_PROJECT ||
  "tfg-sales-record";
const bucket = `${projectId}.firebasestorage.app`;
const corsFile = path.resolve(__dirname, "../storage-cors.json");

if (!fs.existsSync(corsFile)) {
  console.error("Missing firebase/storage-cors.json");
  process.exit(1);
}

try {
  execSync(`gsutil cors set "${corsFile}" gs://${bucket}`, {
    stdio: "inherit",
  });
  console.log(`CORS applied to gs://${bucket}`);
} catch (err) {
  console.error("");
  console.error(`Failed to apply CORS to gs://${bucket}`);
  console.error("Install Google Cloud SDK, then run:");
  console.error(`  gcloud auth login`);
  console.error(`  gsutil cors set firebase/storage-cors.json gs://${bucket}`);
  console.error("");
  process.exit(1);
}
