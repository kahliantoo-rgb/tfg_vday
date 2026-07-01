import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';

/// Applies company filter only when not in cross-company view mode.
Query applyTenantCompanyFilter(Query query) {
  if (TenantContext.instance.isViewingAllCompanies) {
    return query;
  }
  final companyRef = TenantContext.instance.activeCompanyRef;
  if (companyRef == null) {
    return query;
  }
  final profileRef = TenantContext.instance.profile?.companyRef;
  if (profileRef != null && isTypoCompanyId(profileRef.id)) {
    final canonical = canonicalCompanyRef(profileRef);
    return query.where(
      'companyRef',
      whereIn: [profileRef, canonical],
    );
  }
  return query.where('companyRef', isEqualTo: companyRef);
}

/// Tenant filter for audit_logs (companyRef matches legacy + new rows).
Query applyTenantAuditLogFilter(Query query) {
  if (TenantContext.instance.isViewingAllCompanies) {
    return query;
  }
  final companyRef = TenantContext.instance.writeCompanyRef;
  if (companyRef != null) {
    return query.where('companyRef', isEqualTo: companyRef);
  }
  final companyId = TenantContext.instance.writeCompanyId;
  if (companyId.isNotEmpty) {
    return query.where('companyId', isEqualTo: companyId);
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

Stream<List<MaterialRecord>> queryTenantMaterialRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryMaterialRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

// --- Deleted orders archive ---

Stream<List<DeletedOrdersRecord>> queryTenantDeletedOrdersRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryDeletedOrdersRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<DeletedOrdersRecord>> queryTenantDeletedOrdersRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryDeletedOrdersRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

// --- Audit logs ---

Future<List<AuditLogsRecord>> queryTenantAuditLogsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryAuditLogsRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantAuditLogFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<AuditLogsRecord>> queryOrderActivityLogsOnce(
  DocumentReference orderRef,
) async {
  final byEntityId = await queryTenantAuditLogsRecordOnce(
    queryBuilder: (query) => query.where('entityId', isEqualTo: orderRef.id),
  );
  final byEntityRef = await queryTenantAuditLogsRecordOnce(
    queryBuilder: (query) => query.where('entity_ref', isEqualTo: orderRef),
  );
  final merged = <String, AuditLogsRecord>{
    for (final log in [...byEntityId, ...byEntityRef]) log.reference.id: log,
  }.values.toList();
  merged.sort((a, b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return merged;
}

// --- Products ---

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

Future<List<MaterialRecord>> queryTenantMaterialRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryMaterialRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<PriceListsRecord>> queryTenantPriceListsRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryPriceListsRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

/// Keeps only products belonging to [companyRef]. Legacy docs without
/// companyRef are excluded (strict tenant isolation).
List<ProductRecord> filterProductsByCompanyRef(
  List<ProductRecord> products,
  DocumentReference? companyRef,
) {
  if (companyRef == null) {
    return [];
  }
  final target = canonicalCompanyRef(companyRef);
  return products.where((p) {
    if (!p.hasCompanyRef()) {
      return false;
    }
    return canonicalCompanyRef(p.companyRef).path == target.path;
  }).toList();
}

/// Active products for the current tenant without a composite Firestore index.
/// Queries only [isActive], then filters/sorts in memory (avoids stuck loaders).
List<ProductRecord> filterAndSortActiveProducts(List<ProductRecord> products) {
  final tenant = TenantContext.instance;
  final companyRef = canonicalCompanyRef(
    tenant.writeCompanyRef ?? tenant.activeCompanyRef,
  );

  Iterable<ProductRecord> list = products;
  if (companyRef != null) {
    list = filterProductsByCompanyRef(products, companyRef);
  } else if (!tenant.isViewingAllCompanies) {
    list = const <ProductRecord>[];
  }

  final out = list.toList();
  out.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return out;
}

Stream<List<ProductRecord>> queryActiveProductsForTenant() =>
    queryTenantProductRecord(
      queryBuilder: (productRecord) => productRecord.where(
        'isActive',
        isEqualTo: true,
      ),
    ).map(filterAndSortActiveProducts);

Future<List<ProductRecord>> queryActiveProductsForTenantOnce() =>
    queryTenantProductRecordOnce(
      queryBuilder: (productRecord) => productRecord.where(
        'isActive',
        isEqualTo: true,
      ),
    ).then(filterAndSortActiveProducts);

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

/// CompanyRef on Firestore writes — matches [authUserCompanyRef] in security rules.
DocumentReference? tenantCompanyRefForRules() =>
    TenantContext.instance.rulesMatchedCompanyRef ??
    TenantContext.instance.writeCompanyRef;

/// Injects [companyRef] for new Firestore writes.
Map<String, dynamic> withTenantFields(Map<String, dynamic> data) {
  final ref = tenantCompanyRefForRules();
  if (ref == null) {
    return data;
  }
  return {...data, 'companyRef': ref};
}

/// Order create payload including active tenant.
Map<String, dynamic> createTenantOrdersRecordData({
  String? clientName,
  String? recipientName,
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
  String? recipientPhoneNumber,
  DocumentReference? productSelection,
  double? totalAmount,
  int? totalQty,
  int? current,
  int? currentrtl,
  String? pickupDelivery,
  String? orderstatus,
  DocumentReference? customerRef,
}) =>
    createOrdersRecordData(
      clientName: clientName,
      recipientName: recipientName,
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
      recipientPhoneNumber: recipientPhoneNumber,
      productSelection: productSelection,
      totalAmount: totalAmount,
      totalQty: totalQty,
      current: current,
      currentrtl: currentrtl,
      pickupDelivery: pickupDelivery,
      orderstatus: orderstatus,
      customerRef: customerRef,
      companyRef: tenantCompanyRefForRules(),
    );

// --- Customers ---

Stream<List<CustomersRecord>> queryTenantCustomersRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCustomersRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<CustomersRecord>> queryTenantCustomersRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryCustomersRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

// --- Invoices ---

Stream<List<InvoicesRecord>> queryTenantInvoicesRecord({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryInvoicesRecord(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Future<List<InvoicesRecord>> queryTenantInvoicesRecordOnce({
  Query Function(Query)? queryBuilder,
  int limit = -1,
  bool singleRecord = false,
}) =>
    queryInvoicesRecordOnce(
      queryBuilder: chainQueryBuilders(
        applyTenantCompanyFilter,
        queryBuilder,
      ),
      limit: limit,
      singleRecord: singleRecord,
    );

Map<String, dynamic> createTenantCustomersRecordData({
  String? name,
  String? phone,
  String? email,
  String? billingAddress,
  String? uen,
  bool? isCreditCustomer,
  String? creditTerm,
  DateTime? createdTime,
  DateTime? updatedTime,
}) =>
    createCustomersRecordData(
      name: name,
      phone: phone,
      email: email,
      billingAddress: billingAddress,
      uen: uen,
      isCreditCustomer: isCreditCustomer,
      creditTerm: creditTerm,
      createdTime: createdTime,
      updatedTime: updatedTime,
      companyRef: TenantContext.instance.rulesMatchedCompanyRef,
    );

/// Catalog product create payload with active tenant.
Map<String, dynamic> createTenantProductRecordData({
  String? name,
  double? price,
  String? image,
  String? sku,
  bool? isActive,
  String? category,
  List<Map<String, dynamic>>? recipeLines,
}) =>
    createProductRecordData(
      name: name,
      price: price,
      image: image,
      sku: sku,
      isActive: isActive,
      category: category,
      recipeLines: recipeLines,
      companyRef: tenantCompanyRefForRules(),
    );

/// Material catalog row with active tenant.
Map<String, dynamic> createTenantMaterialRecordData({
  String? name,
  String? unit,
  String? sku,
  double? cost,
  bool? isActive,
  String? category,
}) =>
    createMaterialRecordData(
      name: name,
      unit: unit,
      sku: sku,
      cost: cost,
      isActive: isActive,
      category: category,
      companyRef: tenantCompanyRefForRules(),
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
  String? image,
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
      image: image,
      companyRef: tenantCompanyRefForRules(),
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
      companyRef: tenantCompanyRefForRules(),
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
