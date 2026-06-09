import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/audit_log_service.dart';
import '/backend/schema/audit_logs_record.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Audit log action types for order lifecycle events (legacy names).
abstract final class OrderActivityAction {
  static const orderDelete = 'ORDER_DELETE';
  static const orderRestore = 'ORDER_RESTORE';
  static const orderPermanentDelete = 'ORDER_PERMANENT_DELETE';
}

/// Single entry stored in [DeletedOrdersRecord.activityLog].
Map<String, dynamic> createOrderActivityLogEntry({
  required String action,
  required String byUid,
  required String byEmail,
  String? note,
  DateTime? at,
}) {
  return {
    'action': action,
    'by_uid': byUid,
    'by_email': byEmail,
    if (note != null && note.isNotEmpty) 'note': note,
    'at': at ?? getCurrentTimestamp,
  };
}

/// Writes an immutable row to the [audit_logs] collection via [AuditLogService].
Future<void> writeOrderActivityLog({
  required String actionType,
  required DocumentReference? orderRef,
  DocumentReference? companyRef,
  String? beforeValue,
  String? afterValue,
}) async {
  if (orderRef == null) {
    return;
  }

  final mappedAction = switch (actionType) {
    OrderActivityAction.orderDelete => AuditLogAction.deleteOrder,
    OrderActivityAction.orderRestore => AuditLogAction.updateOrder,
    OrderActivityAction.orderPermanentDelete => AuditLogAction.deleteOrder,
    _ => AuditLogAction.updateOrder,
  };

  await AuditLogService.logAction(
    action: mappedAction,
    entityType: AuditLogEntityType.order,
    entityId: orderRef.id,
    entityLabel: beforeValue?.isNotEmpty == true ? beforeValue : orderRef.id,
    oldValue: beforeValue != null && beforeValue.isNotEmpty
        ? {'summary': beforeValue}
        : null,
    newValue: afterValue != null && afterValue.isNotEmpty
        ? {'summary': afterValue}
        : null,
    description: actionType,
    companyId: companyRef?.id,
  );
}
