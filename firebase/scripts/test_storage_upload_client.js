#!/usr/bin/env node
/**
 * Test Storage upload with Firebase client SDK (same path as the Flutter web app).
 *
 *   node scripts/test_storage_upload_client.js --email you@example.com --password secret
 *   node scripts/test_storage_upload_client.js --project staging --email staging.admin@tfg-vday.test
 *   (password: --password or STAGING_ADMIN_PASSWORD env var)
 */
const { initializeApp } = require("firebase/app");
const {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} = require("firebase/auth");
const {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL,
} = require("firebase/storage");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const project = argValue("--project") === "staging" ? "staging" : "production";
const email = argValue("--email");
const password = argValue("--password") || process.env.STAGING_ADMIN_PASSWORD;

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

async function tryBucket(config, bucketName) {
  const app = initializeApp({ ...config, storageBucket: bucketName }, bucketName);
  const auth = getAuth(app);
  await signInWithEmailAndPassword(auth, email, password);
  const storage = getStorage(app);
  const path = `product_images/_diag/${Date.now()}.txt`;
  const storageRef = ref(storage, path);
  try {
    await uploadBytes(storageRef, Buffer.from("diag"), {
      contentType: "text/plain",
    });
    const url = await getDownloadURL(storageRef);
    console.log(`OK bucket=${bucketName} url=${url}`);
    await signOut(auth);
    return true;
  } catch (e) {
    console.error(
      `FAIL bucket=${bucketName} code=${e.code || "unknown"} message=${e.message}`,
    );
    await signOut(auth);
    return false;
  }
}

async function main() {
  if (!email || !password) {
    console.error("Usage: --email USER --password PASS [--project staging|production]");
    process.exit(1);
  }

  const config = configs[project];
  console.log(`Testing ${project} (${config.projectId}) as ${email}`);

  const buckets = [
    config.storageBucket,
    `${config.projectId}.appspot.com`,
  ];

  for (const bucket of buckets) {
    await tryBucket(config, bucket);
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
