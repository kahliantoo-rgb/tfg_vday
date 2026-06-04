import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_list_display_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({required String id, Map<String, dynamic> data = const {}}) {
  return OrdersRecord.getDocumentFromData(
    data,
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

OrderItemRecord _item({
  required String orderId,
  required String name,
  String remark = '',
  int qty = 1,
}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': name,
      if (remark.isNotEmpty) 'Remark': remark,
      'qty': qty,
      'orderRef': FirebaseFirestore.instance.collection('orders').doc(orderId),
    },
    FirebaseFirestore.instance.collection('order_item').doc('item_$name'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('orderListProductSummary includes remark and qty', () {
    final summary = orderListProductSummary([
      _item(orderId: '1', name: 'Rose Box', remark: 'Red ribbon', qty: 2),
    ]);
    expect(summary, 'Rose Box · Red ribbon · Qty 2');
  });

  test('orderListRecipient prefers recipient_name field', () {
    final order = _order(
      id: '1',
      data: {
        'client_name': 'Alice',
        'recipient_name': 'Bob',
      },
    );
    expect(orderListRecipient(order), 'Bob');
  });

  test('orderListPickupDelivery normalizes delivery type', () {
    final order = _order(
      id: '1',
      data: {'pickup_delivery': 'Delivery'},
    );
    expect(orderListPickupDelivery(order), 'Delivery');
  });

  test('orderListDeliveryDate uses created_time for retail orders', () {
    final order = _order(
      id: '1',
      data: {
        'orderType': 'Retail',
        'Order_Id': 'TFG-WI0001',
        'created_time': DateTime(2026, 6, 4),
      },
    );
    expect(orderListDeliveryDate(order), '4/6/2026');
  });
}
