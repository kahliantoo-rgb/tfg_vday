#!/usr/bin/env node
/**
 * Fix users/{docId} where docId !== data.uid (breaks Firestore rules).
 *
 * Rules read users/{request.auth.uid} only; app also queries by uid field.
 * Migrates profile to users/{uid} and removes the legacy doc.
 *
 * Usage:
 *   node scripts/fix_user_profile_ids.js --dry-run [--key ...]
 *   node scripts/fix_user_profile_ids.js [--key ...]
 */
const admin = require("firebase-admin");
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

const db = admin.firestore();

async function countReferences(userRef) {
  const [orders, audits] = await Promise.all([
    db.collection("orders").where("assigned_driver", "==", userRef).count().get(),
    db.collection("audit_logs").where("performed_by", "==", userRef).count().get(),
  ]);
  return {
    assignedDriverOrders: orders.data().count,
    auditLogs: audits.data().count,
  };
}

async function findMismatchedUsers() {
  const snap = await db.collection("users").get();
  const mismatched = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const uid = data.uid;
    if (!uid || doc.id === uid) {
      continue;
    }
    mismatched.push({ doc, data, uid });
  }

  return mismatched;
}

async function migrateUser({ doc, data, uid }) {
  const oldRef = doc.ref;
  const newRef = db.collection("users").doc(uid);
  const newSnap = await newRef.get();
  const refs = await countReferences(oldRef);

  const payload = {
    ...data,
    uid,
  };

  const action = {
    email: data.email || null,
    role: data.role || null,
    oldDocId: doc.id,
    newDocId: uid,
    references: refs,
    newDocExists: newSnap.exists,
  };

  if (newSnap.exists) {
    action.action = "skip_new_exists";
    action.note = `users/${uid} already exists — manual merge required`;
    return action;
  }

  if (refs.assignedDriverOrders > 0 || refs.auditLogs > 0) {
    action.action = "skip_has_references";
    action.note = "Update references before deleting old doc";
    return action;
  }

  if (!dryRun) {
    await newRef.set(payload);
    await oldRef.delete();
  }

  action.action = dryRun ? "would_migrate" : "migrated";
  return action;
}

async function main() {
  const mismatched = await findMismatchedUsers();

  if (mismatched.length === 0) {
    console.log(JSON.stringify({ pass: true, message: "No mismatched user docs." }, null, 2));
    return;
  }

  const results = [];
  for (const item of mismatched) {
    results.push(await migrateUser(item));
  }

  const blocked = results.filter((r) => r.action.startsWith("skip"));
  console.log(
    JSON.stringify(
      {
        projectId,
        dryRun,
        auth: auth.mode,
        mismatched: results.length,
        results,
        pass: blocked.length === 0 && results.every((r) => r.action.includes("migrate")),
      },
      null,
      2,
    ),
  );

  if (blocked.length > 0) {
    process.exit(1);
  }
}

main().catch((err) => {
  if (isCredentialsError(err)) {
    console.error(credentialsHelp());
  } else {
    console.error(err);
  }
  process.exit(1);
});
