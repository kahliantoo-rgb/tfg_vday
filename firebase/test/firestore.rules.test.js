/**
 * Firestore security rules — tenant isolation regression tests.
 * Run: npm run test:rules (from firebase/)
 */
const fs = require("fs");
const path = require("path");
const { describe, it, before, after, beforeEach } = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "tfg-vday-rules-test";
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
    await db.doc("Companies/companyA").set({ Company_name: "A", is_active: true });
    await db.doc("Companies/companyB").set({ Company_name: "B", is_active: true });

    await db.doc("users/driverA").set({
      role: "driver",
      email: "driverA@test.com",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("users/staffB").set({
      role: "senior_florist",
      email: "staffB@test.com",
      companyRef: db.doc("Companies/companyB"),
    });
    await db.doc("users/superA").set({
      role: "superadmin",
      email: "superA@test.com",
    });
    await db.doc("users/admin").set({
      role: "admin",
      email: "admin@test.com",
    });

    await db.doc("orders/orderA").set({
      Order_Id: "TFG-2026-0001",
      status: "pending",
      orderstatus: "pending",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("orders/orderB").set({
      Order_Id: "TFG-2026-0002",
      status: "pending",
      orderstatus: "pending",
      companyRef: db.doc("Companies/companyB"),
    });

    await db.doc("Order_item/itemA").set({
      name: "Rose",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("Order_item/itemB").set({
      name: "Lily",
      companyRef: db.doc("Companies/companyB"),
    });

    await db.doc("counter/companyA_delivery").set({ current: 1 });
    await db.doc("counter/companyB_delivery").set({ current: 1 });

    await db.doc("product/prodA").set({
      name: "Rose",
      price: 10,
      image: "",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("product/prodB").set({
      name: "Lily",
      price: 12,
      image: "",
      companyRef: db.doc("Companies/companyB"),
    });
  });
});

function authed(uid) {
  return testEnv.authenticatedContext(uid, { email: `${uid}@test.com` });
}

describe("orders tenant isolation", () => {
  it("driver reads own-company order", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(db.doc("orders/orderA").get());
  });

  it("driver cannot read other-company order", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("orders/orderB").get());
  });

  it("driver updates status on own-company order", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.doc("orders/orderA").update({
        status: "out_of_delivery",
        orderstatus: "outOfDelivery",
      }),
    );
  });

  it("driver cannot update other-company order", async () => {
    const db = authed("driverA").firestore();
    await assertFails(
      db.doc("orders/orderB").update({
        status: "completed",
        orderstatus: "completed",
      }),
    );
  });

  it("senior_florist reads own-company order only", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(db.doc("orders/orderB").get());
    await assertFails(db.doc("orders/orderA").get());
  });

  it("superadmin reads cross-company orders", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(db.doc("orders/orderA").get());
    await assertSucceeds(db.doc("orders/orderB").get());
  });

  it("senior_florist creates order for own company", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.collection("orders").add({
        Order_Id: "TFG-2026-0099",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("senior_florist cannot create order for other company", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.collection("orders").add({
        Order_Id: "TFG-2026-0100",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("senior_florist updates status only on own-company order", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderB").update({
        status: "processing",
        orderstatus: "processing",
      }),
    );
  });

  it("senior_florist cannot assign driver on order", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.doc("orders/orderB").update({
        assigned_driver: db.doc("users/driverA"),
      }),
    );
  });

  it("admin updates order fields on own company", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/admin").set({
        role: "admin",
        email: "admin@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("orders/orderB").set({
        Order_Id: "TFG-2026-0002",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderB").update({
        client_name: "Updated Client",
        assigned_driver: db.doc("users/driverA"),
      }),
    );
  });
});

describe("Order_item tenant isolation", () => {
  it("driver reads own-company line item", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(db.doc("Order_item/itemA").get());
  });

  it("driver cannot read other-company line item", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("Order_item/itemB").get());
  });
});

describe("counter tenant isolation", () => {
  it("driver reads own-company counter", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(db.doc("counter/companyA_delivery").get());
  });

  it("driver cannot read other-company counter", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("counter/companyB_delivery").get());
  });
});

describe("audit_logs", () => {
  it("driver cannot read audit log", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.collection("audit_logs").doc("log1").get());
  });

  it("senior florist cannot read audit log", async () => {
    const db = authed("staffB").firestore();
    await assertFails(db.collection("audit_logs").doc("log1").get());
  });

  it("admin reads audit log", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("audit_logs").doc("log1").set({
        action: "create_order",
        companyId: "companyA",
        userId: "admin",
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(db.collection("audit_logs").doc("log1").get());
  });

  it("authenticated user creates audit log", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.collection("audit_logs").add({
        action: "print_receipt",
        entityType: "receipt",
        entityId: "orderA",
        userId: "driverA",
      }),
    );
  });

  it("audit log cannot be updated", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("audit_logs").doc("log1").set({
        action: "create_order",
        userId: "admin",
      });
    });
    const db = authed("admin").firestore();
    await assertFails(
      db.collection("audit_logs").doc("log1").update({ action: "hack" }),
    );
  });
});

describe("legacy counters collection", () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("counters/legacy1").set({ current: 1 });
    });
  });

  it("driver cannot read legacy counters collection", async () => {
    const db = authed("driverA").firestore();
    await assertFails(db.doc("counters/legacy1").get());
  });

  it("senior_florist updates own-company counter", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("counter/companyB_delivery").update({ current: 2 }),
    );
  });
});

describe("product catalog", () => {
  it("senior_florist updates image on own-company product", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("product/prodB").update({
        image: "https://example.com/rose.jpg",
      }),
    );
  });

  it("senior_florist cannot update other-company product", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.doc("product/prodA").update({
        image: "https://example.com/rose.jpg",
      }),
    );
  });
});
