/**
 * Regression: admin must update own-company orders (checkout path).
 */
const fs = require("fs");
const path = require("path");
const { describe, it, before, after, beforeEach } = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "tfg-vday-admin-update-test";
const RULES = fs.readFileSync(
  path.resolve(__dirname, "../firestore.rules"),
  "utf8",
);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
      Company_name: "The Flower Guy",
      is_active: true,
    });
    await db.doc("users/adminProd").set({
      role: "admin",
      email: "yanyitoo1025@gmail.com",
      companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
      uid: "adminProd",
    });
    await db.doc("orders/draft1").set({
      created_time: new Date(),
      companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
    });
  });
});

function authed(uid) {
  return testEnv.authenticatedContext(uid, {
    email: "yanyitoo1025@gmail.com",
  });
}

describe("admin order update (production tenant)", () => {
  it("admin updates client_name on own-company draft", async () => {
    const db = authed("adminProd").firestore();
    await assertSucceeds(
      db.doc("orders/draft1").update({ client_name: "Test client" }),
    );
  });

  it("admin checkout-finalize own-company draft", async () => {
    const db = authed("adminProd").firestore();
    await assertSucceeds(
      db.doc("orders/draft1").update({
        Order_Id: "TFG-JUN26-0500",
        pickup_delivery: "Delivery",
        totalAmount: 45,
        total: 45,
        totalQty: 1,
        orderType: "Delivery",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
      }),
    );
  });
});
