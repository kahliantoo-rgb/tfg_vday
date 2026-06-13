import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/deleted_orders_helpers.dart';
import '/backend/dashboard_order_stats_helpers.dart';
import '/backend/order_activity_log_service.dart';
import '/backend/schema/deleted_orders_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrderRestoreException implements Exception {
  OrderRestoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Recreates the active order and line items from a [deleted_orders] archive.
Future<void> restoreDeletedOrder(DeletedOrdersRecord archive) async {
  if (archive.isRestored) {
    throw OrderRestoreException('This order has already been restored.');
  }

  if (archive.originalOrderPath.isEmpty) {
    throw OrderRestoreException('Archive is missing the original order path.');
  }

  final orderRef = FirebaseFirestore.instance.doc(archive.originalOrderPath);
  final existing = await orderRef.get();
  if (existing.exists) {
    throw OrderRestoreException(
      'An active order with this ID already exists. Cannot restore.',
    );
  }

  final restoredByUid = currentUserUid;
  final restoredByEmail = currentUserEmail;
  final batch = FirebaseFirestore.instance.batch();

  batch.set(
    orderRef,
    mapToFirestore(Map<String, dynamic>.from(archive.orderData)),
  );

  for (final raw in archive.orderItems) {
    if (raw is! Map) {
      continue;
    }
    final itemId = raw['item_id'] as String?;
    final itemData = raw['item_data'];
    if (itemId == null || itemId.isEmpty || itemData is! Map) {
      continue;
    }
    final itemRef = OrderItemRecord.collection.doc(itemId);
    batch.set(
      itemRef,
      mapToFirestore(Map<String, dynamic>.from(itemData)),
    );
  }

  final restoreEntry = createOrderActivityLogEntry(
    action: 'restored',
    byUid: restoredByUid,
    byEmail: restoredByEmail,
    at: getCurrentTimestamp,
  );

  final existingLog = sortedActivityLogEntries(archive.activityLog)
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
  existingLog.insert(0, restoreEntry);

  batch.update(
    archive.reference,
    mapToFirestore(
      {
        'is_restored': true,
        'restored_at': FieldValue.serverTimestamp(),
        'restored_by_uid': restoredByUid,
        'restored_by_email': restoredByEmail,
        'activity_log': existingLog,
      },
    ),
  );

  await batch.commit();

  await writeOrderActivityLog(
    actionType: OrderActivityAction.orderRestore,
    orderRef: orderRef,
    companyRef: archive.hasCompanyRef() ? archive.companyRef : null,
    beforeValue: 'deleted',
    afterValue: archive.orderId,
  );

  notifyDashboardStatsChanged();
}
