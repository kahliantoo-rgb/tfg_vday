import '/auth/firebase_auth/auth_util.dart';
import '/backend/audit_log_service.dart';
import '/backend/backend.dart' show queryAuditLogsRecordOnce;
import '/backend/schema/audit_logs_record.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_list_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Map<String, dynamic> orderAuditSnapshot(OrdersRecord order) => {
      'orderId': order.orderId,
      'clientName': order.clientName,
      'recipientName': order.recipientName,
      'customerPhoneNumber': order.customerPhoneNumber,
      'recipientPhoneNumber': order.recipientPhoneNumber,
      'address': order.address,
      'region': order.region,
      'postalCode': order.postalCode,
      'deliveryDate': order.deliveryDate?.toIso8601String(),
      'deliveryTimeSlot': order.deliveryTimeSlot,
      'status': order.status?.serialize(),
      'orderType': order.orderType,
      'assignedDriverId': order.assignedDriver?.id,
    };

Map<String, dynamic> staffAuditSnapshot(UsersRecord user) => {
      'uid': user.uid.isNotEmpty ? user.uid : user.reference.id,
      'name': user.name,
      'email': user.email,
      'role': user.role?.serialize(),
      'isActive': user.isActive,
      'companyId': user.companyRef?.id,
    };

String orderEntityLabel(OrdersRecord order) =>
    order.orderId.isNotEmpty ? order.orderId : order.reference.id;

String staffEntityLabel(UsersRecord user) {
  if (user.displayName.isNotEmpty) {
    return user.displayName;
  }
  if (user.name.isNotEmpty) {
    return user.name;
  }
  return user.email.isNotEmpty ? user.email : user.reference.id;
}

String auditLogPerformerLabel(AuditLogsRecord log) {
  if (log.userName.isNotEmpty) {
    return log.userName;
  }
  if (log.userId.isNotEmpty) {
    return log.userId;
  }
  if (log.performedBy != null) {
    return log.performedBy!.id;
  }
  return 'Unknown user';
}

String auditActionLabel(String action) {
  switch (action) {
    case AuditLogAction.createOrder:
      return 'Create order';
    case AuditLogAction.updateOrder:
      return 'Update order';
    case AuditLogAction.deleteOrder:
      return 'Delete order';
    case AuditLogAction.cancelOrder:
      return 'Cancel order';
    case AuditLogAction.changeOrderStatus:
      return 'Change order status';
    case AuditLogAction.updateDeliveryDateTime:
      return 'Update delivery date/time';
    case AuditLogAction.updateCustomerDetails:
      return 'Update customer details';
    case AuditLogAction.assignDriver:
      return 'Assign driver';
    case AuditLogAction.uploadDeliveryProof:
      return 'Upload delivery proof';
    case AuditLogAction.addStaff:
      return 'Add staff';
    case AuditLogAction.deactivateStaff:
      return 'Deactivate staff';
    case AuditLogAction.reactivateStaff:
      return 'Reactivate staff';
    case AuditLogAction.deleteStaffProfile:
      return 'Delete staff profile';
    case AuditLogAction.exportSalesReport:
      return 'Export sales report';
    case AuditLogAction.printReceipt:
      return 'Print receipt / PDF invoice';
    case AuditLogAction.shopifyOrderImported:
      return 'Shopify Order Imported';
    default:
      return action.replaceAll('_', ' ');
  }
}

Future<void> auditLogCreateOrder(OrdersRecord order) async {
  await AuditLogService.logAction(
    action: AuditLogAction.createOrder,
    entityType: AuditLogEntityType.order,
    entityId: order.reference.id,
    entityLabel: orderEntityLabel(order),
    newValue: orderAuditSnapshot(order),
    description: 'Order created (${order.orderType})',
    companyId: order.companyRef?.id,
  );
  try {
    await ensureStaffOrderCreatedNotice(order);
  } catch (_) {
    // Notices must never block order creation or navigation.
  }
}

