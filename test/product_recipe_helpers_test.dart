import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/material_helpers.dart';
import 'package:tfg_vday/backend/product_recipe_helpers.dart';
import 'package:tfg_vday/backend/schema/material_record.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);

  group('material helpers', () {
    test('normalizeMaterialName trims whitespace', () {
      expect(normalizeMaterialName('  Red Rose  '), 'Red Rose');
    });

    test('normalizeMaterialUnit defaults to pcs', () {
      expect(normalizeMaterialUnit(''), 'pcs');
      expect(normalizeMaterialUnit('Stem'), 'stem');
    });

    test('filterMaterialsByCategory matches category and uncategorized', () {
      MaterialRecord material(String id, String category) {
        return MaterialRecord.getDocumentFromData(
          {
            'name': id,
            'category': category,
            'unit': 'pcs',
            'isActive': true,
          },
          MaterialRecord.collection.doc(id),
        );
      }

      final materials = [
        material('rose', 'Fresh Flowers'),
        material('wrap', 'Packaging'),
        material('misc', ''),
      ];
      expect(
        filterMaterialsByCategory(materials, 'packaging').map((m) => m.name),
        ['wrap'],
      );
      expect(
        filterMaterialsByCategory(
          materials,
          uncategorizedMaterialCategoryLabel,
        ).map((m) => m.name),
        ['misc'],
      );
    });

    test('applyMaterialSelectionFilters searches and filters by category', () {
      MaterialRecord material(String id, String name, String category) {
        return MaterialRecord.getDocumentFromData(
          {
            'name': name,
            'category': category,
            'unit': 'pcs',
            'sku': id.toUpperCase(),
            'isActive': true,
          },
          MaterialRecord.collection.doc(id),
        );
      }

      final materials = [
        material('rose', 'Red Rose', 'Fresh Flowers'),
        material('wrap', 'Wrapper', 'Packaging'),
      ];

      expect(
        applyMaterialSelectionFilters(
          materials: materials,
          searchQuery: 'wrap',
        ).map((m) => m.name),
        ['Wrapper'],
      );
      expect(
        applyMaterialSelectionFilters(
          materials: materials,
          searchQuery: '',
          category: 'Fresh Flowers',
        ).map((m) => m.name),
        ['Red Rose'],
      );
    });
  });

  group('product recipe helpers', () {
    test('round trips recipe lines on product record', () {
      final materialRef = MaterialRecord.collection.doc('rose');
      final product = ProductRecord.getDocumentFromData(
        {
          'name': 'Hand Bouquet',
          'recipeLines': [
            {
              'materialRef': materialRef,
              'materialName': 'Red Rose',
              'qty': 12,
              'unit': 'stem',
            },
          ],
        },
        ProductRecord.collection.doc('bouquet'),
      );

      final parsed = parseProductRecipeLines(product);
      expect(parsed, hasLength(1));
      expect(parsed.first.materialName, 'Red Rose');
      expect(parsed.first.qty, 12);

      final saved = productRecipeLinesToFirestore(parsed);
      expect(saved, hasLength(1));
      expect(saved.first['materialName'], 'Red Rose');
    });

    test('formatProductRecipeLine includes unit', () {
      final line = ProductRecipeLine(
        materialRef: MaterialRecord.collection.doc('wrap'),
        materialName: 'Wrapper',
        qty: 2,
        unit: 'sheet',
      );
      expect(formatProductRecipeLine(line), '2 sheet Wrapper');
    });
  });
}
