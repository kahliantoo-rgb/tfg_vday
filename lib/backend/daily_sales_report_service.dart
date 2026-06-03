import '/backend/backend.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_query_helpers.dart';

/// One payment method row in the daily report.
class PaymentMethodBreakdown {
  const PaymentMethodBreakdown({
    required this.label,
    required this.orderCount,
    required this.totalAmount,
  });

  final String label;
  final int orderCount;
  final double totalAmount;
}

/// Aggregated sales for a single calendar day (paid orders only).
class DailySalesReport {
  const DailySalesReport({
    required this.reportDate,
    required this.totalOrders,
    required this.totalSalesAmount,
    required this.paymentBreakdown,
  });

  final DateTime reportDate;
  final int totalOrders;
  final double totalSalesAmount;
  final List<PaymentMethodBreakdown> paymentBreakdown;

}

/// Normalizes stored paymentType values (e.g. Paynow → PayNow).
String normalizePaymentLabel(String raw) {
  final normalized = raw.trim().toLowerCase().replaceAll(' ', '');
  if (normalized.isEmpty) {
    return 'Unspecified';
  }
  if (normalized == 'cash') {
    return 'Cash';
  }
  if (normalized == 'paynow') {
    return 'PayNow';
  }
  if (normalized == 'card') {
    return 'Card';
  }
  return raw.trim();
}

bool orderQualifiesForDailySales(OrdersRecord order) {
  if (order.paymentType.trim().isEmpty) {
    return false;
  }
  if (order.status == OrderStatus.cancelled) {
    return false;
  }
  final amount = order.totalAmount > 0 ? order.totalAmount : order.total;
  return amount > 0;
}

bool isOrderOnCalendarDay(DateTime? timestamp, DateTime day) {
  if (timestamp == null) {
    return false;
  }
  final local = timestamp.toLocal();
  return local.year == day.year &&
      local.month == day.month &&
      local.day == day.day;
}

double orderSalesAmount(OrdersRecord order) {
  if (order.totalAmount > 0) {
    return order.totalAmount;
  }
  return order.total;
}

/// Loads paid orders for [day] and builds payment breakdown.
Future<DailySalesReport> buildDailySalesReport(DateTime day) async {
  final reportDay = DateTime(day.year, day.month, day.day);
  final rangeStart = startOfDay(reportDay);
  final rangeEnd = endOfDay(reportDay);

  List<OrdersRecord> orders;
  try {
    orders = await queryTenantOrdersRecordOnce(
      queryBuilder: (q) => q
          .where('created_time', isGreaterThanOrEqualTo: rangeStart)
          .where('created_time', isLessThanOrEqualTo: rangeEnd),
    );
  } catch (_) {
    orders = await queryTenantOrdersRecordOnce();
    orders = orders
        .where((o) => isOrderOnCalendarDay(o.createdTime, reportDay))
        .toList();
  }

  final paidOrders =
      orders.where(orderQualifiesForDailySales).toList(growable: false);

  final totalsByPayment = <String, PaymentMethodBreakdown>{};
  var salesSum = 0.0;

  for (final order in paidOrders) {
    final label = normalizePaymentLabel(order.paymentType);
    final amount = orderSalesAmount(order);
    salesSum += amount;

    final existing = totalsByPayment[label];
    if (existing == null) {
      totalsByPayment[label] = PaymentMethodBreakdown(
        label: label,
        orderCount: 1,
        totalAmount: amount,
      );
    } else {
      totalsByPayment[label] = PaymentMethodBreakdown(
        label: label,
        orderCount: existing.orderCount + 1,
        totalAmount: existing.totalAmount + amount,
      );
    }
  }

  final breakdown = totalsByPayment.values.toList()
    ..sort((a, b) {
      const order = ['Cash', 'PayNow', 'Card'];
      final ai = order.indexOf(a.label);
      final bi = order.indexOf(b.label);
      if (ai >= 0 && bi >= 0) {
        return ai.compareTo(bi);
      }
      if (ai >= 0) {
        return -1;
      }
      if (bi >= 0) {
        return 1;
      }
      return a.label.compareTo(b.label);
    });

  return DailySalesReport(
    reportDate: reportDay,
    totalOrders: paidOrders.length,
    totalSalesAmount: salesSum,
    paymentBreakdown: breakdown,
  );
}
