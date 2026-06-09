import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/product_selection_helpers.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';

import 'firebase_test_setup.dart';

ProductRecord _product({
  required String id,
  required String name,
  String sku = '',
  String category = '',
}) {
  return ProductRecord.getDocumentFromData(
    {
      'name': name,
      'sku': sku,
      'category': category,
      'price': 10,
      'isActive': true,
    },
    FirebaseFirestore.instance.collection('product').doc(id),
  );
}

void main() {
  setUpAll(() async {
    await setupFirebaseForTests();
  });

  group('filterProductsBySearchQuery', () {
    test('matches name sku and category', () {
      final products = [
        _product(id: '1', name: 'Rose Bouquet', sku: 'RB01', category: 'Hand Bouquet'),
        _product(id: '2', name: 'Opening Stand A', category: 'Opening Stand'),
      ];

      expect(
        filterProductsBySearchQuery(products, 'rb01').map((p) => p.name),
        ['Rose Bouquet'],
      );
      expect(
        filterProductsBySearchQuery(products, 'opening').map((p) => p.name),
        ['Opening Stand A'],
      );
    });
  });

  group('filterProductsByCategory', () {
    test('returns only selected category', () {
      final products = [
        _product(id: '1', name: 'A', category: 'Wreath'),
        _product(id: '2', name: 'B', category: 'Hand Bouquet'),
      ];

      expect(
        filterProductsByCategory(products, 'Wreath').map((p) => p.name),
        ['A'],
      );
      expect(filterProductsByCategory(products, null), products);
    });
  });

  group('applyProductSelectionFilters', () {
    test('combines search and category filters', () {
      final products = [
        _product(id: '1', name: 'Pink Rose', category: 'Hand Bouquet'),
        _product(id: '2', name: 'Red Rose', category: 'Hand Bouquet'),
        _product(id: '3', name: 'Pink Wreath', category: 'Wreath'),
      ];

      final filtered = applyProductSelectionFilters(
        products: products,
        searchQuery: 'pink',
        category: 'Hand Bouquet',
      );

      expect(filtered.map((p) => p.name), ['Pink Rose']);
    });
  });
}
