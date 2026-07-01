#!/usr/bin/env node
/**
 * Repair corrupted product.image URLs using staff login (no Admin SDK key needed).
 * Uses the same Firestore / Storage permissions as the Flutter web app.
 *
 *   node scripts/repair_product_images_client.js --project production --email YOU@example.com --password PASS
 *   node scripts/repair_product_images_client.js --project staging --email staging.admin@tfg-vday.test --dry-run
 *   (password: --password or STAGING_ADMIN_PASSWORD env var)
 */
const { initializeApp } = require("firebase/app");
const {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} = require("firebase/auth");
const {
  getFirestore,
  collection,
  getDocs,
  doc,
  updateDoc,
} = require("firebase/firestore");
const {
  getStorage,
  ref,
  listAll,
  getDownloadURL,
} = require("firebase/storage");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const project = argValue("--project") === "staging" ? "staging" : "production";
const email = argValue("--email");
const password = argValue("--password") || process.env.STAGING_ADMIN_PASSWORD;
const dryRun = process.argv.includes("--dry-run");

const configs = {
  production: {
    apiKey: "AIzaSyDAnFjOKq05ktKNQblIBjYamOEMXKSLeC8",
    authDomain: "tfg-sales-record.firebaseapp.com",
    projectId: "tfg-sales-record",
    storageBucket: "tfg-sales-record.firebasestorage.app",
    messagingSenderId: "326935454564",
    appId: "1:326935454564:web:23d356d5247525b9b25071",
  },
  staging: {
    apiKey: "AIzaSyDbOJepbmawzlX3_KKPn-sWPz09HQdbCMk",
    authDomain: "tfg-vday-record-staging.firebaseapp.com",
    projectId: "tfg-vday-record-staging",
    storageBucket: "tfg-vday-record-staging.firebasestorage.app",
    messagingSenderId: "972558847351",
    appId: "1:972558847351:web:3d6ebb53318abb5f9a2572",
  },
};

function isValidUrl(url) {
  return (
    typeof url === "string" &&
    url.startsWith("https://firebasestorage.googleapis.com/") &&
    url.includes("?alt=media") &&
    url.includes("&token=") &&
    url.split("/o/")[1]?.includes("%2F")
  );
}

async function freshUrlForProduct(storage, productId) {
  const folderRef = ref(storage, `product_images/${productId}`);
  const listing = await listAll(folderRef);
  if (listing.items.length === 0) {
    return null;
  }
  return getDownloadURL(listing.items[0]);
}

async function main() {
  if (!email || !password) {
    console.error(
      "Usage: node scripts/repair_product_images_client.js --project production|staging --email USER --password PASS [--dry-run]",
    );
    process.exit(1);
  }

  const config = configs[project];
  console.log(`Repair product images on ${config.projectId} as ${email}${dryRun ? " (dry-run)" : ""}`);

  const app = initializeApp(config);
  const auth = getAuth(app);
  await signInWithEmailAndPassword(auth, email, password);

  const db = getFirestore(app);
  const storage = getStorage(app);
  const snap = await getDocs(collection(db, "product"));

  let repaired = 0;
  let skipped = 0;
  let missingFile = 0;
  let failed = 0;

  for (const productDoc of snap.docs) {
    const data = productDoc.data();
    const current = data.image || data.Image || "";
    if (isValidUrl(current)) {
      skipped++;
      continue;
    }

    try {
      const fresh = await freshUrlForProduct(storage, productDoc.id);
      if (!fresh) {
        missingFile++;
        console.log(`SKIP ${productDoc.id} (${data.name || "?"}) — no file in Storage`);
        continue;
      }

      console.log(`FIX  ${productDoc.id} (${data.name || "?"})`);
      if (!dryRun) {
        await updateDoc(doc(db, "product", productDoc.id), {
          image: fresh,
          Image: fresh,
        });
      }
      repaired++;
    } catch (err) {
      failed++;
      console.log(
        `FAIL ${productDoc.id} (${data.name || "?"}) — ${err.code || err.message}`,
      );
    }
  }

  await signOut(auth);

  console.log("");
  console.log(
    `${dryRun ? "Would repair" : "Repaired"} ${repaired}, valid ${skipped}, no Storage file ${missingFile}, failed ${failed}`,
  );
}

main().catch((err) => {
  const code = err.code || "";
  if (code === "auth/invalid-credential" || code === "auth/wrong-password") {
    console.error("Login failed: check email and password.");
  } else if (code === "permission-denied") {
    console.error(
      "Permission denied: use an admin or senior_florist account for this company.",
    );
  } else {
    console.error(err.message || err);
  }
  process.exit(1);
});
