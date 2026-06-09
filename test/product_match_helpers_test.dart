import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_whatsapp_import_helpers.dart';
import 'package:tfg_vday/backend/product_match_helpers.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';

import 'firebase_test_setup.dart';

ProductRecord _product(String name, {double price = 10}) {
  return ProductRecord.getDocumentFromData(
    {
      'name': name,
      'price': price,
      'isActive': true,
      'sku': 'SKU',
    },
    FirebaseFirestore.instance.collection('product').doc(name),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);
  group('parseProductQtyFromHint', () {
    test('defaults to 1 when only product spec count is present', () {
      expect(parseProductQtyFromHint('6支的'), 1);
      expect(parseProductQtyFromHint('3支粉玫瑰手花'), 1);
      expect(parseProductQtyFromHint('3 stalk rose bouquet'), 1);
      expect(parseProductQtyFromHint('3朵玫瑰'), 1);
    });

    test('reads explicit order multiplier only with *3 x3 or ×3', () {
      expect(parseProductQtyFromHint('3 stalks rose *3'), 3);
      expect(parseProductQtyFromHint('3 stalk rose x3'), 3);
      expect(parseProductQtyFromHint('粉玫瑰手花×3'), 3);
    });
  });

  group('stripOrderQtyMultiplier', () {
    test('removes multiplier before product matching', () {
      expect(stripOrderQtyMultiplier('3 stalk rose x3'), '3 stalk rose');
    });
  });

  group('findBestProductMatch', () {
    test('matches product name inside WhatsApp hint', () {
      final match = findBestProductMatch(
        [
          _product('Rose Bouquet'),
          _product('粉玫瑰手花', price: 45),
        ],
        '3支粉玫瑰手花',
      );
      expect(match?.name, '粉玫瑰手花');
    });

    test('matches Chinese catalog name from mixed English and Chinese hint', () {
      final match = findBestProductMatch(
        [
          _product('Rose Bouquet'),
          _product('3朵玫瑰', price: 38),
        ],
        '3 stalk rose bouquet 3朵玫瑰',
      );
      expect(match?.name, '3朵玫瑰');
    });

    test('matches 3朵玫瑰 from English-only stalk hint', () {
      final match = findBestProductMatch(
        [
          _product('Single Rose'),
          _product('3朵玫瑰', price: 38),
        ],
        '3 stalk rose bouquet',
      );
      expect(match?.name, '3朵玫瑰');
    });
  });

  group('shouldAddWhatsAppDeliveryFee', () {
    test('adds fee for delivery orders under 200', () {
      expect(
        shouldAddWhatsAppDeliveryFee(
          orderType: 'Delivery',
          merchandiseSubtotal: 160,
        ),
        isTrue,
      );
      expect(
        shouldAddWhatsAppDeliveryFee(
          orderType: 'Delivery',
          merchandiseSubtotal: 200,
        ),
        isFalse,
      );
      expect(
        shouldAddWhatsAppDeliveryFee(
          orderType: 'PickUp',
          merchandiseSubtotal: 160,
        ),
        isFalse,
      );
    });
  });
}
