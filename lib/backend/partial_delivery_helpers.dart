import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/dashboard_order_stats_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PartialDeliveryLineInput {
  const PartialDeliveryLineInput({
    required this.item,
    required this.deliverNow,
  });

  final OrderItemRecord item;
  final int deliverNow;
}

class PartialDeliveryResult {
  const PartialDeliveryResult({
    required this.deliveredThisRun,
    required this.fullyDelivered,
    required this.remainingQty,
    this.run,
  });

  final int deliveredThisRun;
  final bool fullyDelivered;
  final int remainingQty;
  final PartialDeliveryRun? run;
}

/// One recorded partial-delivery run (stored on the order document).
class PartialDeliveryRun {
  const PartialDeliveryRun({
    required this.runNumber,
    required this.deliveryId,
    required this.items,
    this.deliveredAt,
  });

  final int runNumber;
  final String deliveryId;
  final DateTime? deliveredAt;
  final List<Map<String, dynamic>> items;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'run_number': runNumber,
      'delivery_id': deliveryId,
      'delivered_at': FieldValue.serverTimestamp(),
      'items': items,
    };
  }

  static PartialDeliveryRun? fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return null;
    }
    final runNumber = raw['run_number'];
    final deliveryId = raw['delivery_id'];
    if (runNumber is! num || deliveryId is! String || deliveryId.isEmpty) {
      return null;
    }
    final deliveredAtRaw = raw['delivered_at'];
    DateTime? deliveredAt;
    if (deliveredAtRaw is Timestamp) {
      deliveredAt = deliveredAtRaw.toDate();
    } else if (deliveredAtRaw is DateTime) {
      deliveredAt = deliveredAtRaw;
    }
    final itemsRaw = raw['items'];
    final items = <Map<String, dynamic>>[];
    if (itemsRaw is List) {
      for (final entry in itemsRaw) {
        if (entry is Map) {
          items.add(Map<String, dynamic>.from(entry));
        }
      }
    }
    return PartialDeliveryRun(
      runNumber: runNumber.toInt(),
      deliveryId: deliveryId,
      deliveredAt: deliveredAt,
      items: items,
    );
  }
}

/// Delivery slip id for run N: `{orderId}-N` (e.g. `TFG-JUN26-0005-1`).
String partialDeliveryIdForRun(String orderId, int runNumber) {
  final base = orderId.trim().isNotEmpty ? orderId.trim() : 'ORDER';
  return '$base-$runNumber';
}

List<PartialDeliveryRun> parsePartialDeliveryRuns(
  Map<String, dynamic> orderSnapshotData,
) {
  final raw = orderSnapshotData['partial_delivery_runs'];
  if (raw is! List) {
    return const [];
  }
  final runs = <PartialDeliveryRun>[];
  for (final entry in raw) {
    if (entry is Map) {
      final run = PartialDeliveryRun.fromMap(Map<String, dynamic>.from(entry));
      if (run != null) {
        runs.add(run);
      }
    }
  }
  runs.sort((a, b) => a.runNumber.compareTo(b.runNumber));
  return runs;
}

List<PartialDeliveryRun> parsePartialDeliveryRunsFromOrder(
  OrdersRecord order,
) =>
    parsePartialDeliveryRuns(order.snapshotData);

List<OrderItemRecord> orderItemsFromPartialDeliveryRun(
  PartialDeliveryRun run,
  DocumentReference orderRef,
) {
  return run.items.map((itemData) {
    final data = Map<String, dynamic>.from(itemData);
    data['orderRef'] = orderRef;
    final itemId = data['item_id'] as String? ?? '';
    final ref = itemId.isNotEmpty
        ? OrderItemRecord.collection.doc(itemId)
        : OrderItemRecord.collection.doc();
    return OrderItemRecord.getDocumentFromData(data, ref);
  }).toList();
}

