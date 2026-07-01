import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/backend/backend.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/invoices_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/order_id_service.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

DocumentReference? _pendingCreatedCustomerRef;

/// Stash a freshly created customer ref so the list can refresh even when
/// [GoRouter] does not propagate the pop result.
void markPendingCreatedCustomer(DocumentReference ref) {
  _pendingCreatedCustomerRef = ref;
}

DocumentReference? takePendingCreatedCustomerRef() {
  final ref = _pendingCreatedCustomerRef;
  _pendingCreatedCustomerRef = null;
  return ref;
}

final Set<String> _pendingProfileHistoryRefreshCustomerIds = {};

/// Marks a customer profile so order/invoice history reloads when reopened.
void markCustomerProfileHistoryRefresh(String customerId) {
  if (customerId.isEmpty) {
    return;
  }
  _pendingProfileHistoryRefreshCustomerIds.add(customerId);
}

void markCustomerProfileHistoryRefreshForInvoice(InvoicesRecord invoice) {
  if (invoice.hasCustomerRef()) {
    markCustomerProfileHistoryRefresh(invoice.customerRef!.id);
  }
}

bool customerProfileHistoryRefreshPending(String customerId) =>
    _pendingProfileHistoryRefreshCustomerIds.contains(customerId);

bool takeCustomerProfileHistoryRefresh(String customerId) =>
    _pendingProfileHistoryRefreshCustomerIds.remove(customerId);

String normalizeCustomerName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String normalizeCustomerPhone(String value) =>
    value.replaceAll(RegExp(r'\D'), '');

/// Whether [customer] is a persisted Firestore profile (not an invoice snapshot stub).
bool customerProfileIsPersisted(CustomersRecord customer) =>
    customer.hasCompanyRef();

/// Finds a tenant customer by name/phone when [customer_ref] on an invoice is stale.
Future<CustomersRecord?> findTenantCustomerByHints({
  String? nameHint,
  String? phoneHint,
}) async {
  final normalizedName = nameHint != null && nameHint.trim().isNotEmpty
      ? normalizeCustomerName(nameHint)
      : '';
  final normalizedPhone = phoneHint != null && phoneHint.trim().isNotEmpty
      ? normalizeCustomerPhone(phoneHint)
      : '';
  if (normalizedName.isEmpty && normalizedPhone.isEmpty) {
    return null;
  }

  final customers = await queryCustomersForTenantList(limit: 500);
  if (normalizedPhone.isNotEmpty) {
    final phoneMatches = customers
        .where(
          (customer) =>
              normalizeCustomerPhone(customer.phone) == normalizedPhone,
        )
        .toList();
    if (phoneMatches.length == 1) {
      return phoneMatches.first;
    }
  }

  if (normalizedName.isEmpty) {
    return null;
  }

  final exact = customers
      .where(
        (customer) => normalizeCustomerName(customer.name) == normalizedName,
      )
      .toList();
  if (exact.length == 1) {
    return exact.first;
  }

  final partial = customers.where((customer) {
    final customerName = normalizeCustomerName(customer.name);
    return customerName.startsWith(normalizedName) ||
        normalizedName.startsWith(customerName);
  }).toList();
  if (partial.length == 1) {
    return partial.first;
  }

  return null;
}

/// Loads a customer for profile/detail views; repairs stale invoice [customer_ref].
Future<CustomersRecord> loadCustomerProfileRecord(
  DocumentReference customerRef, {
  String? nameHint,
  String? phoneHint,
}) async {
  try {
    final customer = await CustomersRecord.getDocumentOnce(customerRef);
    if (TenantContext.instance.isViewingAllCompanies ||
        customerBelongsToActiveTenant(customer)) {
      return customer;
    }
  } catch (_) {
    // Document missing or rules blocked — try tenant hints below.
  }

  final resolved = await findTenantCustomerByHints(
    nameHint: nameHint,
    phoneHint: phoneHint,
  );
  if (resolved != null) {
    return resolved;
  }

  throw CustomerWriteException(
    'Customer profile not found. The linked record may have been deleted.',
  );
}

