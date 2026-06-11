import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '/backend/image_compress_helpers.dart';
import '/custom_code/thermal_paper_helpers.dart';

int thermalLogoMinHeightDots(int dotsPerLine) =>
    (dotsPerLine * 0.35).round();

double _colorByte(num value) {
  final v = value.toDouble();
  if (v <= 1.0) {
    return v * 255.0;
  }
  return v;
}

/// Ink level for thermal: 0 = paper white, 1 = print black.
/// Uses color distance so pastel greens/pinks (brand logos) still print.
double thermalInkLevel(img.Pixel pixel) {
  final r = _colorByte(pixel.r);
  final g = _colorByte(pixel.g);
  final b = _colorByte(pixel.b);

  final lum = (255.0 - img.getLuminance(pixel)) / 255.0;

  final dr = (255 - r) / 255.0;
  final dg = (255 - g) / 255.0;
  final db = (255 - b) / 255.0;
  final distFromWhite =
      math.sqrt(dr * dr + dg * dg + db * db) / math.sqrt(3);

  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  final chroma = (maxC - minC) / 255.0;

  final greenness = ((g - math.min(r, b)) / 255.0).clamp(0.0, 1.0);
  final redness = ((r - g) / 255.0).clamp(0.0, 1.0);

  var ink = lum * 0.45 +
      distFromWhite * 0.35 +
      chroma * 0.2 +
      greenness * 0.28 +
      redness * 0.22;
  return ink.clamp(0.0, 1.0);
}

/// Prepare a company logo for sharp monochrome thermal output.
/// Original color logo in Firebase/PDF is unchanged — conversion is print-only.
img.Image prepareCompanyLogoForThermal(
  img.Image source, {
  int? dotsPerLine,
}) {
  final targetWidth = dotsPerLine ?? thermalPaperDotsPerLine();
  final minHeight = thermalLogoMinHeightDots(targetWidth);

  var image = bakeImageOnWhite(source);

  if (image.width > targetWidth) {
    image = img.copyResize(
      image,
      width: targetWidth,
      maintainAspect: true,
      backgroundColor: img.ColorRgb8(255, 255, 255),
      interpolation: img.Interpolation.cubic,
    );
  } else if (image.width < targetWidth) {
    final upscaleWidth = math.min(targetWidth, image.width * 2);
    image = img.copyResize(
      image,
      width: upscaleWidth,
      maintainAspect: true,
      backgroundColor: img.ColorRgb8(255, 255, 255),
      interpolation: img.Interpolation.cubic,
    );
    if (image.width < targetWidth) {
      image = img.copyResize(
        image,
        width: targetWidth,
        maintainAspect: true,
        backgroundColor: img.ColorRgb8(255, 255, 255),
        interpolation: img.Interpolation.cubic,
      );
    }
  }

  if (image.height < minHeight) {
    final scale = minHeight / image.height;
    final scaledWidth = (image.width * scale).round();
    if (scaledWidth <= targetWidth) {
      image = img.copyResize(
        image,
        width: scaledWidth,
        height: minHeight,
        interpolation: img.Interpolation.cubic,
      );
      if (scaledWidth < targetWidth) {
        final centered = img.Image(width: targetWidth, height: minHeight);
        img.fill(centered, color: img.ColorRgb8(255, 255, 255));
        img.compositeImage(
          centered,
          image,
          dstX: (targetWidth - scaledWidth) ~/ 2,
        );
        image = centered;
      }
    }
  }

  image = _floydSteinbergDitherColorAware(image);

  final paddedWidth = ((image.width + 7) ~/ 8) * 8;
  if (paddedWidth != image.width) {
    final padded = img.Image(width: paddedWidth, height: image.height);
    img.fill(padded, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(padded, image);
    image = padded;
  }

  return image;
}

img.Image _floydSteinbergDitherColorAware(img.Image image) {
  final width = image.width;
  final height = image.height;
  final levels = List.generate(
    height,
    (_) => List<double>.filled(width, 0),
  );

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      levels[y][x] = thermalInkLevel(image.getPixel(x, y));
    }
  }

  const threshold = 0.46;

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final old = levels[y][x].clamp(0.0, 1.0);
      final value = old >= threshold ? 0 : 255;
      final newLevel = value == 0 ? 1.0 : 0.0;
      levels[y][x] = newLevel;
      image.setPixelRgb(x, y, value, value, value);

      final error = old - newLevel;
      if (x + 1 < width) {
        levels[y][x + 1] += error * 7 / 16;
      }
      if (y + 1 < height) {
        if (x > 0) {
          levels[y + 1][x - 1] += error * 3 / 16;
        }
        levels[y + 1][x] += error * 5 / 16;
        if (x + 1 < width) {
          levels[y + 1][x + 1] += error * 1 / 16;
        }
      }
    }
  }

  return image;
}

/// ESC/POS raster bit image (GS v 0) — avoids JPEG re-encoding in Generator.
List<int> encodeEscPosRasterImage(img.Image image) {
  final raster = _toEscPosRasterData(image);
  final widthBytes = image.width ~/ 8;
  return <int>[
    0x1D,
    0x76,
    0x30,
    0x00,
    ..._intLowHigh(widthBytes, 2),
    ..._intLowHigh(image.height, 2),
    ...raster,
  ];
}

List<int> _intLowHigh(int value, int bytesNb) {
  final result = <int>[];
  var buf = value;
  for (var i = 0; i < bytesNb; i++) {
    result.add(buf % 256);
    buf = buf ~/ 256;
  }
  return result;
}

List<int> _toEscPosRasterData(img.Image src) {
  final widthPx = src.width;
  final heightPx = src.height;
  final widthBytes = widthPx ~/ 8;
  final result = <int>[];

  for (var y = 0; y < heightPx; y++) {
    for (var byteCol = 0; byteCol < widthBytes; byteCol++) {
      var byte = 0;
      for (var bit = 0; bit < 8; bit++) {
        final x = byteCol * 8 + bit;
        final lum = img.getLuminance(src.getPixel(x, y)) / 255.0;
        if (lum < 0.5) {
          byte |= 1 << (7 - bit);
        }
      }
      result.add(byte);
    }
  }

  return result;
}
