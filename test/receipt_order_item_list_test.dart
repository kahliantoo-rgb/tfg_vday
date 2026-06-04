import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/components/delivery_order_item_table.dart';
import 'package:tfg_vday/components/receipt_order_item_list.dart';

import 'firebase_test_setup.dart';

OrderItemRecord _item({String remark = '', double price = 88, int qty = 1}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': '3 Stalks Sunflower',
      'Remark': remark,
      'price': price,
      'qty': qty,
    },
    FirebaseFirestore.instance.collection('order_item').doc('x'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('displayRemark hides NA placeholders', () {
    expect(ReceiptOrderItemRow.displayRemark(''), '');
    expect(ReceiptOrderItemRow.displayRemark('NA'), '');
    expect(ReceiptOrderItemRow.displayRemark('n/a'), '');
    expect(ReceiptOrderItemRow.displayRemark('Red ribbon'), 'Red ribbon');
  });

  test('lineTotal uses subtotal when set', () {
    final item = OrderItemRecord.getDocumentFromData(
      {'price': 10, 'qty': 2, 'subtotal': 25.0},
      FirebaseFirestore.instance.collection('order_item').doc('y'),
    );
    expect(ReceiptOrderItemRow.lineTotal(item), 25.0);
  });

  test('DeliveryOrderItemTable remarkText hides NA', () {
    expect(
      DeliveryOrderItemTable.remarkText(_item(remark: 'NA')),
      '-',
    );
    expect(
      DeliveryOrderItemTable.remarkText(_item(remark: 'red')),
      'red',
    );
  });
}
