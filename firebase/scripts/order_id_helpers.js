/**

 * Mirrors lib/backend/order_id_service.dart — per-channel counter transactions.

 * Used by emulator integration tests and optional scripts.

 */



/**

 * @param {import('firebase-admin').firestore.Firestore} db

 * @param {string} companyId

 * @param {"delivery"|"retail"} channel

 * @param {import('firebase-admin').firestore.DocumentReference | null} comR

 * @returns {Promise<number>} next sequence number

 */

async function incrementCounter(db, companyId = "default", channel = "delivery", comR = null) {

  const counterRef = db.collection("counter").doc(`${companyId}_${channel}`);



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

async function incrementSharedCounter(db, companyId = "default", comR = null) {

  return incrementCounter(db, companyId, "delivery", comR);

}



/**

 * @param {import('firebase-admin').firestore.Firestore} db

 * @param {string} companyId

 */

async function nextDeliveryOrderId(db, companyId = "default") {

  const year = new Date().getFullYear();

  const seq = await incrementCounter(db, companyId, "delivery");

  return `TFG-${year}-${String(seq).padStart(4, "0")}`;

}



/**

 * @param {import('firebase-admin').firestore.Firestore} db

 * @param {string} companyId

 */

async function nextRetailOrderId(db, companyId = "default") {

  const seq = await incrementCounter(db, companyId, "retail");

  return `TFG-WI${String(seq).padStart(4, "0")}`;

}



module.exports = {

  incrementCounter,

  incrementSharedCounter,

  nextDeliveryOrderId,

  nextRetailOrderId,

};


