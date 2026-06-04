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

/// Aggregated sales for a calendar date range (paid orders only).
class DailySalesReport {
  const DailySalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalSalesAmount,
    required this.paymentBreakdown,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final double totalSalesAmount;
  final List<PaymentMethodBreakdown> paymentBreakdown;

  bool get isSingleDay =>
      calendarDay(startDate) == calendarDay(endDate);
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

DateTime calendarDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

bool isTodayCalendarDay(DateTime day) =>
    calendarDay(day) == calendarDay(DateTime.now());

/// Sales are attributed to the calendar day of [OrdersRecord.createdTime].
DateTime? dailySalesReportDate(OrdersRecord order) {
  if (order.createdTime != null) {
    return order.createdTime;
  }
  if (isRetailOrderRecord(order)) {
    return order.deliveryDate;
  }
  return null;
}

bool orderMatchesDailySalesDate(OrdersRecord order, DateTime day) {
  return isOrderOnCalendarDay(dailySalesReportDate(order), day);
}

bool orderMatchesDailySalesDateRange(
  OrdersRecord order, {
  required DateTime startDate,
  required DateTime endDate,
}) {
  final timestamp = dailySalesReportDate(order);
  if (timestamp == null) {
    return false;
  }
  final effective = timestamp.toLocal();
  return !effective.isBefore(startOfDay(startDate)) &&
      !effective.isAfter(endOfDay(endDate));
}

({DateTime start, DateTime end}) normalizeSalesReportDateRange({
  required DateTime startDate,
  required DateTime endDate,
}) {
  var start = calendarDay(startDate);
  var end = calendarDay(endDate);
  if (start.isAfter(end)) {
    final swapped = start;
    start = end;
    end = swapped;
  }
  return (start: start, end: end);
}

bool isTodayDateRange(DateTime startDate, DateTime endDate) {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  final today = calendarDay(DateTime.now());
  return range.start == today && range.end == today;
}

double orderSalesAmount(OrdersRecord order) {
  if (order.totalAmount > 0) {
    return order.totalAmount;
  }
  return order.total;
}

/// Loads paid orders between [startDate] and [endDate] (inclusive).
Future<DailySalesReport> buildDailySalesReportRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );
  final rangeStart = startOfDay(range.start);
  final rangeEnd = endOfDay(range.end);

  List<OrdersRecord> orders;
  try {
    orders = await queryTenantOrdersRecordOnce(
      queryBuilder: (q) => q
          .where('created_time', isGreaterThanOrEqualTo: rangeStart)
          .where('created_time', isLessThanOrEqualTo: rangeEnd),
    );
    orders = orders
        .where(
          (order) => orderMatchesDailySalesDateRange(
            order,
            startDate: range.start,
            endDate: range.end,
          ),
        )
        .toList();
  } catch (_) {
    orders = await queryTenantOrdersRecordOnce();
    orders = orders
        .where(
          (order) => orderMatchesDailySalesDateRange(
            order,
            startDate: range.start,
            endDate: range.end,
          ),
        )
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
    startDate: range.start,
    endDate: range.end,
    totalOrders: paidOrders.length,
    totalSalesAmount: salesSum,
    paymentBreakdown: breakdown,
  );
}

/// Loads paid orders for a single [day].
Future<DailySalesReport> buildDailySalesReport(DateTime day) =>
    buildDailySalesReportRange(startDate: day, endDate: day);
