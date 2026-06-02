import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';
import 'package:tfg_vday/custom_code/actions/csv_export_helpers.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);
  test('orders + items CSV: headers match row columns', () {
    final order = OrdersRecord.getDocumentFromData(
      {
        'Order_Id': 'TFG-001',
        'client_name': 'Alice',
        'customer_phone_number': '91234567',
        'orderType': 'Delivery',
        'address': '123 Main St',
        'region': 'Central',
        'delivery_date': DateTime(2026, 6, 2),
        'delivery_time_slot': '10-12',
        'status': OrderStatus.pending.serialize(),
        'orderstatus': 'pending',
        'card_message': 'Happy Day',
      },
      FirebaseFirestore.instance.collection('orders').doc('o1'),
    );
    final item = OrderItemRecord.getDocumentFromData(
      {
        'name': 'Rose Bouquet',
        'Remark': 'Red roses',
        'qty': 2,
        'orderRef': order.reference,
      },
      FirebaseFirestore.instance.collection('Order_item').doc('i1'),
    );

    final row = buildOrdersItemsPickupRow(order, item);
    expect(row.length, kOrdersItemsPickupCsvHeaders.length);
    assertCsvRowMatchesHeader(kOrdersItemsPickupCsvHeaders, row);

    expect(row[kOrdersItemsPickupCsvHeaders.indexOf('Delivery Date')],
        '2026-06-02');
    expect(
        row[kOrdersItemsPickupCsvHeaders.indexOf('Product Name')], 'Rose Bouquet');
    expect(row[kOrdersItemsPickupCsvHeaders.indexOf('Remark')], 'Red roses');
    expect(row[kOrdersItemsPickupCsvHeaders.indexOf('Status')], 'pending');
    expect(row[kOrdersItemsPickupCsvHeaders.indexOf('Client Name')], 'Alice');
  });

  test('orders-only CSV: headers match row columns', () {
    final order = OrdersRecord.getDocumentFromData(
      {
        'Order_Id': 'TFG-002',
        'client_name': 'Bob',
        'delivery_date': DateTime(2026, 1, 15),
        'PostalCode': '123456',
        'totalAmount': 99.5,
      },
      FirebaseFirestore.instance.collection('orders').doc('o2'),
    );
    final row = buildOrdersOnlyRow(order);
    expect(row.length, kOrdersOnlyCsvHeaders.length);
    expect(row[kOrdersOnlyCsvHeaders.indexOf('Delivery Date')], '2026-01-15');
    expect(row[kOrdersOnlyCsvHeaders.indexOf('Postal Code')], '123456');
  });

  test('order items CSV: product column is item name', () {
    final item = OrderItemRecord.getDocumentFromData(
      {
        'orderId': 'TFG-003',
        'name': 'Sunflower Box',
        'qty': 1,
        'price': 45.0,
        'deliverydate': DateTime(2026, 3, 1),
        'status': 'pending',
      },
      FirebaseFirestore.instance.collection('Order_item').doc('i2'),
    );
    final row = buildOrderItemOnlyRow(item);
    expect(row.length, kOrderItemsOnlyCsvHeaders.length);
    expect(row[kOrderItemsOnlyCsvHeaders.indexOf('Product Name')],
        'Sunflower Box');
    expect(row[kOrderItemsOnlyCsvHeaders.indexOf('Delivery Date')], '2026-03-01');
  });
}
