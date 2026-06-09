import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/product_category_helpers.dart';

void main() {
  group('normalizeProductCategoryList', () {
    test('trims deduplicates and sorts', () {
      expect(
        normalizeProductCategoryList([
          '  Wreath ',
          'hand bouquet',
          'Hand Bouquet',
          '',
        ]),
        ['hand bouquet', 'Wreath'],
      );
    });
  });

  group('mergeProductCategoryOptions', () {
    test('merges managed and product categories', () {
      expect(
        mergeProductCategoryOptions(
          managedCategories: ['Hand Bouquet', 'Wreath'],
          productCategories: ['Legacy Category', 'Hand Bouquet'],
        ),
        ['Hand Bouquet', 'Legacy Category', 'Wreath'],
      );
    });
  });
}
