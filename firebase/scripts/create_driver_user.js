#!/usr/bin/env node
/**
 * Create a Firebase Auth user + Firestore users/{uid} profile for driver smoke tests.
 *
 * Usage:
 *   node scripts/create_driver_user.js --email driver@test.com --password "Secret123!" --name "Test Driver"
 *   node scripts/create_driver_user.js --dry-run --email driver@test.com ...
 *
 * Options:
 *   --email        required
 *   --password     required (min 6 chars)
 *   --name         default "Test Driver"
 *   --phone        optional
 *   --company-id   Firestore Companies doc id (default: active company or lc3Dhfby8f35Md0E1vZC)
 *   --project      default tfg-sales-record
 *   --key          service account JSON path
 */
const admin = require("firebase-admin");
const {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
} = require("./admin_init");

function argValue(flag) {
  const i = process.argv.indexOf(flag);
  return i >= 0 ? process.argv[i + 1] : null;
}

const projectId = argValue("--project") || process.env.FIREBASE_PROJECT || "tfg-sales-record";
const dryRun = process.argv.includes("--dry-run");
const email = (argValue("--email") || "").trim().toLowerCase();
const password = argValue("--password") || "";
const name = (argValue("--name") || "Test Driver").trim();
const phone = (argValue("--phone") || "").trim();
const companyIdArg = argValue("--company-id");

let authCtx;
try {
  authCtx = initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

const db = admin.firestore();

async function resolveCompanyId() {
  if (companyIdArg) {
    return companyIdArg;
  }
  const snap = await db
    .collection("Companies")
    .where("is_active", "==", true)
    .limit(1)
    .get();
  if (!snap.empty) {
    return snap.docs[0].id;
  }
  return "lc3Dhfby8f35Md0E1vZC";
}

async function main() {
  if (!email) {
    console.error("Missing --email");
    process.exit(1);
  }
  if (password.length < 6) {
    console.error("Missing or invalid --password (min 6 characters)");
    process.exit(1);
  }

  const companyId = await resolveCompanyId();
  const companyRef = db.collection("Companies").doc(companyId);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    console.error(`Company not found: Companies/${companyId}`);
    process.exit(1);
  }

  let existingAuth = null;
  try {
    existingAuth = await admin.auth().getUserByEmail(email);
  } catch (err) {
    if (err.code !== "auth/user-not-found") {
      throw err;
    }
  }

  const plan = {
    projectId,
    dryRun,
    auth: authCtx.mode,
    email,
    name,
    phone: phone || null,
    companyId,
    companyPath: companyRef.path,
    role: "driver",
  };

  if (existingAuth) {
    const profileRef = db.collection("users").doc(existingAuth.uid);
    const profileSnap = await profileRef.get();
    plan.existingAuthUid = existingAuth.uid;
    plan.profileExists = profileSnap.exists;
    if (profileSnap.exists) {
      plan.existingRole = profileSnap.data().role;
    }

    if (profileSnap.exists && profileSnap.data().role === "driver") {
      plan.action = "already_ready";
      plan.message = "Auth + driver profile already exist";
      console.log(JSON.stringify(plan, null, 2));
      return;
    }

    if (!dryRun) {
      await profileRef.set(
        {
          name,
          email,
          role: "driver",
          companyRef,
          uid: existingAuth.uid,
          display_name: name,
          created_time: admin.firestore.FieldValue.serverTimestamp(),
          ...(phone ? { phone_number: phone } : {}),
        },
        { merge: true },
      );
      if (existingAuth.disabled) {
        await admin.auth().updateUser(existingAuth.uid, { disabled: false });
      }
    }
    plan.action = dryRun ? "would_upsert_profile" : "upserted_profile";
    console.log(JSON.stringify(plan, null, 2));
    return;
  }

  if (dryRun) {
    plan.action = "would_create_auth_and_profile";
    console.log(JSON.stringify(plan, null, 2));
    return;
  }

  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName: name,
    disabled: false,
  });

  await db
    .collection("users")
    .doc(userRecord.uid)
    .set({
      name,
      email,
      role: "driver",
      companyRef,
      uid: userRecord.uid,
      display_name: name,
      created_time: admin.firestore.FieldValue.serverTimestamp(),
      ...(phone ? { phone_number: phone } : {}),
    });

  plan.action = "created";
  plan.uid = userRecord.uid;
  plan.usersPath = `users/${userRecord.uid}`;
  plan.loginHint = "Use email + password on login page; should land on driver delivery page";
  console.log(JSON.stringify(plan, null, 2));
}

main().catch((err) => {
  if (isCredentialsError(err)) {
    console.error(credentialsHelp());
  } else {
    console.error(err);
  }
  process.exit(1);
});
