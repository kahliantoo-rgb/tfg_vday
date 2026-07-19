import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/audit_logs_record.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/users_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';

/// Canonical audit log action names.
abstract final class AuditLogAction {
  static const createOrder = 'create_order';
  static const updateOrder = 'update_order';
  static const deleteOrder = 'delete_order';
  static const cancelOrder = 'cancel_order';
  static const changeOrderStatus = 'change_order_status';
  static const updateDeliveryDateTime = 'update_delivery_date_time';
  static const updateCustomerDetails = 'update_customer_details';
  static const assignDriver = 'assign_driver';
  static const uploadDeliveryProof = 'upload_delivery_proof';
  static const addStaff = 'add_staff';
  static const deactivateStaff = 'deactivate_staff';
  static const reactivateStaff = 'reactivate_staff';
  static const deleteStaffProfile = 'delete_staff_profile';
  static const exportSalesReport = 'export_sales_report';
  static const printReceipt = 'print_receipt';
  static const shopifyOrderImported = 'shopify_order_imported';
  static const applyOrderDiscount = 'apply_order_discount';

  static const all = [
    createOrder,
    updateOrder,
    deleteOrder,
    cancelOrder,
    changeOrderStatus,
    updateDeliveryDateTime,
    updateCustomerDetails,
    assignDriver,
    uploadDeliveryProof,
    addStaff,
    deactivateStaff,
    reactivateStaff,
    deleteStaffProfile,
    exportSalesReport,
    printReceipt,
    shopifyOrderImported,
    applyOrderDiscount,
  ];
}

abstract final class AuditLogEntityType {
  static const order = 'order';
  static const staff = 'staff';
  static const report = 'report';
  static const receipt = 'receipt';
}

/// Writes immutable rows to [AuditLogsRecord.collection].
/// Failures are swallowed so business actions are never blocked.
class AuditLogService {
  AuditLogService._();

  static Future<void> logAction({
    required String action,
    required String entityType,
    required String entityId,
    String? entityLabel,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? description,
    String? companyId,
  }) async {
    try {
      final uid = currentUserUid;
      if (uid.isEmpty) {
        return;
      }

      final profileSnap = await UsersRecord.collection.doc(uid).get();
      if (!profileSnap.exists) {
        debugPrint('AuditLogService: missing users/$uid profile');
        return;
      }

      final profile = UsersRecord.getDocumentFromData(
        Map<String, dynamic>.from(profileSnap.data() as Map),
        profileSnap.reference,
      );

      final resolvedCompanyId = companyId ??
          TenantContext.instance.writeCompanyId.ifEmpty(
            () => profile.companyRef?.id ?? '',
          );
      final companyRef = resolvedCompanyId.isEmpty
          ? profile.companyRef
          : CompaniesRecord.collection.doc(
              canonicalCompanyId(resolvedCompanyId),
            );

      final userName = profile.displayName.isNotEmpty
          ? profile.displayName
          : (profile.name.isNotEmpty ? profile.name : profile.email);

      await AuditLogsRecord.collection.add(
        createAuditLogsRecordData(
          userId: uid,
          userName: userName,
          userRole: profile.role?.serialize() ?? '',
          action: action,
          entityType: entityType,
          entityId: entityId,
          entityLabel: entityLabel,
          oldValue: oldValue,
          newValue: newValue,
          description: description,
          companyId: resolvedCompanyId.isEmpty ? null : resolvedCompanyId,
          companyRef: companyRef,
          createdAt: FieldValue.serverTimestamp(),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('AuditLogService.logAction failed: $e');
      debugPrint('$stackTrace');
    }
  }
}

extension _EmptyStringFallback on String {
  String ifEmpty(String Function() fallback) =>
      isEmpty ? fallback() : this;
}
