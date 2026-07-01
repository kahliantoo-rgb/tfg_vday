import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/draft_order_writer.dart';
import '/backend/offline/offline_write_queue.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// User-visible message from Firestore / web interop errors.
String describeFirestoreError(Object error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      final companyPath = TenantContext.instance.writeCompanyRef?.path;
      final uid = currentUserUid;
      final companyHint = companyPath != null
          ? 'Your companyRef is $companyPath — order data must use the same company. '
              'Ensure users/$uid has role and companyRef, then sign out and sign in again.'
          : 'Your profile may be missing companyRef on users/$uid.';
      return 'Permission denied: ${error.message ?? 'Missing or insufficient permissions.'} '
          '$companyHint';
    }
    if (error.code == 'unknown' &&
        (error.message == null || error.message!.trim().isEmpty)) {
      return 'Could not save delivery. Check network and try again. '
          'If it keeps failing, sign out and sign in again.';
    }
    return '${error.code}: ${error.message ?? error.toString()}';
  }
  if (error is CreateOrderException) {
    return error.message;
  }
  final text = error.toString();
  if (text.contains('INTERNAL ASSERTION FAILED') &&
      (text.contains('b815') || text.contains('ca9'))) {
    return 'Firestore connection error. Refresh the page and try again.';
  }
  if (text.contains('permission-denied') ||
      text.contains('PERMISSION_DENIED')) {
    return 'Permission denied. Sign out and in again. '
        'Ensure users/$currentUserUid exists with role and companyRef.';
  }
  return text;
}

/// Creates a draft order + navigates to product selection.
/// On network failure, queues the write and shows a retry-friendly message.
Future<void> createDraftOrderAndOpenProductSelection(
  BuildContext context,
) async {
  try {
    final orderRef = await createDraftOrderDocument();

    if (!context.mounted) {
      return;
    }

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
  } catch (error) {
    if (!isFirestoreNetworkError(error)) {
      rethrow;
    }

    final writeCompany = TenantContext.instance.writeCompanyRef;
    final uid = currentUserUid;
    if (writeCompany == null || uid.isEmpty) {
      rethrow;
    }

    await OfflineWriteQueue.instance.enqueueCreateDraftOrder(
      uid: uid,
      companyId: writeCompany.id,
      companyPath: writeCompany.path,
    );

    final pending = await OfflineWriteQueue.instance.pendingCount();
    throw CreateOrderException(
      'Network unavailable. Order queued ($pending pending). '
      'Continue on paper if needed — app will sync when online. Tap Create Order again to retry.',
    );
  }
}

/// Runs product-selection navigation actions and surfaces Firestore failures.
Future<void> runProductSelectionAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  final blocked = await TenantContext.instance.ensureReadyForTenantWrite();
  if (blocked != null) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(blocked),
        duration: const Duration(seconds: 8),
      ),
    );
    return;
  }

  try {
    await action();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(describeFirestoreError(error)),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}
