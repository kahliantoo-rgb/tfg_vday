import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/backend.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/invoices_record.dart';
import '/backend/schema/orders_record.dart';
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
    this.month,
    this.creditTerm = '',
    this.includeVoided = false,
  });

  final String invoiceNumberQuery;
  final String customerQuery;
  final DateTime? month;
  final String creditTerm;
  final bool includeVoided;
}

bool isOrderAvailableForInvoicing(OrdersRecord order) {
  if (order.invoiceRef == null) {
    return true;
  }
  final status = order.invoicePaymentStatus.trim().toLowerCase();
  return status.isEmpty || status == InvoiceStatus.voided;
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
  InvoiceListFilters filters,
) {
  final numberQuery = filters.invoiceNumberQuery.trim().toLowerCase();
  final customerQuery = filters.customerQuery.trim().toLowerCase();
  final creditTerm = filters.creditTerm.trim();

  return invoices.where((invoice) {
    if (!filters.includeVoided && invoice.status == InvoiceStatus.voided) {
      return false;
    }
    if (numberQuery.isNotEmpty &&
        !invoice.invoiceNumber.toLowerCase().contains(numberQuery)) {
      return false;
    }
    if (customerQuery.isNotEmpty &&
        !invoice.customerName.toLowerCase().contains(customerQuery)) {
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

Future<DocumentReference> createCustomerInvoiceRecord({
  required String invoiceNumber,
  required CustomersRecord customer,
  required List<CustomerPurchaseEntry> entries,
  required CustomerInvoiceTotals totals,
}) async {
  if (entries.isEmpty) {
    throw StateError('Invoice requires at least one order.');
  }

  for (final entry in entries) {
    if (!isOrderAvailableForInvoicing(entry.order)) {
      throw StateError(
        'Order ${entry.order.orderId.isNotEmpty ? entry.order.orderId : entry.order.reference.id} '
        'is already on an active invoice.',
      );
    }
  }

  final orderRefs = entries.map((entry) => entry.order.reference).toList();
  final orderIds = entries
      .map(
        (entry) => entry.order.orderId.isNotEmpty
            ? entry.order.orderId
            : entry.order.reference.id,
      )
      .toList();

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
  for (final invoiceRef in invoiceRefs) {
    final invoice = await InvoicesRecord.getDocumentOnce(invoiceRef);
    if (invoice.status == InvoiceStatus.voided) {
      continue;
    }

    batch.update(
      invoiceRef,
      createInvoicesRecordData(status: InvoiceStatus.voided),
    );

    for (final orderRef in invoice.orderRefs) {
      batch.update(orderRef, {
        'invoice_ref': FieldValue.delete(),
        'invoice_number': '',
        'invoice_payment_status': InvoiceStatus.voided,
      });
    }
  }
  await batch.commit();
}

Future<void> markInvoicesPaid(List<DocumentReference> invoiceRefs) async {
  if (invoiceRefs.isEmpty) {
    return;
  }

  final batch = FirebaseFirestore.instance.batch();
  final paidAt = getCurrentTimestamp;

  for (final invoiceRef in invoiceRefs) {
    final invoice = await InvoicesRecord.getDocumentOnce(invoiceRef);
    if (invoice.status != InvoiceStatus.pending) {
      continue;
    }

    batch.update(
      invoiceRef,
      createInvoicesRecordData(
        status: InvoiceStatus.paid,
        paidAt: paidAt,
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
