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
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("users/floristA").set({
      role: "florist",
      email: "floristA@test.com",
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("users/managerB").set({
      role: "manager",
      email: "managerB@test.com",
      companyRef: db.doc("Companies/companyB"),
    });
    await db.doc("users/floristB").set({
      role: "florist",
      email: "floristB@test.com",
      companyRef: db.doc("Companies/companyB"),
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

    await db.doc("materials/matA").set({
      name: "Ribbon",
      unit: "roll",
      price: 2,
      companyRef: db.doc("Companies/companyA"),
    });
    await db.doc("materials/matB").set({
      name: "Wrap",
      unit: "sheet",
      price: 3,
      companyRef: db.doc("Companies/companyB"),
    });
  });
});

function authed(uid) {
  return testEnv.authenticatedContext(uid, { email: `${uid}@test.com` });
}

function authedWithEmail(uid, email) {
  return testEnv.authenticatedContext(uid, { email });
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

  it("driver uploads delivery proof fields on own-company order", async () => {
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.doc("orders/orderA").update({
        delivery_proof_url: "https://example.com/proof.jpg",
        delivery_proof_at: new Date(),
      }),
    );
  });

  it("driver records partial delivery on assigned order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderA").update({
        assigned_driver: db.doc("users/driverA"),
        status: "out_of_delivery",
        orderstatus: "outOfDelivery",
      });
      await db.doc("Order_item/itemA").update({
        orderRef: db.doc("orders/orderA"),
        qty: 10,
        delivered_qty: 0,
      });
    });
    const db = authed("driverA").firestore();
    await assertSucceeds(
      db.doc("Order_item/itemA").update({
        delivered_qty: 5,
        status: "partial",
      }),
    );
    await assertSucceeds(
      db.doc("orders/orderA").update({
        partial_delivery_run_count: 1,
        partial_delivery_runs: [
          {
            run_number: 1,
            delivery_id: "TFG-2026-0001-D1",
            items: [{ item_id: "itemA", qty: 5 }],
          },
        ],
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

  it("senior_florist completes draft order without Order_Id", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderDraft").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderDraft").update({
        client_name: "Imported customer",
        Order_Id: "TFG-JUN26-0002",
        paymentType: "Cash",
      }),
    );
  });

  it("senior_florist updates customer details on pending order with Order_Id", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPending").set({
        Order_Id: "TFG-JUN26-0003",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPending").update({
        client_name: "Updated client",
        recipient_name: "Jane",
        address: "123 Road",
        delivery_date: new Date("2026-06-15"),
        orderType: "Delivery",
        pickup_delivery: "Delivery",
      }),
    );
  });

  it("senior_florist records cash payment on unpaid order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPay").set({
        Order_Id: "TFG-JUN26-0099",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 100,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPay").update({
        paymentType: "Cash",
        amount_paid: 100,
        balance_due: 0,
        cash_received: 100,
        cash_change: 0,
        totalAmount: 100,
        total: 100,
      }),
    );
  });

  it("senior_florist cannot change payment on fully paid order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPaid").set({
        Order_Id: "TFG-JUN26-0100",
        status: "completed",
        orderstatus: "completed",
        totalAmount: 100,
        amount_paid: 100,
        balance_due: 0,
        paymentType: "Cash",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("staffB").firestore();
    await assertFails(
      db.doc("orders/orderPaid").update({
        amount_paid: 80,
        balance_due: 20,
      }),
    );
  });

  it("florist finalizes draft order with payment after exact amount", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderDraftPay").set({
        status: "pending",
        orderstatus: "pending",
        totalAmount: 88,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderDraftPay").update({
        Order_Id: "TFG-JUN26-0200",
        client_name: "Alice",
        recipient_name: "Bob",
        recipient_phone_number: "91234567",
        address: "1 Test St",
        PostalCode: "123456",
        region: "North",
        delivery_date: new Date("2026-06-16"),
        delivery_time_slot: "AM",
        card_message: "Hi",
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        paymentType: "Cash",
        status: "pending",
        orderstatus: "pending",
        amount_paid: 88,
        balance_due: 0,
        cash_received: 88,
        cash_change: 0,
        totalAmount: 88,
        total: 88,
      }),
    );
  });

  it("florist recalculates order totals while building cart", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderTotals").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("Order_item/itemTotals").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderTotals").update({
        totalAmount: 120,
        total: 120,
        totalQty: 3,
        ProductSelection: db.doc("Order_item/itemTotals"),
      }),
    );
  });

  it("admin submits delivery detail form after payment on pending order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/admin").set({
        role: "admin",
        email: "admin@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("customers/custB").set({
        name: "Walk-in",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("orders/orderPaidPending").set({
        Order_Id: "TFG-JUN26-0400",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 80,
        total: 80,
        amount_paid: 80,
        balance_due: 0,
        paymentType: "Cash",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderPaidPending").update({
        client_name: "Alice",
        recipient_name: "Bob",
        recipient_phone_number: "91234567",
        address: "1 Test St",
        PostalCode: "123456",
        region: "Central",
        delivery_date: new Date("2026-06-20"),
        delivery_time_slot: "10:00-12:00",
        card_message: "Hi",
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        customer_phone_number: "",
        customerRef: db.doc("customers/custB"),
        created_time: new Date(),
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("account submits delivery detail after payment when createOrders override is false", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/accountB").set({
        role: "account",
        email: "accountB@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("role_permissions/companyB").set({
        companyRef: db.doc("Companies/companyB"),
        roles: {
          account: { createOrders: false },
        },
      });
      await db.doc("orders/orderAccountPaid").set({
        Order_Id: "TFG-JUN26-0502",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 50,
        total: 50,
        amount_paid: 50,
        balance_due: 0,
        paymentType: "Cash",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("accountB").firestore();
    await assertSucceeds(
      db.doc("orders/orderAccountPaid").update({
        client_name: "Alice",
        recipient_name: "Bob",
        recipient_phone_number: "91234567",
        address: "1 Test St",
        PostalCode: "123456",
        region: "Central",
        delivery_date: new Date("2026-06-20"),
        delivery_time_slot: "10:00-12:00",
        card_message: "Hi",
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        customer_phone_number: "",
        created_time: new Date(),
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("florist progresses delivery order from product selection", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderDeliveryProgress").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyB"),
      });
      await db.doc("Order_item/itemDelivery").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderDeliveryProgress").update({
        Order_Id: "TFG-JUN26-0300",
        client_name: "",
        pickup_delivery: "Delivery",
        totalAmount: 45,
        total: 45,
        ProductSelection: db.doc("Order_item/itemDelivery"),
        totalQty: 1,
        orderType: "Delivery",
        status: "pending",
        orderstatus: "pending",
      }),
    );
  });

  it("florist records payment when balance_due remains on order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPartial").set({
        Order_Id: "TFG-JUN26-0201",
        status: "pending",
        orderstatus: "pending",
        totalAmount: 100,
        amount_paid: 40,
        balance_due: 60,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPartial").update({
        paymentType: "Paynow",
        amount_paid: 100,
        balance_due: 0,
        totalAmount: 100,
        total: 100,
      }),
    );
  });

  it("florist locks material cost snapshot after order is fully paid", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderPaidSnapshot").set({
        Order_Id: "TFG-JUN26-0202",
        status: "pending",
        orderstatus: "pending",
        paymentType: "Cash",
        totalAmount: 88,
        amount_paid: 88,
        balance_due: 0,
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("floristB").firestore();
    await assertSucceeds(
      db.doc("orders/orderPaidSnapshot").update({
        material_usage_cost: 12.5,
        material_cost_snapshot: { "materials/rose": 2.5 },
        material_cost_snapshotted_at: new Date(),
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

  it("florist saves Remark on own-company line item", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("Order_item/itemA").update({ Remark: "Extra ribbon" }),
    );
  });

  it("florist adjusts checkout qty on own-company line item", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Order_item/itemRetail").set({
        name: "Bouquet",
        orderRef: db.doc("orders/orderA"),
        qty: 1,
        price: 50,
        subtotal: 50,
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("Order_item/itemRetail").update({ qty: 2, subtotal: 100 }),
    );
  });

  it("admin saves Remark on line item without companyRef via parent order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Order_item/itemNoCo").set({
        name: "NoCo",
        orderRef: db.doc("orders/orderA"),
        qty: 1,
        price: 5,
        subtotal: 5,
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("Order_item/itemNoCo").update({ Remark: "via order" }),
    );
  });

  it("florist cannot save Remark on other-company line item", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("Order_item/itemB").update({ Remark: "hack" }),
    );
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
  it("florist creates product in own company", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("product/newProd").set({
        name: "Tulip",
        price: 8,
        companyRef: db.doc("Companies/companyA"),
        is_active: true,
      }),
    );
  });

  it("florist creates material in own company", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("materials/newMat").set({
        name: "Stem",
        unit: "stem",
        companyRef: db.doc("Companies/companyA"),
        is_active: true,
      }),
    );
  });

  it("florist cannot create product for other company", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("product/badProd").set({
        name: "Stolen",
        price: 1,
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("driver cannot create product", async () => {
    const db = authed("driverA").firestore();
    await assertFails(
      db.doc("product/driverProd").set({
        name: "No",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("florist updates own product price", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("product/prodA").update({
        price: 15,
        name: "Rose Premium",
      }),
    );
  });

  it("florist updates own material", async () => {
    const db = authed("floristA").firestore();
    await assertSucceeds(
      db.doc("materials/matA").update({
        price: 2.5,
        name: "Ribbon Gold",
      }),
    );
  });

  it("florist cannot update other-company material", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.doc("materials/matB").update({
        price: 99,
      }),
    );
  });

  it("superadmin creates product for another company", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("product/superProd").set({
        name: "Orchid",
        price: 20,
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

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

  it("senior_florist deletes own-company product", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(db.doc("product/prodB").delete());
  });

  it("senior_florist cannot delete other-company product", async () => {
    const db = authed("staffB").firestore();
    await assertFails(db.doc("product/prodA").delete());
  });
});

describe("users staff profiles", () => {
  it("admin deletes florist in own company", async () => {
    const db = authed("admin").firestore();
    await assertSucceeds(db.doc("users/floristA").delete());
  });

  it("admin cannot delete other-company staff", async () => {
    const db = authed("admin").firestore();
    await assertFails(db.doc("users/staffB").delete());
  });

  it("admin cannot delete another admin", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/adminB").set({
        role: "admin",
        email: "adminB@test.com",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("admin").firestore();
    await assertFails(db.doc("users/adminB").delete());
  });

  it("manager deletes florist in own company", async () => {
    const db = authed("managerB").firestore();
    await assertSucceeds(db.doc("users/floristB").delete());
  });

  it("manager cannot delete another manager", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/managerB2").set({
        role: "manager",
        email: "managerB2@test.com",
        companyRef: db.doc("Companies/companyB"),
      });
    });
    const db = authed("managerB").firestore();
    await assertFails(db.doc("users/managerB2").delete());
  });
});

