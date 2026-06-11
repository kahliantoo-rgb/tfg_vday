import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:tfg_vday/custom_code/thermal_logo_helpers.dart';

void main() {
  test('prepareCompanyLogoForThermal pads width to multiple of 8', () {
    final source = img.Image(width: 100, height: 40);
    img.fill(source, color: img.ColorRgb8(0, 0, 0));
    final prepared = prepareCompanyLogoForThermal(
      source,
      dotsPerLine: 384,
    );
    expect(prepared.width % 8, 0);
    expect(prepared.width, 384);
    expect(
      prepared.height,
      greaterThanOrEqualTo(thermalLogoMinHeightDots(384)),
    );
  });

  test('encodeEscPosRasterImage returns ESC/POS raster header', () {
    final image = img.Image(width: 384, height: 32);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final raster = encodeEscPosRasterImage(image);
    expect(raster.length, greaterThan(8));
    expect(raster[0], 0x1D);
    expect(raster[1], 0x76);
    expect(raster[2], 0x30);
  });

  test('thermalInkLevel detects pastel brand colours on white', () {
    img.Pixel pixel(int r, int g, int b) {
      final image = img.Image(width: 1, height: 1);
      image.setPixelRgb(0, 0, r, g, b);
      return image.getPixel(0, 0);
    }

    expect(thermalInkLevel(pixel(122, 154, 126)), greaterThan(0.3));
    expect(thermalInkLevel(pixel(232, 160, 150)), greaterThan(0.3));
    expect(thermalInkLevel(pixel(255, 255, 255)), lessThan(0.12));
    expect(thermalInkLevel(pixel(40, 40, 40)), greaterThan(0.65));
  });

  test('encodeEscPosRasterImage sets MSB for left black column', () {
    final image = img.Image(width: 8, height: 8);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    for (var y = 0; y < 8; y++) {
      image.setPixelRgb(0, y, 0, 0, 0);
    }
    final raster = encodeEscPosRasterImage(image);
    expect(raster[8], 0x80);
  });

}
