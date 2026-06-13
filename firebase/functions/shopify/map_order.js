/**
 * Maps a Shopify orders/create payload into ERP order + line item fields.
 * Mirrors lib/backend/order_status_helpers.dart (pending / pending).
 */

const ORDER_CREATED_NOTICE_ROLES = new Set([
  "admin",
  "director",
  "manager",
  "senior_florist",
  "florist",
]);

function pickCustomerName(order) {
  const customer = order.customer || {};
  const shipping = order.shipping_address || {};
  const billing = order.billing_address || {};

  const fromParts = (first, last) =>
    [first, last].filter(Boolean).join(" ").trim();

  return (
    fromParts(customer.first_name, customer.last_name) ||
    fromParts(shipping.first_name, shipping.last_name) ||
    fromParts(billing.first_name, billing.last_name) ||
    order.email ||
    "Shopify Customer"
  );
}

function pickRecipientName(order) {
  const shipping = order.shipping_address || {};
  const name = [shipping.first_name, shipping.last_name]
    .filter(Boolean)
    .join(" ")
    .trim();
  return name || pickCustomerName(order);
}

function formatShippingAddress(address) {
  if (!address) {
    return "";
  }
  return [
    address.address1,
    address.address2,
    address.city,
    address.province,
    address.zip,
    address.country,
  ]
    .filter(Boolean)
    .join(", ");
}

function resolveOrderType(order) {
  const shipping = order.shipping_address || {};
  const hasShipping =
    Boolean(shipping.address1) ||
    Boolean(shipping.city) ||
    Boolean(shipping.zip);
  if (hasShipping) {
    return "Delivery";
  }
  if (Array.isArray(order.fulfillment_orders) && order.fulfillment_orders.length) {
    return "Delivery";
  }
  return "Pick Up";
}

function lineItemSummary(lineItems) {
  if (!Array.isArray(lineItems) || lineItems.length === 0) {
    return "Shopify order";
  }
  return lineItems
    .slice(0, 3)
    .map((item) => {
      const qty = Number(item.quantity || 1);
      const name = item.name || item.title || "Item";
      return `${qty}x ${name}`;
    })
    .join(", ");
}

function mapShopifyLineItems(lineItems, orderRef, companyRef, erpOrderId) {
  if (!Array.isArray(lineItems)) {
    return [];
  }
  return lineItems.map((item) => {
    const qty = Number(item.quantity || 1);
    const price = Number(item.price || 0);
    const subtotal = price * qty;
    const variant = item.variant_title ? ` (${item.variant_title})` : "";
    return {
      orderRef,
      companyRef,
      name: `${item.name || item.title || "Shopify item"}${variant}`,
      qty,
      price,
      subtotal,
      sku: item.sku || "",
      orderId: erpOrderId,
      status: "pending",
    };
  });
}

function buildShopifyNoticeMessage({
  externalOrderName,
  customerName,
  totalAmount,
}) {
  return [
    `Order: ${externalOrderName}`,
    `Customer: ${customerName}`,
    `Total: ${totalAmount}`,
    "Source: Shopify",
  ].join("\n");
}

function isActiveStaffRecipient(userData) {
  if (userData.is_active === false) {
    return false;
  }
  return ORDER_CREATED_NOTICE_ROLES.has(userData.role);
}

function staffNoticeRecipientRef(db, userDoc) {
  const data = userDoc.data();
  const uid = data.uid || userDoc.id;
  return db.collection("users").doc(uid);
}

module.exports = {
  ORDER_CREATED_NOTICE_ROLES,
  pickCustomerName,
  pickRecipientName,
  formatShippingAddress,
  resolveOrderType,
  lineItemSummary,
  mapShopifyLineItems,
  buildShopifyNoticeMessage,
  isActiveStaffRecipient,
  staffNoticeRecipientRef,
};
