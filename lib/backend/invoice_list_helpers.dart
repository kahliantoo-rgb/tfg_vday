import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/customer_navigation_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/order_whatsapp_import_helpers.dart' show findOrderByOrderId;
import '/backend/schema/customers_record.dart';
import '/backend/schema/invoices_record.dart';
import '/auth/record_edit_permissions.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

class InvoiceStatus {
  static const pending = 'pending';
  static const paid = 'paid';
  static const voided = 'voided';
}

class InvoiceListFilters {
  const InvoiceListFilters({
    this.invoiceNumberQuery = '',
    this.customerQuery = '',
    this.selectedCustomerRefPath,
    this.month,
    this.creditTerm = '',
    this.includeVoided = false,
  });

  final String invoiceNumberQuery;
  final String customerQuery;
  final String? selectedCustomerRefPath;
  final DateTime? month;
  final String creditTerm;
  final bool includeVoided;
}

Map<String, CustomersRecord> buildCustomersByRefPath(
  Iterable<CustomersRecord> customers,
) {
  return {
    for (final customer in customers) customer.reference.path: customer,
  };
}

List<String> invoiceCustomerSearchTerms(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return const [];
  }
  if (trimmed.contains('·')) {
    return trimmed
        .split('·')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
  return [trimmed];
}

bool invoiceMatchesCustomerSearchTerm(
  InvoicesRecord invoice,
  String term,
  Map<String, CustomersRecord> customersByRefPath,
) {
  final raw = term.trim().toLowerCase();
  final normalized = normalizeCustomerName(term);
  if (raw.isEmpty) {
    return true;
  }
  if (normalizeCustomerName(invoice.customerName).contains(normalized) ||
      invoice.customerName.toLowerCase().contains(raw)) {
    return true;
  }
  final ref = invoice.customerRef;
  if (ref == null) {
    return false;
  }
  final customer = customersByRefPath[ref.path];
  if (customer == null) {
    return false;
  }
  return normalizeCustomerName(customer.name).contains(normalized) ||
      customer.name.toLowerCase().contains(raw) ||
      customer.customerId.toLowerCase().contains(raw);
}

bool invoiceMatchesCustomerQuery(
  InvoicesRecord invoice,
  String query,
  Map<String, CustomersRecord> customersByRefPath,
) {
  final terms = invoiceCustomerSearchTerms(query);
  if (terms.isEmpty) {
    return true;
  }
  return terms.every(
    (term) => invoiceMatchesCustomerSearchTerm(
      invoice,
      term,
      customersByRefPath,
    ),
  );
}

bool isOrderAvailableForInvoicing(OrdersRecord order) {
  final status = order.invoicePaymentStatus.trim().toLowerCase();
  if (status == InvoiceStatus.voided) {
    return true;
  }
  if (order.invoiceRef == null) {
    return true;
  }
  return status.isEmpty;
}

bool orderInvoicingAvailabilityFromInvoiceStatus(
  OrdersRecord order,
  Map<String, String> invoiceStatusByPath,
) {
  if (isOrderAvailableForInvoicing(order)) {
    return true;
  }
  final ref = order.invoiceRef;
  if (ref == null) {
    return true;
  }
  return invoiceStatusByPath[ref.path] == InvoiceStatus.voided;
}

Future<Map<String, bool>> resolveOrderInvoicingAvailability(
  Iterable<OrdersRecord> orders,
) async {
  final invoiceRefs = <DocumentReference>{};
  for (final order in orders) {
    if (isOrderAvailableForInvoicing(order)) {
      continue;
    }
    final ref = order.invoiceRef;
    if (ref != null) {
      invoiceRefs.add(ref);
    }
  }

  final invoiceStatusByPath = <String, String>{};
  await Future.wait(
    invoiceRefs.map((ref) async {
      try {
        final invoice = await InvoicesRecord.getDocumentOnce(ref);
        invoiceStatusByPath[ref.path] = invoice.status;
      } catch (_) {
        invoiceStatusByPath[ref.path] = InvoiceStatus.voided;
      }
    }),
  );

  return {
    for (final order in orders)
      order.reference.path: orderInvoicingAvailabilityFromInvoiceStatus(
        order,
        invoiceStatusByPath,
      ),
  };
}

Future<List<CustomerPurchaseEntry>> enrichCustomerPurchaseEntriesForInvoicing(
  List<CustomerPurchaseEntry> entries,
) async {
  if (entries.isEmpty) {
    return entries;
  }
  final availability = await resolveOrderInvoicingAvailability(
    entries.map((entry) => entry.order),
  );
  return [
    for (final entry in entries)
      CustomerPurchaseEntry(
        order: entry.order,
        items: entry.items,
        availableForInvoicing:
            availability[entry.order.reference.path] ?? false,
      ),
  ];
}

