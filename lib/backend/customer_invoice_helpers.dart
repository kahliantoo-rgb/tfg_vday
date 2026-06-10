import '/backend/customer_helpers.dart';
import '/backend/order_item_helpers.dart';
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
  });

  final String orderId;
  final String productName;
  final String remark;
  final int qty;
  final double unitPrice;
  final double lineSubtotal;
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
