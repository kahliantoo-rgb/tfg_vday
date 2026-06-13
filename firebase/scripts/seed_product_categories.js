#!/usr/bin/env node
/**
 * Seed product_categories/{companyId} from company defaults + existing product.category text.
 *
 *   node scripts/seed_product_categories.js --project tfg-sales-record
 *   node scripts/seed_product_categories.js --project tfg-sales-record --company-id lc3Dhfby8f35Md0E1vZC --force
 */
const { initializeAdmin, credentialsHelp } = require("./admin_init");

const projectId =
  process.argv.find((a, i) => process.argv[i - 1] === "--project") ||
  process.env.FIREBASE_PROJECT ||
  "tfg-sales-record";
const dryRun = process.argv.includes("--dry-run");
const force = process.argv.includes("--force");
const companyIdArg = process.argv.find(
  (a, i) => process.argv[i - 1] === "--company-id",
);

const TYPO_COMPANY_ID = "Ic3Dhfby8f35Md0E1vZC";
const CANONICAL_TFG_ID = "lc3Dhfby8f35Md0E1vZC";

const THE_FLOWER_GUY_CATEGORIES = [
  "Funeral",
  "Hand Bouquet",
  "Wreath",
  "Opening Stand",
  "Wedding",
  "Ad-Hoc",
];

const GENERIC_DEFAULTS = [
  "Hand Bouquet",
  "Wreath",
  "Opening Stand",
  "Table arrangement",
  "AdHoc",
];

function canonicalCompanyId(id) {
  if (!id) {
    return CANONICAL_TFG_ID;
  }
  return id === TYPO_COMPANY_ID ? CANONICAL_TFG_ID : id;
}

function normalizeCategory(value) {
  return String(value || "")
    .trim()
    .replace(/\s+/g, " ");
}

function normalizeCategoryList(values) {
  const seen = new Set();
  const out = [];
  for (const value of values) {
    const name = normalizeCategory(value);
    if (!name) {
      continue;
    }
    const key = name.toLowerCase();
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    out.push(name);
  }
  out.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
  return out;
}

function defaultsForCompany(companyId) {
  return canonicalCompanyId(companyId) === CANONICAL_TFG_ID
    ? [...THE_FLOWER_GUY_CATEGORIES]
    : [...GENERIC_DEFAULTS];
}

let auth;
try {
  auth = initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

const admin = require("firebase-admin");
const db = admin.firestore();

async function collectProductCategories(companyId) {
  const companyRef = db.collection("Companies").doc(companyId);
  const snap = await db
    .collection("product")
    .where("companyRef", "==", companyRef)
    .limit(500)
    .get();
  return snap.docs
    .map((doc) => doc.data().category)
    .filter((value) => normalizeCategory(value));
}

async function seedCompany(companyId) {
  const canonicalId = canonicalCompanyId(companyId);
  const companyRef = db.collection("Companies").doc(canonicalId);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    return { companyId: canonicalId, action: "missing_company" };
  }

  const fromProducts = await collectProductCategories(canonicalId);
  const target = normalizeCategoryList([
    ...defaultsForCompany(canonicalId),
    ...fromProducts,
  ]);

  const docRef = db.collection("product_categories").doc(canonicalId);
  const existingSnap = await docRef.get();
  const existing = existingSnap.exists
    ? normalizeCategoryList(existingSnap.data().categories || [])
    : [];

  const merged = normalizeCategoryList([...existing, ...target]);
  const shouldWrite =
    force ||
    !existingSnap.exists ||
    merged.length !== existing.length ||
    merged.some((value, index) => value !== existing[index]);

  if (!shouldWrite) {
    return { companyId: canonicalId, action: "unchanged", count: existing.length };
  }

  if (!dryRun) {
    await docRef.set(
      {
        companyRef,
        categories: force ? target : merged,
        updated_time: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  return {
    companyId: canonicalId,
    action: existingSnap.exists ? "updated" : "created",
    count: (force ? target : merged).length,
    dryRun,
  };
}

async function main() {
  console.log(`Project: ${projectId} (${auth.mode})`);
  const companyIds = [];
  if (companyIdArg) {
    companyIds.push(canonicalCompanyId(companyIdArg));
  } else {
    const companiesSnap = await db.collection("Companies").get();
    for (const doc of companiesSnap.docs) {
      companyIds.push(canonicalCompanyId(doc.id));
    }
  }

  const uniqueIds = [...new Set(companyIds)];
  for (const companyId of uniqueIds) {
    const result = await seedCompany(companyId);
    console.log(JSON.stringify(result));
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
