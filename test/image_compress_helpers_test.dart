import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:tfg_vday/backend/image_compress_helpers.dart';

void main() {
  test('compressImageBytesForUpload leaves small images unchanged', () async {
    final image = img.Image(width: 200, height: 200);
    img.fill(image, color: img.ColorRgb8(120, 80, 200));
    final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 90));

    expect(bytes.length, lessThan(maxUploadImageBytes));

    final result = await compressImageBytesForUpload(bytes);
    expect(result, same(bytes));
  });

  test('compressImageBytesForUpload shrinks large photos under limit', () async {
    final image = img.Image(width: 4000, height: 4000);
    for (var y = 0; y < image.height; y += 20) {
      for (var x = 0; x < image.width; x += 20) {
        img.drawPixel(
          image,
          x,
          y,
          img.ColorRgb8((x * 17) % 255, (y * 31) % 255, ((x + y) * 13) % 255),
        );
      }
    }
    final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 100));
    const testLimit = 400 * 1024;

    expect(bytes.length, greaterThan(testLimit));

    final result = await compressImageBytesForUpload(
      bytes,
      maxBytes: testLimit,
    );
    expect(result.length, lessThanOrEqualTo(testLimit));
    expect(looksLikeImageBytes(result), isTrue);
  });

  test('compressImageBytesForUpload returns non-image bytes unchanged', () async {
    final bytes = Uint8List.fromList(List<int>.filled(6 * 1024 * 1024, 7));
    final result = await compressImageBytesForUpload(bytes);
    expect(result, same(bytes));
  });
}
