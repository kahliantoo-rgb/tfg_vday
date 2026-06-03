/**
 * Integration test: init_counters.js against Firestore emulator (no prod credentials).
 * Run via: npm run test:firebase
 */
const { describe, it, before, after } = require("node:test");
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const path = require("node:path");
const admin = require("firebase-admin");

const PROJECT_ID = process.env.GCLOUD_PROJECT || "tfg-vday-rules-test";

before(() => {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: PROJECT_ID });
  }
});

after(async () => {
  if (admin.apps.length) {
    await admin.app().delete();
  }
});

describe("init_counters.js (emulator)", () => {
  it("creates and syncs delivery/retail counter pairs", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("Companies"));
    await db.recursiveDelete(db.collection("counter"));

    await db.doc("Companies/acme").set({ Company_name: "Acme", is_active: true });
    await db.doc("counter/acme_delivery").set({ current: 5 });
    // retail missing — script should sync both to 5

    const firebaseRoot = path.resolve(__dirname, "..");
    const result = spawnSync("node", ["scripts/init_counters.js"], {
      cwd: firebaseRoot,
      encoding: "utf8",
      env: { ...process.env, FIREBASE_PROJECT: PROJECT_ID },
    });

    assert.equal(
      result.status,
      0,
      `init_counters failed:\n${result.stderr}\n${result.stdout}`,
    );

    const delivery = (await db.doc("counter/acme_delivery").get()).data();
    const retail = (await db.doc("counter/acme_retail").get()).data();
    const defaultDelivery = (await db.doc("counter/default_delivery").get()).data();
    const defaultRetail = (await db.doc("counter/default_retail").get()).data();

    assert.equal(delivery.current, 5);
    assert.equal(retail.current, 5);
    assert.equal(defaultDelivery.current, 0);
    assert.equal(defaultRetail.current, 0);
  });
});