Map<String, dynamic> _partialDeliveryRunItemSnapshot(
  PartialDeliveryLineInput line,
) {
  final qty = line.deliverNow;
  final price = line.item.price;
  return {
    'item_id': line.item.reference.id,
    'name': line.item.name,
    'qty': qty,
    'price': price,
    'subtotal': price > 0 ? price * qty : line.item.subtotal,
    'remark': line.item.remark,
    'sku': line.item.sku,
  };
}

int readDeliveredQty(OrderItemRecord item) {
  final delivered = item.deliveredQty;
  if (delivered < 0) {
    return 0;
  }
  if (delivered > item.qty) {
    return item.qty;
  }
  return delivered;
}

int remainingDeliveryQty(OrderItemRecord item) {
  final ordered = item.qty > 0 ? item.qty : 0;
  return (ordered - readDeliveredQty(item)).clamp(0, ordered);
}

bool isItemFullyDelivered(OrderItemRecord item) =>
    remainingDeliveryQty(item) <= 0;

bool isOrderFullyDelivered(List<OrderItemRecord> items) {
  final active = activeOrderItems(items);
  if (active.isEmpty) {
    return false;
  }
  return active.every(isItemFullyDelivered);
}

int orderTotalOrderedQty(List<OrderItemRecord> items) =>
    activeOrderItems(items).fold<int>(0, (sum, item) => sum + item.qty);

int orderTotalDeliveredQty(List<OrderItemRecord> items) =>
    activeOrderItems(items)
        .fold<int>(0, (sum, item) => sum + readDeliveredQty(item));

int orderTotalRemainingQty(List<OrderItemRecord> items) =>
    activeOrderItems(items)
        .fold<int>(0, (sum, item) => sum + remainingDeliveryQty(item));

String partialDeliveryItemStatus(OrderItemRecord item) {
  final remaining = remainingDeliveryQty(item);
  if (remaining <= 0) {
    return 'delivered';
  }
  if (readDeliveredQty(item) > 0) {
    return 'partial';
  }
  return 'pending';
}

String formatPartialDeliveryProgress(List<OrderItemRecord> items) {
  final ordered = orderTotalOrderedQty(items);
  if (ordered <= 0) {
    return '-';
  }
  final delivered = orderTotalDeliveredQty(items);
  if (delivered <= 0) {
    return 'Qty $ordered';
  }
  final remaining = orderTotalRemainingQty(items);
  if (remaining <= 0) {
    return 'Qty $ordered (all delivered)';
  }
  return 'Qty $ordered ($delivered delivered, $remaining left)';
}

String? validatePartialDeliveryLines(List<PartialDeliveryLineInput> lines) {
  var hasPositive = false;
  for (final line in lines) {
    if (line.deliverNow <= 0) {
      continue;
    }
    hasPositive = true;
    final remaining = remainingDeliveryQty(line.item);
    if (line.deliverNow > remaining) {
      final name = line.item.name.isNotEmpty ? line.item.name : 'Item';
      return '$name: cannot deliver ${line.deliverNow} (only $remaining left)';
    }
  }
  if (!hasPositive) {
    return 'Enter at least one quantity to deliver';
  }
  return null;
}

