#!/usr/bin/env node
/**
 * Sync Firebase Auth custom claims from Firestore users/{uid} staff profiles.
 *
 * Storage security rules read role, companyId, and (for drivers) assignedOrderIds
 * from custom claims because Firestore cross-service lookups are unavailable on
 * this project's Storage rules bridge.
 *
 * Usage:
 *   node scripts/sync_staff_auth_claims.js --project tfg-sales-record
 *   node scripts/sync_staff_auth_claims.js --email xinhow0423@hotmail.com
 *   node scripts/sync_staff_auth_claims.js --dry-run
 */
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
} = require("./admin_init");

const STAFF_ROLES = new Set([
  "superadmin",
  "admin",
  "director",
  "manager",
  "account",
  "hr",
  "payroll",
  "senior_florist",
  "florist",
  "driver",
]);

const MAX_ASSIGNED_ORDER_IDS = 200;

function argValue(flag) {
  const index = process.argv.indexOf(flag);
  return index >= 0 ? process.argv[index + 1] : null;
}

const projectId =
  argValue("--project") || process.env.FIREBASE_PROJECT || "tfg-sales-record";
const emailFilter = (argValue("--email") || "").trim().toLowerCase();
const dryRun = process.argv.includes("--dry-run");

try {
  initializeAdmin(projectId);
} catch (_) {
  console.error(credentialsHelp(projectId));
  process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();

function canonicalCompanyDocId(companyId) {
  return companyId === "Ic3Dhfby8f35Md0E1vZC" ? "lc3Dhfby8f35Md0E1vZC" : companyId;
}

async function loadAssignedOrderIds(uid) {
  const userRef = db.collection("users").doc(uid);
  const snap = await db
    .collection("orders")
    .where("assigned_driver", "==", userRef)
    .get();
  const orderIds = snap.docs.map((doc) => doc.id);
  orderIds.sort();
  return orderIds.slice(0, MAX_ASSIGNED_ORDER_IDS);
}

function claimsEqual(currentClaims, nextClaims) {
  const currentRole = currentClaims.role || null;
  const nextRole = nextClaims.role || null;
  const currentCompanyId = currentClaims.companyId || null;
  const nextCompanyId = nextClaims.companyId || null;
  const currentOrders = Array.isArray(currentClaims.assignedOrderIds)
    ? [...currentClaims.assignedOrderIds].sort()
    : [];
  const nextOrders = Array.isArray(nextClaims.assignedOrderIds)
    ? [...nextClaims.assignedOrderIds].sort()
    : [];
  if (currentRole !== nextRole || currentCompanyId !== nextCompanyId) {
    return false;
  }
  if (currentOrders.length !== nextOrders.length) {
    return false;
  }
  return currentOrders.every((value, index) => value === nextOrders[index]);
}

async function claimsFromProfile(uid, data) {
  const role = typeof data.role === "string" ? data.role.trim() : "";
  if (!STAFF_ROLES.has(role)) {
    return null;
  }
  const companyRef = data.companyRef;
  const companyId =
    companyRef && typeof companyRef.id === "string"
      ? canonicalCompanyDocId(companyRef.id)
      : null;
  const claims = { role };
  if (companyId) {
    claims.companyId = companyId;
  }
  if (role === "driver") {
    claims.assignedOrderIds = await loadAssignedOrderIds(uid);
  }
  return claims;
}

async function syncUserDoc(doc) {
  const uid = doc.id;
  const data = doc.data();
  const nextClaims = await claimsFromProfile(uid, data);
  if (!nextClaims) {
    return { uid, action: "skipped_non_staff" };
  }

  let currentClaims = {};
  try {
    const userRecord = await auth.getUser(uid);
    currentClaims = userRecord.customClaims || {};
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      return { uid, action: "skipped_missing_auth" };
    }
    throw error;
  }

  if (claimsEqual(currentClaims, nextClaims)) {
    return { uid, action: "unchanged", claims: nextClaims };
  }

  if (!dryRun) {
    await auth.setCustomUserClaims(uid, nextClaims);
  }
  return {
    uid,
    email: data.email || null,
    action: dryRun ? "would_update" : "updated",
    claims: nextClaims,
  };
}

async function main() {
  let docs = [];
  if (emailFilter) {
    const snap = await db
      .collection("users")
      .where("email", "==", emailFilter)
      .limit(5)
      .get();
    docs = snap.docs;
    if (docs.length === 0) {
      console.error(`No users profile found for email ${emailFilter}`);
      process.exit(1);
    }
  } else {
    const snap = await db.collection("users").get();
    docs = snap.docs;
  }

  const results = [];
  for (const doc of docs) {
    results.push(await syncUserDoc(doc));
  }

  const summary = {
    projectId,
    dryRun,
    total: results.length,
    updated: results.filter((row) => row.action === "updated").length,
    wouldUpdate: results.filter((row) => row.action === "would_update").length,
    unchanged: results.filter((row) => row.action === "unchanged").length,
    skipped: results.filter((row) => row.action.startsWith("skipped")).length,
  };

  console.log(JSON.stringify({ summary, results }, null, 2));
  if (summary.updated > 0 || summary.wouldUpdate > 0) {
    console.log(
      "\nUsers must sign out and sign in again so Storage rules receive fresh ID tokens.",
    );
  }
}

main().catch((error) => {
  if (isCredentialsError(error)) {
    console.error(credentialsHelp(projectId));
  } else {
    console.error(error);
  }
  process.exit(1);
});
