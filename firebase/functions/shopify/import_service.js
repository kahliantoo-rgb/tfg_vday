const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { nextDeliveryOrderId } = require("./order_id_helpers");

const {
  pickCustomerName,
  pickRecipientName,
  formatShippingAddress,
  resolveOrderType,
  lineItemSummary,
  mapShopifyLineItems,
  buildShopifyNoticeMessage,
  isActiveStaffRecipient,
  staffNoticeRecipientRef,
} = require("./map_order");

const AUDIT_ACTION = "shopify_order_imported";
const NOTICE_TYPE = "shopify_order_imported";

async function findExistingShopifyOrder(db, companyRef, externalOrderId) {
  const snap = await db
    .collection("orders")
    .where("source", "==", "shopify")
    .where("externalOrderId", "==", String(externalOrderId))
    .where("companyRef", "==", companyRef)
    .limit(1)
    .get();
  return snap.empty ? null : snap.docs[0];
}

async function loadNoticeRecipients(db, companyRef) {
  const companyId = companyRef.id;
  const snap = await db.collection("users").get();
  return snap.docs.filter((doc) => {
    const data = doc.data();
    if (!isActiveStaffRecipient(data)) {
      return false;
    }
    const userCompanyId = data.companyRef?.id;
    return userCompanyId === companyId;
  });
}

/**
 * Imports a Shopify order into Firestore (orders + Order_item + staff_notices + audit_logs).
 * Idempotent by source + externalOrderId + companyRef.
 *
 * @returns {Promise<{duplicate: boolean, orderRef: FirebaseFirestore.DocumentReference, orderId: string}>}
 */
async function importShopifyOrder(db, shopifyOrder, companyId) {
  const companyRef = db.collection("Companies").doc(companyId);
  const companySnap = await companyRef.get();
  if (!companySnap.exists) {
    throw new Error(`Companies/${companyId} does not exist`);
  }

  const externalOrderId = String(shopifyOrder.id);
  const externalOrderName =
    shopifyOrder.name || `#${shopifyOrder.order_number || shopifyOrder.id}`;

  const existing = await findExistingShopifyOrder(db, companyRef, externalOrderId);
  if (existing) {
    return {
      duplicate: true,
      orderRef: existing.ref,
      orderId: existing.data().Order_Id || externalOrderName,
      externalOrderId,
      externalOrderName,
    };
  }

  const customerName = pickCustomerName(shopifyOrder);
  const recipientName = pickRecipientName(shopifyOrder);
  const shipping = shopifyOrder.shipping_address || {};
  const address = formatShippingAddress(shipping);
  const orderType = resolveOrderType(shopifyOrder);
  const lineItems = shopifyOrder.line_items || [];
  const totalAmount = Number(shopifyOrder.total_price || 0);
  const totalQty = lineItems.reduce(
    (sum, item) => sum + Number(item.quantity || 0),
    0,
  );
  const erpOrderId = await nextDeliveryOrderId(db);
  const now = FieldValue.serverTimestamp();
  const paymentType =
    shopifyOrder.financial_status === "paid" ? "Shopify" : "";

  const orderRef = db.collection("orders").doc();
  const orderData = {
    client_name: customerName,
    recipient_name: recipientName,
    address,
    region: shipping.province || shipping.city || "",
    PostalCode: shipping.zip || "",
    customer_phone_number:
      shopifyOrder.phone ||
      shopifyOrder.customer?.phone ||
      shipping.phone ||
      "",
    recipient_phone_number: shipping.phone || shopifyOrder.phone || "",
    card_message: shopifyOrder.note || "",
    Order_Id: erpOrderId,
    orderType,
    pickup_delivery: orderType,
    paymentType,
    amount_paid: paymentType ? totalAmount : 0,
    total: totalAmount,
    totalAmount,
    totalQty,
    status: "pending",
    orderstatus: "pending",
    companyRef,
    created_time: now,
    source: "shopify",
    externalOrderId,
    externalOrderName,
  };

  if (paymentType) {
    const {
      buildMaterialCostSnapshotPatch,
    } = require("./material_cost_snapshot");
    const [materialSnap, productSnap] = await Promise.all([
      db.collection("materials").where("companyRef", "==", companyRef).get(),
      db.collection("product").where("companyRef", "==", companyRef).get(),
    ]);
    const materialsByPath = new Map();
    for (const doc of materialSnap.docs) {
      materialsByPath.set(doc.ref.path, {
        cost: Number(doc.data().cost || 0),
      });
    }
    const products = productSnap.docs.map((doc) => ({
      id: doc.id,
      name: doc.data().name || "",
      recipeLines: doc.data().recipeLines || [],
    }));
    const shopifyItems = mapShopifyLineItems(
      lineItems,
      orderRef,
      companyRef,
      erpOrderId,
    ).map((item) => ({
      ...item,
      productRef: item.productRef || null,
    }));
    Object.assign(
      orderData,
      buildMaterialCostSnapshotPatch({
        orderItems: shopifyItems,
        products,
        materialsByPath,
      }),
    );
  }

  const batch = db.batch();
  batch.set(orderRef, orderData);

  const mappedItems = mapShopifyLineItems(
    lineItems,
    orderRef,
    companyRef,
    erpOrderId,
  );
  for (const item of mappedItems) {
    const itemRef = db.collection("Order_item").doc();
    batch.set(itemRef, item);
  }

  const itemSummary = lineItemSummary(lineItems);
  const noticeMessage = buildShopifyNoticeMessage({
    externalOrderName,
    customerName,
    totalAmount: totalAmount.toFixed(2),
  });

  const recipients = await loadNoticeRecipients(db, companyRef);
  for (const recipient of recipients) {
    const noticeRef = db.collection("staff_notices").doc();
    batch.set(noticeRef, {
      type: NOTICE_TYPE,
      recipient_user_ref: staffNoticeRecipientRef(db, recipient),
      order_ref: orderRef,
      order_id: erpOrderId,
      delivery_date: Timestamp.now(),
      item_summary: itemSummary,
      message: noticeMessage,
      created_time: now,
      companyRef,
    });
  }

  const auditRef = db.collection("audit_logs").doc();
  batch.set(auditRef, {
    userId: "shopify_webhook",
    userName: "Shopify Webhook",
    userRole: "system",
    action: AUDIT_ACTION,
    entityType: "order",
    entityId: orderRef.id,
    entityLabel: erpOrderId,
    description: "Shopify Order Imported",
    companyId,
    companyRef,
    newValue: {
      shopifyOrderId: externalOrderId,
      shopifyOrderName: externalOrderName,
      customerName,
      erpOrderId,
    },
    createdAt: now,
    created_at: now,
  });

  await batch.commit();

  return {
    duplicate: false,
    orderRef,
    orderId: erpOrderId,
    externalOrderId,
    externalOrderName,
    noticesCreated: recipients.length,
  };
}

module.exports = {
  AUDIT_ACTION,
  NOTICE_TYPE,
  findExistingShopifyOrder,
  importShopifyOrder,
};