describe("customers tenant writes", () => {
  it("staff creates customer for own company", async () => {
    const db = authed("staffB").firestore();
    await assertSucceeds(
      db.collection("customers").add({
        name: "Jane Tan",
        phone: "91234567",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("staff cannot create customer for other company", async () => {
    const db = authed("staffB").firestore();
    await assertFails(
      db.collection("customers").add({
        name: "Jane Tan",
        phone: "91234567",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("admin reads and updates product_categories for own company", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("product_categories/companyA").set({
        companyRef: db.doc("Companies/companyA"),
        categories: ["Hand Bouquet"],
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(db.doc("product_categories/companyA").get());
    await assertSucceeds(
      db.doc("product_categories/companyA").set(
        {
          companyRef: db.doc("Companies/companyA"),
          categories: ["Hand Bouquet", "Funeral"],
        },
        { merge: true },
      ),
    );
  });

  it("admin with typo companyRef can read and update canonical product_categories doc", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "The Flower Guy",
        is_active: true,
      });
      await db.doc("product_categories/lc3Dhfby8f35Md0E1vZC").set({
        companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
        categories: ["Funeral", "Hand Bouquet"],
      });
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo",
        is_active: true,
      });
      await db.doc("users/typoAdmin").set({
        role: "admin",
        email: "typoAdmin@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
    });
    const db = authed("typoAdmin").firestore();
    await assertSucceeds(
      db.doc("product_categories/lc3Dhfby8f35Md0E1vZC").get(),
    );
    await assertSucceeds(
      db.doc("product_categories/lc3Dhfby8f35Md0E1vZC").set(
        {
          companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
          categories: ["Funeral", "Hand Bouquet", "Others"],
        },
        { merge: true },
      ),
    );
  });

  it("staff with typo companyRef can create customer for canonical company", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "Canonical",
        is_active: true,
      });
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo",
        is_active: true,
      });
      await db.doc("users/typoStaff").set({
        role: "senior_florist",
        email: "typoStaff@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
    });
    const db = authed("typoStaff").firestore();
    await assertSucceeds(
      db.collection("customers").add({
        name: "Typo Co Customer",
        phone: "87571239",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      }),
    );
  });
});

describe("canonical companyRef catalog reads (production menu path)", () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const canonicalCompany = db.doc("Companies/lc3Dhfby8f35Md0E1vZC");
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "The Flower Guy",
        is_active: true,
      });
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo legacy id",
        is_active: true,
      });
      await db.doc("users/typoFlorist").set({
        role: "florist",
        email: "typoFlorist@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
      await db.doc("orders/canonicalOrder").set({
        Order_Id: "TFG-TEST-PROD-MENU",
        status: "pending",
        orderstatus: "pending",
        companyRef: canonicalCompany,
      });
      await db.doc("Order_item/canonicalItem").set({
        name: "Rose Bouquet",
        qty: 1,
        orderRef: db.doc("orders/canonicalOrder"),
        companyRef: canonicalCompany,
      });
      await db.doc("product/canonicalProd").set({
        name: "Rose Bouquet",
        price: 50,
        isActive: true,
        companyRef: canonicalCompany,
        recipeLines: [{ materialName: "Rose", qty: 12, unit: "stem" }],
      });
      await db.doc("materials/matRose").set({
        name: "Rose",
        cost: 1.5,
        unit: "stem",
        companyRef: canonicalCompany,
      });
    });
  });

  it("florist with typo companyRef reads canonical product", async () => {
    const db = authed("typoFlorist").firestore();
    await assertSucceeds(db.doc("product/canonicalProd").get());
  });

  it("florist with typo companyRef reads canonical materials", async () => {
    const db = authed("typoFlorist").firestore();
    await assertSucceeds(db.doc("materials/matRose").get());
  });

  it("florist with typo companyRef reads canonical order line items", async () => {
    const db = authed("typoFlorist").firestore();
    await assertSucceeds(db.doc("orders/canonicalOrder").get());
    await assertSucceeds(db.doc("Order_item/canonicalItem").get());
  });

  it("driver with typo companyRef uploads delivery proof on assigned canonical order", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("users/typoDriver").set({
        role: "driver",
        email: "typoDriver@test.com",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
      await db.doc("orders/canonicalOrder").update({
        assigned_driver: db.doc("users/typoDriver"),
        status: "out_of_delivery",
        orderstatus: "out_of_delivery",
      });
    });
    const db = authed("typoDriver").firestore();
    await assertSucceeds(
      db.doc("orders/canonicalOrder").update({
        delivery_proof_url: "https://example.com/proof.jpg",
        delivery_proof_at: new Date(),
      }),
    );
  });
});

