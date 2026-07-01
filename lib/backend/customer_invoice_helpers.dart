import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/customer_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/schema/invoices_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/components/delivery_order_item_table.dart';

class CustomerInvoiceLineItem {
  const CustomerInvoiceLineItem({
    required this.orderId,
    required this.productName,
    required this.remark,
    required this.qty,
    required this.unitPrice,
    required this.lineSubtotal,
    this.orderRef,
    this.orderItemRef,
  });

  final String orderId;
  final String productName;
  final String remark;
  final int qty;
  final double unitPrice;
  final double lineSubtotal;
  final DocumentReference? orderRef;
  final DocumentReference? orderItemRef;
}

CustomerInvoiceLineItem copyCustomerInvoiceLineItem(
  CustomerInvoiceLineItem line, {
  int? qty,
  double? unitPrice,
}) {
  final nextQty = qty ?? line.qty;
  final nextPrice = unitPrice ?? line.unitPrice;
  return CustomerInvoiceLineItem(
    orderId: line.orderId,
    productName: line.productName,
    remark: line.remark,
    qty: nextQty,
    unitPrice: nextPrice,
    lineSubtotal: nextPrice * nextQty,
    orderRef: line.orderRef,
    orderItemRef: line.orderItemRef,
  );
}

class CustomerInvoiceTotals {
  const CustomerInvoiceTotals({
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

enum CustomerInvoiceDiscountType { percent, amount }

class CustomerInvoiceDiscountInput {
  const CustomerInvoiceDiscountInput({
    required this.type,
    required this.value,
  });

  final CustomerInvoiceDiscountType type;
  final double value;
}

List<CustomerInvoiceLineItem> buildCustomerInvoiceLineItems(
  List<CustomerPurchaseEntry> entries,
) {
  final lines = <CustomerInvoiceLineItem>[];
  for (final entry in entries) {
    final orderId = entry.order.orderId.isNotEmpty
        ? entry.order.orderId
        : entry.order.reference.id;
    for (final item in activeOrderItems(entry.items)) {
      final qty = item.qty;
      final lineSubtotal =
          item.subtotal > 0 ? item.subtotal : item.price * qty;
      final remark = DeliveryOrderItemTable.remarkText(item);
      lines.add(
        CustomerInvoiceLineItem(
          orderId: orderId,
          productName: item.name.isNotEmpty ? item.name : 'Item',
          remark: remark == '-' ? '' : remark,
          qty: qty,
          unitPrice: item.price,
          lineSubtotal: lineSubtotal,
          orderRef: entry.order.reference,
          orderItemRef: item.reference,
        ),
      );
    }
  }
  return lines;
}

CustomerInvoiceTotals calculateCustomerInvoiceTotals({
  required List<CustomerInvoiceLineItem> lines,
  CustomerInvoiceDiscountInput discount = const CustomerInvoiceDiscountInput(
    type: CustomerInvoiceDiscountType.amount,
    value: 0,
  ),
}) {
  final subtotal = lines.fold<double>(
    0,
    (sum, line) => sum + line.lineSubtotal,
  );
  var discountAmount = 0.0;
  var discountLabel = '-';
  if (discount.value > 0) {
    if (discount.type == CustomerInvoiceDiscountType.percent) {
      discountAmount = subtotal * discount.value / 100;
      discountLabel = '${discount.value.toStringAsFixed(2)}%';
    } else {
      discountAmount = discount.value;
      discountLabel = 'SGD ${discount.value.toStringAsFixed(2)}';
    }
  }
  if (discountAmount > subtotal) {
    discountAmount = subtotal;
  }
  if (discountAmount <= 0) {
    discountLabel = '-';
  }
  final total = subtotal - discountAmount;
  return CustomerInvoiceTotals(
    subtotal: subtotal,
    discount: discountAmount,
    total: total,
    discountLabel: discountLabel,
  );
}

List<Map<String, dynamic>> customerInvoiceLineItemsToFirestoreMaps(
  List<CustomerInvoiceLineItem> lines,
) =>
    [
      for (final line in lines)
        {
          'order_id': line.orderId,
          'product_name': line.productName,
          'remark': line.remark,
          'qty': line.qty,
          'unit_price': line.unitPrice,
          'line_subtotal': line.lineSubtotal,
          if (line.orderRef != null) 'order_ref_path': line.orderRef!.path,
          if (line.orderItemRef != null)
            'order_item_ref_path': line.orderItemRef!.path,
        },
    ];

List<CustomerInvoiceLineItem> parseInvoiceLineItemsSnapshot(
  List<Map<String, dynamic>> raw,
) {
  final db = FirebaseFirestore.instance;
  final lines = <CustomerInvoiceLineItem>[];
  for (final entry in raw) {
    final orderId = (entry['order_id'] as String?)?.trim() ?? '';
    final productName = (entry['product_name'] as String?)?.trim() ?? 'Item';
    if (orderId.isEmpty && productName.isEmpty) {
      continue;
    }
    DocumentReference? orderRef;
    DocumentReference? orderItemRef;
    final orderRefPath = entry['order_ref_path'] as String?;
    final orderItemRefPath = entry['order_item_ref_path'] as String?;
    if (orderRefPath != null && orderRefPath.isNotEmpty) {
      orderRef = db.doc(orderRefPath);
    }
    if (orderItemRefPath != null && orderItemRefPath.isNotEmpty) {
      orderItemRef = db.doc(orderItemRefPath);
    }
    final qty = (entry['qty'] as num?)?.toInt() ?? 0;
    final unitPrice = (entry['unit_price'] as num?)?.toDouble() ?? 0;
    final lineSubtotal = (entry['line_subtotal'] as num?)?.toDouble() ??
        (unitPrice * (qty > 0 ? qty : 1));
    lines.add(
      CustomerInvoiceLineItem(
        orderId: orderId.isNotEmpty ? orderId : '-',
        productName: productName,
        remark: (entry['remark'] as String?)?.trim() ?? '',
        qty: qty > 0 ? qty : 1,
        unitPrice: unitPrice,
        lineSubtotal: lineSubtotal,
        orderRef: orderRef,
        orderItemRef: orderItemRef,
      ),
    );
  }
  return lines;
}

CustomerInvoiceDiscountInput parseInvoiceDiscountInput(InvoicesRecord invoice) {
  final label = invoice.discountLabel.trim();
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
            invoice.discount;
    return CustomerInvoiceDiscountInput(
      type: CustomerInvoiceDiscountType.amount,
      value: value,
    );
  }
  if (invoice.discount > 0) {
    return CustomerInvoiceDiscountInput(
      type: CustomerInvoiceDiscountType.amount,
      value: invoice.discount,
    );
  }
  return const CustomerInvoiceDiscountInput(
    type: CustomerInvoiceDiscountType.amount,
    value: 0,
  );
}
