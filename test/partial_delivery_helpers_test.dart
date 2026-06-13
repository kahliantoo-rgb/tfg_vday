import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/partial_delivery_helpers.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrderItemRecord _item({required int qty, int deliveredQty = 0, double price = 0}) {
  return OrderItemRecord.getDocumentFromData(
    {
      'name': 'Rose bouquet',
      'qty': qty,
      'delivered_qty': deliveredQty,
      if (price > 0) 'price': price,
    },
    OrderItemRecord.collection.doc('test-item'),
  );
}

void main() {
  setUpAll(() async {
    await setupFirebaseForTests();
  });

  group('remainingDeliveryQty', () {
    test('returns full qty when nothing delivered yet', () {
      expect(remainingDeliveryQty(_item(qty: 10)), 10);
    });

    test('returns remainder after partial delivery', () {
      expect(remainingDeliveryQty(_item(qty: 10, deliveredQty: 5)), 5);
    });
  });

  group('isOrderFullyDelivered', () {
    test('false when any line has remaining qty', () {
      expect(
        isOrderFullyDelivered([
          _item(qty: 10, deliveredQty: 5),
          _item(qty: 2, deliveredQty: 2),
        ]),
        isFalse,
      );
    });

    test('true when every active line is fully delivered', () {
      expect(
        isOrderFullyDelivered([
          _item(qty: 10, deliveredQty: 10),
          _item(qty: 2, deliveredQty: 2),
        ]),
        isTrue,
      );
    });
  });

  group('validatePartialDeliveryLines', () {
    test('rejects deliver qty above remaining', () {
      final error = validatePartialDeliveryLines([
        PartialDeliveryLineInput(item: _item(qty: 10, deliveredQty: 5), deliverNow: 6),
      ]);
      expect(error, contains('cannot deliver 6'));
    });

    test('accepts valid partial quantities', () {
      final error = validatePartialDeliveryLines([
        PartialDeliveryLineInput(item: _item(qty: 10), deliverNow: 5),
      ]);
      expect(error, isNull);
    });
  });

  group('formatPartialDeliveryProgress', () {
    test('shows delivered and remaining counts', () {
      expect(
        formatPartialDeliveryProgress([
          _item(qty: 10, deliveredQty: 5),
        ]),
        'Qty 10 (5 delivered, 5 left)',
      );
    });
  });

  group('partialDeliveryPrintItems', () {
    test('orderItemForPrintQty adjusts qty and subtotal', () {
      final source = _item(qty: 10, price: 12);
      final printed = orderItemForPrintQty(source, 3);
      expect(printed.qty, 3);
      expect(printed.subtotal, 36.0);
    });

    test('partialDeliveryPrintItems includes only deliver-now lines', () {
      final items = partialDeliveryPrintItems([
        PartialDeliveryLineInput(item: _item(qty: 10), deliverNow: 4),
        PartialDeliveryLineInput(item: _item(qty: 5), deliverNow: 0),
      ]);
      expect(items, hasLength(1));
      expect(items.first.qty, 4);
    });
  });

  group('partialDeliveryIdForRun', () {
    test('appends run suffix to order id', () {
      expect(
        partialDeliveryIdForRun('TFG-JUN26-0005', 1),
        'TFG-JUN26-0005-1',
      );
      expect(
        partialDeliveryIdForRun('TFG-JUN26-0005', 2),
        'TFG-JUN26-0005-2',
      );
    });
  });

  group('parsePartialDeliveryRuns', () {
    test('parses and sorts runs by run number', () {
      final runs = parsePartialDeliveryRuns({
        'partial_delivery_runs': [
          {
            'run_number': 2,
            'delivery_id': 'TFG-JUN26-0005-2',
            'items': [
              {'name': 'Rose', 'qty': 3},
            ],
          },
          {
            'run_number': 1,
            'delivery_id': 'TFG-JUN26-0005-1',
            'items': [
              {'name': 'Rose', 'qty': 2},
            ],
          },
        ],
      });
      expect(runs, hasLength(2));
      expect(runs.first.deliveryId, 'TFG-JUN26-0005-1');
      expect(runs.last.deliveryId, 'TFG-JUN26-0005-2');
    });
  });

  group('orderItemsFromPartialDeliveryRun', () {
    test('rebuilds order items for printing', () {
      final orderRef = OrdersRecord.collection.doc('order-1');
      final run = PartialDeliveryRun(
        runNumber: 1,
        deliveryId: 'TFG-JUN26-0005-1',
        items: [
          {
            'item_id': 'line-1',
            'name': 'Rose bouquet',
            'qty': 4,
            'price': 10.0,
            'subtotal': 40.0,
          },
        ],
      );
      final items = orderItemsFromPartialDeliveryRun(run, orderRef);
      expect(items, hasLength(1));
      expect(items.first.name, 'Rose bouquet');
      expect(items.first.qty, 4);
      expect(items.first.subtotal, 40.0);
    });
  });
}
