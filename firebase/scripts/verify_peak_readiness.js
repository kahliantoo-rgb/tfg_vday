#!/usr/bin/env node
/**
 * Automated peak-readiness checks (P1): users, roles, counters, rules test hint.
 *
 * Usage:
 *   node scripts/verify_peak_readiness.js [--project tfg-sales-record] [--key serviceAccount.json]
 */
const admin = require("firebase-admin");
const { spawnSync } = require("node:child_process");
const path = require("node:path");
const {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
} = require("./admin_init");

const projectId =
  process.argv.find((a, i) => process.argv[i - 1] === "--project") ||
  process.env.FIREBASE_PROJECT ||
  "tfg-sales-record";

const ALLOWED_ROLES = new Set(["superadmin", "admin", "senior_florist", "driver"]);

let auth;
try {
  auth = initializeAdmin(projectId);
} catch (err) {
  console.error(credentialsHelp());
  process.exit(1);
}

const db = admin.firestore();

function issue(level, code, message, extra = {}) {
  return { level, code, message, ...extra };
}

async function verifyUsers() {
  const findings = [];
  const roleCounts = { admin: 0, senior_florist: 0, driver: 0, other: 0 };
  let staffAccounts = 0;
  let driverAccounts = 0;

  const usersSnap = await db.collection("users").get();
  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const role = data.role;

    if (!ALLOWED_ROLES.has(role)) {
      findings.push(
        issue("error", "USER_INVALID_ROLE", `users/${doc.id} has invalid role: ${role}`),
      );
      roleCounts.other += 1;
      continue;
    }

    roleCounts[role] += 1;
    if (role === "admin" || role === "senior_florist" || role === "superadmin") {
      staffAccounts += 1;
    }
    if (role === "driver") {
      driverAccounts += 1;
      if (!data.companyRef) {
        findings.push(
          issue(
            "error",
            "DRIVER_MISSING_COMPANY",
            `users/${doc.id} (driver) missing companyRef`,
          ),
        );
      }
    }

    if (data.uid && data.uid !== doc.id) {
      findings.push(
        issue(
          "warn",
          "USER_UID_MISMATCH",
          `users/${doc.id} uid field does not match doc id`,
          { uid: data.uid },
        ),
      );
    }
  }

  if (staffAccounts === 0) {
    findings.push(
      issue(
        "error",
        "NO_STAFF_ACCOUNT",
        "No admin or senior_florist user found for smoke tests",
      ),
    );
  }
  if (driverAccounts === 0) {
    findings.push(
      issue(
        "warn",
        "NO_DRIVER_ACCOUNT",
        "No driver user found for driver smoke tests",
      ),
    );
  }

  return { findings, roleCounts, staffAccounts, driverAccounts, total: usersSnap.size };
}

async function verifyCounters() {
  const findings = [];
  const rows = [];

  const companiesSnap = await db
    .collection("Companies")
    .where("is_active", "==", true)
    .get();

  const companyIds = companiesSnap.docs.map((d) => d.id);
  companyIds.push("default");

  for (const companyId of companyIds) {
    const deliveryRef = db.collection("counter").doc(`${companyId}_delivery`);
    const retailRef = db.collection("counter").doc(`${companyId}_retail`);
    const [deliverySnap, retailSnap] = await Promise.all([
      deliveryRef.get(),
      retailRef.get(),
    ]);

    const delivery = deliverySnap.exists ? deliverySnap.data().current ?? 0 : null;
    const retail = retailSnap.exists ? retailSnap.data().current ?? 0 : null;

    if (delivery === null || retail === null) {
      findings.push(
        issue(
          "error",
          "COUNTER_MISSING",
          `Missing counter docs for ${companyId}`,
          { delivery: deliverySnap.exists, retail: retailSnap.exists },
        ),
      );
    }

    rows.push({
      companyId,
      delivery,
      retail,
      ready: delivery !== null && retail !== null,
    });
  }

  return { findings, rows, activeCompanies: companiesSnap.size };
}

function runRulesTestsIfPossible() {
  const java = spawnSync("java", ["-version"], { encoding: "utf8" });
  if (java.error || java.status !== 0) {
    return {
      ran: false,
      reason: "Java not installed — run npm run test:rules in CI or install JDK 17",
    };
  }

  const firebaseRoot = path.resolve(__dirname, "..");
  const result = spawnSync("npm", ["run", "test:rules"], {
    cwd: firebaseRoot,
    encoding: "utf8",
    shell: true,
  });

  return {
    ran: true,
    pass: result.status === 0,
    stdout: result.stdout,
    stderr: result.stderr,
  };
}

async function main() {
  const [users, counters] = await Promise.all([verifyUsers(), verifyCounters()]);
  const rules = runRulesTestsIfPossible();

  const findings = [...users.findings, ...counters.findings];
  if (rules.ran && !rules.pass) {
    findings.push(issue("error", "RULES_TEST_FAIL", "Firestore rules unit tests failed"));
  }

  const errors = findings.filter((f) => f.level === "error");
  const report = {
    projectId,
    auth: auth.mode,
    keyPath: auth.keyPath || null,
    ranAt: new Date().toISOString(),
    pass: errors.length === 0,
    users: {
      total: users.total,
      roleCounts: users.roleCounts,
      staffAccounts: users.staffAccounts,
      driverAccounts: users.driverAccounts,
    },
    counters: {
      activeCompanies: counters.activeCompanies,
      rows: counters.rows,
    },
    rulesTests: rules.ran
      ? { pass: rules.pass }
      : { skipped: true, reason: rules.reason },
    findings,
    manualRemaining: [
      "C2-1..C2-6: staff order create / retail / delivery / CSV in app",
      "C2-5, C4-2, D4: Bluetooth print on Android device",
      "C3-1..C3-5: driver login + status advance in app",
      "D1-D2: full retail/delivery flows on device",
    ],
  };

  console.log(JSON.stringify(report, null, 2));
  process.exit(errors.length === 0 ? 0 : 1);
}

main().catch((err) => {
  if (isCredentialsError(err)) {
    console.error(credentialsHelp());
  } else {
    console.error(err);
  }
  process.exit(1);
});
