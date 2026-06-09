#!/usr/bin/env node
/**
 * Sample product image fields in Firestore (diagnose missing photos).
 *
 *   node scripts/sample_product_images.js --project tfg-sales-record --limit 20
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
const limit = parseInt(argValue("--limit") || "15", 10);

function describeImageField(value) {
  if (value == null) return "null";
  if (typeof value === "string") {
    const s = value.trim();
    if (!s) return "empty string";
    if (s.startsWith("http")) return `url (${s.slice(0, 72)}…)`;
    if (s.startsWith("gs://")) return `gs (${s.slice(0, 72)}…)`;
    return `path (${s.slice(0, 72)}…)`;
  }
  if (typeof value === "object") {
    const keys = Object.keys(value);
    return `map keys=[${keys.join(", ")}]`;
  }
  return typeof value;
}

try {
  initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

async function main() {
  const snap = await admin
    .firestore()
    .collection("product")
    .limit(limit)
    .get();

  if (snap.empty) {
    console.log(`No products in ${projectId}.`);
    return;
  }

  let withImage = 0;
  console.log(`Sample ${snap.size} products from ${projectId}:\n`);
  for (const doc of snap.docs) {
    const data = doc.data();
    const image = data.image;
    const Image = data.Image;
    const hasAny =
      (typeof image === "string" && image.trim()) ||
      (typeof Image === "string" && Image.trim()) ||
      (Image && typeof Image === "object");
    if (hasAny) withImage++;

    console.log(`${doc.id} | ${data.name || "(no name)"}`);
    console.log(`  image:  ${describeImageField(image)}`);
    console.log(`  Image:  ${describeImageField(Image)}`);
    console.log("");
  }

  console.log(
    `Summary: ${withImage}/${snap.size} docs have image/Image set.`,
  );
  if (withImage === 0) {
    console.log(
      "\nNo image URLs in Firestore — UI will show placeholders until photos are uploaded.",
    );
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