/// Signed-in staff label for receipts (Firestore profile name, else auth).
String resolvedCurrentCashierLabel() {
  final profile = TenantContext.instance.profile;
  if (profile != null) {
    final fromProfile = userListDisplayName(profile);
    if (fromProfile != 'Unknown user') {
      return fromProfile;
    }
  }
  if (currentUserDisplayName.trim().isNotEmpty) {
    return currentUserDisplayName.trim();
  }
  if (currentUserEmail.trim().isNotEmpty) {
    return currentUserEmail.trim();
  }
  return '';
}

/// Receipt "Cashier:" value — order creator name from audit log.
String formatReceiptCashierLabel(String? cashierName) {
  final trimmed = cashierName?.trim() ?? '';
  if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'cashier') {
    return trimmed;
  }
  return 'Not set';
}

/// Full receipt line: `Cashier: <staff name>`.
String formatReceiptCashierLine(String? cashierName) {
  return 'Cashier: ${formatReceiptCashierLabel(cashierName)}';
}

String _cashierFallbackFromRoute(String? routeCashier) {
  final route = routeCashier?.trim() ?? '';
  if (route.isNotEmpty && route.toLowerCase() != 'cashier') {
    return route;
  }
  return resolvedCurrentCashierLabel();
}

/// Cashier label for receipts: staff who created the order.
Future<String> receiptCashierLabelForOrder(
  DocumentReference orderRef, {
  String? routeCashier,
}) async {
  return formatReceiptCashierLabel(
    await resolveOrderCashierName(
      orderRef,
      fallback: _cashierFallbackFromRoute(routeCashier),
    ),
  );
}

/// Full cashier line for receipts and PDF invoices.
Future<String> receiptCashierLineForOrder(
  DocumentReference orderRef, {
  String? routeCashier,
}) async {
  return formatReceiptCashierLine(
    await resolveOrderCashierName(
      orderRef,
      fallback: _cashierFallbackFromRoute(routeCashier),
    ),
  );
}

Future<String> _cashierNameFromAuditLog(AuditLogsRecord log) async {
  if (log.userId.isNotEmpty) {
    try {
      final user = await UsersRecord.getDocumentOnce(
        UsersRecord.collection.doc(log.userId),
      );
      final name = userListDisplayName(user);
      if (name != 'Unknown user') {
        return name;
      }
    } catch (_) {
      // Profile missing — fall back to audit log fields below.
    }
  }
  final label = auditLogPerformerLabel(log);
  if (label.isNotEmpty && label != 'Unknown user') {
    return label;
  }
  return '';
}

/// Staff name who created the order (from audit log), else [fallback].
Future<String> resolveOrderCashierName(
  DocumentReference orderRef, {
  String fallback = '',
}) async {
  try {
    final logs = await queryAuditLogsRecordOnce(
      queryBuilder: (q) => q
          .where('entity_id', isEqualTo: orderRef.id)
          .limit(25),
    );
    AuditLogsRecord? latestCreate;
    for (final log in logs) {
      if (log.action != AuditLogAction.createOrder) {
        continue;
      }
      if (latestCreate == null ||
          (log.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .isAfter(latestCreate.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0))) {
        latestCreate = log;
      }
    }
    if (latestCreate != null) {
      final name = await _cashierNameFromAuditLog(latestCreate);
      if (name.isNotEmpty) {
        return name;
      }
    }
  } catch (_) {
    // Missing index or permission — fall back below.
  }
  return fallback.trim();
}

Future<void> auditLogUpdateOrder({
  required OrdersRecord before,
  required Map<String, dynamic> afterSnapshot,
  String? description,
}) async {
  await AuditLogService.logAction(
    action: AuditLogAction.updateOrder,
    entityType: AuditLogEntityType.order,
    entityId: before.reference.id,
    entityLabel: orderEntityLabel(before),
    oldValue: orderAuditSnapshot(before),
    newValue: afterSnapshot,
    description: description,
    companyId: before.companyRef?.id,
  );
}

