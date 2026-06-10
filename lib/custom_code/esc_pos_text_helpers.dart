import 'dart:convert';

import 'package:charset_converter/charset_converter.dart';

/// 58mm thermal paper (~32 Latin columns; CJK counts double).
const escPosLineWidth = 32;

/// ESC/POS: enable simplified Chinese (GBK / GB18030) on common printers.
const escPosEnableChinese = <int>[0x1C, 0x26, 0x1B, 0x74, 0x0F];

/// Display width on receipt (CJK = 2 columns).
int escPosDisplayWidth(String text) {
  var width = 0;
  for (final codeUnit in text.runes) {
    width += codeUnit <= 0x7F ? 1 : 2;
  }
  return width;
}

String escPosTruncate(String text, int maxWidth) {
  if (maxWidth <= 0) {
    return '';
  }
  final buffer = StringBuffer();
  var width = 0;
  for (final rune in text.runes) {
    final charWidth = rune <= 0x7F ? 1 : 2;
    if (width + charWidth > maxWidth) {
      break;
    }
    buffer.writeCharCode(rune);
    width += charWidth;
  }
  return buffer.toString();
}

String escPosTwoColumn(
  String left,
  String right, {
  int width = escPosLineWidth,
}) {
  final rightText = escPosTruncate(right, 12);
  final leftMax = width - escPosDisplayWidth(rightText) - 1;
  final leftText = escPosTruncate(left, leftMax.clamp(0, width));
  final pad = width - escPosDisplayWidth(leftText) - escPosDisplayWidth(rightText);
  if (pad < 1) {
    return leftText;
  }
  return '$leftText${' ' * pad}$rightText';
}

List<String> escPosWrapLines(String text, {int width = escPosLineWidth}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return const [];
  }
  final lines = <String>[];
  final buffer = StringBuffer();
  var lineWidth = 0;

  void flush() {
    if (buffer.isEmpty) {
      return;
    }
    lines.add(buffer.toString());
    buffer.clear();
    lineWidth = 0;
  }

  for (final rune in trimmed.runes) {
    final char = String.fromCharCode(rune);
    final charWidth = rune <= 0x7F ? 1 : 2;
    if (lineWidth + charWidth > width) {
      flush();
    }
    buffer.write(char);
    lineWidth += charWidth;
  }
  flush();
  return lines;
}

Future<List<int>> encodeEscPosText(String text) async {
  if (text.isEmpty) {
    return const [];
  }
  for (final charset in ['GB18030', 'GBK', 'GB2312']) {
    try {
      final encoded = await CharsetConverter.encode(charset, text);
      if (encoded != null && encoded.isNotEmpty) {
        return encoded;
      }
    } catch (_) {
      // Try next charset.
    }
  }
  return utf8.encode(text);
}
