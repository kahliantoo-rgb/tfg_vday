import '/backend/backend.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/product_recipe_helpers.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/product_record.dart';
import '/backend/tenant_query_helpers.dart';

class MaterialUsageBreakdown {
  const MaterialUsageBreakdown({
    required this.materialName,
    required this.unit,
    required this.totalQty,
    this.materialRefPath,
  });

  final String materialName;
  final String unit;
  final double totalQty;
  final String? materialRefPath;
}

class ProductWithoutRecipeBreakdown {
  const ProductWithoutRecipeBreakdown({
    required this.productName,
    required this.totalQty,
  });

  final String productName;
  final int totalQty;
}

class DailyMaterialUsageReport {
  const DailyMaterialUsageReport({
    required this.startDate,
    required this.endDate,
    required this.totalPaidOrders,
    required this.matchedProductLines,
    required this.materialBreakdown,
    required this.unmatchedProducts,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int totalPaidOrders;
  final int matchedProductLines;
  final List<MaterialUsageBreakdown> materialBreakdown;
  final List<ProductWithoutRecipeBreakdown> unmatchedProducts;

  bool get isSingleDay =>
      calendarDay(startDate) == calendarDay(endDate);

  double get totalMaterialKinds => materialBreakdown.length.toDouble();
}

String normalizeProductLookupName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class ProductRecipeLookup {
  ProductRecipeLookup._({
    required this.byRef,
    required this.byName,
  });

  final Map<String, List<ProductRecipeLine>> byRef;
  final Map<String, List<ProductRecipeLine>> byName;

  factory ProductRecipeLookup.fromProducts(List<ProductRecord> products) {
    final byRef = <String, List<ProductRecipeLine>>{};
    final byName = <String, List<ProductRecipeLine>>{};

    for (final product in products) {
      final lines = parseProductRecipeLines(product);
      if (lines.isEmpty) {
        continue;
      }
      byRef[product.reference.path] = lines;
      final nameKey = normalizeProductLookupName(product.name);
      if (nameKey.isNotEmpty) {
        byName[nameKey] = lines;
      }
    }

    return ProductRecipeLookup._(byRef: byRef, byName: byName);
  }

  List<ProductRecipeLine>? linesForOrderItem(OrderItemRecord item) {
    final productRef = item.productRef;
    if (productRef != null) {
      final byReference = byRef[productRef.path];
      if (byReference != null && byReference.isNotEmpty) {
        return byReference;
      }
    }
    final nameKey = normalizeProductLookupName(item.name);
    if (nameKey.isEmpty) {
      return null;
    }
    return byName[nameKey];
  }
}

String materialUsageKey({
  required String materialName,
  required String unit,
  String? materialRefPath,
}) {
  if (materialRefPath != null && materialRefPath.isNotEmpty) {
    return materialRefPath;
  }
  return '${normalizeProductLookupName(materialName)}|${unit.trim().toLowerCase()}';
}

String formatMaterialUsageQty(double qty) {
  if (qty == qty.roundToDouble()) {
    return qty.toInt().toString();
  }
  return qty.toStringAsFixed(2);
}

List<MaterialUsageBreakdown> aggregateMaterialUsage({
  required List<OrderItemRecord> items,
  required ProductRecipeLookup lookup,
  List<ProductWithoutRecipeBreakdown>? unmatchedProductsOut,
}) {
  final totals = <String, MaterialUsageBreakdown>{};
  final unmatched = <String, int>{};

  for (final item in activeOrderItems(items)) {
    final lines = lookup.linesForOrderItem(item);
    if (lines == null || lines.isEmpty) {
      final name = item.name.trim().isEmpty ? 'Item' : item.name.trim();
      unmatched[name] = (unmatched[name] ?? 0) + item.qty;
      continue;
    }

    for (final line in lines) {
      if (line.qty <= 0) {
        continue;
      }
      final usedQty = line.qty * item.qty;
      final key = materialUsageKey(
        materialName: line.materialName,
        unit: line.unit,
        materialRefPath: line.materialRef?.path,
      );
      final existing = totals[key];
      if (existing == null) {
        totals[key] = MaterialUsageBreakdown(
          materialName: line.materialName,
          unit: line.unit,
          totalQty: usedQty,
          materialRefPath: line.materialRef?.path,
        );
      } else {
        totals[key] = MaterialUsageBreakdown(
          materialName: existing.materialName,
          unit: existing.unit,
          totalQty: existing.totalQty + usedQty,
          materialRefPath: existing.materialRefPath,
        );
      }
    }
  }

  if (unmatchedProductsOut != null) {
    unmatchedProductsOut
      ..clear()
      ..addAll(
        unmatched.entries
            .map(
              (entry) => ProductWithoutRecipeBreakdown(
                productName: entry.key,
                totalQty: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final byQty = b.totalQty.compareTo(a.totalQty);
            if (byQty != 0) {
              return byQty;
            }
            return a.productName.compareTo(b.productName);
          }),
      );
  }

  final breakdown = totals.values.toList()
    ..sort((a, b) {
      final byQty = b.totalQty.compareTo(a.totalQty);
      if (byQty != 0) {
        return byQty;
      }
      return a.materialName.compareTo(b.materialName);
    });

  return breakdown;
}

Future<List<OrderItemRecord>> loadPaidOrderItemsForSalesReportRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  final rangeStart = startOfDay(range.start);
  final rangeEnd = endOfDay(range.end);

  List<OrdersRecord> orders;
  try {
    orders = await queryTenantOrdersRecordOnce(
      queryBuilder: (q) => q
          .where('created_time', isGreaterThanOrEqualTo: rangeStart)
          .where('created_time', isLessThanOrEqualTo: rangeEnd),
    );
    orders = orders
        .where(
          (order) => orderMatchesDailySalesDateRange(
            order,
            startDate: range.start,
            endDate: range.end,
          ),
        )
        .toList();
  } catch (_) {
    orders = await queryTenantOrdersRecordOnce();
    orders = orders
        .where(
          (order) => orderMatchesDailySalesDateRange(
            order,
            startDate: range.start,
            endDate: range.end,
          ),
        )
        .toList();
  }

  final paidOrders =
      orders.where(orderQualifiesForDailySales).toList(growable: false);
  final paidOrderIds = paidOrders.map((order) => order.reference.id).toSet();
  final orderItems = await queryTenantOrderItemRecordOnce();
  return orderItems
      .where(
        (item) =>
            item.orderRef != null &&
            paidOrderIds.contains(item.orderRef!.id),
      )
      .toList(growable: false);
}

Future<DailyMaterialUsageReport> buildMaterialUsageReportRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );

  final products = await queryTenantProductRecordOnce();
  final lookup = ProductRecipeLookup.fromProducts(products);
  final paidOrderItems = await loadPaidOrderItemsForSalesReportRange(
    startDate: range.start,
    endDate: range.end,
  );

  final unmatchedProducts = <ProductWithoutRecipeBreakdown>[];
  final materialBreakdown = aggregateMaterialUsage(
    items: paidOrderItems,
    lookup: lookup,
    unmatchedProductsOut: unmatchedProducts,
  );

  final paidOrdersCount = paidOrderItems
      .map((item) => item.orderRef?.id)
      .whereType<String>()
      .toSet()
      .length;

  return DailyMaterialUsageReport(
    startDate: range.start,
    endDate: range.end,
    totalPaidOrders: paidOrdersCount,
    matchedProductLines: paidOrderItems
        .where(isActiveOrderItem)
        .where((item) {
          final lines = lookup.linesForOrderItem(item);
          return lines != null && lines.isNotEmpty;
        })
        .length,
    materialBreakdown: materialBreakdown,
    unmatchedProducts: unmatchedProducts,
  );
}

Future<DailyMaterialUsageReport> buildMaterialUsageReport(DateTime day) =>
    buildMaterialUsageReportRange(startDate: day, endDate: day);
