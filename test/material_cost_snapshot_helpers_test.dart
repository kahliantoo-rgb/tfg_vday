import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/material_cost_snapshot_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/material_record.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);
  group('orderQualifiesForMaterialCostSnapshot', () {
    test('requires payment type, non-cancelled status, and positive total', () {
      expect(
        orderQualifiesForMaterialCostSnapshot(
          paymentType: 'Cash',
          status: OrderStatus.completed,
          totalAmount: 100,
        ),
        isTrue,
      );
      expect(
        orderQualifiesForMaterialCostSnapshot(
          paymentType: '',
          status: OrderStatus.completed,
          totalAmount: 100,
        ),
        isFalse,
      );
    });
  });

  group('sumSnapshottedMaterialUsageCost', () {
    test('sums only orders with locked snapshot', () {
      final orders = [
        OrdersRecord.getDocumentFromData(
          {
            'paymentType': 'Cash',
            'totalAmount': 50,
            'material_usage_cost': 12.5,
            'material_cost_snapshotted_at': DateTime(2026, 1, 1),
          },
          FirebaseFirestore.instance.collection('orders').doc('a'),
        ),
        OrdersRecord.getDocumentFromData(
          {
            'paymentType': 'Cash',
            'totalAmount': 80,
          },
          FirebaseFirestore.instance.collection('orders').doc('b'),
        ),
      ];

      expect(sumSnapshottedMaterialUsageCost(orders), 12.5);
    });
  });

  group('computeOrderMaterialCostSnapshot', () {
    test('multiplies recipe usage by catalog unit costs', () async {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc('o1');
      final productRef =
          FirebaseFirestore.instance.collection('product').doc('bouquet');
      final roseRef = FirebaseFirestore.instance.collection('materials').doc('rose');
      final wrapRef = FirebaseFirestore.instance.collection('materials').doc('wrap');

      final orderItems = [
        OrderItemRecord.getDocumentFromData(
          {
            'orderRef': orderRef,
            'productRef': productRef,
            'name': 'Rose Bouquet',
            'qty': 2,
            'price': 50,
            'status': 'active',
          },
          FirebaseFirestore.instance.collection('Order_item').doc('item1'),
        ),
      ];
      final products = [
        ProductRecord.getDocumentFromData(
          {
            'name': 'Rose Bouquet',
            'recipeLines': [
              {
                'materialRef': roseRef,
                'materialName': 'Rose',
                'qty': 10,
                'unit': 'stem',
              },
              {
                'materialRef': wrapRef,
                'materialName': 'Wrap',
                'qty': 1,
                'unit': 'sheet',
              },
            ],
          },
          productRef,
        ),
      ];
      final materials = [
        MaterialRecord.getDocumentFromData(
          {'name': 'Rose', 'cost': 2.5, 'unit': 'stem'},
          roseRef,
        ),
        MaterialRecord.getDocumentFromData(
          {'name': 'Wrap', 'cost': 1, 'unit': 'sheet'},
          wrapRef,
        ),
      ];

      final result = await computeOrderMaterialCostSnapshot(
        orderRef: orderRef,
        orderItems: orderItems,
        products: products,
        materials: materials,
      );

      expect(result.totalCost, 52);
      expect(result.unitCostByMaterialRefPath[roseRef.path], 2.5);
      expect(result.unitCostByMaterialRefPath[wrapRef.path], 1);
    });
  });
}