/// E.164-style length limits for local and international numbers.
const int kCustomerPhoneMinDigits = 7;
const int kCustomerPhoneMaxDigits = 15;

int customerPhoneDigitCount(String value) =>
    normalizeCustomerPhone(value).length;

bool isValidCustomerPhone(String value) {
  final count = customerPhoneDigitCount(value);
  return count >= kCustomerPhoneMinDigits && count <= kCustomerPhoneMaxDigits;
}

/// Shared validation for customer profile, orders, and imports.
String? validateCustomerPhoneInput(
  String? value, {
  bool required = true,
}) {
  if (value == null || value.trim().isEmpty) {
    return required ? 'Phone is required' : null;
  }
  final count = customerPhoneDigitCount(value);
  if (count < kCustomerPhoneMinDigits) {
    return 'Enter at least $kCustomerPhoneMinDigits digits. '
        'For overseas numbers include country code (e.g. +65, +1, +44).';
  }
  if (count > kCustomerPhoneMaxDigits) {
    return 'Phone number is too long (max $kCustomerPhoneMaxDigits digits).';
  }
  return null;
}

String normalizeCustomerEmail(String value) => value.trim().toLowerCase();

DateTime? normalizeCustomerBirthday(DateTime? value) {
  if (value == null) {
    return null;
  }
  return DateTime(value.year, value.month, value.day);
}

String formatCustomerBirthday(DateTime? birthday) {
  if (birthday == null) {
    return 'Not set';
  }
  return DateFormat('d MMM yyyy').format(birthday);
}

Future<DateTime?> pickCustomerBirthday(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial ?? DateTime(now.year - 30, now.month, now.day),
    firstDate: DateTime(1900),
    lastDate: now,
  );
  if (picked == null) {
    return null;
  }
  return DateTime(picked.year, picked.month, picked.day);
}

/// Optional email on customer profiles.
String? validateCustomerEmailInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final trimmed = value.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return 'Enter a valid email address';
  }
  return null;
}

List<CustomersRecord> filterCustomersByNameQuery(
  List<CustomersRecord> customers,
  String input, {
  int limit = 8,
}) {
  final query = normalizeCustomerName(input);
  if (query.length < 2) {
    return const [];
  }
  final matches = customers.where((customer) {
    final name = normalizeCustomerName(customer.name);
    return name.contains(query) || name.startsWith(query);
  }).toList()
    ..sort(
      (a, b) => normalizeCustomerName(a.name)
          .compareTo(normalizeCustomerName(b.name)),
    );
  if (matches.length <= limit) {
    return matches;
  }
  return matches.sublist(0, limit);
}

List<CustomersRecord> filterCustomersForInvoiceSearch(
  List<CustomersRecord> customers,
  String input, {
  int limit = 8,
}) {
  final rawQuery = input.trim().toLowerCase();
  final normalizedQuery = normalizeCustomerName(input);
  if (rawQuery.length < 2 && normalizedQuery.length < 2) {
    return const [];
  }
  final matches = customers.where((customer) {
    final normalizedName = normalizeCustomerName(customer.name);
    final matchesName = normalizedQuery.length >= 2 &&
        (normalizedName.contains(normalizedQuery) ||
            normalizedName.startsWith(normalizedQuery));
    final matchesId =
        rawQuery.length >= 2 && customer.customerId.toLowerCase().contains(rawQuery);
    return matchesName || matchesId;
  }).toList()
    ..sort((a, b) {
      final aId = a.customerId.toLowerCase();
      final bId = b.customerId.toLowerCase();
      final aName = normalizeCustomerName(a.name);
      final bName = normalizeCustomerName(b.name);
      final aStarts = aId.startsWith(rawQuery) || aName.startsWith(normalizedQuery);
      final bStarts = bId.startsWith(rawQuery) || bName.startsWith(normalizedQuery);
      if (aStarts != bStarts) {
        return aStarts ? -1 : 1;
      }
      return aName.compareTo(bName);
    });
  if (matches.length <= limit) {
    return matches;
  }
  return matches.sublist(0, limit);
}