Future<void> auditLogOrderStatusChange(
  OrdersRecord order,
  OrderStatus newStatus,
) async {
  await AuditLogService.logAction(
    action: AuditLogAction.changeOrderStatus,
    entityType: AuditLogEntityType.order,
    entityId: order.reference.id,
    entityLabel: orderEntityLabel(order),
    oldValue: {'status': order.status?.serialize()},
    newValue: {'status': newStatus.serialize()},
    companyId: order.companyRef?.id,
  );
}

Future<void> auditLogOrderStatusChangeByRef(
  DocumentReference orderRef,
  OrderStatus newStatus,
) async {
  final order = await OrdersRecord.getDocumentOnce(orderRef);
  await auditLogOrderStatusChange(order, newStatus);
}

Future<void> auditLogCancelOrder(OrdersRecord order) async {
  await AuditLogService.logAction(
    action: AuditLogAction.cancelOrder,
    entityType: AuditLogEntityType.order,
    entityId: order.reference.id,
    entityLabel: orderEntityLabel(order),
    oldValue: orderAuditSnapshot(order),
    newValue: {
      ...orderAuditSnapshot(order),
      'status': OrderStatus.cancelled.serialize(),
    },
    companyId: order.companyRef?.id,
  );
}

Future<void> auditLogAssignDriver({
  required OrdersRecord order,
  required String? oldDriverId,
  required String? newDriverId,
}) async {
  await AuditLogService.logAction(
    action: AuditLogAction.assignDriver,
    entityType: AuditLogEntityType.order,
    entityId: order.reference.id,
    entityLabel: orderEntityLabel(order),
    oldValue: {'assignedDriverId': oldDriverId},
    newValue: {'assignedDriverId': newDriverId},
    companyId: order.companyRef?.id,
  );
}

Future<void> auditLogDeliveryProofUpload({
  required OrdersRecord order,
  required int previousPhotoCount,
  required List<String> uploadedUrls,
  required int totalPhotoCount,
}) async {
  await AuditLogService.logAction(
    action: AuditLogAction.uploadDeliveryProof,
    entityType: AuditLogEntityType.order,
    entityId: order.reference.id,
    entityLabel: orderEntityLabel(order),
    oldValue: {'deliveryProofCount': previousPhotoCount},
    newValue: {
      'deliveryProofCount': totalPhotoCount,
      'uploadedUrls': uploadedUrls,
    },
    description: uploadedUrls.length == 1
        ? 'Delivery proof photo uploaded'
        : '${uploadedUrls.length} delivery proof photos uploaded',
    companyId: order.companyRef?.id,
  );
}

Future<void> auditLogStaffChange({
  required String action,
  required UsersRecord user,
  Map<String, dynamic>? oldValue,
  Map<String, dynamic>? newValue,
  String? description,
}) async {
  await AuditLogService.logAction(
    action: action,
    entityType: AuditLogEntityType.staff,
    entityId: user.uid.isNotEmpty ? user.uid : user.reference.id,
    entityLabel: staffEntityLabel(user),
    oldValue: oldValue,
    newValue: newValue,
    description: description,
    companyId: user.companyRef?.id,
  );
}

Future<void> auditLogExportSalesReport({
  required DateTime startDate,
  required DateTime endDate,
  required int totalOrders,
  required double totalSales,
}) async {
  final label = DateFormat('yyyy-MM-dd').format(startDate);
  final endLabel = DateFormat('yyyy-MM-dd').format(endDate);
  await AuditLogService.logAction(
    action: AuditLogAction.exportSalesReport,
    entityType: AuditLogEntityType.report,
    entityId: '$label..$endLabel',
    entityLabel: 'Sales report $label – $endLabel',
    newValue: {
      'startDate': label,
      'endDate': endLabel,
      'totalOrders': totalOrders,
      'totalSales': totalSales,
    },
    description: 'Sales report generated',
  );
}

