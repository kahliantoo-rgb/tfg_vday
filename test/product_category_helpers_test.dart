import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/product_category_helpers.dart';
import 'package:tfg_vday/backend/tenant_company_helpers.dart';

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

  group('parseProductCategoriesFromData', () {
    test('returns empty when doc is missing', () {
      expect(parseProductCategoriesFromData(null), isEmpty);
    });

    test('parses stored categories', () {
      expect(
        parseProductCategoriesFromData({
          'categories': ['Funerals', 'Hand Bouquet'],
        }),
        ['Funerals', 'Hand Bouquet'],
      );
    });
  });

  group('defaultCategoriesForCompanyId', () {
    test('uses The Flower Guy defaults for canonical company', () {
      expect(
        defaultCategoriesForCompanyId(kCanonicalCompanyId),
        theFlowerGuyProductCategories,
      );
    });

    test('uses generic defaults for other companies', () {
      expect(
        defaultCategoriesForCompanyId('other_company_id'),
        defaultProductCategories,
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
