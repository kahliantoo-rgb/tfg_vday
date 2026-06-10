#!/usr/bin/env node
/**
 * Set users/{uid}.role (and optional companyRef). For superadmin bootstrap only.
 *
 * Usage:
 *   node scripts/set_user_role.js --email kahliantoo@gmail.com --role superadmin --key ...
 *   node scripts/set_user_role.js --uid MgnbXfUoOpZgbbo6VSGgVeIgqlo1 --role superadmin --dry-run
 */
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
} = require("./admin_init");

const ALLOWED = new Set([
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

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId = argValue("--project") || process.env.FIREBASE_PROJECT || "tfg-sales-record";
const dryRun = process.argv.includes("--dry-run");
const email = (argValue("--email") || "").trim().toLowerCase();
const uidArg = argValue("--uid");
const role = (argValue("--role") || "").trim();
const companyId = argValue("--company-id");

let authCtx;
try {
  authCtx = initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

const db = admin.firestore();

async function resolveUid() {
  if (uidArg) {
    return uidArg;
  }
  if (!email) {
    throw new Error("Provide --email or --uid");
  }
  const user = await admin.auth().getUserByEmail(email);
  return user.uid;
}

async function main() {
  if (!ALLOWED.has(role)) {
    throw new Error(`Invalid --role. Allowed: ${[...ALLOWED].join(", ")}`);
  }

  const uid = await resolveUid();
  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new Error(`users/${uid} does not exist`);
  }

  const patch = { role, uid };
  if (companyId) {
    patch.companyRef = db.collection("Companies").doc(companyId);
  }

  if (!dryRun) {
    await ref.set(patch, { merge: true });
  }

  console.log(
    JSON.stringify(
      {
        projectId,
        dryRun,
        auth: authCtx.mode,
        uid,
        email: snap.data().email || email || null,
        previousRole: snap.data().role,
        newRole: role,
        companyId: companyId || null,
        action: dryRun ? "would_update" : "updated",
      },
      null,
      2,
    ),
  );
}

main().catch((err) => {
  if (isCredentialsError(err)) {
    console.error(credentialsHelp());
  } else {
    console.error(err);
  }
  process.exit(1);
});