Future<void> auditLogPrintReceipt({
  required OrdersRecord order,
  required String format,
}) async {
  await AuditLogService.logAction(
    action: AuditLogAction.printReceipt,
    entityType: AuditLogEntityType.receipt,
    entityId: order.reference.id,
    entityLabel: orderEntityLabel(order),
    newValue: {'format': format, 'orderId': order.orderId},
    description: 'Printed $format for ${orderEntityLabel(order)}',
    companyId: order.companyRef?.id,
  );
}

Future<void> auditLogOrderDetailEdits({
  required OrdersRecord before,
  required Map<String, dynamic> afterSnapshot,
}) async {
  final beforeSnapshot = orderAuditSnapshot(before);
  const customerKeys = {
    'clientName',
    'recipientName',
    'customerPhoneNumber',
    'recipientPhoneNumber',
    'address',
    'region',
    'postalCode',
    'cardMessage',
  };
  const deliveryKeys = {'deliveryDate', 'deliveryTimeSlot'};

  Map<String, dynamic>? pickKeys(
    Map<String, dynamic> source,
    Set<String> keys,
  ) {
    final picked = <String, dynamic>{};
    for (final key in keys) {
      if (source[key] != null) {
        picked[key] = source[key];
      }
    }
    return picked.isEmpty ? null : picked;
  }

  bool changed(Set<String> keys) {
    for (final key in keys) {
      if (beforeSnapshot[key] != afterSnapshot[key]) {
        return true;
      }
    }
    return false;
  }

  if (changed(customerKeys)) {
    await AuditLogService.logAction(
      action: AuditLogAction.updateCustomerDetails,
      entityType: AuditLogEntityType.order,
      entityId: before.reference.id,
      entityLabel: orderEntityLabel(before),
      oldValue: pickKeys(beforeSnapshot, customerKeys),
      newValue: pickKeys(afterSnapshot, customerKeys),
      companyId: before.companyRef?.id,
    );
  }

  if (changed(deliveryKeys)) {
    await AuditLogService.logAction(
      action: AuditLogAction.updateDeliveryDateTime,
      entityType: AuditLogEntityType.order,
      entityId: before.reference.id,
      entityLabel: orderEntityLabel(before),
      oldValue: pickKeys(beforeSnapshot, deliveryKeys),
      newValue: pickKeys(afterSnapshot, deliveryKeys),
      companyId: before.companyRef?.id,
    );
  }

  final otherChanged = {...beforeSnapshot.keys, ...afterSnapshot.keys}
      .where(
        (key) =>
            !customerKeys.contains(key) &&
            !deliveryKeys.contains(key) &&
            beforeSnapshot[key] != afterSnapshot[key],
      )
      .isNotEmpty;

  if (otherChanged) {
    await auditLogUpdateOrder(
      before: before,
      afterSnapshot: afterSnapshot,
      description: 'Order details updated',
    );
  }
}

Map<String, dynamic> orderSnapshotFromEditForm({
  required OrdersRecord order,
  required String clientName,
  required String recipientName,
  required String recipientPhone,
  required String customerPhone,
  required String address,
  required String region,
  required String postalCode,
  required DateTime? deliveryDate,
  required String deliveryTimeSlot,
  required String cardMessage,
}) =>
    {
      'orderId': order.orderId,
      'clientName': clientName,
      'recipientName': recipientName,
      'recipientPhoneNumber': recipientPhone,
      'customerPhoneNumber': customerPhone,
      'address': address,
      'region': region,
      'postalCode': postalCode,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'deliveryTimeSlot': deliveryTimeSlot,
      'status': order.status?.serialize(),
      'orderType': order.orderType,
      'assignedDriverId': order.assignedDriver?.id,
      'cardMessage': cardMessage,
    };
