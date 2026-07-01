#!/usr/bin/env node
/**
 * Backfill locked material cost snapshots on paid orders (profit report history).
 *
 * Usage:
 *   node scripts/backfill_material_cost_snapshot.js --dry-run
 *   node scripts/backfill_material_cost_snapshot.js --project tfg-sales-record
 *   node scripts/backfill_material_cost_snapshot.js --company-id lc3Dhfby8f35Md0E1vZC
 */
const admin = require("firebase-admin");
const { initializeAdmin, credentialsHelp } = require("./admin_init");
const {
  buildMaterialCostSnapshotPatch,
  orderQualifiesForMaterialCostSnapshot,
} = require("./material_cost_snapshot_helpers");

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
  400,
  Math.max(1, parseInt(readArg("--batch-size", "400"), 10) || 400),
);

try {
  initializeAdmin(projectId);
} catch (_) {
  console.error(credentialsHelp(projectId));
  process.exit(1);
}

const db = admin.firestore();
const companyRef = db.collection("Companies").doc(companyId);

async function loadCatalog() {
  const [materialSnap, productSnap] = await Promise.all([
    db.collection("materials").where("companyRef", "==", companyRef).get(),
    db.collection("product").where("companyRef", "==", companyRef).get(),
  ]);

  const materialsByPath = new Map();
  for (const doc of materialSnap.docs) {
    materialsByPath.set(doc.ref.path, { cost: Number(doc.data().cost || 0) });
  }

  const products = productSnap.docs.map((doc) => ({
    id: doc.id,
    name: doc.data().name || "",
    recipeLines: doc.data().recipeLines || [],
  }));

  return { materialsByPath, products };
}

async function loadOrderItemsByOrderId() {
  const snap = await db
    .collection("Order_item")
    .where("companyRef", "==", companyRef)
    .get();
  const byOrderId = new Map();
  for (const doc of snap.docs) {
    const data = doc.data();
    const orderRef = data.orderRef;
    if (!orderRef) {
      continue;
    }
    const orderId = orderRef.id;
    const list = byOrderId.get(orderId) || [];
    list.push({
      ...data,
      productRef: data.productRef || null,
    });
    byOrderId.set(orderId, list);
  }
  return byOrderId;
}

async function main() {
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    throw new Error(`Companies/${companyId} does not exist in ${projectId}`);
  }

  console.log(
    `Backfill material cost snapshots — project=${projectId} company=${companyId} dryRun=${dryRun}`,
  );

  const { materialsByPath, products } = await loadCatalog();
  const itemsByOrderId = await loadOrderItemsByOrderId();

  const ordersSnap = await db
    .collection("orders")
    .where("companyRef", "==", companyRef)
    .get();

  let scanned = 0;
  let eligible = 0;
  let updated = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of ordersSnap.docs) {
    scanned += 1;
    const data = doc.data();
    if (data.material_cost_snapshotted_at) {
      continue;
    }
    if (!orderQualifiesForMaterialCostSnapshot(data)) {
      continue;
    }
    eligible += 1;

    const orderItems = itemsByOrderId.get(doc.id) || [];
    const patch = buildMaterialCostSnapshotPatch({
      orderItems,
      products,
      materialsByPath,
    });

    if (dryRun) {
      if (updated < 5) {
        console.log(
          `  [dry-run] ${doc.ref.path} material_usage_cost=${patch.material_usage_cost}`,
        );
      }
      updated += 1;
      continue;
    }

    batch.update(doc.ref, patch);
    batchCount += 1;
    updated += 1;

    if (batchCount >= batchSize) {
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (!dryRun && batchCount > 0) {
    await batch.commit();
  }

  console.log(
    `Done. scanned=${scanned} eligible=${eligible} ${dryRun ? "wouldUpdate" : "updated"}=${updated}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
