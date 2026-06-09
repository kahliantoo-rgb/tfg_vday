#!/usr/bin/env node
/**
 * Repair corrupted product.image URLs by reading Storage folder
 * `product_images/{productId}/` and rewriting Firestore with a fresh download URL.
 *
 *   node scripts/repair_product_images.js --project tfg-sales-record
 *   node scripts/repair_product_images.js --project tfg-sales-record --dry-run
 */
const admin = require("firebase-admin");
const { initializeAdmin, credentialsHelp } = require("./admin_init");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId =
  argValue("--project") ||
  process.env.FIREBASE_PROJECT ||
  "tfg-sales-record";
const dryRun = process.argv.includes("--dry-run");

function isValidUrl(url) {
  return (
    typeof url === "string" &&
    url.startsWith("https://firebasestorage.googleapis.com/") &&
    url.includes("?alt=media") &&
    url.includes("&token=") &&
    url.includes("%2F")
  );
}

try {
  initializeAdmin(projectId);
} catch (err) {
  console.error(err.message || err);
  console.error(credentialsHelp(projectId));
  process.exit(1);
}

async function freshUrlForProduct(productId) {
  const bucket = admin.storage().bucket(`${projectId}.firebasestorage.app`);
  const [files] = await bucket.getFiles({
    prefix: `product_images/${productId}/`,
    maxResults: 5,
  });
  const imageFile = files.find((f) => !f.name.endsWith("/"));
  if (!imageFile) {
    return null;
  }
  const [signed] = await imageFile.getSignedUrl({
    action: "read",
    expires: Date.now() + 60 * 60 * 1000,
  });
  // Prefer Firebase download-token style URL if metadata has token
  const [metadata] = await imageFile.getMetadata();
  const token = metadata.metadata?.firebaseStorageDownloadTokens;
  if (token) {
    const encoded = encodeURIComponent(imageFile.name);
    return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encoded}?alt=media&token=${token.split(",")[0]}`;
  }
  return signed;
}

async function main() {
  const snap = await admin.firestore().collection("product").get();
  let repaired = 0;
  let skipped = 0;
  let missingFile = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const current = data.image || data.Image || "";
    if (isValidUrl(current)) {
      skipped++;
      continue;
    }

    const fresh = await freshUrlForProduct(doc.id);
    if (!fresh) {
      missingFile++;
      console.log(`SKIP ${doc.id} (${data.name || "?"}) — no file in Storage`);
      continue;
    }

    console.log(`FIX  ${doc.id} (${data.name || "?"})`);
    if (!dryRun) {
      await doc.ref.update({ image: fresh, Image: fresh });
    }
    repaired++;
  }

  console.log("");
  console.log(
    `${dryRun ? "Would repair" : "Repaired"} ${repaired}, valid ${skipped}, no Storage file ${missingFile}`,
  );
}

main().catch((err) => {
  const msg = err.message || String(err);
  if (msg.includes("PERMISSION_DENIED") || err.code === 7) {
    console.error("PERMISSION_DENIED: Admin key cannot access this project.");
    console.error(credentialsHelp(projectId));
    console.error("");
    console.error("Use staff login instead:");
    console.error(
      "  npm run repair:product-images:client -- --email YOUR@email.com --password PASS",
    );
  } else {
    console.error(msg);
  }
  process.exit(1);
});
