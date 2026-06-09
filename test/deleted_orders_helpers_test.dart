import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/deleted_orders_helpers.dart';
import 'package:tfg_vday/backend/schema/deleted_orders_record.dart';

import 'firebase_test_setup.dart';

DeletedOrdersRecord _archive({
  required String id,
  String orderId = 'TFG-WI0001',
  String clientName = 'Alice',
  String deletedBy = 'admin@test.com',
  DateTime? deletedAt,
  String status = 'completed',
  double total = 50.0,
  bool isRestored = false,
  List<Map<String, dynamic>>? items,
}) {
  return DeletedOrdersRecord.getDocumentFromData(
    {
      'original_order_id': id,
      'order_id': orderId,
      'order_data': {
        'client_name': clientName,
        'created_time': DateTime(2026, 2, 14),
        'totalAmount': total,
        'status': status,
      },
      'order_items': items ??
          [
            {
              'item_id': 'item1',
              'item_data': {'name': 'Rose Bouquet', 'qty': 2},
            },
          ],
      'deleted_at': deletedAt ?? DateTime(2026, 6, 1),
      'deleted_by_email': deletedBy,
      'original_order_status': status,
      'is_restored': isRestored,
    },
    FirebaseFirestore.instance.collection('deleted_orders').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('filterDeletedOrders matches search and excludes restored', () {
    final records = [
      _archive(id: 'a1', orderId: 'TFG-WI0001', clientName: 'Alice'),
      _archive(id: 'a2', orderId: 'TFG-WI0002', clientName: 'Bob'),
      _archive(id: 'a3', orderId: 'TFG-WI0003', isRestored: true),
    ];

    final filtered = filterDeletedOrders(
      records: records,
      searchQuery: 'alice',
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.orderId, 'TFG-WI0001');
  });

  test('computeDeletedOrdersAnalytics aggregates revenue and products', () {
    final records = [
      _archive(id: 'a1', total: 100, deletedBy: 'admin@test.com'),
      _archive(
        id: 'a2',
        total: 40,
        deletedBy: 'florist@test.com',
        items: [
          {
            'item_id': 'i1',
            'item_data': {'name': 'Rose Bouquet', 'qty': 3},
          },
        ],
      ),
    ];

    final analytics = computeDeletedOrdersAnalytics(records);

    expect(analytics.totalDeletedOrders, 2);
    expect(analytics.totalDeletedRevenue, 140);
    expect(analytics.mostDeletedProduct, 'Rose Bouquet');
    expect(analytics.mostActiveDeleter, 'admin@test.com');
  });

  test('paginateDeletedOrders returns correct slice', () {
    final records = List.generate(
      25,
      (index) => _archive(id: 'a$index', orderId: 'TFG-WI$index'),
    );

    final slice = paginateDeletedOrders(records: records, pageIndex: 1);

    expect(slice.pageIndex, 1);
    expect(slice.totalPages, 2);
    expect(slice.items, hasLength(5));
  });
}
