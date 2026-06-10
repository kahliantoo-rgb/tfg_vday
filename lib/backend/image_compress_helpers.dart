import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Maximum upload size for photos (Firebase Storage / mobile bandwidth).
const int maxUploadImageBytes = 5 * 1024 * 1024;

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
