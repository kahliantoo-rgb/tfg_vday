import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/order_id_service.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/counter_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/serialization_util.dart';
import '/index.dart';

/// Thrown when draft order creation fails before navigation.
class CreateOrderException implements Exception {
  CreateOrderException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// User-visible message from Firestore / web interop errors.
String describeFirestoreError(Object error) {
  if (error is FirebaseException) {
    return '${error.code}: ${error.message ?? error.toString()}';
  }
  if (error is CreateOrderException) {
    return error.message;
  }
  final text = error.toString();
  if (text.contains('permission-denied') ||
      text.contains('PERMISSION_DENIED')) {
    return 'Permission denied. Sign out and in again. '
        'Ensure users/$currentUserUid exists with role and companyRef.';
  }
  return text;
}

/// Creates a draft order + navigates to product selection.
Future<void> createDraftOrderAndOpenProductSelection(
  BuildContext context,
) async {
  final block = await TenantContext.instance.ensureReadyForNewOrder();
  if (block != null) {
    throw CreateOrderException(block);
  }

  final uid = currentUserUid;
  if (uid.isEmpty) {
    throw CreateOrderException('Not signed in.');
  }

  final canonicalSnap = await UsersRecord.collection.doc(uid).get();
  if (!canonicalSnap.exists) {
    throw CreateOrderException(
      'Missing Firestore profile at users/$uid. '
      'Ask admin to run: npm run fix:user-ids (firebase folder).',
    );
  }

  final profile = UsersRecord.getDocumentFromData(
    Map<String, dynamic>.from(canonicalSnap.data() as Map),
    canonicalSnap.reference,
  );

  // Always bind writes to companyRef on users/{uid} (fixes I/l typo + stale cache).
  final companyRef = canonicalCompanyRef(profile.companyRef);
  if (profile.companyRef != null) {
    await TenantContext.instance.setActiveCompany(companyRef, viewAll: false);
  }

  final writeCompany = TenantContext.instance.writeCompanyRef;
  if (writeCompany == null) {
    throw CreateOrderException(
      'Your profile has no companyRef. Set it in Firebase users/$uid.',
    );
  }

  final companyId = writeCompany.id;

  try {
    await CompaniesRecord.getDocumentOnce(writeCompany);
  } catch (_) {
    throw CreateOrderException(
      'Companies/$companyId does not exist. '
      'Fix companyRef on users/$uid to the correct Companies document.',
    );
  }

  try {
    await CounterRecord.collection.doc('default_delivery').get();
  } on FirebaseException catch (e) {
    throw CreateOrderException(
      'Cannot access counter/default_delivery (${e.code}). '
      'Ensure the doc exists with fields current and comR.',
    );
  }

  final orderId = await OrderIdService.nextDeliveryOrderId();
  final orderRef = OrdersRecord.collection.doc();
  final orderData = createTenantOrdersRecordData(
    createdTime: getCurrentTimestamp,
    orderId: orderId,
  );

  await orderRef.set(orderData);

  if (!context.mounted) {
    return;
  }

  // extra for same-session nav; query param survives web refresh / deep link.
  final orderRefParam = serializeParam(
    orderRef,
    ParamType.DocumentReference,
  );
  context.pushNamed(
    ProductselectionCopyWidget.routeName,
    queryParameters: orderRefParam != null
        ? <String, String>{'orderRef': orderRefParam}
        : const <String, String>{},
    extra: <String, dynamic>{
      'orderRef': orderRef,
    },
  );
}
