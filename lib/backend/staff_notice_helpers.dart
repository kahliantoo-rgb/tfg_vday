import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/staff_notices_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_list_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

abstract final class StaffNoticeType {
  static const orderCreated = 'order_created';
  static const driverAssigned = 'driver_assigned';
  static const shopifyOrderImported = 'shopify_order_imported';
}

const _orderCreatedRecipientRoles = {
  UserRole.admin,
  UserRole.director,
  UserRole.manager,
  UserRole.senior_florist,
  UserRole.florist,
};

/// Firestore rules only allow reading notices where [recipient_user_ref] is
/// `users/{auth.uid}` — not a legacy profile document id.
DocumentReference staffNoticeRecipientRef(UsersRecord user) {
  final ref = tryStaffNoticeRecipientRef(user);
  if (ref == null) {
    throw StateError(
      'User ${user.reference.path} is missing uid — run fix_user_profile_ids.js',
    );
  }
  return ref;
}

DocumentReference? tryStaffNoticeRecipientRef(UsersRecord user) {
  final uid = user.uid.trim();
  if (uid.isEmpty) {
    return null;
  }
  return UsersRecord.collection.doc(uid);
}

bool receivesOrderCreatedNotices(UserRole? role) =>
    role != null && _orderCreatedRecipientRoles.contains(role);

bool isStaffNoticeUnread(StaffNoticesRecord notice) => !notice.hasReadAt();

String staffNoticeTitle(StaffNoticesRecord notice) {
  switch (notice.type) {
    case StaffNoticeType.driverAssigned:
      return 'Delivery assigned';
    case StaffNoticeType.shopifyOrderImported:
      return 'New Shopify Order';
    case StaffNoticeType.orderCreated:
    default:
      return 'New order';
  }
}

String staffNoticeDeliveryDateLabel(StaffNoticesRecord notice) {
  final date = notice.deliveryDate;
  if (date == null) {
    return '-';
  }
  return '${date.day} ${_monthLabel(date.month)} ${date.year}';
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) {
    return '';
  }
  return labels[month - 1];
}

String staffNoticeBody(StaffNoticesRecord notice) {
  if (notice.type == StaffNoticeType.shopifyOrderImported &&
      notice.message.isNotEmpty) {
    return notice.message;
  }
  return [
    if (notice.orderId.isNotEmpty) 'Order ${notice.orderId}',
    'Delivery ${staffNoticeDeliveryDateLabel(notice)}',
    if (notice.itemSummary.isNotEmpty) notice.itemSummary,
  ].join('\n');
}

Stream<List<StaffNoticesRecord>> streamStaffNoticesForRecipient(
  DocumentReference recipientRef, {
  int limit = 50,
}) =>
    StaffNoticesRecord.collection
        .where('recipient_user_ref', isEqualTo: recipientRef)
        .orderBy('created_time', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffNoticesRecord.fromSnapshot(doc))
              .toList(),
        );

Future<String> resolveOrderItemSummary(DocumentReference orderRef) async {
  final items = await queryTenantOrderItemRecordOnce(
    queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
    limit: 20,
  );
  return orderListProductSummary(items);
}

Future<List<UsersRecord>> loadOrderCreatedNoticeRecipients({
  required DocumentReference? companyRef,
  String? excludeUid,
}) async {
  if (companyRef == null) {
    return const [];
  }
  final companyId = canonicalCompanyId(companyRef.id);
  final allUsers = await queryUsersRecordOnce();
  return allUsers.where((user) {
    if (!userIsActive(user)) {
      return false;
    }
    if (!receivesOrderCreatedNotices(user.role)) {
      return false;
    }
    final uid = user.uid.trim();
    if (uid.isEmpty) {
      return false;
    }
    if (excludeUid != null && excludeUid.isNotEmpty && uid == excludeUid) {
      return false;
    }
    return canonicalCompanyId(user.companyRef?.id) == companyId;
  }).toList();
}

Future<bool> staffOrderCreatedNoticeAlreadySent(DocumentReference orderRef) async {
  final existing = await StaffNoticesRecord.collection
      .where('order_ref', isEqualTo: orderRef)
      .limit(10)
      .get();
  return existing.docs.any((doc) {
    final data = doc.data();
    return data is Map<String, dynamic> &&
        data['type'] == StaffNoticeType.orderCreated;
  });
}

/// Sends order-created notices once per order (safe to call from multiple flows).
Future<void> ensureStaffOrderCreatedNotice(OrdersRecord order) async {
  if (await staffOrderCreatedNoticeAlreadySent(order.reference)) {
    return;
  }
  await notifyStaffOrderCreated(order);
}

Future<void> _writeStaffNotice({
  required String type,
  required DocumentReference recipientUserRef,
  required OrdersRecord order,
  required String itemSummary,
  required String message,
}) async {
  await StaffNoticesRecord.collection.doc().set(
        createStaffNoticesRecordData(
          type: type,
          recipientUserRef: recipientUserRef,
          orderRef: order.reference,
          orderId: orderListOrderId(order),
          deliveryDate: order.deliveryDate ?? order.createdTime,
          itemSummary: itemSummary,
          message: message,
          createdTime: getCurrentTimestamp,
          companyRef: order.companyRef,
        ),
      );
}

Future<void> notifyStaffOrderCreated(OrdersRecord order) async {
  try {
    final companyRef = order.companyRef;
    if (companyRef == null) {
      return;
    }

    final recipients = await loadOrderCreatedNoticeRecipients(
      companyRef: companyRef,
      excludeUid: currentUserUid,
    );
    if (recipients.isEmpty) {
      return;
    }

    final itemSummary = await resolveOrderItemSummary(order.reference);
    final orderId = orderListOrderId(order);
    final message = 'Order $orderId was created';

    final batch = FirebaseFirestore.instance.batch();
    var writes = 0;
    for (final recipient in recipients) {
      final recipientRef = tryStaffNoticeRecipientRef(recipient);
      if (recipientRef == null) {
        continue;
      }
      final ref = StaffNoticesRecord.collection.doc();
      batch.set(
        ref,
        createStaffNoticesRecordData(
          type: StaffNoticeType.orderCreated,
          recipientUserRef: recipientRef,
          orderRef: order.reference,
          orderId: orderId,
          deliveryDate: order.deliveryDate ?? order.createdTime,
          itemSummary: itemSummary,
          message: message,
          createdTime: getCurrentTimestamp,
          companyRef: companyRef,
        ),
      );
      writes++;
    }
    if (writes == 0) {
      return;
    }
    await batch.commit();
  } catch (_) {
    // Notice delivery must not block order flows.
  }
}

Future<void> notifyDriverAssigned({
  required OrdersRecord order,
  required DocumentReference driverUserRef,
}) async {
  if (driverUserRef.path.isEmpty) {
    return;
  }

  final driver = await UsersRecord.getDocumentOnce(driverUserRef);
  final itemSummary = await resolveOrderItemSummary(order.reference);
  final orderId = orderListOrderId(order);
  await _writeStaffNotice(
    type: StaffNoticeType.driverAssigned,
    recipientUserRef: staffNoticeRecipientRef(driver),
    order: order,
    itemSummary: itemSummary,
    message: 'You were assigned order $orderId',
  );
}

Future<void> markStaffNoticeRead(DocumentReference noticeRef) async {
  await noticeRef.update(
    createStaffNoticesRecordData(readAt: getCurrentTimestamp),
  );
}
