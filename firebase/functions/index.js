const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { verifyShopifyWebhookHmac } = require("./shopify/verify_hmac");
const { importShopifyOrder } = require("./shopify/import_service");
const { sendStaffNoticePush } = require("./staff_notice_push");
const {
  syncStaffAuthClaims,
  driverUidFromAssignedRef,
} = require("./staff_auth_claims");
const {
  BUSINESS_TIMEZONE,
  sendTomorrowPrepReminders,
  sendTodayOpsReminders,
} = require("./operation_reminders");

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
  .region(FUNCTION_REGION)
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

/**
 * Keep driver assignedOrderIds custom claims in sync for Storage delivery proof uploads.
 */
exports.onOrderAssignedDriverChanged = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 30,
    memory: "256MB",
  })
  .firestore.document("orders/{orderId}")
  .onWrite(async (change, context) => {
    const beforeDriver = driverUidFromAssignedRef(
      change.before.exists ? change.before.data()?.assigned_driver : null,
    );
    const afterDriver = driverUidFromAssignedRef(
      change.after.exists ? change.after.data()?.assigned_driver : null,
    );

    const uids = new Set([beforeDriver, afterDriver].filter(Boolean));
    if (uids.size === 0) {
      return null;
    }

    const results = [];
    for (const uid of uids) {
      try {
        results.push(await syncStaffAuthClaims(db, uid));
      } catch (error) {
        functions.logger.error("driver claims sync failed", {
          orderId: context.params.orderId,
          uid,
          error,
        });
      }
    }

    functions.logger.info("driver claims sync complete", {
      orderId: context.params.orderId,
      results,
    });
    return results;
  });

/**
 * Sync role/company claims when a staff profile is created or updated.
 */
exports.onStaffUserProfileChanged = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 30,
    memory: "256MB",
  })
  .firestore.document("users/{userId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) {
      return null;
    }
    try {
      const result = await syncStaffAuthClaims(db, context.params.userId);
      functions.logger.info("staff claims sync complete", result);
      return result;
    } catch (error) {
      functions.logger.error("staff claims sync failed", {
        userId: context.params.userId,
        error,
      });
      return null;
    }
  });

/**
 * Weekday close (Mon–Fri 19:00 SGT): remind staff about tomorrow's unfinished orders.
 * Friday run covers Sat + Sun + Mon.
 */
exports.scheduledTomorrowPrepReminderWeekday = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .pubsub.schedule("0 19 * * 1-5")
  .timeZone(BUSINESS_TIMEZONE)
  .onRun(async () => {
    const results = await sendTomorrowPrepReminders(db, new Date());
    functions.logger.info("tomorrow prep reminder (weekday)", { results });
    return results;
  });

/**
 * Weekend close (Sat–Sun 16:00 SGT): remind staff about tomorrow's unfinished orders.
 */
exports.scheduledTomorrowPrepReminderWeekend = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .pubsub.schedule("0 16 * * 0,6")
  .timeZone(BUSINESS_TIMEZONE)
  .onRun(async () => {
    const results = await sendTomorrowPrepReminders(db, new Date());
    functions.logger.info("tomorrow prep reminder (weekend)", { results });
    return results;
  });

/**
 * Daily open (09:15 SGT): remind staff about today's unfinished delivery orders.
 */
exports.scheduledTodayOpsReminder = functions
  .region(FUNCTION_REGION)
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .pubsub.schedule("15 9 * * *")
  .timeZone(BUSINESS_TIMEZONE)
  .onRun(async () => {
    const results = await sendTodayOpsReminders(db, new Date());
    functions.logger.info("today ops reminder", { results });
    return results;
  });
