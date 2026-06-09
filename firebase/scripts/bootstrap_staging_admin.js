#!/usr/bin/env node
/**
 * Idempotent staging bootstrap: company + counters + staging.admin profile.
 *
 *   node scripts/bootstrap_staging_admin.js
 *   node scripts/bootstrap_staging_admin.js --dry-run
 */
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
} = require("./admin_init");

const STAGING_PROJECT = "tfg-vday-record-staging";
const ADMIN_EMAIL = "staging.admin@tfg-vday.test";
const ADMIN_PASSWORD = "StagingTest2026!";
const ADMIN_NAME = "Staging Admin";
const DEFAULT_COMPANY_ID = "staging_company";
const DEFAULT_COMPANY_NAME = "TFG Staging Florist";

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId = argValue("--project") || process.env.FIREBASE_PROJECT || STAGING_PROJECT;
const dryRun = process.argv.includes("--dry-run");

let authCtx;
try {
  authCtx = initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

const db = admin.firestore();

async function ensureCompany() {
  const ref = db.collection("Companies").doc(DEFAULT_COMPANY_ID);
  const snap = await ref.get();
  if (snap.exists) {
    return { companyId: ref.id, action: "exists" };
  }
  if (!dryRun) {
    await ref.set({
      Company_name: DEFAULT_COMPANY_NAME,
      is_active: true,
    });
  }
  return { companyId: ref.id, action: dryRun ? "would_create" : "created" };
}

async function ensureCounters(companyId) {
  const results = [];
  for (const suffix of ["delivery", "retail"]) {
    const ref = db.collection("counter").doc(`${companyId}_${suffix}`);
    const snap = await ref.get();
    if (snap.exists) {
      results.push({ counter: ref.id, action: "exists" });
      continue;
    }
    if (!dryRun) {
      await ref.set({ current: 0 });
    }
    results.push({ counter: ref.id, action: dryRun ? "would_create" : "created" });
  }
  return results;
}

async function ensureAdminUser(companyRef) {
  let authUser;
  try {
    authUser = await admin.auth().getUserByEmail(ADMIN_EMAIL);
  } catch (err) {
    if (err.code !== "auth/user-not-found") {
      throw err;
    }
    if (dryRun) {
      return { action: "would_create_auth_and_profile", email: ADMIN_EMAIL };
    }
    authUser = await admin.auth().createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      displayName: ADMIN_NAME,
      disabled: false,
    });
  }

  const profileRef = db.collection("users").doc(authUser.uid);
  const profileSnap = await profileRef.get();
  const profileData = {
    name: ADMIN_NAME,
    email: ADMIN_EMAIL,
    role: "admin",
    companyRef,
    uid: authUser.uid,
    display_name: ADMIN_NAME,
    is_active: true,
    created_time: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (
    profileSnap.exists &&
    profileSnap.data().role === "admin" &&
    profileSnap.data().companyRef &&
    profileSnap.data().is_active !== false &&
    !dryRun
  ) {
    await profileRef.set(profileData, { merge: true });
    return {
      action: "refreshed",
      uid: authUser.uid,
      usersPath: profileRef.path,
    };
  }

  if (
    profileSnap.exists &&
    profileSnap.data().role === "admin" &&
    profileSnap.data().companyRef
  ) {
    return {
      action: dryRun ? "already_ready" : "refreshed",
      uid: authUser.uid,
      usersPath: profileRef.path,
    };
  }

  if (!dryRun) {
    await profileRef.set(profileData, { merge: true });
    if (authUser.disabled) {
      await admin.auth().updateUser(authUser.uid, { disabled: false });
    }
  }

  return {
    action: dryRun ? "would_upsert_profile" : "upserted_profile",
    uid: authUser.uid,
    usersPath: profileRef.path,
  };
}

async function main() {
  const company = await ensureCompany();
  const companyRef = db.collection("Companies").doc(company.companyId);
  const counters = await ensureCounters(company.companyId);
  const adminUser = await ensureAdminUser(companyRef);

  console.log(
    JSON.stringify(
      {
        projectId,
        dryRun,
        auth: authCtx.mode,
        company,
        counters,
        adminUser,
        login: {
          email: ADMIN_EMAIL,
          password: ADMIN_PASSWORD,
          webUrl: "https://tfg-vday-record-staging.web.app",
        },
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