describe("staff registration intents", () => {
  it("blocks users profile create without registration intent", async () => {
    const db = authed("attacker").firestore();
    await assertFails(
      db.doc("users/attacker").set({
        uid: "attacker",
        email: "attacker@test.com",
        role: "admin",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("admin creates registration intent for new hire", async () => {
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("staff_registration_intents/newhire@test.com").set({
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("superadmin creates registration intent for any company", async () => {
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("staff_registration_intents/tenanthire@test.com").set({
        email: "tenanthire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("superadmin can replace stale registration intent (update)", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("staff_registration_intents/stale@test.com").set({
        email: "stale@test.com",
        role: "driver",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("superA").firestore();
    await assertSucceeds(
      db.doc("staff_registration_intents/stale@test.com").set({
        email: "stale@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyB"),
      }),
    );
  });

  it("new hire completes profile when intent matches", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("staff_registration_intents/newhire@test.com").set({
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authedWithEmail("newhire", "newhire@test.com").firestore();
    await assertSucceeds(
      db.doc("users/newhire").set({
        uid: "newhire",
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("new hire completes profile when intent companyRef uses legacy typo id", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("Companies/Ic3Dhfby8f35Md0E1vZC").set({
        Company_name: "Typo legacy id",
        is_active: true,
      });
      await db.doc("Companies/lc3Dhfby8f35Md0E1vZC").set({
        Company_name: "Canonical company",
        is_active: true,
      });
      await db.doc("staff_registration_intents/typohire@test.com").set({
        email: "typohire@test.com",
        role: "driver",
        companyRef: db.doc("Companies/Ic3Dhfby8f35Md0E1vZC"),
      });
    });
    const db = authedWithEmail("typohire", "typohire@test.com").firestore();
    await assertSucceeds(
      db.doc("users/typohire").set({
        uid: "typohire",
        email: "typohire@test.com",
        role: "driver",
        companyRef: db.doc("Companies/lc3Dhfby8f35Md0E1vZC"),
      }),
    );
  });

  it("rejects profile create when intent role mismatches", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("staff_registration_intents/newhire@test.com").set({
        email: "newhire@test.com",
        role: "florist",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authedWithEmail("newhire", "newhire@test.com").firestore();
    await assertFails(
      db.doc("users/newhire").set({
        uid: "newhire",
        email: "newhire@test.com",
        role: "admin",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });
});

describe("legacy companyRef isolation", () => {
  it("staff cannot read order without companyRef", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/legacyOrder").set({
        Order_Id: "TFG-LEGACY-0001",
        status: "pending",
        orderstatus: "pending",
      });
    });
    const db = authed("floristA").firestore();
    await assertFails(db.doc("orders/legacyOrder").get());
  });

  it("superadmin can read order without companyRef", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/legacyRead").set({
        Order_Id: "TFG-LEGACY-0002",
        status: "pending",
        orderstatus: "pending",
      });
    });
    const db = authed("superA").firestore();
    await assertSucceeds(db.doc("orders/legacyRead").get());
  });

  it("admin can progress delivery order when createOrders override is false", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("role_permissions/companyA").set({
        companyRef: db.doc("Companies/companyA"),
        roles: {
          admin: { createOrders: false },
        },
      });
      await db.doc("orders/orderAdminNoCreate").set({
        status: "pending",
        orderstatus: "pending",
      });
      await db.doc("Order_item/itemAdminNoCreate").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderAdminNoCreate").update({ companyRef: db.doc("Companies/companyA") }),
    );
    await assertSucceeds(
      db.doc("orders/orderAdminNoCreate").update({
        Order_Id: "TFG-JUN26-0501",
        pickup_delivery: "Delivery",
        totalAmount: 45,
        total: 45,
        ProductSelection: db.doc("Order_item/itemAdminNoCreate"),
        totalQty: 1,
        orderType: "Delivery",
        status: "pending",
        orderstatus: "pending",
      }),
    );
  });

  it("admin can progress delivery order from product selection", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc("orders/orderAdminDelivery").set({
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyA"),
      });
      await db.doc("Order_item/itemAdminDelivery").set({
        name: "Rose",
        companyRef: db.doc("Companies/companyA"),
      });
    });
    const db = authed("admin").firestore();
    await assertSucceeds(
      db.doc("orders/orderAdminDelivery").update({
        Order_Id: "TFG-JUN26-0500",
        client_name: "",
        pickup_delivery: "Delivery",
        totalAmount: 45,
        total: 45,
        ProductSelection: db.doc("Order_item/itemAdminDelivery"),
        totalQty: 1,
        orderType: "Delivery",
        status: "pending",
        orderstatus: "pending",
        companyRef: db.doc("Companies/companyA"),
      }),
    );
  });

  it("superadmin can save role_permissions without profile companyRef", async () => {
    const db = authed("superA").firestore();
    const companyRef = db.doc("Companies/companyA");
    await assertSucceeds(
      db.doc("role_permissions/companyA").set({
        companyRef,
        roles: {
          admin: { createOrders: true },
        },
        updated_time: new Date(),
      }),
    );
  });

  it("superadmin cannot save role_permissions with mismatched companyRef", async () => {
    const db = authed("superA").firestore();
    const companyRef = db.doc("Companies/companyB");
    await assertFails(
      db.doc("role_permissions/companyA").set({
        companyRef,
        roles: {
          admin: { createOrders: true },
        },
        updated_time: new Date(),
      }),
    );
  });

  it("staff cannot create order without companyRef", async () => {
    const db = authed("floristA").firestore();
    await assertFails(
      db.collection("orders").add({
        Order_Id: "TFG-2026-LEGACY",
        status: "pending",
        orderstatus: "pending",
      }),
    );
  });
});
