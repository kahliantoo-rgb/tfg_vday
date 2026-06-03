#!/usr/bin/env node
/**
 * Initialize or sync counter/{companyId}_delivery and _retail for peak season.
 *
 * Credentials (pick one):
 *   - Place JSON at firebase/keys/serviceAccount.json  (recommended)
 *   - set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\key.json
 *   - node scripts/init_counters.js --key C:\path\to\key.json
 */
const {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
} = require("./admin_init");

const projectId =
  process.argv.find((a, i) => process.argv[i - 1] === "--project") ||
  process.env.FIREBASE_PROJECT ||
  "tfg-sales-record";
const dryRun = process.argv.includes("--dry-run");

let auth;
try {
  auth = initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

const admin = require("firebase-admin");
const db = admin.firestore();

async function readCurrent(ref) {
  const snap = await ref.get();
  if (!snap.exists) {
    return null;
  }
  const value = snap.data().current;
  return typeof value === "number" ? value : 0;
}

async function ensureCounterPair(companyId) {
  const deliveryRef = db.collection("counter").doc(`${companyId}_delivery`);
  const retailRef = db.collection("counter").doc(`${companyId}_retail`);

  const deliveryCurrent = await readCurrent(deliveryRef);
  const retailCurrent = await readCurrent(retailRef);

  if (deliveryCurrent === null && retailCurrent === null) {
    if (!dryRun) {
      await deliveryRef.set({ current: 0 });
      await retailRef.set({ current: 0 });
    }
    return {
      companyId,
      action: "created",
      delivery: 0,
      retail: 0,
    };
  }

  const synced = Math.max(deliveryCurrent ?? 0, retailCurrent ?? 0);
  const needsSync =
    deliveryCurrent !== synced ||
    retailCurrent !== synced ||
    deliveryCurrent === null ||
    retailCurrent === null;

  if (needsSync && !dryRun) {
    await deliveryRef.set({ current: synced }, { merge: true });
    await retailRef.set({ current: synced }, { merge: true });
  }

  return {
    companyId,
    action: needsSync ? "synced" : "ok",
    delivery: synced,
    retail: synced,
  };
}

async function main() {
  const results = [];
  const companiesSnap = await db
    .collection("Companies")
    .where("is_active", "==", true)
    .get();

  if (companiesSnap.empty) {
    console.warn("No active Companies found; only initializing default_* counters.");
  }

  for (const doc of companiesSnap.docs) {
    results.push(await ensureCounterPair(doc.id));
  }

  results.push(await ensureCounterPair("default"));

  const summary = {
    projectId,
    dryRun,
    auth: auth.mode,
    keyPath: auth.keyPath || null,
    emulator: Boolean(process.env.FIRESTORE_EMULATOR_HOST),
    ranAt: new Date().toISOString(),
    companies: companiesSnap.size,
    results,
  };

  console.log(JSON.stringify(summary, null, 2));
}

main().catch((err) => {
  if (isCredentialsError(err)) {
    console.error(credentialsHelp());
  } else {
    console.error(err);
  }
  process.exit(1);
});
