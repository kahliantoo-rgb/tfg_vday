import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/material_cost_snapshot_helpers.dart';
import '/backend/material_usage_report_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/product_recipe_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
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

Future<void> ensureTenantContextForOrder(OrdersRecord order) async {
  if (loggedIn) {
    final profile = await resolveCurrentUserProfile();
    await TenantContext.instance.initialize(profile);
  }

  if (order.hasCompanyRef()) {
    await TenantContext.instance.setActiveCompany(
      canonicalCompanyRef(order.companyRef),
      viewAll: false,
    );
    return;
  }

  final blocked = await TenantContext.instance.ensureReadyForTenantWrite();
  if (blocked != null) {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: blocked,
    );
  }
}

Future<List<ProductRecord>> loadProductsForProductionMenu(
  List<OrderItemRecord> orderItems,
) async {
  final loaded = <String, ProductRecord>{};
  final productRefs = orderItems
      .map((item) => item.productRef)
      .whereType<DocumentReference>()
      .toSet();

  for (final ref in productRefs) {
    try {
      final product = await ProductRecord.getDocumentOnce(ref);
      loaded[product.reference.path] = product;
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }
  }

  final needsNameLookup = orderItems.any((item) {
    final ref = item.productRef;
    if (ref != null && loaded.containsKey(ref.path)) {
      return false;
    }
    return item.name.trim().isNotEmpty;
  });

  if (needsNameLookup) {
    final tenantProducts = await queryTenantProductRecordOnce();
    for (final product in tenantProducts) {
      loaded.putIfAbsent(product.reference.path, () => product);
    }
  }

  return loaded.values.toList();
}

Future<List<MaterialRecord>> loadMaterialsForProductionMenu() async {
  try {
    return await queryTenantMaterialRecordOnce();
  } on FirebaseException catch (error) {
    if (error.code == 'permission-denied') {
      return const [];
    }
    rethrow;
  }
}

Future<OrderProductionMenu> buildOrderProductionMenu(
  DocumentReference orderRef,
) async {
  if (loggedIn) {
    final profile = await resolveCurrentUserProfile();
    await TenantContext.instance.initialize(profile);
  }

  final order = await OrdersRecord.getDocumentOnce(orderRef);
  await ensureTenantContextForOrder(order);

  final orderItems = activeOrderItems(
    await queryTenantOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
    ),
  );
  final products = await loadProductsForProductionMenu(orderItems);
  final materialsCatalog = await loadMaterialsForProductionMenu();
  final catalogCosts = {
    for (final material in materialsCatalog)
      material.reference.path: material.cost,
  };
  final costByRef = resolveMaterialUnitCostsForOrder(order, catalogCosts);

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
