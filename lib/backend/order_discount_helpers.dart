import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/audit_log_helpers.dart';
import '/backend/customer_invoice_helpers.dart';
import '/backend/schema/orders_record.dart';

/// Order-level payable totals after an optional % / SGD discount.
class OrderPayableTotals {
  const OrderPayableTotals({
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.discountLabel,
  });

  final double subtotal;
  final double discount;
  final double total;
  final String discountLabel;
}

/// Same math as customer invoices: percent or fixed amount, capped at subtotal.
OrderPayableTotals calculateOrderPayableTotals({
  required double itemSubtotal,
  CustomerInvoiceDiscountInput discount = const CustomerInvoiceDiscountInput(
    type: CustomerInvoiceDiscountType.amount,
    value: 0,
  ),
}) {
  final invoiceTotals = calculateCustomerInvoiceTotals(
    lines: [
      if (itemSubtotal > 0)
        CustomerInvoiceLineItem(
          orderId: '-',
          productName: 'Subtotal',
          remark: '',
          qty: 1,
          unitPrice: itemSubtotal,
          lineSubtotal: itemSubtotal,
        ),
    ],
    discount: discount,
  );
  return OrderPayableTotals(
    subtotal: invoiceTotals.subtotal,
    discount: invoiceTotals.discount,
    total: invoiceTotals.total,
    discountLabel: invoiceTotals.discountLabel,
  );
}

CustomerInvoiceDiscountInput parseOrderDiscountInput(OrdersRecord order) {
  final label = order.discountLabel.trim();
  if (label.endsWith('%')) {
    final raw = label.substring(0, label.length - 1).trim();
    final value = double.tryParse(raw) ?? 0;
    return CustomerInvoiceDiscountInput(
      type: CustomerInvoiceDiscountType.percent,
      value: value,
    );
  }
  if (label.toLowerCase().startsWith('sgd')) {
    final value =
        double.tryParse(label.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            order.discount;
    return CustomerInvoiceDiscountInput(
      type: CustomerInvoiceDiscountType.amount,
      value: value,
    );
  }
  if (order.discount > 0) {
    return CustomerInvoiceDiscountInput(
      type: CustomerInvoiceDiscountType.amount,
      value: order.discount,
    );
  }
  return const CustomerInvoiceDiscountInput(
    type: CustomerInvoiceDiscountType.amount,
    value: 0,
  );
}

Map<String, dynamic> orderDiscountWriteData(
  OrderPayableTotals totals, {
  String discountRemark = '',
}) =>
    createOrdersRecordData(
      discount: totals.discount,
      discountLabel: totals.discountLabel,
      discountRemark: discountRemark.trim(),
      totalAmount: totals.total,
      total: totals.total,
    );

/// Persists discount fields and writes an audit log when a discount is applied
/// or cleared. Call only when the signed-in user may apply order discounts.
Future<void> persistOrderDiscountFields(
  DocumentReference orderRef,
  OrderPayableTotals totals, {
  String remark = '',
}) async {
  final trimmedRemark = remark.trim();
  final before = await OrdersRecord.getDocumentOnce(orderRef);
  await orderRef.update(
    orderDiscountWriteData(totals, discountRemark: trimmedRemark),
  );
  final hadDiscount = before.discount > 0.005;
  final hasDiscount = totals.discount > 0.005;
  if (!hadDiscount && !hasDiscount) {
    return;
  }
  await auditLogApplyOrderDiscount(
    before: before,
    discount: totals.discount,
    discountLabel: totals.discountLabel,
    total: totals.total,
    remark: trimmedRemark,
  );
}