CustomersRecord? findExactCustomerByName(
  List<CustomersRecord> customers,
  String input,
) {
  final query = normalizeCustomerName(input);
  if (query.isEmpty) {
    return null;
  }
  for (final customer in customers) {
    if (normalizeCustomerName(customer.name) == query) {
      return customer;
    }
  }
  return null;
}

CustomersRecord? findCustomerByNameOrId(
  List<CustomersRecord> customers,
  String input,
) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.contains('·')) {
    final idPart = trimmed.split('·').first.trim().toLowerCase();
    if (idPart.isNotEmpty) {
      for (final customer in customers) {
        if (customer.customerId.toLowerCase() == idPart) {
          return customer;
        }
      }
    }
  }
  for (final customer in customers) {
    if (customer.customerId.isNotEmpty &&
        customer.customerId.toLowerCase() == trimmed.toLowerCase()) {
      return customer;
    }
  }
  return findExactCustomerByName(customers, trimmed);
}

class CustomerPurchaseEntry {
  const CustomerPurchaseEntry({
    required this.order,
    required this.items,
    this.availableForInvoicing,
  });

  final OrdersRecord order;
  final List<OrderItemRecord> items;
  final bool? availableForInvoicing;

  DateTime? get purchasedAt =>
      order.deliveryDate ?? order.createdTime ?? order.deliveryTimeActual;

  String get productSummary {
    if (items.isEmpty) {
      return order.orderId.isNotEmpty ? 'Order ${order.orderId}' : 'Order';
    }
    return items
        .map((item) {
          final qty = item.qty > 0 ? '${item.qty}x ' : '';
          return '$qty${item.name}';
        })
        .join(', ');
  }
}

class CustomerPurchaseSummary {
  const CustomerPurchaseSummary({
    required this.totalSpending,
    required this.lastPurchaseAt,
    required this.orderCount,
  });

  final double totalSpending;
  final DateTime? lastPurchaseAt;
  final int orderCount;
}

double customerOrderTotalAmount(OrdersRecord order) {
  if (order.totalAmount > 0) {
    return order.totalAmount;
  }
  if (order.total > 0) {
    return order.total;
  }
  return 0;
}

bool customerOrderIncludedInPurchaseSummary(OrdersRecord order) {
  if (order.status == OrderStatus.cancelled) {
    return false;
  }
  if (order.invoicePaymentStatus.trim().toLowerCase() == 'voided') {
    return false;
  }
  return true;
}

bool customerOrderCountsTowardTotalSpending(OrdersRecord order) {
  if (!customerOrderIncludedInPurchaseSummary(order)) {
    return false;
  }
  final invoiceStatus = order.invoicePaymentStatus.trim().toLowerCase();
  if (invoiceStatus == 'paid') {
    return true;
  }
  if (invoiceStatus == 'pending') {
    return false;
  }
  final total = customerOrderTotalAmount(order);
  if (order.balanceDue > 0) {
    return false;
  }
  if (total > 0 && order.amountPaid >= total) {
    return true;
  }
  if (order.cashReceived > 0 || order.amountPaid > 0) {
    return true;
  }
  return false;
}

CustomerPurchaseSummary summarizeCustomerPurchaseHistory(
  Iterable<CustomerPurchaseEntry> entries,
) {
  var totalSpending = 0.0;
  DateTime? lastPurchaseAt;
  var orderCount = 0;

  for (final entry in entries) {
    if (!customerOrderIncludedInPurchaseSummary(entry.order)) {
      continue;
    }
    orderCount++;
    final purchasedAt = entry.purchasedAt;
    if (purchasedAt != null &&
        (lastPurchaseAt == null || purchasedAt.isAfter(lastPurchaseAt))) {
      lastPurchaseAt = purchasedAt;
    }
    if (customerOrderCountsTowardTotalSpending(entry.order)) {
      totalSpending += customerOrderTotalAmount(entry.order);
    }
  }

  return CustomerPurchaseSummary(
    totalSpending: totalSpending,
    lastPurchaseAt: lastPurchaseAt,
    orderCount: orderCount,
  );
}

