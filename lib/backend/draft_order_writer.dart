import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/observability/app_logger.dart';
import '/backend/observability/observability_service.dart';
import '/backend/observability/performance_baselines.dart';
import '/backend/offline/offline_write_queue.dart';
import '/backend/order_id_service.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/counter_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Returns true when Firestore failed due to connectivity / availability.
bool isFirestoreNetworkError(Object error) {
  if (error is FirebaseException) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'network-request-failed';
  }
  final text = error.toString().toLowerCase();
  return text.contains('network') ||
      text.contains('unavailable') ||
      text.contains('offline');
}

/// Validates tenant context and writes a draft delivery order to Firestore.
Future<DocumentReference> createDraftOrderDocument() async {
  return ObservabilityService.trace(
    PerformanceBaselines.traceCreateDraftOrder,
    _createDraftOrderDocument,
  );
}

Future<DocumentReference> _createDraftOrderDocument() async {
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

  final deliveryCounterId = OrderIdService.counterDocId('delivery');
  try {
    await CounterRecord.collection.doc(deliveryCounterId).get();
  } on FirebaseException catch (e) {
    throw CreateOrderException(
      'Cannot access counter/$deliveryCounterId (${e.code}). '
      'Run npm run init:counters (firebase folder) for company $companyId.',
    );
  }

  final orderId = await ObservabilityService.trace(
    PerformanceBaselines.traceNextDeliveryOrderId,
    OrderIdService.nextDeliveryOrderId,
  );

  final orderRef = OrdersRecord.collection.doc();
  final orderData = createTenantOrdersRecordData(
    createdTime: getCurrentTimestamp,
    orderId: orderId,
  );

  await orderRef.set(orderData);
  AppLogger.info('Draft order created', context: {'orderId': orderId});
  return orderRef;
}

/// Replays a queued create-order after connectivity returns.
Future<bool> syncQueuedDraftOrder(OfflineWriteItem item) async {
  if (item.retryCount >= 5) {
    AppLogger.error(
      'Dropping offline item after max retries',
      context: {'queueId': item.id},
    );
    return true;
  }

  try {
    final companyPath = item.payload['companyPath'] as String?;
    if (companyPath != null && companyPath.isNotEmpty) {
      await TenantContext.instance.setActiveCompany(
        FirebaseFirestore.instance.doc(companyPath),
        viewAll: false,
      );
    }
    await createDraftOrderDocument();
    return true;
  } catch (error, stackTrace) {
    if (isFirestoreNetworkError(error)) {
      return false;
    }
    AppLogger.error(
      'Permanent offline sync failure',
      error: error,
      stackTrace: stackTrace,
      context: {'queueId': item.id},
    );
    return item.retryCount >= 4;
  }
}

/// Thrown when draft order creation fails before navigation.
class CreateOrderException implements Exception {
  CreateOrderException(this.message);
  final String message;

  @override
  String toString() => message;
}
