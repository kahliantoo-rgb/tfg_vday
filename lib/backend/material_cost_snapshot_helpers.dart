import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/material_usage_report_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/material_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/product_record.dart';
import '/backend/tenant_query_helpers.dart';

class OrderMaterialCostSnapshotResult {
  const OrderMaterialCostSnapshotResult({
    required this.totalCost,
    required this.unitCostByMaterialRefPath,
  });

  final double totalCost;
  final Map<String, double> unitCostByMaterialRefPath;
}

/// Computes material usage cost for an order using current catalog unit costs.
Future<OrderMaterialCostSnapshotResult> computeOrderMaterialCostSnapshot({
  required DocumentReference orderRef,
  List<OrderItemRecord>? orderItems,
  List<ProductRecord>? products,
  List<MaterialRecord>? materials,
}) async {
  final resolvedItems = orderItems ??
      activeOrderItems(await queryOrderItemsForOrderOnce(orderRef));
  final resolvedProducts = products ?? await queryTenantProductRecordOnce();
  final resolvedMaterials = materials ?? await queryTenantMaterialRecordOnce();
  final costByRef = {
    for (final material in resolvedMaterials)
      material.reference.path: material.cost,
  };

  final lookup = ProductRecipeLookup.fromProducts(resolvedProducts);
  final usage = aggregateMaterialUsage(
    items: resolvedItems,
    lookup: lookup,
  );

  final unitCostByMaterialRefPath = <String, double>{};
  var totalCost = 0.0;
  for (final row in usage) {
    final refPath = row.materialRefPath;
    if (refPath == null || refPath.isEmpty) {
      continue;
    }
    final unitCost = costByRef[refPath] ?? 0;
    unitCostByMaterialRefPath[refPath] = unitCost;
    totalCost += row.totalQty * unitCost;
  }

  return OrderMaterialCostSnapshotResult(
    totalCost: totalCost,
    unitCostByMaterialRefPath: unitCostByMaterialRefPath,
  );
}

bool orderQualifiesForMaterialCostSnapshot({
  required String paymentType,
  required OrderStatus? status,
  required double totalAmount,
}) {
  if (paymentType.trim().isEmpty) {
    return false;
  }
  if (status == OrderStatus.cancelled) {
    return false;
  }
  return totalAmount > 0;
}

bool orderRecordQualifiesForMaterialCostSnapshot(OrdersRecord order) {
  final amount = order.totalAmount > 0 ? order.totalAmount : order.total;
  return orderQualifiesForMaterialCostSnapshot(
    paymentType: order.paymentType,
    status: order.status,
    totalAmount: amount,
  );
}

Future<Map<String, dynamic>> materialCostSnapshotUpdateFields({
  required DocumentReference orderRef,
  required OrdersRecord order,
  String? paymentType,
  double? totalAmount,
  OrderStatus? status,
}) async {
  if (order.hasMaterialCostSnapshot()) {
    return const {};
  }
  final effectiveAmount = totalAmount ??
      (order.totalAmount > 0 ? order.totalAmount : order.total);
  if (!orderQualifiesForMaterialCostSnapshot(
    paymentType: paymentType ?? order.paymentType,
    status: status ?? order.status,
    totalAmount: effectiveAmount,
  )) {
    return const {};
  }

  final computed = await computeOrderMaterialCostSnapshot(orderRef: orderRef);
  return {
    'material_usage_cost': computed.totalCost,
    'material_cost_snapshot': computed.unitCostByMaterialRefPath,
    'material_cost_snapshotted_at': FieldValue.serverTimestamp(),
  };
}

/// Locks material unit costs on the order the first time it qualifies for sales.
Future<void> ensureOrderMaterialCostSnapshot(DocumentReference orderRef) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final fields = await materialCostSnapshotUpdateFields(
    orderRef: orderRef,
    order: order,
  );
  if (fields.isEmpty) {
    return;
  }
  await orderRef.update(fields);
}

/// Sum locked costs for profit reporting. Legacy orders without a snapshot are
/// computed on the fly with current catalog costs (run backfill to lock them).
double sumSnapshottedMaterialUsageCost(Iterable<OrdersRecord> orders) {
  var total = 0.0;
  for (final order in orders) {
    if (order.hasMaterialCostSnapshot()) {
      total += order.materialUsageCost;
    }
  }
  return total;
}

Future<double> resolveMaterialUsageCostForPaidOrders(
  List<OrdersRecord> paidOrders,
) async {
  var total = sumSnapshottedMaterialUsageCost(paidOrders);
  for (final order in paidOrders) {
    if (order.hasMaterialCostSnapshot()) {
      continue;
    }
    final computed =
        await computeOrderMaterialCostSnapshot(orderRef: order.reference);
    total += computed.totalCost;
  }
  return total;
}

Map<String, double> resolveMaterialUnitCostsForOrder(
  OrdersRecord order,
  Map<String, double> currentCatalogCosts,
) {
  if (order.materialCostSnapshot.isNotEmpty) {
    return order.materialCostSnapshot;
  }
  return currentCatalogCosts;
}
