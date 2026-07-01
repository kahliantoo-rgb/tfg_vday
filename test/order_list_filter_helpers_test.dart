import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_list_filter_helpers.dart';
import 'package:tfg_vday/backend/order_status_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  required String id,
  String clientName = '',
  String address = '',
  String orderId = '',
  String orderType = '',
  String pickupDelivery = '',
  OrderStatus? status,
  DateTime? deliveryDate,
  DateTime? createdTime,
}) {
  return OrdersRecord.getDocumentFromData(
    {
      'client_name': clientName,
      'address': address,
      'Order_Id': orderId,
      if (orderType.isNotEmpty) 'orderType': orderType,
      if (pickupDelivery.isNotEmpty) 'pickup_delivery': pickupDelivery,
      if (status != null) 'status': status.serialize(),
      if (status != null) 'orderstatus': legacyOrderStatusLabel(status),
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (createdTime != null) 'created_time': createdTime,
    },
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

OrderItemRecord _item({
  required String orderId,
  required String name,
}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': name,
      'orderRef': FirebaseFirestore.instance.collection('orders').doc(orderId),
    },
    FirebaseFirestore.instance.collection('order_item').doc('item_$orderId'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('applyOrderListTextFilter matches client name', () {
    final orders = [_order(id: '1', clientName: 'Alice Lee')];
    final result = applyOrderListTextFilter(
      orders: orders,
      orderItems: [],
      searchText: 'alice',
    );
    expect(result.length, 1);
  });

  test('applyOrderListTextFilter matches product name', () {
    final orders = [_order(id: '1', clientName: 'Bob')];
    final items = [_item(orderId: '1', name: 'Rose Bouquet')];
    final result = applyOrderListTextFilter(
      orders: orders,
      orderItems: items,
      searchText: 'rose',
    );
    expect(result.length, 1);
  });

  test('legacyStatusToEnum maps readyToShip', () {
    expect(legacyStatusToEnum('readyToShip'), OrderStatus.ready_to_delivery);
  });

  test('isOrderListTypeFilterActive treats All as no filter', () {
    expect(isOrderListTypeFilterActive(null), isFalse);
    expect(isOrderListTypeFilterActive(''), isFalse);
    expect(isOrderListTypeFilterActive('All'), isFalse);
    expect(isOrderListTypeFilterActive('all'), isFalse);
    expect(isOrderListTypeFilterActive('Retail'), isTrue);
  });

  test('applyOrderListClientFilters All shows every order type', () {
    final orders = [
      _order(id: '1', orderType: 'Retail'),
      _order(id: '2', pickupDelivery: 'Delivery'),
      _order(id: '3', pickupDelivery: 'PickUp'),
    ];
    final all = applyOrderListClientFilters(
      orders: orders,
      orderItems: [],
      orderType: 'All',
      searchText: '',
    );
    expect(all.length, 3);

    final retailOnly = applyOrderListClientFilters(
      orders: orders,
      orderItems: [],
      orderType: 'Retail',
      searchText: '',
    );
    expect(retailOnly.length, 1);
    expect(retailOnly.first.reference.id, '1');
  });

  test('retail orders match date filter by created_time', () {
    final created = DateTime(2026, 6, 4, 10, 30);
    final orders = [
      _order(
        id: 'retail',
        orderType: 'Retail',
        orderId: 'TFG-WI0001',
        createdTime: created,
      ),
      _order(
        id: 'delivery',
        orderType: 'Delivery',
        deliveryDate: DateTime(2026, 6, 10),
        createdTime: created,
      ),
    ];

    final today = applyOrderListClientFilters(
      orders: orders,
      orderItems: [],
      startDate: DateTime(2026, 6, 4),
      endDate: DateTime(2026, 6, 4),
      searchText: '',
    );
    expect(today.map((o) => o.reference.id), ['retail']);

    final deliveryDay = applyOrderListClientFilters(
      orders: orders,
      orderItems: [],
      startDate: DateTime(2026, 6, 10),
      endDate: DateTime(2026, 6, 10),
      searchText: '',
    );
    expect(deliveryDay.map((o) => o.reference.id), ['delivery']);
  });

  test('retail order id matches Retail type filter without orderType field', () {
    final orders = [
      _order(id: '1', orderId: 'TFG-WI0002'),
    ];
    final retailOnly = applyOrderListClientFilters(
      orders: orders,
      orderItems: [],
      orderType: 'Retail',
      searchText: '',
    );
    expect(retailOnly.length, 1);
  });

  test('defaultOrderListDateRange spans three days before and after today', () {
    final asOf = DateTime(2026, 6, 12, 15, 30);
    final range = defaultOrderListDateRange(asOf: asOf);
    expect(range.start, DateTime(2026, 6, 9));
    expect(range.end, DateTime(2026, 6, 15, 23, 59, 59, 999));
  });

  test('sortOrdersForOrderList orders earliest delivery date first', () {
    final orders = [
      _order(id: 'late', deliveryDate: DateTime(2026, 6, 15)),
      _order(id: 'early', deliveryDate: DateTime(2026, 6, 10)),
      _order(id: 'mid', deliveryDate: DateTime(2026, 6, 12)),
    ];
    final sorted = sortOrdersForOrderList(orders);
    expect(sorted.map((o) => o.reference.id), ['early', 'mid', 'late']);
  });

  test('applyOrderListClientFilters returns date-sorted orders', () {
    final orders = [
      _order(id: 'b', deliveryDate: DateTime(2026, 6, 20)),
      _order(id: 'a', deliveryDate: DateTime(2026, 6, 5)),
    ];
    final filtered = applyOrderListClientFilters(
      orders: orders,
      orderItems: [],
      searchText: '',
    );
    expect(filtered.map((o) => o.reference.id), ['a', 'b']);
  });
}
