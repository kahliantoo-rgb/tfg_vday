import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/daily_sales_report_service.dart';
import 'package:tfg_vday/backend/leftover_orders_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  required String id,
  OrderStatus? status,
  DateTime? deliveryDate,
}) {
  return OrdersRecord.getDocumentFromData(
    {
      'orderType': 'Delivery',
      'pickup_delivery': 'Delivery',
      if (status != null) 'status': status!.serialize(),
      if (deliveryDate != null) 'delivery_date': deliveryDate,
    },
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('detects out for delivery orders scheduled today as leftover', () {
    final today = calendarDay(DateTime.now());
    expect(
      isLeftoverDeliveryOrder(
        _order(
          id: '1',
          status: OrderStatus.out_of_delivery,
          deliveryDate: today,
        ),
      ),
      isTrue,
    );
  });

  test('detects past-due out for delivery orders as leftover', () {
    final yesterday = calendarDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(
      isLeftoverDeliveryOrder(
        _order(
          id: '2',
          status: OrderStatus.out_of_delivery,
          deliveryDate: yesterday,
        ),
      ),
      isTrue,
    );
  });

  test('completed orders are not leftover', () {
    final today = calendarDay(DateTime.now());
    expect(
      isLeftoverDeliveryOrder(
        _order(
          id: '3',
          status: OrderStatus.completed,
          deliveryDate: today,
        ),
      ),
      isFalse,
    );
  });

  test('needs roll forward only when scheduled before today', () {
    final today = calendarDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    expect(
      needsRollForwardDeliveryDate(
        _order(
          id: '4',
          status: OrderStatus.out_of_delivery,
          deliveryDate: yesterday,
        ),
      ),
      isTrue,
    );
    expect(
      needsRollForwardDeliveryDate(
        _order(
          id: '5',
          status: OrderStatus.out_of_delivery,
          deliveryDate: today,
        ),
      ),
      isFalse,
    );
  });
}
