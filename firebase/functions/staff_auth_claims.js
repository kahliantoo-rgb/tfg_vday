const admin = require("firebase-admin");

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

function canonicalCompanyDocId(companyId) {
  return companyId === "Ic3Dhfby8f35Md0E1vZC" ? "lc3Dhfby8f35Md0E1vZC" : companyId;
}

async function loadAssignedOrderIds(db, uid) {
  const userRef = db.collection("users").doc(uid);
  const snap = await db
    .collection("orders")
    .where("assigned_driver", "==", userRef)
    .get();
  return snap.docs
    .map((doc) => doc.id)
    .sort()
    .slice(0, MAX_ASSIGNED_ORDER_IDS);
}

async function buildStaffClaims(db, uid, profileData) {
  const role = typeof profileData.role === "string" ? profileData.role.trim() : "";
  if (!STAFF_ROLES.has(role)) {
    return null;
  }
  const claims = { role };
  const companyRef = profileData.companyRef;
  if (companyRef && typeof companyRef.id === "string") {
    claims.companyId = canonicalCompanyDocId(companyRef.id);
  }
  if (role === "driver") {
    claims.assignedOrderIds = await loadAssignedOrderIds(db, uid);
  }
  return claims;
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

async function syncStaffAuthClaims(db, uid) {
  const profileSnap = await db.collection("users").doc(uid).get();
  if (!profileSnap.exists) {
    return { uid, action: "skipped_missing_profile" };
  }

  const nextClaims = await buildStaffClaims(db, uid, profileSnap.data());
  if (!nextClaims) {
    return { uid, action: "skipped_non_staff" };
  }

  let currentClaims = {};
  try {
    const userRecord = await admin.auth().getUser(uid);
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

  await admin.auth().setCustomUserClaims(uid, nextClaims);
  return { uid, action: "updated", claims: nextClaims };
}

function driverUidFromAssignedRef(ref) {
  if (!ref || typeof ref.path !== "string") {
    return null;
  }
  const parts = ref.path.split("/");
  if (parts.length !== 2 || parts[0] !== "users" || !parts[1]) {
    return null;
  }
  return parts[1];
}

module.exports = {
  syncStaffAuthClaims,
  driverUidFromAssignedRef,
};
