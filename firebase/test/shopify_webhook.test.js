const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("crypto");
const { verifyShopifyWebhookHmac } = require("../functions/shopify/verify_hmac");
const {
  pickCustomerName,
  resolveOrderType,
  buildShopifyNoticeMessage,
} = require("../functions/shopify/map_order");

describe("verifyShopifyWebhookHmac", () => {
  it("accepts valid HMAC", () => {
    const secret = "test-secret";
    const body = JSON.stringify({ id: 123, name: "#1001" });
    const hmac = crypto
      .createHmac("sha256", secret)
      .update(body, "utf8")
      .digest("base64");
    assert.equal(verifyShopifyWebhookHmac(body, hmac, secret), true);
  });

  it("rejects invalid HMAC", () => {
    const body = JSON.stringify({ id: 123 });
    assert.equal(
      verifyShopifyWebhookHmac(body, "bad-signature", "test-secret"),
      false,
    );
  });
});

describe("map_order helpers", () => {
  it("maps customer name from Shopify payload", () => {
    const name = pickCustomerName({
      customer: { first_name: "Jane", last_name: "Tan" },
    });
    assert.equal(name, "Jane Tan");
  });

  it("detects delivery when shipping address exists", () => {
    assert.equal(
      resolveOrderType({
        shipping_address: { address1: "1 Orchard Rd", city: "Singapore" },
      }),
      "Delivery",
    );
    assert.equal(resolveOrderType({}), "Pick Up");
  });

  it("builds notice message", () => {
    const message = buildShopifyNoticeMessage({
      externalOrderName: "#1001",
      customerName: "Jane Tan",
      totalAmount: "88.00",
    });
    assert.match(message, /Order: #1001/);
    assert.match(message, /Customer: Jane Tan/);
    assert.match(message, /Source: Shopify/);
  });
});
