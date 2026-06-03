/**
 * Integration: order ID counter transaction + order doc create (emulator).
 * Mirrors OrderIdService in lib/backend/order_id_service.dart.
 * Run via: npm run test:firebase
 */
const { describe, it, before, after } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const {
  incrementSharedCounter,
  nextDeliveryOrderId,
  nextRetailOrderId,
} = require("../scripts/order_id_helpers");

const PROJECT_ID = process.env.GCLOUD_PROJECT || "tfg-vday-rules-test";
const COMPANY_ID = "acme";

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

describe("order counter + order create (emulator)", () => {
  it("incrementCounter advances delivery and retail independently", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("counter"));

    await db.doc(`counter/${COMPANY_ID}_delivery`).set({ current: 7 });
    await db.doc(`counter/${COMPANY_ID}_retail`).set({ current: 3 });

    const { incrementCounter } = require("../scripts/order_id_helpers");
    const nextDelivery = await incrementCounter(db, COMPANY_ID, "delivery");
    const nextRetail = await incrementCounter(db, COMPANY_ID, "retail");
    assert.equal(nextDelivery, 8);
    assert.equal(nextRetail, 4);

    const delivery = (await db.doc(`counter/${COMPANY_ID}_delivery`).get()).data();
    const retail = (await db.doc(`counter/${COMPANY_ID}_retail`).get()).data();
    assert.equal(delivery.current, 8);
    assert.equal(retail.current, 4);
  });

  it("nextDeliveryOrderId increments counter and creates orders doc", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("counter"));
    await db.recursiveDelete(db.collection("orders"));

    await db.doc(`counter/${COMPANY_ID}_delivery`).set({ current: 10 });
    await db.doc(`counter/${COMPANY_ID}_retail`).set({ current: 10 });

    const orderId = await nextDeliveryOrderId(db, COMPANY_ID);
    const year = new Date().getFullYear();
    assert.match(orderId, new RegExp(`^TFG-${year}-0011$`));

    const orderRef = db.collection("orders").doc();
    await orderRef.set({
      Order_Id: orderId,
      orderType: "Delivery",
      status: "pending",
      orderstatus: "pending",
      companyRef: db.doc(`Companies/${COMPANY_ID}`),
    });

    const saved = (await orderRef.get()).data();
    assert.equal(saved.Order_Id, orderId);

    const delivery = (await db.doc(`counter/${COMPANY_ID}_delivery`).get()).data();
    const retail = (await db.doc(`counter/${COMPANY_ID}_retail`).get()).data();
    assert.equal(delivery.current, 11);
    assert.equal(retail.current, 11);
  });

  it("retail and delivery IDs use independent counters", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("counter"));

    const deliveryId = await nextDeliveryOrderId(db, "default");
    const retailId = await nextRetailOrderId(db, "default");

    const year = new Date().getFullYear();
    assert.match(deliveryId, new RegExp(`^TFG-${year}-0001$`));
    assert.equal(retailId, "TFG-WI0001");

    const delivery = (await db.doc("counter/default_delivery").get()).data();
    const retail = (await db.doc("counter/default_retail").get()).data();
    assert.equal(delivery.current, 1);
    assert.equal(retail.current, 1);
  });
});
