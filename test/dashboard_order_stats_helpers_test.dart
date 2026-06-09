import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/daily_sales_report_service.dart';
import 'package:tfg_vday/backend/dashboard_order_stats_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  required String id,
  String orderType = 'Delivery',
  String pickupDelivery = 'Delivery',
  OrderStatus? status,
  String orderstatus = '',
  DateTime? deliveryDate,
  DateTime? createdTime,
}) {
  return OrdersRecord.getDocumentFromData(
    {
      if (orderType.isNotEmpty) 'orderType': orderType,
      if (pickupDelivery.isNotEmpty) 'pickup_delivery': pickupDelivery,
      if (status != null) 'status': status!.serialize(),
      if (orderstatus.isNotEmpty) 'orderstatus': orderstatus,
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (createdTime != null) 'created_time': createdTime,
    },
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('computeDashboardOrderStats counts today delivery without pickup', () {
    final today = calendarDay(DateTime.now());
    final stats = computeDashboardOrderStats([
      _order(
        id: '1',
        deliveryDate: today,
        status: OrderStatus.pending,
      ),
      _order(
        id: '2',
        pickupDelivery: 'PickUp',
        deliveryDate: today,
        status: OrderStatus.pending,
      ),
      _order(
        id: '3',
        pickupDelivery: 'Delivery/Pick Up',
        deliveryDate: today,
        status: OrderStatus.completed,
      ),
      _order(
        id: '4',
        orderType: 'Retail',
        pickupDelivery: 'Retail',
        createdTime: today,
        status: OrderStatus.completed,
      ),
      _order(
        id: '5',
        deliveryDate: today.subtract(const Duration(days: 1)),
        status: OrderStatus.pending,
      ),
    ]);

    expect(stats.todayDeliveryOrders, 1);
    expect(stats.todayPendingOrders, 2);
    expect(stats.todayCompletedOrders, 2);
    expect(stats.todayTotalOrders, 4);
    expect(stats.tomorrowDeliveryOrders, 0);
    expect(stats.tomorrowTotalOrders, 0);
  });

  test('computeDashboardOrderStats counts tomorrow delivery and total', () {
    final today = calendarDay(DateTime.now());
    final tomorrow = calendarDay(today.add(const Duration(days: 1)));
    final stats = computeDashboardOrderStats([
      _order(
        id: 'tomorrow-delivery',
        deliveryDate: tomorrow,
        status: OrderStatus.pending,
      ),
      _order(
        id: 'tomorrow-pickup',
        pickupDelivery: 'PickUp',
        deliveryDate: tomorrow,
        status: OrderStatus.pending,
      ),
      _order(
        id: 'tomorrow-retail',
        orderType: 'Retail',
        pickupDelivery: 'Retail',
        createdTime: tomorrow,
        status: OrderStatus.completed,
      ),
    ]);

    expect(stats.tomorrowDeliveryOrders, 1);
    expect(stats.tomorrowTotalOrders, 3);
  });
}
