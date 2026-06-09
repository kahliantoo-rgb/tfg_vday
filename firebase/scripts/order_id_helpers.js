/**
 * Mirrors lib/backend/order_id_service.dart — shared default_* counter transactions.
 * Used by emulator integration tests and optional scripts.
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
  let base;
  if (channel === "delivery") {
    base = "default_delivery";
  } else if (channel === "retail") {
    base = "default_retail";
  } else {
    base = `default_${channel}`;
  }
  return `${base}_${period}`;
}

/**
 * @param {import('firebase-admin').firestore.Firestore} db
 * @param {string} channel
 * @param {import('firebase-admin').firestore.DocumentReference | null} comR
 * @param {string} [period]
 * @returns {Promise<number>} next sequence number
 */
async function incrementCounter(db, channel = "delivery", comR = null, period) {
  const counterRef = db.collection("counter").doc(counterDocId(channel, period));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const current = snap.exists ? Number(snap.data().current ?? 0) : 0;
    const next = current + 1;
    const payload = { current: next };
    if (comR) {
      payload.comR = comR;
    }
    tx.set(counterRef, payload, { merge: true });
    return next;
  });
}

/** @deprecated Use incrementCounter — kept for older tests/scripts. */
async function incrementSharedCounter(db, _companyId = "default", comR = null) {
  return incrementCounter(db, "delivery", comR);
}

/**
 * @param {import('firebase-admin').firestore.Firestore} db
 */
async function nextDeliveryOrderId(db) {
  const period = orderPeriodSuffix();
  const seq = await incrementCounter(db, "delivery");
  return `TFG-${period}-000${seq}`;
}

/**
 * @param {import('firebase-admin').firestore.Firestore} db
 */
async function nextRetailOrderId(db) {
  const period = orderPeriodSuffix();
  const seq = await incrementCounter(db, "retail");
  return `TFG-${period}-WI000${seq}`;
}

module.exports = {
  orderPeriodSuffix,
  counterDocId,
  incrementCounter,
  incrementSharedCounter,
  nextDeliveryOrderId,
  nextRetailOrderId,
};
