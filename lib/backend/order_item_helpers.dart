import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';

/// Line items with qty > 0 only (excludes removed / zero-qty rows).
bool isActiveOrderItem(OrderItemRecord item) => item.qty > 0;

List<OrderItemRecord> activeOrderItems(List<OrderItemRecord> items) =>
    items.where(isActiveOrderItem).toList();

/// Decrements qty by 1. When qty is 1, deletes the line item instead of leaving qty at 0.
Future<void> decreaseOrderItemQuantityOrDelete({
  required OrderItemRecord item,
  required DocumentReference orderRef,
}) async {
  final unitPrice = item.price;

  if (item.qty <= 1) {
    await item.reference.delete();
  } else {
    await item.reference.update({
      ...createOrderItemRecordData(
        subtotal: functions.decreaseQtysubtotal(item.price, item.qty),
      ),
      ...mapToFirestore({
        'qty': FieldValue.increment(-1),
      }),
    });
  }

  await orderRef.update({
    ...mapToFirestore({
      'totalAmount': FieldValue.increment(-unitPrice),
      'totalQty': FieldValue.increment(-1),
    }),
  });
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
  await item.reference.update({
    ...createOrderItemRecordData(
      subtotal: functions.increaseQtySubtotal(item.price, item.qty),
    ),
    ...mapToFirestore({
      'qty': FieldValue.increment(1),
    }),
  });

  await orderRef.update({
    ...mapToFirestore({
      'totalAmount': FieldValue.increment(item.price),
      'totalQty': FieldValue.increment(1),
    }),
  });
}

Future<void> addCatalogProductToOrderItem({
  required DocumentReference orderRef,
  required ProductRecord product,
  int qty = 1,
}) async {
  await OrderItemRecord.collection.doc().set(
        createTenantOrderItemRecordData(
          orderRef: orderRef,
          productRef: product.reference,
          name: product.name,
          qty: qty,
          sku: product.sku,
          price: product.price,
          subtotal: functions.newCustomFunction2(product.price, qty),
          image: productImageFromRecord(product),
        ),
      );
}

Future<void> recalculateOrderTotals(DocumentReference orderRef) async {
  final items = await queryOrderItemRecordOnce(
    queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
  );
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
