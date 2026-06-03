import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/daily_sales_report_service.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
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
}
