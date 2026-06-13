const admin = require("firebase-admin");

const ANDROID_CHANNEL_ID = "tfg_staff_notices";

function staffNoticeTitle(type) {
  switch (type) {
    case "driver_assigned":
      return "Delivery assigned";
    case "shopify_order_imported":
      return "New Shopify Order";
    case "order_created":
    default:
      return "New order";
  }
}

function formatDeliveryDate(value) {
  if (!value) {
    return "-";
  }
  const date = value.toDate ? value.toDate() : new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "-";
  }
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  return `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`;
}

function staffNoticeBody(notice) {
  if (notice.type === "shopify_order_imported" && notice.message) {
    return notice.message;
  }
  const parts = [];
  if (notice.order_id) {
    parts.push(`Order ${notice.order_id}`);
  }
  parts.push(`Delivery ${formatDeliveryDate(notice.delivery_date)}`);
  if (notice.item_summary) {
    parts.push(notice.item_summary);
  }
  return parts.join("\n");
}

function orderRefPath(notice) {
  if (!notice.order_ref) {
    return "";
  }
  if (typeof notice.order_ref === "string") {
    return notice.order_ref;
  }
  if (notice.order_ref.path) {
    return notice.order_ref.path;
  }
  return "";
}

async function loadRecipientTokenDocs(db, recipientUserRef) {
  if (!recipientUserRef || !recipientUserRef.id) {
    return [];
  }
  const snap = await db
    .collection("users")
    .doc(recipientUserRef.id)
    .collection("fcm_tokens")
    .get();
  return snap.docs.filter((doc) => {
    const token = doc.data().token;
    return typeof token === "string" && token.length > 0;
  });
}

async function pruneInvalidTokens(responses, tokenDocs) {
  const batch = admin.firestore().batch();
  let deletes = 0;
  responses.forEach((response, index) => {
    if (response.success) {
      return;
    }
    const code = response.error?.code || "";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      batch.delete(tokenDocs[index].ref);
      deletes += 1;
    }
  });
  if (deletes > 0) {
    await batch.commit();
  }
  return deletes;
}

async function sendStaffNoticePush(db, notice, noticeId) {
  const tokenDocs = await loadRecipientTokenDocs(db, notice.recipient_user_ref);
  if (tokenDocs.length === 0) {
    return { sent: 0, failed: 0, pruned: 0 };
  }

  const tokens = tokenDocs.map((doc) => doc.data().token);
  const title = staffNoticeTitle(notice.type);
  const body = staffNoticeBody(notice);
  const orderPath = orderRefPath(notice);

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title,
      body: body.replace(/\n/g, " · "),
    },
    data: {
      noticeId: noticeId || "",
      orderPath,
      type: notice.type || "",
      title,
      body,
    },
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  });

  const sent = response.successCount;
  const failed = response.failureCount;
  const pruned = await pruneInvalidTokens(response.responses, tokenDocs);
  return { sent, failed, pruned };
}

module.exports = {
  staffNoticeTitle,
  staffNoticeBody,
  sendStaffNoticePush,
};
