const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { verifyShopifyWebhookHmac } = require("./shopify/verify_hmac");
const { importShopifyOrder } = require("./shopify/import_service");
const { sendStaffNoticePush } = require("./staff_notice_push");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FUNCTION_REGION = "asia-southeast1";

function readConfig() {
  const secret =
    process.env.SHOPIFY_WEBHOOK_SECRET ||
    functions.config().shopify?.webhook_secret ||
    "";
  const companyId =
    process.env.SHOPIFY_DEFAULT_COMPANY_ID ||
    functions.config().shopify?.default_company_id ||
    "";
  return { secret, companyId };
}

function rawBodyBuffer(req) {
  if (Buffer.isBuffer(req.rawBody)) {
    return req.rawBody;
  }
  if (typeof req.rawBody === "string") {
    return Buffer.from(req.rawBody, "utf8");
  }
  if (req.body == null) {
    return Buffer.alloc(0);
  }
  return Buffer.from(
    typeof req.body === "string" ? req.body : JSON.stringify(req.body),
    "utf8",
  );
}

/**
 * POST /shopifyOrderCreated
 * Shopify orders/create webhook → ERP order + staff notice + audit log.
 */
exports.shopifyOrderCreated = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return res.status(405).json({ error: "Method not allowed" });
    }

    const { secret, companyId } = readConfig();
    if (!secret) {
      functions.logger.error("SHOPIFY_WEBHOOK_SECRET is not configured");
      return res.status(500).json({ error: "Webhook secret not configured" });
    }
    if (!companyId) {
      functions.logger.error("SHOPIFY_DEFAULT_COMPANY_ID is not configured");
      return res.status(500).json({ error: "Company id not configured" });
    }

    const hmacHeader = req.get("x-shopify-hmac-sha256");
    const rawBody = rawBodyBuffer(req);
    if (!verifyShopifyWebhookHmac(rawBody, hmacHeader, secret)) {
      functions.logger.warn("Shopify HMAC verification failed");
      return res.status(401).json({ error: "Invalid webhook signature" });
    }

    let shopifyOrder;
    try {
      shopifyOrder = JSON.parse(rawBody.toString("utf8"));
    } catch (error) {
      functions.logger.error("Invalid JSON body", error);
      return res.status(400).json({ error: "Invalid JSON body" });
    }

    if (!shopifyOrder?.id) {
      return res.status(400).json({ error: "Missing Shopify order id" });
    }

    try {
      const result = await importShopifyOrder(db, shopifyOrder, companyId);
      functions.logger.info("Shopify order processed", {
        duplicate: result.duplicate,
        externalOrderId: result.externalOrderId,
        orderPath: result.orderRef.path,
      });
      return res.status(200).json({
        ok: true,
        duplicate: result.duplicate,
        orderId: result.orderId,
        externalOrderId: result.externalOrderId,
        externalOrderName: result.externalOrderName,
        orderPath: result.orderRef.path,
        noticesCreated: result.noticesCreated ?? 0,
      });
    } catch (error) {
      functions.logger.error("Shopify import failed", error);
      return res.status(500).json({ error: "Import failed" });
    }
  });

/**
 * staff_notices onCreate → FCM push to recipient devices (background / killed app).
 */
exports.onStaffNoticeCreated = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 30,
    memory: "256MB",
  })
  .firestore.document("staff_notices/{noticeId}")
  .onCreate(async (snap, context) => {
    const notice = snap.data();
    if (!notice?.recipient_user_ref) {
      functions.logger.warn("staff notice missing recipient", {
        noticeId: context.params.noticeId,
      });
      return null;
    }

    try {
      const result = await sendStaffNoticePush(
        db,
        notice,
        context.params.noticeId,
      );
      functions.logger.info("staff notice push sent", {
        noticeId: context.params.noticeId,
        ...result,
      });
      return result;
    } catch (error) {
      functions.logger.error("staff notice push failed", {
        noticeId: context.params.noticeId,
        error,
      });
      return null;
    }
  });