Future<List<CustomerPurchaseEntry>> loadCustomerPurchaseHistory(
  CustomersRecord customer, {
  int orderLimit = 50,
}) async {
  final byRef = <OrdersRecord>[];
  try {
    byRef.addAll(
      await queryTenantOrdersRecordOnce(
        queryBuilder: (query) => query
            .where('customerRef', isEqualTo: customer.reference)
            .orderBy('created_time', descending: true),
        limit: orderLimit,
      ),
    );
  } catch (_) {
    // Index may not exist yet; legacy phone/name merge below still works.
  }

  final merged = <String, OrdersRecord>{};
  for (final order in byRef) {
    merged[order.reference.path] = order;
  }

  final normalizedPhone = normalizeCustomerPhone(customer.phone);
  if (normalizedPhone.isNotEmpty) {
    final recentOrders = await queryTenantOrdersRecordOnce(
      queryBuilder: (query) =>
          query.orderBy('created_time', descending: true),
      limit: 200,
    );
    for (final order in recentOrders) {
      if (normalizeCustomerPhone(order.customerPhoneNumber) ==
              normalizedPhone ||
          normalizeCustomerName(order.clientName) ==
              normalizeCustomerName(customer.name)) {
        merged[order.reference.path] = order;
      }
    }
  }

  final orders = merged.values.toList()
    ..sort((a, b) {
      final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  if (orders.length > orderLimit) {
    orders.removeRange(orderLimit, orders.length);
  }

  final entries = <CustomerPurchaseEntry>[];
  for (final order in orders) {
    final items = await queryTenantOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: order.reference),
      limit: 50,
    );
    entries.add(CustomerPurchaseEntry(order: order, items: items));
  }
  return entries;
}

