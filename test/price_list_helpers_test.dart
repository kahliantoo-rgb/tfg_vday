import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/price_list_helpers.dart';
import 'package:tfg_vday/backend/price_list_import_helpers.dart';
import 'package:tfg_vday/backend/schema/price_lists_record.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);

  group('lookupContractPrice', () {
    test('matches by SKU case-insensitively', () {
      final productRef =
          FirebaseFirestore.instance.collection('product').doc('p1');
      final list = PriceListsRecord.getDocumentFromData(
        {
          'name': 'Hotel A',
          'price_lines': [
            {'sku': 'fl01', 'price': 180.0},
          ],
        },
        FirebaseFirestore.instance.collection('price_lists').doc('l1'),
      );
      final product = ProductRecord.getDocumentFromData(
        {'name': 'Bouquet', 'sku': 'FL01', 'price': 200},
        productRef,
      );

      expect(
        lookupContractPrice(priceList: list, product: product),
        180,
      );
    });
  });

  group('mergePriceListLinesBySku', () {
    test('incoming rows replace same SKU', () {
      final merged = mergePriceListLinesBySku(
        existing: const [
          PriceListLine(sku: 'FL01', price: 180),
        ],
        incoming: const [
          PriceListLine(sku: 'fl01', price: 190),
        ],
      );
      expect(merged, hasLength(1));
      expect(merged.first.price, 190);
    });
  });

  group('parsePriceListImportFile', () {
    test('parses CSV template rows', () {
      final result = parsePriceListImportFile(
        bytes: priceListImportTemplateBytes(),
        filename: 'price_list_import_template.csv',
      );
      expect(result.validCount, 3);
      expect(result.rows.first.sku, 'FL01');
      expect(result.rows.first.price, 180);
    });
  });
}
