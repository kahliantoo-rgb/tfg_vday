#!/usr/bin/env node
/**
 * Reset permission overrides in Firestore (staging rehearsal).
 *
 * Modes:
 *   --mode clear     Remove role + user overrides (revert to code defaults)
 *   --mode deny-all  Set every AppPermission to false for all configurable roles
 *
 * Usage:
 *   node scripts/reset_permission_overrides.js --project tfg-vday-record-staging --dry-run
 *   node scripts/reset_permission_overrides.js --project tfg-vday-record-staging --mode deny-all
 *   node scripts/reset_permission_overrides.js --project tfg-vday-record-staging --company-id staging_company
 */
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
} = require("./admin_init");

const STAGING_PROJECT = "tfg-vday-record-staging";
const DEFAULT_COMPANY_ID = "staging_company";

const CONFIGURABLE_ROLES = [
  "director",
  "admin",
  "manager",
  "account",
  "hr",
  "payroll",
  "senior_florist",
  "florist",
  "driver",
];

const APP_PERMISSIONS = [
  "manageRolePermissions",
  "viewInvoices",
  "editInvoices",
  "editPaidInvoices",
  "createInvoices",
  "voidInvoices",
  "markInvoicesPaid",
  "viewCustomers",
  "editCustomers",
  "createCreditCustomers",
  "deleteCustomers",
  "viewOrders",
  "createOrders",
  "editOrderDetails",
  "editPaidOrderDetails",
  "updateOrderStatus",
  "assignDriver",
  "printCashInvoice",
  "manageProducts",
  "viewStaffList",
  "createStaff",
  "editStaffRoles",
  "exportOrdersCsv",
  "deleteOrders",
  "viewDeletedOrders",
  "restoreDeletedOrders",
  "permanentlyDeleteDeletedOrders",
  "editCompanyProfile",
  "viewAuditLog",
  "accessSalesDashboard",
];

function readArg(name, fallback) {
  const argv = process.argv.slice(2);
  const index = argv.indexOf(name);
  if (index === -1 || index + 1 >= argv.length) {
    return fallback;
  }
  return argv[index + 1];
}

const projectId =
  readArg("--project", process.env.FIREBASE_PROJECT) || STAGING_PROJECT;
const companyId = readArg("--company-id", DEFAULT_COMPANY_ID);
const mode = readArg("--mode", "clear");
const allCompanies = process.argv.includes("--all-companies");
const dryRun = process.argv.includes("--dry-run");

if (projectId !== STAGING_PROJECT) {
  console.error(
    `Refusing to run: project must be staging (${STAGING_PROJECT}). Got: ${projectId}`,
  );
  process.exit(1);
}

if (!["clear", "deny-all"].includes(mode)) {
  console.error(`Unknown --mode ${mode}. Use clear or deny-all.`);
  process.exit(1);
}

try {
  initializeAdmin(projectId);
} catch (_) {
  console.error(credentialsHelp(projectId));
  process.exit(1);
}

const db = admin.firestore();

function buildDenyAllRoles() {
  const denied = {};
  for (const key of APP_PERMISSIONS) {
    denied[key] = false;
  }
  const roles = {};
  for (const roleKey of CONFIGURABLE_ROLES) {
    roles[roleKey] = { ...denied };
  }
  return roles;
}

async function listRolePermissionDocRefs() {
  if (allCompanies) {
    const snap = await db.collection("role_permissions").get();
    return snap.docs.map((doc) => doc.ref);
  }
  return [db.collection("role_permissions").doc(companyId)];
}

async function resetRolePermissions() {
  const refs = await listRolePermissionDocRefs();
  const results = [];

  for (const ref of refs) {
    const snap = await ref.get();
    const before = snap.exists ? snap.data() : null;
    const roleCount = before?.roles ? Object.keys(before.roles).length : 0;

    if (!snap.exists && mode === "clear") {
      results.push({ docId: ref.id, action: "skip_missing" });
      continue;
    }

    if (mode === "clear") {
      if (!dryRun) {
        await ref.set(
          {
            roles: {},
            updated_time: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
      results.push({
        docId: ref.id,
        action: dryRun ? "would_clear_roles" : "cleared_roles",
        previousRoleKeys: roleCount,
      });
      continue;
    }

    const companyRef =
      before?.companyRef ||
      db.collection("Companies").doc(ref.id === companyId ? companyId : ref.id);

    if (!dryRun) {
      await ref.set(
        {
          companyRef,
          roles: buildDenyAllRoles(),
          updated_time: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    results.push({
      docId: ref.id,
      action: dryRun ? "would_deny_all" : "deny_all",
      roles: CONFIGURABLE_ROLES.length,
      permissionsPerRole: APP_PERMISSIONS.length,
    });
  }

  return results;
}

async function clearUserPermissionOverrides() {
  const snap = await db.collection("users").get();
  const results = [];
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const overrides = data.permission_overrides;
    if (!overrides || Object.keys(overrides).length === 0) {
      continue;
    }

    results.push({
      uid: doc.id,
      email: data.email || null,
      keys: Object.keys(overrides).length,
    });

    if (!dryRun) {
      batch.update(doc.ref, { permission_overrides: {} });
      batchCount += 1;
      if (batchCount >= 400) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }

  if (!dryRun && batchCount > 0) {
    await batch.commit();
  }

  return results;
}

async function main() {
  console.log(
    JSON.stringify(
      {
        projectId,
        companyId: allCompanies ? "* (all role_permissions docs)" : companyId,
        mode,
        dryRun,
      },
      null,
      2,
    ),
  );

  const roleResults = await resetRolePermissions();
  console.log("\nrole_permissions:");
  console.log(JSON.stringify(roleResults, null, 2));

  const userResults = await clearUserPermissionOverrides();
  console.log(`\nusers.permission_overrides cleared: ${userResults.length}`);
  if (userResults.length > 0) {
    console.log(JSON.stringify(userResults, null, 2));
  }

  if (dryRun) {
    console.log("\nDry run only — no writes performed.");
  } else {
    console.log("\nDone. Reload the app to pick up changes.");
    if (mode === "deny-all") {
      console.log(
        "All configurable roles now have every AppPermission denied via Firestore override.",
      );
      console.log("Re-enable permissions in User List → shield icon (matrix).");
    } else {
      console.log("Overrides removed — effective permissions use code defaults.");
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
