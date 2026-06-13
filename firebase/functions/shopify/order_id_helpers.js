/**
 * Mirrors lib/backend/order_id_service.dart and firebase/scripts/order_id_helpers.js
 */

const MONTHS = [
  "JAN",
  "FEB",
  "MAR",
  "APR",
  "MAY",
  "JUN",
  "JUL",
  "AUG",
  "SEP",
  "OCT",
  "NOV",
  "DEC",
];

function orderPeriodSuffix(date = new Date()) {
  const month = MONTHS[date.getMonth()];
  const year = String(date.getFullYear()).slice(-2);
  return `${month}${year}`;
}

function counterDocId(channel, period = orderPeriodSuffix()) {
  const base =
    channel === "delivery"
      ? "default_delivery"
      : channel === "retail"
        ? "default_retail"
        : `default_${channel}`;
  return `${base}_${period}`;
}

async function incrementCounter(db, channel = "delivery") {
  const counterRef = db.collection("counter").doc(counterDocId(channel));
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const current = snap.exists ? Number(snap.data().current ?? 0) : 0;
    const next = current + 1;
    tx.set(counterRef, { current: next }, { merge: true });
    return next;
  });
}

async function nextDeliveryOrderId(db) {
  const period = orderPeriodSuffix();
  const seq = await incrementCounter(db, "delivery");
  return `TFG-${period}-000${seq}`;
}

module.exports = {
  orderPeriodSuffix,
  counterDocId,
  incrementCounter,
  nextDeliveryOrderId,
};
