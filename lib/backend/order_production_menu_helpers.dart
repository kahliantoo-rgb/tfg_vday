import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/material_usage_report_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/product_recipe_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

class OrderProductionMaterialLine {
  const OrderProductionMaterialLine({
    required this.materialName,
    required this.unit,
    required this.totalQty,
    required this.unitCost,
    this.materialRefPath,
  });

  final String materialName;
  final String unit;
  final double totalQty;
  final double unitCost;
  final String? materialRefPath;

  double get lineCost => totalQty * unitCost;
}

class OrderProductionMenu {
  const OrderProductionMenu({
    required this.order,
    required this.orderItems,
    required this.materials,
    required this.unmatchedProducts,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> orderItems;
  final List<OrderProductionMaterialLine> materials;
  final List<ProductWithoutRecipeBreakdown> unmatchedProducts;

  double get totalMaterialCost =>
      materials.fold(0.0, (sum, line) => sum + line.lineCost);
}

Future<OrderProductionMenu> buildOrderProductionMenu(
  DocumentReference orderRef,
) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final orderItems = activeOrderItems(
    await queryOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
    ),
  );
  final products = await queryTenantProductRecordOnce();
  final materialsCatalog = await queryTenantMaterialRecordOnce();
  final costByRef = {
    for (final material in materialsCatalog)
      material.reference.path: material.cost,
  };

  final lookup = ProductRecipeLookup.fromProducts(products);
  final unmatched = <ProductWithoutRecipeBreakdown>[];
  final usage = aggregateMaterialUsage(
    items: orderItems,
    lookup: lookup,
    unmatchedProductsOut: unmatched,
  );

  final lines = usage
      .map(
        (row) => OrderProductionMaterialLine(
          materialName: row.materialName,
          unit: row.unit,
          totalQty: row.totalQty,
          unitCost: row.materialRefPath != null
              ? (costByRef[row.materialRefPath!] ?? 0)
              : 0,
          materialRefPath: row.materialRefPath,
        ),
      )
      .toList();

  return OrderProductionMenu(
    order: order,
    orderItems: orderItems,
    materials: lines,
    unmatchedProducts: unmatched,
  );
}

void openProductionMenuPreview(
  BuildContext context,
  DocumentReference orderRef,
) {
  context.pushNamed(
    ProductionMenuPreviewPageWidget.routeName,
    queryParameters: {
      'orderRef': serializeParam(
        orderRef,
        ParamType.DocumentReference,
      )!,
    },
    extra: <String, dynamic>{'orderRef': orderRef},
  );
}

String productionMenuOrderLabel(OrdersRecord order) {
  if (order.orderId.isNotEmpty) {
    return order.orderId;
  }
  return order.reference.id;
}
