const crypto = require("crypto");

/**
 * Validates Shopify x-shopify-hmac-sha256 against the raw request body.
 * @param {Buffer|string} rawBody
 * @param {string|undefined} hmacHeader
 * @param {string} secret
 */
function verifyShopifyWebhookHmac(rawBody, hmacHeader, secret) {
  if (!secret || !hmacHeader || rawBody == null) {
    return false;
  }

  const digest = crypto
    .createHmac("sha256", secret)
    .update(rawBody, "utf8")
    .digest("base64");

  const expected = Buffer.from(digest, "utf8");
  const received = Buffer.from(hmacHeader, "utf8");
  if (expected.length !== received.length) {
    return false;
  }
  return crypto.timingSafeEqual(expected, received);
}

module.exports = { verifyShopifyWebhookHmac };
