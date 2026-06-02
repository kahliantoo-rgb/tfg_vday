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
  OrderStatus? status,
}) {
  return OrdersRecord.getDocumentFromData(
    {
      'client_name': clientName,
      'address': address,
      'Order_Id': orderId,
      if (status != null) 'status': status.serialize(),
      if (status != null) 'orderstatus': legacyOrderStatusLabel(status),
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
}
