import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/price_list_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';

/// Line items with qty > 0 only (excludes removed / zero-qty rows).
bool isActiveOrderItem(OrderItemRecord item) => item.qty > 0;

List<OrderItemRecord> activeOrderItems(List<OrderItemRecord> items) =>
    items.where(isActiveOrderItem).toList();

/// Live line items for one order (bypasses [queryCollection] error swallowing).
Stream<List<OrderItemRecord>> streamOrderLineItemsForOrder(
  DocumentReference orderRef,
) {
  return streamOrderItemsForOrder(orderRef).map(activeOrderItems);
}

/// All line items for one order (tenant-scoped; required by Firestore rules).
Stream<List<OrderItemRecord>> streamOrderItemsForOrder(
  DocumentReference orderRef,
) {
  final query = applyTenantCompanyFilter(
    OrderItemRecord.collection.where('orderRef', isEqualTo: orderRef),
  );
  return query.snapshots().map(
        (snapshot) =>
            snapshot.docs.map(OrderItemRecord.fromSnapshot).toList(),
      );
}

/// One-shot line items for one order (tenant-scoped).
Future<List<OrderItemRecord>> queryOrderItemsForOrderOnce(
  DocumentReference orderRef,
) =>
    queryTenantOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
    );

bool _orderItemMatchesInvoiceOrder(
  OrderItemRecord item,
  OrdersRecord order,
) {
  if (!item.hasCompanyRef()) {
    return true;
  }
  final orderCompany = order.companyRef;
  if (orderCompany == null) {
    return true;
  }
  return item.companyRef!.path == orderCompany.path;
}

/// Invoice/PDF line items — tenant query first, then orderRef-only fallback
/// for legacy rows missing [companyRef] or composite-index gaps.
Future<List<OrderItemRecord>> queryOrderLineItemsForInvoiceOrder(
  DocumentReference orderRef, {
  OrdersRecord? order,
}) async {
  List<OrderItemRecord> tenantItems = const [];
  try {
    tenantItems = await queryOrderItemsForOrderOnce(orderRef);
  } on FirebaseException catch (error) {
    if (error.code != 'failed-precondition') {
      rethrow;
    }
  }
  if (tenantItems.isNotEmpty) {
    return tenantItems;
  }

  final snap = await OrderItemRecord.collection
      .where('orderRef', isEqualTo: orderRef)
      .limit(100)
      .get();
  final rawItems = activeOrderItems(
    snap.docs.map(OrderItemRecord.fromSnapshot).toList(),
  );
  if (rawItems.isEmpty) {
    return rawItems;
  }

  OrdersRecord? resolvedOrder = order;
  try {
    resolvedOrder ??= await OrdersRecord.getDocumentOnce(orderRef);
  } catch (_) {
    // Linked order may be unreadable; keep line items for invoice/PDF.
    return rawItems;
  }
  return rawItems
      .where((item) => _orderItemMatchesInvoiceOrder(item, resolvedOrder!))
      .toList();
}

/// Decrements qty by 1. At qty 1, zeroes the line (keeps doc for checkout permissions).
Future<void> decreaseOrderItemQuantityOrDelete({
  required OrderItemRecord item,
  required DocumentReference orderRef,
}) async {
  if (item.qty <= 1) {
    await item.reference.update(
      createOrderItemRecordData(
        qty: 0,
        subtotal: 0,
      ),
    );
    await recalculateOrderTotals(orderRef);
    return;
  }

  final nextQty = item.qty - 1;
  await item.reference.update(
    createOrderItemRecordData(
      qty: nextQty,
      subtotal: item.price * nextQty,
    ),
  );
  await recalculateOrderTotals(orderRef);
}

/// Removes an entire line item and adjusts order totals.
Future<void> deleteOrderItemLine({
  required OrderItemRecord item,
  required DocumentReference orderRef,
}) async {
  final qty = item.qty > 0 ? item.qty : 0;
  if (qty == 0) {
    await item.reference.delete();
    return;
  }

  final lineTotal = item.subtotal > 0 ? item.subtotal : item.price * qty;
  await item.reference.delete();
  await orderRef.update({
    ...mapToFirestore({
      'totalAmount': FieldValue.increment(-lineTotal),
      'totalQty': FieldValue.increment(-qty),
    }),
  });
}

/// Increments qty by 1 and updates order totals.
Future<void> increaseOrderItemQuantity({
  required OrderItemRecord item,
  required DocumentReference orderRef,
}) async {
  await setOrderItemQuantity(
    item: item,
    orderRef: orderRef,
    qty: item.qty + 1,
  );
}

/// Sets absolute qty (checkout summary). Zeroes the line when qty <= 0.
Future<void> setOrderItemQuantity({
  required OrderItemRecord item,
  required DocumentReference orderRef,
  required int qty,
}) async {
  if (qty <= 0) {
    await item.reference.update(
      createOrderItemRecordData(
        qty: 0,
        subtotal: 0,
      ),
    );
    await recalculateOrderTotals(orderRef);
    return;
  }

  await item.reference.update(
    createOrderItemRecordData(
      qty: qty,
      subtotal: item.price * qty,
    ),
  );
  await recalculateOrderTotals(orderRef);
}

Future<DocumentReference> addCatalogProductToOrderItem({
  required DocumentReference orderRef,
  required ProductRecord product,
  int qty = 1,
}) async {
  final unitPrice = await resolveProductUnitPriceForOrder(
    orderRef: orderRef,
    product: product,
  );
  final existing = await queryOrderItemsForOrderOnce(orderRef);
  for (final item in existing) {
    if (item.productRef?.path == product.reference.path) {
      if (qty == 1) {
        await increaseOrderItemQuantity(item: item, orderRef: orderRef);
      } else {
        final nextQty = item.qty + qty;
        final linePrice = item.price > 0 ? item.price : unitPrice;
        await item.reference.update(
          createOrderItemRecordData(
            qty: nextQty,
            subtotal: linePrice * nextQty,
          ),
        );
        await recalculateOrderTotals(orderRef);
      }
      return item.reference;
    }
  }

  final itemRef = OrderItemRecord.collection.doc();
  await itemRef.set(
    createTenantOrderItemRecordData(
      orderRef: orderRef,
      productRef: product.reference,
      name: product.name,
      qty: qty,
      sku: product.sku,
      price: unitPrice,
      subtotal: functions.newCustomFunction2(unitPrice, qty),
      image: productImageFromRecord(product),
    ),
  );
  await recalculateOrderTotals(orderRef);
  return itemRef;
}

Future<void> recalculateOrderTotals(DocumentReference orderRef) async {
  final items = activeOrderItems(await queryOrderItemsForOrderOnce(orderRef));
  if (items.isEmpty) {
    await orderRef.update(
      createOrdersRecordData(
        totalAmount: 0,
        total: 0,
        totalQty: 0,
      ),
    );
    return;
  }
  final total = functions.calculationTotal(
    items.map((item) => item.price).toList(),
    items.map((item) => item.qty).toList(),
  );
  final totalQty = items.fold<int>(0, (running, item) => running + item.qty);
  await orderRef.update(
    createOrdersRecordData(
      totalAmount: total,
      total: total,
      totalQty: totalQty,
      productSelection: items.first.reference,
    ),
  );
}
