import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/order_activity_log_service.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/deleted_orders_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Firestore collection for archived orders removed from the active list.
CollectionReference get deletedOrdersCollection =>
    DeletedOrdersRecord.collection;

String _resolveOriginalOrderStatus(OrdersRecord order) {
  if (order.hasStatus()) {
    return order.status!.name;
  }
  if (order.orderstatus.isNotEmpty) {
    return order.orderstatus;
  }
  return '';
}

/// Payload written to [deletedOrdersCollection] before an order is removed.
Map<String, dynamic> createDeletedOrderArchiveData({
  required OrdersRecord order,
  required List<OrderItemRecord> items,
  required String deletedByUid,
  required String deletedByEmail,
  String? deleteReason,
}) {
  final originalStatus = _resolveOriginalOrderStatus(order);
  return mapToFirestore(
    {
      'original_order_id': order.reference.id,
      'original_order_path': order.reference.path,
      'order_id': order.orderId,
      'order_data': order.snapshotData,
      'order_items': items
          .map(
            (item) => {
              'item_id': item.reference.id,
              'item_data': item.snapshotData,
            },
          )
          .toList(),
      'deleted_at': FieldValue.serverTimestamp(),
      'deleted_by_uid': deletedByUid,
      'deleted_by_email': deletedByEmail,
      'delete_reason': deleteReason ?? '',
      'original_order_status': originalStatus,
      'is_restored': false,
      'activity_log': [
        createOrderActivityLogEntry(
          action: 'deleted',
          byUid: deletedByUid,
          byEmail: deletedByEmail,
          note: deleteReason,
          at: getCurrentTimestamp,
        ),
      ],
      if (order.hasCompanyRef()) 'companyRef': order.companyRef,
    },
  );
}

/// Archives each order (with line items) then deletes active Firestore docs.
Future<int> archiveAndDeleteOrders({
  required List<OrdersRecord> orders,
  required List<OrderItemRecord> allItems,
  String? deleteReason,
}) async {
  if (orders.isEmpty) {
    return 0;
  }

  final deletedByUid = currentUserUid;
  final deletedByEmail = currentUserEmail;
  var deletedCount = 0;

  for (final order in orders) {
    final items = orderItemsForOrders(allItems, [order]);
    final batch = FirebaseFirestore.instance.batch();
    final archiveRef = deletedOrdersCollection.doc();

    batch.set(
      archiveRef,
      createDeletedOrderArchiveData(
        order: order,
        items: items,
        deletedByUid: deletedByUid,
        deletedByEmail: deletedByEmail,
        deleteReason: deleteReason,
      ),
    );

    for (final item in items) {
      batch.delete(item.reference);
    }
    batch.delete(order.reference);

    await batch.commit();

    await writeOrderActivityLog(
      actionType: OrderActivityAction.orderDelete,
      orderRef: order.reference,
      companyRef: order.hasCompanyRef() ? order.companyRef : null,
      beforeValue: order.orderId.isNotEmpty ? order.orderId : order.reference.id,
      afterValue: deleteReason ?? 'archived',
    );

    deletedCount++;
  }

  return deletedCount;
}

/// Permanently removes an archived order document (admin only).
Future<void> permanentlyDeleteArchivedOrder(DeletedOrdersRecord archive) async {
  final orderRef = FirebaseFirestore.instance.doc(archive.originalOrderPath);

  await writeOrderActivityLog(
    actionType: OrderActivityAction.orderPermanentDelete,
    orderRef: orderRef,
    companyRef: archive.hasCompanyRef() ? archive.companyRef : null,
    beforeValue: archive.orderId,
    afterValue: 'permanently_deleted',
  );

  await archive.reference.delete();
}