bool customerPurchaseEntryCanInvoice(CustomerPurchaseEntry entry) =>
    entry.availableForInvoicing ??
    isOrderAvailableForInvoicing(entry.order);

Future<void> assertOrdersAvailableForInvoicing(
  List<CustomerPurchaseEntry> entries,
) async {
  final availability = await resolveOrderInvoicingAvailability(
    entries.map((entry) => entry.order),
  );
  for (final entry in entries) {
    final available = entry.availableForInvoicing ??
        availability[entry.order.reference.path] ??
        false;
    if (!available) {
      final label = entry.order.orderId.isNotEmpty
          ? entry.order.orderId
          : entry.order.reference.id;
      throw StateError('Order $label is already on an active invoice.');
    }
  }
}

double resolveOrderTotalForPayment(OrdersRecord order) {
  if (order.totalAmount > 0) {
    return order.totalAmount;
  }
  if (order.total > 0) {
    return order.total;
  }
  return 0;
}

List<InvoicesRecord> filterInvoiceList(
  List<InvoicesRecord> invoices,
  InvoiceListFilters filters, {
  Map<String, CustomersRecord> customersByRefPath = const {},
}) {
  final numberQuery = filters.invoiceNumberQuery.trim().toLowerCase();
  final customerQuery = filters.customerQuery.trim();
  final selectedCustomerRefPath = filters.selectedCustomerRefPath?.trim();
  final creditTerm = filters.creditTerm.trim();

  return invoices.where((invoice) {
    if (!filters.includeVoided && invoice.status == InvoiceStatus.voided) {
      return false;
    }
    if (numberQuery.isNotEmpty &&
        !invoice.invoiceNumber.toLowerCase().contains(numberQuery)) {
      return false;
    }
    if (selectedCustomerRefPath != null && selectedCustomerRefPath.isNotEmpty) {
      if (invoice.customerRef?.path != selectedCustomerRefPath) {
        return false;
      }
    } else if (customerQuery.isNotEmpty &&
        !invoiceMatchesCustomerQuery(
          invoice,
          customerQuery,
          customersByRefPath,
        )) {
      return false;
    }
    if (creditTerm.isNotEmpty && invoice.creditTerm != creditTerm) {
      return false;
    }
    if (filters.month != null) {
      final created = invoice.createdTime;
      if (created == null) {
        return false;
      }
      if (created.year != filters.month!.year ||
          created.month != filters.month!.month) {
        return false;
      }
    }
    return true;
  }).toList();
}

List<String> collectInvoiceCreditTerms(List<InvoicesRecord> invoices) {
  final terms = invoices
      .map((invoice) => invoice.creditTerm.trim())
      .where((term) => term.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return terms;
}

bool invoiceBelongsToActiveTenant(InvoicesRecord invoice) {
  if (TenantContext.instance.isViewingAllCompanies) {
    return true;
  }
  if (!invoice.hasCompanyRef()) {
    return true;
  }
  final allowed = customerTenantCompanyRefs().map((ref) => ref.path).toSet();
  return allowed.contains(invoice.companyRef!.path);
}

/// Loads invoices for the list page without Firestore composite indexes.
Future<List<InvoicesRecord>> queryInvoicesForTenantList({
  int limit = 500,
}) async {
  var invoices = await queryInvoicesRecordOnce(
    queryBuilder: applyTenantCompanyFilter,
    limit: limit,
  );
  if (!TenantContext.instance.isViewingAllCompanies) {
    invoices = invoices.where(invoiceBelongsToActiveTenant).toList();
    if (invoices.isEmpty) {
      final broader = await queryInvoicesRecordOnce(limit: limit);
      invoices = broader.where(invoiceBelongsToActiveTenant).toList();
    }
  }

  invoices.sort((a, b) {
    final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  if (invoices.length > limit) {
    return invoices.sublist(0, limit);
  }
  return invoices;
}

class InvoicePrintContext {
  const InvoicePrintContext({
    required this.invoice,
    required this.customer,
    required this.lines,
    required this.totals,
  });

  final InvoicesRecord invoice;
  final CustomersRecord customer;
  final List<CustomerInvoiceLineItem> lines;
  final CustomerInvoiceTotals totals;
}

Future<CustomersRecord> resolveInvoiceCustomer(InvoicesRecord invoice) async {
  if (invoice.hasCustomerRef()) {
    try {
      return await loadCustomerProfileRecord(
        invoice.customerRef!,
        nameHint: invoice.customerName,
      );
    } catch (_) {
      // Fall back to hints / snapshot below.
    }
  }

  for (final orderRef in invoice.orderRefs) {
    try {
      final order = await OrdersRecord.getDocumentOnce(orderRef);
      if (order.hasCustomerRef()) {
        try {
          return await loadCustomerProfileRecord(
            order.customerRef!,
            nameHint: invoice.customerName,
            phoneHint: order.customerPhoneNumber,
          );
        } catch (_) {
          // Try next order.
        }
      }
    } catch (_) {
      // Skip missing order.
    }
  }

  final byHints = await findTenantCustomerByHints(
    nameHint: invoice.customerName,
  );
  if (byHints != null) {
    return byHints;
  }

  return CustomersRecord.getDocumentFromData(
    {
      'name': invoice.customerName,
      'credit_term': invoice.creditTerm,
    },
    invoice.customerRef ??
        CustomersRecord.collection.doc('invoice_${invoice.reference.id}'),
  );
}

/// Opens customer profile using invoice snapshot + tenant lookup (not raw [customer_ref]).
Future<void> openInvoiceCustomerProfile(
  BuildContext context,
  InvoicesRecord invoice,
) async {
  final customer = await resolveInvoiceCustomer(invoice);
  if (!context.mounted) {
    return;
  }
  if (!customerProfileIsPersisted(customer)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No customer profile is linked to this invoice. '
          'The customer record may have been deleted or renamed.',
        ),
      ),
    );
    return;
  }
  await openCustomerProfile(context, customer.reference);
}

