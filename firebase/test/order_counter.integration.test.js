/**
 * Integration: order ID counter transaction + order doc create (emulator).
 * Mirrors OrderIdService in lib/backend/order_id_service.dart.
 * Run via: npm run test:firebase
 */
const { describe, it, before, after } = require("node:test");
const assert = require("node:assert/strict");
const admin = require("firebase-admin");
const {
  incrementCounter,
  nextDeliveryOrderId,
  nextRetailOrderId,
  orderPeriodSuffix,
} = require("../scripts/order_id_helpers");

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

describe("order counter + order create (emulator)", () => {
  it("incrementCounter advances delivery and retail independently", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("counter"));

    const period = orderPeriodSuffix();
    await db.doc(`counter/default_delivery_${period}`).set({ current: 7 });
    await db.doc(`counter/default_retail_${period}`).set({ current: 3 });

    const nextDelivery = await incrementCounter(db, "delivery");
    const nextRetail = await incrementCounter(db, "retail");
    assert.equal(nextDelivery, 8);
    assert.equal(nextRetail, 4);

    const delivery = (await db.doc(`counter/default_delivery_${period}`).get()).data();
    const retail = (await db.doc(`counter/default_retail_${period}`).get()).data();
    assert.equal(delivery.current, 8);
    assert.equal(retail.current, 4);
  });

  it("nextDeliveryOrderId increments counter and creates orders doc", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("counter"));
    await db.recursiveDelete(db.collection("orders"));

    const period = orderPeriodSuffix();
    await db.doc(`counter/default_delivery_${period}`).set({ current: 10 });
    await db.doc(`counter/default_retail_${period}`).set({ current: 10 });

    const orderId = await nextDeliveryOrderId(db);
    assert.match(orderId, new RegExp(`^TFG-${period}-00011$`));

    const orderRef = db.collection("orders").doc();
    await orderRef.set({
      Order_Id: orderId,
      orderType: "Delivery",
      status: "pending",
      orderstatus: "pending",
      companyRef: db.doc("Companies/acme"),
    });

    const saved = (await orderRef.get()).data();
    assert.equal(saved.Order_Id, orderId);

    const delivery = (await db.doc(`counter/default_delivery_${period}`).get()).data();
    const retail = (await db.doc(`counter/default_retail_${period}`).get()).data();
    assert.equal(delivery.current, 11);
    assert.equal(retail.current, 10);
  });

  it("retail and delivery IDs use independent counters", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("counter"));

    const deliveryId = await nextDeliveryOrderId(db);
    const retailId = await nextRetailOrderId(db);

    const period = orderPeriodSuffix();
    assert.match(deliveryId, new RegExp(`^TFG-${period}-0001$`));
    assert.equal(retailId, `TFG-${period}-WI0001`);

    const delivery = (await db.doc(`counter/default_delivery_${period}`).get()).data();
    const retail = (await db.doc(`counter/default_retail_${period}`).get()).data();
    assert.equal(delivery.current, 1);
    assert.equal(retail.current, 1);
  });

  it("counter resets when month period changes", async () => {
    const db = admin.firestore();
    await db.recursiveDelete(db.collection("counter"));

    await db.doc("counter/default_delivery_JUN26").set({ current: 99 });
    const seq = await incrementCounter(db, "delivery", null, "JUL26");
    assert.equal(seq, 1);

    const july = (await db.doc("counter/default_delivery_JUL26").get()).data();
    assert.equal(july.current, 1);
    const june = (await db.doc("counter/default_delivery_JUN26").get()).data();
    assert.equal(june.current, 99);
  });
});
