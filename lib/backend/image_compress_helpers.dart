import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Maximum upload size for photos (Firebase Storage / mobile bandwidth).
const int maxUploadImageBytes = 2 * 1024 * 1024;

/// Stored logo long edge — 2× 80mm thermal width for sharp receipt printing.
const int kCompanyLogoMinLongEdgePx = 1152;

/// Flatten transparent PNG/JPEG edges onto white (avoids gray halos on thermal).
img.Image bakeImageOnWhite(img.Image source) {
  final out = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final alpha = pixel.a / 255.0;
      final r = (pixel.r * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
      final g = (pixel.g * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
      final b = (pixel.b * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
      out.setPixelRgb(x, y, r, g, b);
    }
  }
  return out;
}

/// Returns [bytes] unchanged when already within [maxUploadImageBytes].
/// Otherwise re-encodes as JPEG, lowering quality and size until under the limit.
Future<Uint8List> compressImageBytesForUpload(
  Uint8List bytes, {
  int maxBytes = maxUploadImageBytes,
}) async {
  if (bytes.length <= maxBytes) {
    return bytes;
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  var image = decoded;
  var quality = 85;

  while (true) {
    final encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    if (encoded.length <= maxBytes) {
      return encoded;
    }

    if (quality > 35) {
      quality -= 10;
      continue;
    }

    final nextWidth = (image.width * 0.85).round();
    final nextHeight = (image.height * 0.85).round();
    if (nextWidth < 320 || nextHeight < 320) {
      return encoded;
    }

    image = img.copyResize(image, width: nextWidth, height: nextHeight);
    quality = 85;
  }
}

/// Upscale small logos before upload; prefer PNG to avoid JPEG edge blur.
Future<Uint8List> prepareCompanyLogoBytesForUpload(Uint8List bytes) async {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return bytes;
  }

  var image = bakeImageOnWhite(decoded);
  final longEdge = math.max(image.width, image.height);
  if (longEdge < kCompanyLogoMinLongEdgePx) {
    final scale = kCompanyLogoMinLongEdgePx / longEdge;
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.cubic,
    );
  }

  final png = Uint8List.fromList(img.encodePng(image));
  if (png.length <= maxUploadImageBytes) {
    return png;
  }

  return compressImageBytesForUpload(
    Uint8List.fromList(img.encodeJpg(image, quality: 92)),
    maxBytes: maxUploadImageBytes,
  );
}

bool looksLikeImageBytes(Uint8List bytes) {
  if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return true;
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return true;
  }
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46) {
    return true;
  }
  return false;
}