CustomerInvoiceTotals invoiceTotalsFromRecord(InvoicesRecord invoice) {
  return CustomerInvoiceTotals(
    subtotal: invoice.subtotal,
    discount: invoice.discount,
    total: invoice.total,
    discountLabel:
        invoice.discountLabel.isNotEmpty ? invoice.discountLabel : '-',
  );
}

Future<List<DocumentReference>> resolveInvoiceOrderRefs(
  InvoicesRecord invoice,
) async {
  if (invoice.orderRefs.isNotEmpty) {
    return invoice.orderRefs;
  }
  final refs = <DocumentReference>[];
  for (final orderId in invoice.orderIds) {
    final order = await findOrderByOrderId(orderId);
    if (order != null) {
      refs.add(order.reference);
    }
  }
  return refs;
}

Future<List<CustomerInvoiceLineItem>> loadLiveInvoiceLines(
  InvoicesRecord invoice,
) async {
  final entries = <CustomerPurchaseEntry>[];
  final orderRefs = await resolveInvoiceOrderRefs(invoice);

  for (var i = 0; i < orderRefs.length; i++) {
    final orderRef = orderRefs[i];
    try {
      OrdersRecord? order;
      try {
        order = await OrdersRecord.getDocumentOnce(orderRef);
      } catch (_) {
        order = null;
      }
      final items = await queryOrderLineItemsForInvoiceOrder(
        orderRef,
        order: order,
      );
      if (items.isEmpty) {
        continue;
      }
      final fallbackOrderId = i < invoice.orderIds.length
          ? invoice.orderIds[i]
          : orderRef.id;
      final resolvedOrder = order ??
          OrdersRecord.getDocumentFromData(
            {
              if (fallbackOrderId.isNotEmpty) 'Order_Id': fallbackOrderId,
            },
            orderRef,
          );
      entries.add(CustomerPurchaseEntry(order: resolvedOrder, items: items));
    } catch (_) {
      // Try next linked order.
    }
  }

  return buildCustomerInvoiceLineItems(entries);
}

Future<InvoicePrintContext> loadInvoicePrintContext(
  InvoicesRecord invoice,
) async {
  final customer = await resolveInvoiceCustomer(invoice);
  var lines = parseInvoiceLineItemsSnapshot(invoice.lineItems);
  if (lines.isEmpty) {
    lines = await loadLiveInvoiceLines(invoice);
    if (lines.isNotEmpty && invoice.lineItems.isEmpty) {
      try {
        await invoice.reference.update(
          createInvoicesRecordData(
            lineItems: customerInvoiceLineItemsToFirestoreMaps(lines),
          ),
        );
      } catch (_) {
        // Read path still works; snapshot backfill is best-effort.
      }
    }
  }

  return InvoicePrintContext(
    invoice: invoice,
    customer: customer,
    lines: lines,
    totals: invoiceTotalsFromRecord(invoice),
  );
}

