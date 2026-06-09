import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_delete_service.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({required String id, String orderId = 'TFG-WI0001'}) {
  return OrdersRecord.getDocumentFromData(
    {
      'Order_Id': orderId,
      'client_name': 'Alice',
    },
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

OrderItemRecord _item({required String orderId}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': 'Rose',
      'qty': 1,
      'orderRef': FirebaseFirestore.instance.collection('orders').doc(orderId),
    },
    FirebaseFirestore.instance.collection('Order_item').doc('item_$orderId'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('createDeletedOrderArchiveData includes order and items snapshot', () {
    final order = _order(id: 'order1');
    final items = [_item(orderId: 'order1')];

    final data = createDeletedOrderArchiveData(
      order: order,
      items: items,
      deletedByUid: 'uid-1',
      deletedByEmail: 'admin@test.com',
    );

    expect(data['original_order_id'], 'order1');
    expect(data['order_id'], 'TFG-WI0001');
    expect(data['deleted_by_uid'], 'uid-1');
    expect(data['deleted_by_email'], 'admin@test.com');
    expect(data['delete_reason'], '');
    expect(data['original_order_status'], '');
    expect(data['activity_log'], hasLength(1));
    expect(data['order_data'], isA<Map>());
    expect(data['order_items'], hasLength(1));
  });

  test('createDeletedOrderArchiveData captures order status', () {
    final order = OrdersRecord.getDocumentFromData(
      {
        'Order_Id': 'TFG-2026-0001',
        'client_name': 'Bob',
        'status': 'pending',
        'orderstatus': 'pending',
      },
      FirebaseFirestore.instance.collection('orders').doc('order2'),
    );

    final data = createDeletedOrderArchiveData(
      order: order,
      items: const [],
      deletedByUid: 'uid-2',
      deletedByEmail: 'florist@test.com',
      deleteReason: 'Customer cancelled',
    );

    expect(data['original_order_status'], 'pending');
    expect(data['delete_reason'], 'Customer cancelled');
  });
}
