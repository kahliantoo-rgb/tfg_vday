/**
 * Material cost snapshot for Cloud Functions (mirrors firebase/scripts version).
 */
const { FieldValue } = require("firebase-admin/firestore");

function normalizeProductLookupName(name) {
  return String(name || "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function parseRecipeLines(product) {
  const lines = product.recipeLines || [];
  return lines.filter(
    (line) =>
      (line.materialName && String(line.materialName).trim()) ||
      line.materialRef,
  );
}

function buildProductRecipeLookup(products) {
  const byRef = new Map();
  const byName = new Map();
  for (const product of products) {
    const lines = parseRecipeLines(product);
    if (lines.length === 0) {
      continue;
    }
    byRef.set(product.id, lines);
    const nameKey = normalizeProductLookupName(product.name);
    if (nameKey) {
      byName.set(nameKey, lines);
    }
  }
  return { byRef, byName };
}

function linesForOrderItem(item, lookup) {
  const productRef = item.productRef;
  if (productRef && lookup.byRef.has(productRef.id)) {
    return lookup.byRef.get(productRef.id);
  }
  const nameKey = normalizeProductLookupName(item.name);
  if (nameKey && lookup.byName.has(nameKey)) {
    return lookup.byName.get(nameKey);
  }
  return null;
}

function materialUsageKey({ materialName, unit, materialRefPath }) {
  if (materialRefPath) {
    return materialRefPath;
  }
  return `${normalizeProductLookupName(materialName)}|${String(unit || "")
    .trim()
    .toLowerCase()}`;
}

function aggregateMaterialUsage(items, lookup) {
  const totals = new Map();
  for (const item of items) {
    if (item.status === "deleted" || item.qty <= 0) {
      continue;
    }
    const lines = linesForOrderItem(item, lookup);
    if (!lines || lines.length === 0) {
      continue;
    }
    for (const line of lines) {
      const qty = Number(line.qty || 0);
      if (qty <= 0) {
        continue;
      }
      const usedQty = qty * Number(item.qty || 0);
      const materialRefPath = line.materialRef?.path || null;
      const key = materialUsageKey({
        materialName: line.materialName,
        unit: line.unit,
        materialRefPath,
      });
      const existing = totals.get(key);
      if (!existing) {
        totals.set(key, {
          materialName: line.materialName || "",
          unit: line.unit || "",
          totalQty: usedQty,
          materialRefPath,
        });
      } else {
        existing.totalQty += usedQty;
      }
    }
  }
  return [...totals.values()];
}

function computeOrderMaterialCostSnapshot({
  orderItems,
  products,
  materialsByPath,
}) {
  const lookup = buildProductRecipeLookup(products);
  const usage = aggregateMaterialUsage(orderItems, lookup);
  const unitCostByMaterialRefPath = {};
  let totalCost = 0;
  for (const row of usage) {
    const refPath = row.materialRefPath;
    if (!refPath) {
      continue;
    }
    const unitCost = Number(materialsByPath.get(refPath)?.cost || 0);
    unitCostByMaterialRefPath[refPath] = unitCost;
    totalCost += row.totalQty * unitCost;
  }
  return { totalCost, unitCostByMaterialRefPath };
}

function buildMaterialCostSnapshotPatch({
  orderItems,
  products,
  materialsByPath,
}) {
  const computed = computeOrderMaterialCostSnapshot({
    orderItems,
    products,
    materialsByPath,
  });
  return {
    material_usage_cost: computed.totalCost,
    material_cost_snapshot: computed.unitCostByMaterialRefPath,
    material_cost_snapshotted_at: FieldValue.serverTimestamp(),
  };
}

module.exports = {
  buildMaterialCostSnapshotPatch,
};
