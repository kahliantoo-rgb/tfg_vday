import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/material_category_helpers.dart';
import 'package:tfg_vday/backend/tenant_company_helpers.dart';

void main() {
  group('normalizeMaterialCategoryList', () {
    test('trims deduplicates and sorts', () {
      expect(
        normalizeMaterialCategoryList([
          '  Foliage ',
          'fresh flowers',
          'Fresh Flowers',
          '',
        ]),
        ['Foliage', 'fresh flowers'],
      );
    });
  });

  group('parseMaterialCategoriesFromData', () {
    test('returns empty when doc is missing', () {
      expect(parseMaterialCategoriesFromData(null), isEmpty);
    });

    test('parses stored categories', () {
      expect(
        parseMaterialCategoriesFromData({
          'categories': ['Packaging', 'Fresh Flowers'],
        }),
        ['Fresh Flowers', 'Packaging'],
      );
    });
  });

  group('defaultMaterialCategoriesForCompanyId', () {
    test('uses The Flower Guy defaults for canonical company', () {
      expect(
        defaultMaterialCategoriesForCompanyId(kCanonicalCompanyId),
        theFlowerGuyMaterialCategories,
      );
    });

    test('uses generic defaults for other companies', () {
      expect(
        defaultMaterialCategoriesForCompanyId('other_company_id'),
        defaultMaterialCategories,
      );
    });
  });

  group('mergeMaterialCategoryOptions', () {
    test('merges managed and material categories', () {
      expect(
        mergeMaterialCategoryOptions(
          managedCategories: ['Fresh Flowers', 'Foliage'],
          materialCategories: ['Legacy Category', 'Fresh Flowers'],
        ),
        ['Foliage', 'Fresh Flowers', 'Legacy Category'],
      );
    });
  });
}