Future<PartialDeliveryResult> submitPartialDelivery({
  required DocumentReference orderRef,
  required List<PartialDeliveryLineInput> lines,
  DateTime? nextDeliveryDate,
}) async {
  final error = validatePartialDeliveryLines(lines);
  if (error != null) {
    throw PartialDeliveryValidationException(error);
  }

  PartialDeliveryRun? savedRun;

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final orderSnap = await transaction.get(orderRef);
    if (!orderSnap.exists) {
      throw PartialDeliveryValidationException('Order not found');
    }
    final orderData = orderSnap.data() as Map<String, dynamic>;
    final baseOrderId = (orderData['order_id'] as String?)?.trim() ?? '';
    final existingRuns = parsePartialDeliveryRuns(orderData);
    final runNumber = existingRuns.isEmpty
        ? 1
        : existingRuns.map((run) => run.runNumber).reduce((a, b) => a > b ? a : b) +
            1;
    final deliveryId = partialDeliveryIdForRun(
      baseOrderId.isNotEmpty ? baseOrderId : orderRef.id,
      runNumber,
    );

    var deliveredThisRun = 0;
    final runItems = <Map<String, dynamic>>[];

    for (final line in lines) {
      if (line.deliverNow <= 0) {
        continue;
      }
      deliveredThisRun += line.deliverNow;
      runItems.add(_partialDeliveryRunItemSnapshot(line));
      final newDelivered = readDeliveredQty(line.item) + line.deliverNow;
      transaction.update(
        line.item.reference,
        createOrderItemRecordData(
          deliveredQty: newDelivered,
          status: partialDeliveryItemStatus(
            OrderItemRecord.getDocumentFromData(
              {
                ...line.item.snapshotData,
                'delivered_qty': newDelivered,
                'qty': line.item.qty,
              },
              line.item.reference,
            ),
          ),
        ),
      );
    }

    final newRun = PartialDeliveryRun(
      runNumber: runNumber,
      deliveryId: deliveryId,
      items: runItems,
    );
    savedRun = newRun;

    transaction.update(orderRef, {
      'partial_delivery_run_count': runNumber,
      'partial_delivery_runs': [
        ...existingRuns.map(
          (run) => {
            'run_number': run.runNumber,
            'delivery_id': run.deliveryId,
            if (run.deliveredAt != null)
              'delivered_at': Timestamp.fromDate(run.deliveredAt!),
            'items': run.items,
          },
        ),
        newRun.toFirestoreMap(),
      ],
    });
  });

  final items = await queryOrderItemRecordOnce(
    queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
  );
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final fullyDelivered = isOrderFullyDelivered(items);
  final remainingQty = orderTotalRemainingQty(items);

  if (fullyDelivered) {
    await updateOrderStatus(
      orderRef,
      OrderStatus.completed,
      extraFields: mapToFirestore({
        'delivery_time_actual': FieldValue.serverTimestamp(),
      }),
    );
  } else {
    final updates = <String, dynamic>{};
    if (order.status == OrderStatus.ready_to_delivery ||
        order.status == OrderStatus.processing) {
      updates.addAll(createOrderStatusUpdateData(OrderStatus.out_of_delivery));
    }
    if (nextDeliveryDate != null) {
      updates.addAll(
        createOrdersRecordData(deliveryDate: nextDeliveryDate),
      );
    }
    if (updates.isNotEmpty) {
      await orderRef.update(updates);
      notifyDashboardStatsChanged();
    }
  }

  final deliveredThisRun = savedRun?.items.fold<int>(
        0,
        (sum, item) => sum + ((item['qty'] as num?)?.toInt() ?? 0),
      ) ??
      0;

  return PartialDeliveryResult(
    deliveredThisRun: deliveredThisRun,
    fullyDelivered: fullyDelivered,
    remainingQty: remainingQty,
    run: savedRun,
  );
}

class PartialDeliveryValidationException implements Exception {
  PartialDeliveryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Line item with [qty] adjusted for partial-delivery printouts.
OrderItemRecord orderItemForPrintQty(OrderItemRecord item, int qty) {
  final safeQty = qty.clamp(0, item.qty > 0 ? item.qty : qty);
  final data = Map<String, dynamic>.from(item.snapshotData);
  data['qty'] = safeQty;
  if (item.price > 0) {
    data['subtotal'] = item.price * safeQty;
  }
  return OrderItemRecord.getDocumentFromData(data, item.reference);
}

/// Items selected on the partial delivery page (deliver-now qty per line).
List<OrderItemRecord> partialDeliveryPrintItems(
  List<PartialDeliveryLineInput> lines,
) {
  return lines
      .where((line) => line.deliverNow > 0)
      .map((line) => orderItemForPrintQty(line.item, line.deliverNow))
      .toList();
}
