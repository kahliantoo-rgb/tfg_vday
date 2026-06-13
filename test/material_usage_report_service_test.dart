import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/material_usage_report_service.dart';
import 'package:tfg_vday/backend/product_recipe_helpers.dart';
import 'package:tfg_vday/backend/schema/material_record.dart';
import 'package:tfg_vday/backend/schema/order_item_record.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);

  group('aggregateMaterialUsage', () {
    test('multiplies recipe qty by sold item qty', () {
      final roseRef = MaterialRecord.collection.doc('rose');
      final wrapRef = MaterialRecord.collection.doc('wrap');
      final productRef = ProductRecord.collection.doc('bouquet');
      final lookup = ProductRecipeLookup.fromProducts([
        ProductRecord.getDocumentFromData(
          {
            'name': 'Hand Bouquet',
            'recipeLines': [
              {
                'materialRef': roseRef,
                'materialName': 'Red Rose',
                'qty': 12,
                'unit': 'stem',
              },
              {
                'materialRef': wrapRef,
                'materialName': 'Wrapper',
                'qty': 2,
                'unit': 'sheet',
              },
            ],
          },
          productRef,
        ),
      ]);

      final unmatched = <ProductWithoutRecipeBreakdown>[];
      final usage = aggregateMaterialUsage(
        items: [
          OrderItemRecord.getDocumentFromData(
            {
              'name': 'Hand Bouquet',
              'qty': 3,
              'productRef': productRef,
            },
            OrderItemRecord.collection.doc('line1'),
          ),
        ],
        lookup: lookup,
        unmatchedProductsOut: unmatched,
      );

      expect(unmatched, isEmpty);
      expect(usage, hasLength(2));
      final rose = usage.firstWhere((row) => row.materialName == 'Red Rose');
      final wrap = usage.firstWhere((row) => row.materialName == 'Wrapper');
      expect(rose.totalQty, 36);
      expect(wrap.totalQty, 6);
    });

    test('tracks sold products without recipes', () {
      final lookup = ProductRecipeLookup.fromProducts(const []);
      final unmatched = <ProductWithoutRecipeBreakdown>[];
      aggregateMaterialUsage(
        items: [
          OrderItemRecord.getDocumentFromData(
            {
              'name': 'Custom Item',
              'qty': 2,
            },
            OrderItemRecord.collection.doc('line2'),
          ),
        ],
        lookup: lookup,
        unmatchedProductsOut: unmatched,
      );

      expect(unmatched, hasLength(1));
      expect(unmatched.first.productName, 'Custom Item');
      expect(unmatched.first.totalQty, 2);
    });
  });
}
