import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/daily_sales_report_service.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  required String id,
  double totalAmount = 100,
  String paymentType = 'Cash',
  DateTime? createdTime,
  OrderStatus? status,
}) {
  return OrdersRecord.getDocumentFromData(
    {
      'totalAmount': totalAmount,
      'paymentType': paymentType,
      if (createdTime != null) 'created_time': createdTime,
      if (status != null) 'status': status!.serialize(),
    },
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('normalizePaymentLabel maps Paynow to PayNow', () {
    expect(normalizePaymentLabel('Paynow'), 'PayNow');
    expect(normalizePaymentLabel('cash'), 'Cash');
  });

  test('orderQualifiesForDailySales requires payment and amount', () {
    expect(
      orderQualifiesForDailySales(
        _order(id: '1', paymentType: '', totalAmount: 50),
      ),
      isFalse,
    );
    expect(
      orderQualifiesForDailySales(
        _order(
          id: '2',
          paymentType: 'Card',
          status: OrderStatus.cancelled,
        ),
      ),
      isFalse,
    );
    expect(
      orderQualifiesForDailySales(
        _order(id: '3', paymentType: 'Cash', totalAmount: 80),
      ),
      isTrue,
    );
  });

  test('isOrderOnCalendarDay matches local calendar day', () {
    final day = DateTime(2026, 6, 3);
    expect(
      isOrderOnCalendarDay(DateTime(2026, 6, 3, 15, 30), day),
      isTrue,
    );
    expect(
      isOrderOnCalendarDay(DateTime(2026, 6, 4, 1), day),
      isFalse,
    );
  });

  test('orderMatchesDailySalesDate uses created_time', () {
    final day = DateTime(2026, 6, 4);
    expect(
      orderMatchesDailySalesDate(
        _order(
          id: '1',
          createdTime: DateTime(2026, 6, 4, 10),
          paymentType: 'Cash',
        ),
        day,
      ),
      isTrue,
    );
    expect(
      orderMatchesDailySalesDate(
        _order(
          id: '2',
          createdTime: DateTime(2026, 6, 3, 23, 59),
          paymentType: 'Cash',
        ),
        day,
      ),
      isFalse,
    );
  });

  test('isTodayCalendarDay matches current local day', () {
    final now = DateTime.now();
    expect(isTodayCalendarDay(now), isTrue);
    expect(
      isTodayCalendarDay(now.subtract(const Duration(days: 1))),
      isFalse,
    );
  });

  test('orderMatchesDailySalesDateRange includes inclusive bounds', () {
    final order = _order(
      id: '1',
      createdTime: DateTime(2026, 6, 5, 12),
      paymentType: 'Cash',
    );
    expect(
      orderMatchesDailySalesDateRange(
        order,
        startDate: DateTime(2026, 6, 4),
        endDate: DateTime(2026, 6, 6),
      ),
      isTrue,
    );
    expect(
      orderMatchesDailySalesDateRange(
        order,
        startDate: DateTime(2026, 6, 6),
        endDate: DateTime(2026, 6, 7),
      ),
      isFalse,
    );
  });

  test('normalizeSalesReportDateRange swaps inverted dates', () {
    final range = normalizeSalesReportDateRange(
      startDate: DateTime(2026, 6, 10),
      endDate: DateTime(2026, 6, 3),
    );
    expect(range.start, calendarDay(DateTime(2026, 6, 3)));
    expect(range.end, calendarDay(DateTime(2026, 6, 10)));
  });

  test('isTodayDateRange is true only for today', () {
    final today = calendarDay(DateTime.now());
    expect(isTodayDateRange(today, today), isTrue);
    expect(
      isTodayDateRange(
        today.subtract(const Duration(days: 1)),
        today,
      ),
      isFalse,
    );
  });

  test('aggregateProductSales sums qty and amount by product name', () {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc('o1');
    final items = [
      OrderItemRecord.getDocumentFromData(
        {
          'name': 'Rose Bouquet',
          'price': 50.0,
          'qty': 2,
          'subtotal': 100.0,
          'orderRef': orderRef,
        },
        FirebaseFirestore.instance.collection('order_item').doc('i1'),
      ),
      OrderItemRecord.getDocumentFromData(
        {
          'name': 'Rose Bouquet',
          'price': 50.0,
          'qty': 1,
          'subtotal': 50.0,
          'orderRef': orderRef,
        },
        FirebaseFirestore.instance.collection('order_item').doc('i2'),
      ),
      OrderItemRecord.getDocumentFromData(
        {
          'name': 'Sunflower',
          'price': 30.0,
          'qty': 1,
          'orderRef': orderRef,
        },
        FirebaseFirestore.instance.collection('order_item').doc('i3'),
      ),
      OrderItemRecord.getDocumentFromData(
        {
          'name': 'Removed',
          'price': 10.0,
          'qty': 0,
          'orderRef': orderRef,
        },
        FirebaseFirestore.instance.collection('order_item').doc('i4'),
      ),
    ];

    final breakdown = aggregateProductSales(items);
    expect(breakdown.length, 2);
    expect(breakdown.first.productName, 'Rose Bouquet');
    expect(breakdown.first.totalQty, 3);
    expect(breakdown.first.totalAmount, 150.0);

    final sunflower = breakdown.firstWhere((row) => row.productName == 'Sunflower');
    expect(sunflower.totalQty, 1);
    expect(sunflower.totalAmount, 30.0);
  });
}
