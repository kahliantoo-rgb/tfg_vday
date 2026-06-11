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
  final uid = user.uid.isNotEmpty ? user.uid : user.reference.id;
  return UsersRecord.collection.doc(uid);
}

bool receivesOrderCreatedNotices(UserRole? role) =>
    role != null && _orderCreatedRecipientRoles.contains(role);

bool isStaffNoticeUnread(StaffNoticesRecord notice) => !notice.hasReadAt();

String staffNoticeTitle(StaffNoticesRecord notice) {
  switch (notice.type) {
    case StaffNoticeType.driverAssigned:
      return 'Delivery assigned';
    case StaffNoticeType.orderCreated:
    default:
      return 'New order';
  }
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
    final uid = user.uid.isNotEmpty ? user.uid : user.reference.id;
    if (excludeUid != null && excludeUid.isNotEmpty && uid == excludeUid) {
      return false;
    }
    return canonicalCompanyId(user.companyRef?.id) == companyId;
  }).toList();
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
  for (final recipient in recipients) {
    final ref = StaffNoticesRecord.collection.doc();
    batch.set(
      ref,
      createStaffNoticesRecordData(
        type: StaffNoticeType.orderCreated,
        recipientUserRef: staffNoticeRecipientRef(recipient),
        orderRef: order.reference,
        orderId: orderId,
        deliveryDate: order.deliveryDate ?? order.createdTime,
        itemSummary: itemSummary,
        message: message,
        createdTime: getCurrentTimestamp,
        companyRef: companyRef,
      ),
    );
  }
  await batch.commit();
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
