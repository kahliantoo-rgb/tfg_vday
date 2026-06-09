import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_item_helpers.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';

import 'firebase_test_setup.dart';

OrderItemRecord _item({int qty = 1}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': 'Rose',
      'price': 10.0,
      'qty': qty,
    },
    FirebaseFirestore.instance.collection('order_item').doc('x'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('activeOrderItems excludes zero-qty rows', () {
    final items = [
      _item(qty: 2),
      _item(qty: 0),
      _item(qty: 1),
    ];

    final active = activeOrderItems(items);
    expect(active.length, 2);
    expect(active.every((item) => item.qty > 0), isTrue);
  });

  test('isActiveOrderItem treats missing qty as inactive', () {
    final item = OrderItemRecord.getDocumentFromData(
      {'name': 'Rose', 'price': 10.0},
      FirebaseFirestore.instance.collection('order_item').doc('y'),
    );
    expect(isActiveOrderItem(item), isFalse);
  });
}