class InvoiceWriteException implements Exception {
  InvoiceWriteException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<void> updateCustomerInvoice({
  required InvoicesRecord invoice,
  required List<CustomerInvoiceLineItem> lines,
  required CustomerInvoiceTotals totals,
  UserRole? editorRole,
}) async {
  if (invoice.status == InvoiceStatus.voided) {
    throw InvoiceWriteException('Voided invoices cannot be edited.');
  }
  assertCanEditInvoiceRecord(editorRole, invoice);
  if (lines.isEmpty) {
    throw InvoiceWriteException('Invoice requires at least one line item.');
  }

  final batch = FirebaseFirestore.instance.batch();
  final touchedOrders = <DocumentReference>{};

  for (final line in lines) {
    if (line.orderItemRef == null) {
      continue;
    }
    batch.update(
      line.orderItemRef!,
      createOrderItemRecordData(
        qty: line.qty,
        price: line.unitPrice,
        subtotal: line.lineSubtotal,
      ),
    );
    if (line.orderRef != null) {
      touchedOrders.add(line.orderRef!);
    }
  }

  batch.update(
    invoice.reference,
    createInvoicesRecordData(
      subtotal: totals.subtotal,
      discount: totals.discount,
      discountLabel: totals.discountLabel,
      total: totals.total,
      lineItems: customerInvoiceLineItemsToFirestoreMaps(lines),
    ),
  );

  await batch.commit();

  for (final orderRef in touchedOrders) {
    final items = await queryTenantOrderItemRecordOnce(
      queryBuilder: (query) => query.where('orderRef', isEqualTo: orderRef),
      limit: 100,
    );
    final order = await OrdersRecord.getDocumentOnce(orderRef);
    final active = activeOrderItems(items);
    final totalAmount = active.fold<double>(
      0,
      (sum, item) =>
          sum + (item.subtotal > 0 ? item.subtotal : item.price * item.qty),
    );
    final totalQty = active.fold<int>(0, (sum, item) => sum + item.qty);
    final isPaid =
        order.invoicePaymentStatus.trim().toLowerCase() == InvoiceStatus.paid;

    await orderRef.update(
      createOrdersRecordData(
        totalAmount: totalAmount,
        total: totalAmount,
        totalQty: totalQty,
        amountPaid: isPaid ? totalAmount : 0,
        balanceDue: isPaid ? 0 : totalAmount,
      ),
    );
  }

  markCustomerProfileHistoryRefreshForInvoice(invoice);
}

Future<DocumentReference> createCustomerInvoiceRecord({
  required String invoiceNumber,
  required CustomersRecord customer,
  required List<CustomerPurchaseEntry> entries,
  required CustomerInvoiceTotals totals,
}) async {
  if (entries.isEmpty) {
    throw StateError('Invoice requires at least one order.');
  }

  await assertOrdersAvailableForInvoicing(entries);

  final orderRefs = entries.map((entry) => entry.order.reference).toList();
  final orderIds = entries
      .map(
        (entry) => entry.order.orderId.isNotEmpty
            ? entry.order.orderId
            : entry.order.reference.id,
      )
      .toList();
  final lineItems =
      customerInvoiceLineItemsToFirestoreMaps(
        buildCustomerInvoiceLineItems(entries),
      );

  final invoiceRef = InvoicesRecord.collection.doc();
  final batch = FirebaseFirestore.instance.batch();

  batch.set(
    invoiceRef,
    createInvoicesRecordData(
      invoiceNumber: invoiceNumber,
      customerRef: customer.reference,
      customerName: customer.name,
      creditTerm: customer.creditTerm,
      orderRefs: orderRefs,
      orderIds: orderIds,
      subtotal: totals.subtotal,
      discount: totals.discount,
      discountLabel: totals.discountLabel,
      total: totals.total,
      status: InvoiceStatus.pending,
      createdTime: getCurrentTimestamp,
      companyRef: TenantContext.instance.writeCompanyRef,
      lineItems: lineItems,
    ),
  );

  for (final entry in entries) {
    batch.update(
      entry.order.reference,
      createOrdersRecordData(
        invoiceRef: invoiceRef,
        invoiceNumber: invoiceNumber,
        invoicePaymentStatus: InvoiceStatus.pending,
      ),
    );
  }

  await batch.commit();
  markCustomerProfileHistoryRefresh(customer.reference.id);
  return invoiceRef;
}

Future<String> createCustomerInvoiceWithNumber({
  required CustomersRecord customer,
  required List<CustomerPurchaseEntry> entries,
  required CustomerInvoiceTotals totals,
}) async {
  final invoiceNumber = await OrderIdService.nextInvoiceNumber();
  await createCustomerInvoiceRecord(
    invoiceNumber: invoiceNumber,
    customer: customer,
    entries: entries,
    totals: totals,
  );
  return invoiceNumber;
}

Future<void> voidInvoices(List<DocumentReference> invoiceRefs) async {
  if (invoiceRefs.isEmpty) {
    return;
  }

  final batch = FirebaseFirestore.instance.batch();
  final customerIds = <String>{};
  for (final invoiceRef in invoiceRefs) {
    final invoice = await InvoicesRecord.getDocumentOnce(invoiceRef);
    if (invoice.status == InvoiceStatus.voided) {
      continue;
    }
    if (invoice.hasCustomerRef()) {
      customerIds.add(invoice.customerRef!.id);
    }

    batch.update(
      invoiceRef,
      createInvoicesRecordData(status: InvoiceStatus.voided),
    );

    for (final orderRef in invoice.orderRefs) {
      final order = await OrdersRecord.getDocumentOnce(orderRef);
      final orderTotal = resolveOrderTotalForPayment(order);
      batch.update(
        orderRef,
        createOrdersRecordData(
          invoiceNumber: '',
          invoicePaymentStatus: InvoiceStatus.voided,
          amountPaid: 0,
          balanceDue: orderTotal,
        )..['invoice_ref'] = FieldValue.delete(),
      );
    }
  }
  await batch.commit();
  for (final customerId in customerIds) {
    markCustomerProfileHistoryRefresh(customerId);
  }
}

Future<void> markInvoicesPaid(
  List<DocumentReference> invoiceRefs, {
  String? paymentProofUrl,
}) async {
  if (invoiceRefs.isEmpty) {
    return;
  }

  final batch = FirebaseFirestore.instance.batch();
  final paidAt = getCurrentTimestamp;
  final proofAt = paymentProofUrl != null && paymentProofUrl.trim().isNotEmpty
      ? getCurrentTimestamp
      : null;
  final trimmedProofUrl = paymentProofUrl?.trim();
  final customerIds = <String>{};

  for (final invoiceRef in invoiceRefs) {
    final invoice = await InvoicesRecord.getDocumentOnce(invoiceRef);
    if (invoice.status != InvoiceStatus.pending) {
      continue;
    }
    if (invoice.hasCustomerRef()) {
      customerIds.add(invoice.customerRef!.id);
    }

    batch.update(
      invoiceRef,
      createInvoicesRecordData(
        status: InvoiceStatus.paid,
        paidAt: paidAt,
        paymentProofUrl: trimmedProofUrl,
        paymentProofAt: proofAt,
      ),
    );

    for (final orderRef in invoice.orderRefs) {
      final order = await OrdersRecord.getDocumentOnce(orderRef);
      final orderTotal = resolveOrderTotalForPayment(order);
      batch.update(
        orderRef,
        createOrdersRecordData(
          invoicePaymentStatus: InvoiceStatus.paid,
          amountPaid: orderTotal,
          balanceDue: 0,
        ),
      );
    }
  }

  await batch.commit();
  for (final customerId in customerIds) {
    markCustomerProfileHistoryRefresh(customerId);
  }
}

String invoiceStatusLabel(String status) {
  switch (status) {
    case InvoiceStatus.paid:
      return 'Paid';
    case InvoiceStatus.voided:
      return 'Voided';
    case InvoiceStatus.pending:
    default:
      return 'Pending';
  }
}

enum CustomerOrderPaymentFilter { all, unpaid, paid }

/// Whether an order is treated as paid for customer profile filters.
bool isCustomerOrderPaid(OrdersRecord order) {
  final invoiceStatus = order.invoicePaymentStatus.trim().toLowerCase();
  if (invoiceStatus == InvoiceStatus.voided) {
    return false;
  }
  if (invoiceStatus == InvoiceStatus.paid) {
    return true;
  }
  if (invoiceStatus == InvoiceStatus.pending) {
    return false;
  }
  final total = resolveOrderTotalForPayment(order);
  if (order.balanceDue > 0) {
    return false;
  }
  if (total > 0 && order.amountPaid >= total) {
    return true;
  }
  final paymentType = order.paymentType.trim().toLowerCase();
  if (paymentType == 'credit') {
    return invoiceStatus == InvoiceStatus.paid;
  }
  if (order.cashReceived > 0 || order.amountPaid > 0) {
    return true;
  }
  return false;
}

bool matchesCustomerOrderPaymentFilter(
  OrdersRecord order,
  CustomerOrderPaymentFilter filter,
) {
  if (filter == CustomerOrderPaymentFilter.all) {
    return true;
  }
  final paid = isCustomerOrderPaid(order);
  return filter == CustomerOrderPaymentFilter.paid ? paid : !paid;
}