class CustomerWriteException implements Exception {
  CustomerWriteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CustomerCreateResult {
  const CustomerCreateResult({
    required this.reference,
    required this.customerId,
  });

  final DocumentReference reference;
  final String customerId;
}

bool _backfillCustomerIdsInProgress = false;

/// Assigns TFG01–TFG1000 codes to existing customers missing `customer_id`.
Future<void> backfillMissingCustomerPublicIds() async {
  if (_backfillCustomerIdsInProgress) {
    return;
  }
  _backfillCustomerIdsInProgress = true;
  try {
    final customers = await queryCustomersForTenantList(limit: 1000);
    final missing = customers.where((c) => c.customerId.isEmpty).toList()
      ..sort((a, b) {
        final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });
    for (final customer in missing) {
      try {
        final customerId = await OrderIdService.nextCustomerId();
        await customer.reference.set(
          {
            'customer_id': customerId,
            'updated_time': getCurrentTimestamp,
          },
          SetOptions(merge: true),
        );
      } on StateError {
        break;
      }
    }
  } finally {
    _backfillCustomerIdsInProgress = false;
  }
}

Future<CustomerCreateResult?> createCustomerProfile({
  required String name,
  required String phone,
  String? email,
  String? billingAddress,
  String? uen,
  DateTime? birthday,
  bool isCreditCustomer = false,
  String? creditTerm,
  DocumentReference? priceListRef,
}) async {
  final tenantBlocked = await TenantContext.instance.ensureReadyForTenantWrite();
  if (tenantBlocked != null) {
    throw CustomerWriteException(tenantBlocked);
  }

  final companyRef = TenantContext.instance.rulesMatchedCompanyRef;
  if (companyRef == null) {
    throw CustomerWriteException(
      'No company selected. Choose a company before creating a customer.',
    );
  }

  final duplicateError = await validateCustomerProfileUniqueness(
    name: name,
    phone: phone,
  );
  if (duplicateError != null) {
    throw CustomerWriteException(duplicateError);
  }

  final ref = CustomersRecord.collection.doc();
  final trimmedBilling = billingAddress?.trim() ?? '';
  final trimmedUen = uen?.trim() ?? '';
  final trimmedEmail = email?.trim() ?? '';
  final trimmedTerm = creditTerm?.trim() ?? '';
  final customerId = await OrderIdService.nextCustomerId();
  await ref.set(
    createCustomersRecordData(
      customerId: customerId,
      name: name.trim(),
      phone: phone.trim(),
      email: trimmedEmail.isEmpty ? null : normalizeCustomerEmail(trimmedEmail),
      billingAddress: trimmedBilling.isEmpty ? null : trimmedBilling,
      uen: trimmedUen.isEmpty ? null : trimmedUen,
      isCreditCustomer: isCreditCustomer,
      creditTerm: isCreditCustomer && trimmedTerm.isNotEmpty
          ? trimmedTerm
          : null,
      priceListRef: isCreditCustomer ? priceListRef : null,
      birthday: normalizeCustomerBirthday(birthday),
      createdTime: getCurrentTimestamp,
      updatedTime: getCurrentTimestamp,
      companyRef: companyRef,
    ),
  ).timeout(
    const Duration(seconds: 30),
    onTimeout: () => throw CustomerWriteException(
      'Save timed out. Check your internet connection and try again.',
    ),
  );
  return CustomerCreateResult(reference: ref, customerId: customerId);
}

Future<String?> validateCustomerProfileUniqueness({
  required String name,
  required String phone,
  DocumentReference? excludeRef,
}) async {
  final customers = await queryCustomersForTenantList();
  return findCustomerProfileDuplicateError(
    existing: customers,
    name: name,
    phone: phone,
    excludeRef: excludeRef,
  );
}

String? findCustomerProfileDuplicateError({
  required Iterable<CustomersRecord> existing,
  required String name,
  required String phone,
  DocumentReference? excludeRef,
}) {
  final phoneKey = normalizeCustomerPhone(phone);
  final nameKey = normalizeCustomerName(name);
  for (final customer in existing) {
    if (excludeRef != null && customer.reference.path == excludeRef.path) {
      continue;
    }
    if (phoneKey.isNotEmpty &&
        normalizeCustomerPhone(customer.phone) == phoneKey) {
      return kCustomerDuplicatePhoneError;
    }
    if (nameKey.isNotEmpty &&
        normalizeCustomerName(customer.name) == nameKey) {
      return kCustomerDuplicateNameError;
    }
  }
  return null;
}

const kCustomerDuplicateNameError =
    'Another customer already uses this name.';
const kCustomerDuplicatePhoneError =
    'Another customer already uses this phone number.';

Future<void> updateCustomerProfile({
  required CustomersRecord customer,
  required String name,
  required String phone,
  String? email,
  String? billingAddress,
  String? uen,
  DateTime? birthday,
  bool isCreditCustomer = false,
  String? creditTerm,
  DocumentReference? priceListRef,
}) async {
  final tenantBlocked = await TenantContext.instance.ensureReadyForTenantWrite();
  if (tenantBlocked != null) {
    throw CustomerWriteException(tenantBlocked);
  }

  final duplicateError = await validateCustomerProfileUniqueness(
    name: name,
    phone: phone,
    excludeRef: customer.reference,
  );
  if (duplicateError != null) {
    throw CustomerWriteException(duplicateError);
  }

  final trimmedBilling = billingAddress?.trim() ?? '';
  final trimmedUen = uen?.trim() ?? '';
  final trimmedEmail = email?.trim() ?? '';
  final trimmedTerm = creditTerm?.trim() ?? '';
  final updateData = createCustomersRecordData(
    customerId: customer.customerId.isEmpty ? null : customer.customerId,
    name: name.trim(),
    phone: phone.trim(),
    email: trimmedEmail.isEmpty ? null : normalizeCustomerEmail(trimmedEmail),
    billingAddress: trimmedBilling.isEmpty ? null : trimmedBilling,
    uen: trimmedUen.isEmpty ? null : trimmedUen,
    isCreditCustomer: isCreditCustomer,
    creditTerm: isCreditCustomer && trimmedTerm.isNotEmpty
        ? trimmedTerm
        : null,
    priceListRef: isCreditCustomer ? priceListRef : null,
    birthday: normalizeCustomerBirthday(birthday),
    updatedTime: getCurrentTimestamp,
    companyRef: customer.companyRef,
  );
  if (!isCreditCustomer) {
    if (customer.hasPriceListRef()) {
      updateData['price_list_ref'] = FieldValue.delete();
    }
  } else if (priceListRef == null && customer.hasPriceListRef()) {
    updateData['price_list_ref'] = FieldValue.delete();
  }
  await customer.reference.update(updateData).timeout(
    const Duration(seconds: 30),
    onTimeout: () => throw CustomerWriteException(
      'Save timed out. Check your internet connection and try again.',
    ),
  );
}

Future<String?> validateCustomerCanBeDeleted(CustomersRecord customer) async {
  final invoices = await queryInvoicesRecordOnce(
    queryBuilder: (query) =>
        query.where('customer_ref', isEqualTo: customer.reference),
    limit: 100,
  );
  final hasPending = invoices.any(
    (invoice) => invoice.status.trim().toLowerCase() == 'pending',
  );
  if (hasPending) {
    return 'Cannot delete customer with pending invoices.';
  }
  return null;
}

Future<void> deleteCustomerProfile(CustomersRecord customer) async {
  final tenantBlocked = await TenantContext.instance.ensureReadyForTenantWrite();
  if (tenantBlocked != null) {
    throw CustomerWriteException(tenantBlocked);
  }

  final blockReason = await validateCustomerCanBeDeleted(customer);
  if (blockReason != null) {
    throw CustomerWriteException(blockReason);
  }

  final releasedId = customer.customerId;
  await customer.reference.delete().timeout(
    const Duration(seconds: 30),
    onTimeout: () => throw CustomerWriteException(
      'Delete timed out. Check your internet connection and try again.',
    ),
  );
  if (releasedId.isNotEmpty) {
    await OrderIdService.releaseCustomerId(releasedId);
  }
}

/// All companyRef values that should match customers for the active tenant.
List<DocumentReference> customerTenantCompanyRefs() {
  final paths = <String>{};
  final refs = <DocumentReference>[];

  void addRef(DocumentReference? ref) {
    if (ref == null || paths.contains(ref.path)) {
      return;
    }
    paths.add(ref.path);
    refs.add(ref);
  }

  final profileRef = TenantContext.instance.profile?.companyRef;
  addRef(profileRef);
  addRef(canonicalCompanyRef(profileRef));
  addRef(TenantContext.instance.rulesMatchedCompanyRef);
  addRef(TenantContext.instance.writeCompanyRef);
  addRef(TenantContext.instance.activeCompanyRef);

  return refs;
}

bool customerBelongsToActiveTenant(CustomersRecord customer) {
  if (TenantContext.instance.isViewingAllCompanies) {
    return true;
  }
  if (!customer.hasCompanyRef()) {
    return true;
  }
  final allowed = customerTenantCompanyRefs().map((ref) => ref.path).toSet();
  return allowed.contains(customer.companyRef!.path);
}

int _compareCustomerName(CustomersRecord a, CustomersRecord b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

/// Loads customers for the list page without Firestore composite indexes.
Future<List<CustomersRecord>> queryCustomersForTenantList({
  int limit = 500,
}) async {
  var customers = await queryCustomersRecordOnce(
    queryBuilder: applyTenantCompanyFilter,
    limit: limit,
  );
  if (!TenantContext.instance.isViewingAllCompanies) {
    customers = customers.where(customerBelongsToActiveTenant).toList();
  }

  customers.sort(_compareCustomerName);
  if (customers.length > limit) {
    return customers.sublist(0, limit);
  }
  return customers;
}
