import 'dart:convert';

import 'package:charset_converter/charset_converter.dart';

import '/custom_code/thermal_paper_helpers.dart';

/// Thermal paper line width (32 for 58mm, 48 for 80mm; CJK counts double).
int escPosLineWidthChars() => thermalPaperLineWidth();

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
  int? width,
}) {
  final lineWidth = width ?? escPosLineWidthChars();
  final rightText = escPosTruncate(right, 12);
  final leftMax = lineWidth - escPosDisplayWidth(rightText) - 1;
  final leftText = escPosTruncate(left, leftMax.clamp(0, lineWidth));
  final pad =
      lineWidth - escPosDisplayWidth(leftText) - escPosDisplayWidth(rightText);
  if (pad < 1) {
    return leftText;
  }
  return '$leftText${' ' * pad}$rightText';
}

List<String> escPosWrapLines(String text, {int? width}) {
  final maxWidth = width ?? escPosLineWidthChars();
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return const [];
  }
  final lines = <String>[];
  final buffer = StringBuffer();
  var currentWidth = 0;

  void flush() {
    if (buffer.isEmpty) {
      return;
    }
    lines.add(buffer.toString());
    buffer.clear();
    currentWidth = 0;
  }

  for (final rune in trimmed.runes) {
    final char = String.fromCharCode(rune);
    final charWidth = rune <= 0x7F ? 1 : 2;
    if (currentWidth + charWidth > maxWidth) {
      flush();
    }
    buffer.write(char);
    currentWidth += charWidth;
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
