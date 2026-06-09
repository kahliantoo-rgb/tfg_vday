import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/product_edit_helpers.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';

import 'firebase_test_setup.dart';

ProductRecord _product(Map<String, dynamic> data) {
  return ProductRecord.getDocumentFromData(
    data,
    FirebaseFirestore.instance.collection('product').doc('test'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  group('coerceProductImageUrl', () {
    test('returns trimmed http URL from string', () {
      expect(
        coerceProductImageUrl('  https://example.com/a.jpg  '),
        'https://example.com/a.jpg',
      );
    });

    test('extracts url from legacy FlutterFlow map', () {
      expect(
        coerceProductImageUrl({
          'blurHash': 'abc',
          'path': 'https://firebasestorage.googleapis.com/v0/b/x/o/y?alt=media',
        }),
        'https://firebasestorage.googleapis.com/v0/b/x/o/y?alt=media',
      );
    });

    test('returns null for empty values', () {
      expect(coerceProductImageUrl(''), isNull);
      expect(coerceProductImageUrl(null), isNull);
      expect(coerceProductImageUrl({}), isNull);
    });
  });

  group('productImageFromRecord', () {
    test('prefers lowercase image field', () {
      final product = _product({
        'image': 'https://example.com/primary.jpg',
        'Image': 'https://example.com/legacy.jpg',
      });
      expect(productImageFromRecord(product), 'https://example.com/primary.jpg');
    });

    test('falls back to legacy Image string', () {
      final product = _product({
        'Image': 'https://example.com/legacy.jpg',
      });
      expect(productImageFromRecord(product), 'https://example.com/legacy.jpg');
    });

    test('falls back to legacy Image map path', () {
      final product = _product({
        'Image': {
          'path': 'https://example.com/map.jpg',
        },
      });
      expect(productImageFromRecord(product), 'https://example.com/map.jpg');
    });
  });

  group('isUsableImageUrl', () {
    test('accepts http(s) and gs URLs', () {
      expect(isUsableImageUrl('https://a.b/c'), isTrue);
      expect(isUsableImageUrl('gs://bucket/path'), isTrue);
    });

    test('rejects empty and bare filenames', () {
      expect(isUsableImageUrl(''), isFalse);
      expect(isUsableImageUrl('photo.jpg'), isFalse);
    });

    test('accepts relative storage paths', () {
      expect(
        isUsableImageUrl('product_images/abc123/rose.jpg'),
        isTrue,
      );
    });
  });

  group('isValidFirebaseStorageDownloadUrl', () {
    test('accepts well-formed Firebase download URLs', () {
      expect(
        isValidFirebaseStorageDownloadUrl(
          'https://firebasestorage.googleapis.com/v0/b/tfg-sales-record.firebasestorage.app/o/product_images%2Fabc%2Frose.jpg?alt=media&token=xyz',
        ),
        isTrue,
      );
    });

    test('rejects corrupted URLs missing query separator', () {
      expect(
        isValidFirebaseStorageDownloadUrl(
          'https://firebasestorage.googleapis.com/v0/b/tfg-sales-record.firebasestorage.app/o/product_images%2FAytOOm5h5galt=media&token=54615822-779c-4a20-8f33-19f41a52d569',
        ),
        isFalse,
      );
    });
  });

  group('repairFirebaseStorageDownloadUrl', () {
    test('inserts missing question mark before alt=media', () {
      expect(
        repairFirebaseStorageDownloadUrl(
          'https://firebasestorage.googleapis.com/v0/b/x/o/product_images%2Fid%2Fphoto.jpgalt=media&token=t',
        ),
        'https://firebasestorage.googleapis.com/v0/b/x/o/product_images%2Fid%2Fphoto.jpg?alt=media&token=t',
      );
    });
  });

  group('productImageStoragePath', () {
    test('scopes uploads under product id', () {
      expect(
        productImageStoragePath('abc123', 'rose.png'),
        'product_images/abc123/rose.png',
      );
    });
  });
}
