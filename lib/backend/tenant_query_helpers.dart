import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_context.dart';

/// Applies company filter only when not in cross-company view mode.
Query applyTenantCompanyFilter(Query query) {
  if (TenantContext.instance.isViewingAllCompanies) {
    return query;
  }
  final companyRef = TenantContext.instance.activeCompanyRef;
  if (companyRef != null) {
    return query.where('companyRef', isEqualTo: companyRef);
  }
  return query;
}

Query Function(Query) chainQueryBuilders(
  Query Function(Query) base,
  Query Function(Query)? extra,
) {
  return (Query query) {
    query = base(query);
    if (extra != null) {
      query = extra(query);
    }
    return query;
  };
}

// --- Orders ---

Stream<List<OrdersRecord>> queryTenantOrdersRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryOrdersRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<OrdersRecord>> queryTenantOrdersRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryOrdersRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<int> queryTenantOrdersRecordCount({
  Query Function(Query)? queryBuilder,
  int limit = -1,
}) =>
    queryOrdersRecordCount(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
    );

// --- Order items ---

Stream<List<OrderItemRecord>> queryTenantOrderItemRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryOrderItemRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<OrderItemRecord>> queryTenantOrderItemRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryOrderItemRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

// --- Products ---

Stream<List<ProductRecord>> queryTenantProductRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryProductRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<ProductRecord>> queryTenantProductRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryProductRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Stream<List<CustomProductRecord>> queryTenantCustomProductRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCustomProductRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

/// Injects [companyRef] for new Firestore writes.
Map<String, dynamic> withTenantFields(Map<String, dynamic> data) {
  final ref = TenantContext.instance.activeCompanyRef;
  if (ref == null) {
    return data;
  }
  return {...data, 'companyRef': ref};
}

/// Order create payload including active tenant.
Map<String, dynamic> createTenantOrdersRecordData({
  String? clientName,
  String? address,
  String? region,
  DateTime? deliveryDate,
  DocumentReference? assignedDriver,
  DateTime? createdTime,
  String? cardMessage,
  String? orderId,
  String? autoRegion,
  String? postalCode,
  String? cancelReason,
  DateTime? cancelledAt,
  String? deliveryTimeSlot,
  DateTime? deliveryTimeActual,
  double? total,
  String? orderType,
  String? paymentType,
  OrderStatus? status,
  String? customerPhoneNumber,
  DocumentReference? productSelection,
  double? totalAmount,
  int? totalQty,
  int? current,
  int? currentrtl,
  String? pickupDelivery,
  String? orderstatus,
}) =>
    createOrdersRecordData(
      clientName: clientName,
      address: address,
      region: region,
      deliveryDate: deliveryDate,
      assignedDriver: assignedDriver,
      createdTime: createdTime,
      cardMessage: cardMessage,
      orderId: orderId,
      autoRegion: autoRegion,
      postalCode: postalCode,
      cancelReason: cancelReason,
      cancelledAt: cancelledAt,
      deliveryTimeSlot: deliveryTimeSlot,
      deliveryTimeActual: deliveryTimeActual,
      total: total,
      orderType: orderType,
      paymentType: paymentType,
      status: status,
      customerPhoneNumber: customerPhoneNumber,
      productSelection: productSelection,
      totalAmount: totalAmount,
      totalQty: totalQty,
      current: current,
      currentrtl: currentrtl,
      pickupDelivery: pickupDelivery,
      orderstatus: orderstatus,
      companyRef: TenantContext.instance.activeCompanyRef,
    );

/// Catalog product create payload with active tenant.
Map<String, dynamic> createTenantProductRecordData({
  String? name,
  double? price,
  String? image,
  String? sku,
  bool? isActive,
  String? category,
}) =>
    createProductRecordData(
      name: name,
      price: price,
      image: image,
      sku: sku,
      isActive: isActive,
      category: category,
      companyRef: TenantContext.instance.activeCompanyRef,
    );

/// Order line item (incl. customize SKU) with active tenant.
Map<String, dynamic> createTenantOrderItemRecordData({
  DocumentReference? orderRef,
  DocumentReference? productRef,
  String? name,
  int? qty,
  double? subtotal,
  String? sku,
  double? price,
  DocumentReference? customProduct,
  String? remark,
  String? clientName,
  String? orderId,
  String? customerphonenumber,
  String? address,
  String? region,
  String? cardmessage,
  String? status,
  DateTime? deliverydate,
}) =>
    createOrderItemRecordData(
      orderRef: orderRef,
      productRef: productRef,
      name: name,
      qty: qty,
      subtotal: subtotal,
      sku: sku,
      price: price,
      customProduct: customProduct,
      remark: remark,
      clientName: clientName,
      orderId: orderId,
      customerphonenumber: customerphonenumber,
      address: address,
      region: region,
      cardmessage: cardmessage,
      status: status,
      deliverydate: deliverydate,
      companyRef: TenantContext.instance.activeCompanyRef,
    );

/// Custom product template row with active tenant.
Map<String, dynamic> createTenantCustomProductRecordData({
  String? name,
  int? qty,
  double? price,
  String? remark,
  DocumentReference? orderRef,
  DocumentReference? orderItem,
}) =>
    createCustomProductRecordData(
      name: name,
      qty: qty,
      price: price,
      remark: remark,
      orderRef: orderRef,
      orderItem: orderItem,
      companyRef: TenantContext.instance.activeCompanyRef,
    );

/// Returns false and shows a snackbar if no company is selected for writes.
bool ensureActiveCompanyForWrite(BuildContext context) {
  if (TenantContext.instance.hasActiveCompany) {
    return true;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        TenantContext.instance.isViewingAllCompanies
            ? 'Please select a company first (top-right Company menu).'
            : 'Please select a company before saving.',
      ),
    ),
  );
  return false;
}
