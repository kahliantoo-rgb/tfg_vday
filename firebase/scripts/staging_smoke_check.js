#!/usr/bin/env node
/**
 * Post-deploy smoke checks against staging Firebase + Hosting.
 *
 *   set STAGING_ADMIN_PASSWORD=<from team vault>
 *   node scripts/staging_smoke_check.js
 *   node scripts/staging_smoke_check.js --json
 *
 * Requires network + valid staging staff credentials.
 */
const { initializeApp } = require("firebase/app");
const {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} = require("firebase/auth");
const { getFirestore, doc, getDoc, collection, query, where, limit, getDocs } =
  require("firebase/firestore");
const {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL,
  deleteObject,
} = require("firebase/storage");

const STAGING_WEB_URL = "https://tfg-vday-record-staging.web.app";
const ADMIN_EMAIL = "staging.admin@tfg-vday.test";
const COMPANY_ID = "staging_company";

const firebaseConfig = {
  apiKey: "AIzaSyDbOJepbmawzlX3_KKPn-sWPz09HQdbCMk",
  authDomain: "tfg-vday-record-staging.firebaseapp.com",
  projectId: "tfg-vday-record-staging",
  storageBucket: "tfg-vday-record-staging.firebasestorage.app",
  messagingSenderId: "972558847351",
  appId: "1:972558847351:web:3d6ebb53318abb5f9a2572",
};

const asJson = process.argv.includes("--json");
const password = process.env.STAGING_ADMIN_PASSWORD;

async function checkHosting() {
  const response = await fetch(STAGING_WEB_URL, { redirect: "follow" });
  return {
    name: "hosting",
    ok: response.ok,
    status: response.status,
    url: STAGING_WEB_URL,
  };
}

async function checkFirebaseAuthAndData(app) {
  if (!password) {
    return {
      name: "firebase_auth",
      ok: false,
      error: "STAGING_ADMIN_PASSWORD is not set",
    };
  }

  const auth = getAuth(app);
  const db = getFirestore(app);
  const storage = getStorage(app);

  await signInWithEmailAndPassword(auth, ADMIN_EMAIL, password);
  const uid = auth.currentUser?.uid;
  if (!uid) {
    throw new Error("Signed in but uid is missing");
  }

  const companySnap = await getDoc(doc(db, "Companies", COMPANY_ID));
  const userSnap = await getDoc(doc(db, "users", uid));

  const ownLogoPath = `company_logos/${COMPANY_ID}/_smoke_${Date.now()}.txt`;
  const ownLogoRef = ref(storage, ownLogoPath);
  await uploadBytes(ownLogoRef, Buffer.from("staging-smoke"), {
    contentType: "text/plain",
  });
  const downloadUrl = await getDownloadURL(ownLogoRef);
  await deleteObject(ownLogoRef);

  const foreignLogoPath = `company_logos/foreign_company_${Date.now()}.txt`;
  let foreignUploadBlocked = false;
  try {
    await uploadBytes(ref(storage, foreignLogoPath), Buffer.from("blocked"), {
      contentType: "text/plain",
    });
  } catch (error) {
    foreignUploadBlocked =
      error.code === "storage/unauthorized" || error.code === "permission-denied";
  }
  if (!foreignUploadBlocked) {
    try {
      await deleteObject(ref(storage, foreignLogoPath));
    } catch (_) {
      // ignore cleanup errors
    }
  }

  const catalogCheck = await checkTenantCatalogReads(db, userSnap);

  await signOut(auth);

  return {
    name: "firebase_auth",
    ok:
      companySnap.exists() &&
      userSnap.exists() &&
      !!downloadUrl &&
      foreignUploadBlocked &&
      catalogCheck.ok,
    companyExists: companySnap.exists(),
    userProfileExists: userSnap.exists(),
    storageUploadOk: !!downloadUrl,
    storageTenantWriteBlocked: foreignUploadBlocked,
    catalogReadsOk: catalogCheck.ok,
    email: ADMIN_EMAIL,
    catalogCheck,
  };
}

async function checkTenantCatalogReads(db, userSnap) {
  const companyRef = userSnap.data()?.companyRef;
  if (!companyRef) {
    return {
      name: "tenant_catalog_reads",
      ok: false,
      error: "staging admin user profile has no companyRef",
    };
  }

  try {
    const [productSnap, materialSnap] = await Promise.all([
      getDocs(
        query(
          collection(db, "product"),
          where("companyRef", "==", companyRef),
          limit(1),
        ),
      ),
      getDocs(
        query(
          collection(db, "materials"),
          where("companyRef", "==", companyRef),
          limit(1),
        ),
      ),
    ]);

    return {
      name: "tenant_catalog_reads",
      ok: true,
      productSampleCount: productSnap.size,
      materialSampleCount: materialSnap.size,
    };
  } catch (error) {
    return {
      name: "tenant_catalog_reads",
      ok: false,
      error: error.message || String(error),
      code: error.code || null,
    };
  }
}

async function main() {
  const checks = [];

  try {
    checks.push(await checkHosting());
  } catch (error) {
    checks.push({
      name: "hosting",
      ok: false,
      error: error.message || String(error),
    });
  }

  const app = initializeApp(firebaseConfig, "staging-smoke");
  try {
    checks.push(await checkFirebaseAuthAndData(app));
  } catch (error) {
    checks.push({
      name: "firebase_auth",
      ok: false,
      error: error.message || String(error),
    });
  }

  const manual = [
    "Login on staging web as staging.admin@tfg-vday.test",
    "Create Order → Select Products: Retail / Delivery buttons appear (not endless loading)",
    "Order Detail → Production menu loads (no permission-denied)",
    "Driver My Deliveries → upload delivery proof",
    "Add Staff flow (registration intent → new profile)",
  ];

  const ok = checks.every((check) => check.ok);
  const payload = { ok, checks, manualChecklist: manual };

  if (asJson) {
    console.log(JSON.stringify(payload, null, 2));
  } else {
    console.log(`Staging smoke ${ok ? "PASS" : "FAIL"}`);
    for (const check of checks) {
      console.log(`  [${check.ok ? "OK" : "FAIL"}] ${check.name}`);
      if (check.error) {
        console.log(`       ${check.error}`);
      }
      if (check.catalogCheck && !check.catalogCheck.ok) {
        console.log(`       catalog: ${check.catalogCheck.error}`);
      }
    }
    console.log("\nManual checklist:");
    for (const item of manual) {
      console.log(`  - ${item}`);
    }
  }

  process.exit(ok ? 0 : 1);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
