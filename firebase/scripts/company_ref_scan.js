/**
 * Shared scan helpers for companyRef backfill / verification.
 */
const TENANT_COLLECTIONS = [
  "orders",
  "Order_item",
  "product",
  "materials",
  "customers",
  "invoices",
  "deleted_orders",
  "customProduct",
  "staff_notices",
];

function missingCompanyRef(data) {
  const ref = data.companyRef;
  return ref == null || ref === undefined;
}

async function scanCollection(db, collectionId) {
  const snap = await db.collection(collectionId).get();
  const missing = [];
  for (const doc of snap.docs) {
    if (missingCompanyRef(doc.data())) {
      missing.push({
        path: doc.ref.path,
        id: doc.id,
      });
    }
  }
  return { collectionId, total: snap.size, missing };
}

async function scanUsers(db) {
  const snap = await db.collection("users").get();
  const missing = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.role === "superadmin") {
      continue;
    }
    if (missingCompanyRef(data)) {
      missing.push({
        path: doc.ref.path,
        id: doc.id,
        role: data.role || null,
      });
    }
  }
  return { collectionId: "users", total: snap.size, missing };
}

async function scanAuditLogs(db) {
  const snap = await db.collection("audit_logs").get();
  const missing = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    const hasRef = data.companyRef != null;
    const hasId =
      typeof data.companyId === "string" && data.companyId.length > 0;
    if (!hasRef && !hasId) {
      missing.push({
        path: doc.ref.path,
        id: doc.id,
      });
    }
  }
  return { collectionId: "audit_logs", total: snap.size, missing };
}

async function scanAllCompanyRefGaps(db) {
  const reports = [];
  for (const collectionId of TENANT_COLLECTIONS) {
    reports.push(await scanCollection(db, collectionId));
  }
  reports.push(await scanUsers(db));
  reports.push(await scanAuditLogs(db));
  return reports;
}

function summarizeReports(reports) {
  const missingTotal = reports.reduce(
    (sum, report) => sum + report.missing.length,
    0,
  );
  const missingByCollection = reports
    .filter((report) => report.missing.length > 0)
    .map((report) => ({
      collection: report.collectionId,
      count: report.missing.length,
      total: report.total,
      samplePaths: report.missing.slice(0, 5).map((item) => item.path),
    }));
  return { missingTotal, missingByCollection, reports };
}

module.exports = {
  TENANT_COLLECTIONS,
  missingCompanyRef,
  scanCollection,
  scanUsers,
  scanAuditLogs,
  scanAllCompanyRefGaps,
  summarizeReports,
};
