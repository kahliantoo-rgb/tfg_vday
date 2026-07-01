import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/order_id_service.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';

/// Default delivery window when WhatsApp text has no time slot.
const defaultWhatsAppDeliveryTimeSlot = '09:00-20:00';

String resolveWhatsAppDeliveryTimeSlot(String? detected) {
  final trimmed = detected?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return defaultWhatsAppDeliveryTimeSlot;
  }
  return trimmed;
}

/// Paste-from-WhatsApp order import (staging and production).
const bool isWhatsAppOrderImportEnabled = true;

/// Normalizes WhatsApp paste text (BOM, fullwidth $, Chinese colons, line breaks).
String normalizeWhatsAppPasteText(String text) {
  return text
      .replaceAll('\uFEFF', '')
      .replaceAll('\u200B', '')
      .replaceAll('\u200C', '')
      .replaceAll('\u200D', '')
      .replaceAll('\u00A0', ' ')
      .replaceAll('＄', r'$')
      .replaceAll(RegExp(r'[：﹕]'), ':')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
}

/// Default order type when WhatsApp text does not indicate pickup/delivery.
const whatsAppImportOrderType = 'Delivery';

String resolveWhatsAppImportOrderType(String? parsedOrderType) {
  final trimmed = parsedOrderType?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return whatsAppImportOrderType;
  }
  return trimmed;
}

/// Parsed fields from a WhatsApp order message (confirmation or staff notes).
class WhatsAppParsedOrderDetails {
  const WhatsAppParsedOrderDetails({
    this.orderId,
    this.clientName,
    this.recipientName,
    this.phone,
    this.address,
    this.postalCode,
    this.region,
    this.deliveryTimeSlot,
    this.cardMessage,
    this.deliveryDate,
    this.orderType,
    this.productHint,
    this.productPrice,
    this.needsReferencePhoto = false,
  });

  final String? orderId;
  final String? clientName;
  final String? recipientName;
  final String? phone;
  final String? address;
  final String? postalCode;
  final String? region;
  final String? deliveryTimeSlot;
  final String? cardMessage;
  final DateTime? deliveryDate;
  final String? orderType;
  final String? productHint;
  final double? productPrice;
  final bool needsReferencePhoto;

  bool get hasFormFields =>
      clientName != null ||
      recipientName != null ||
      phone != null ||
      address != null ||
      postalCode != null ||
      region != null ||
      deliveryTimeSlot != null ||
      cardMessage != null ||
      deliveryDate != null ||
      orderType != null ||
      productHint != null;
}

final _orderIdPatterns = [
  RegExp(
    r'order\s*id\s*[:\-]\s*(TFG[^\s,\n]+)',
    caseSensitive: false,
  ),
  RegExp(r'\b(TFG-[A-Z]{3}\d{2}-WI000\d+)\b'),
  RegExp(r'\b(TFG-[A-Z]{3}\d{2}-000\d+)\b'),
  RegExp(r'\b(TFG-\d{4}-\d+)\b'),
];

String? extractOrderIdFromWhatsAppText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  for (final pattern in _orderIdPatterns) {
    final match = pattern.firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!.trim();
    }
  }
  return null;
}

String _normalizeLabel(String label) => label.trim().toLowerCase();

DateTime? _parseLooseDate(String raw) {
  final value = raw.trim();
  final patterns = [
    RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})$'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(value);
    if (match == null) {
      continue;
    }
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    var year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) {
      continue;
    }
    if (year < 100) {
      year += 2000;
    }
    return DateTime(year, month, day);
  }
  return null;
}

const _monthAbbrev = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

DateTime? _parseDayMonthSlashDate(String text, DateTime referenceDate) {
  final match = RegExp(
    r'\b(\d{1,2})[/.](\d{1,2})(?:[/.](\d{2,4}))?\b',
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  if (day == null || month == null) {
    return null;
  }
  var year = int.tryParse(match.group(3) ?? '');
  year ??= referenceDate.year;
  if (year < 100) {
    year += 2000;
  }
  var candidate = DateTime(year, month, day);
  if (match.group(3) == null &&
      candidate.isBefore(referenceDate.subtract(const Duration(days: 60)))) {
    candidate = DateTime(year + 1, month, day);
  }
  return candidate;
}

DateTime? _parseDayMonthAbbrevDate(String text) {
  final match = RegExp(
    r'\b(\d{1,2})\s*([A-Za-z]{3})\b',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  final day = int.tryParse(match.group(1)!);
  if (day == null) {
    return null;
  }
  final month = _monthAbbrev[match.group(2)!.toLowerCase().substring(0, 3)];
  if (month == null) {
    return null;
  }
  final now = DateTime.now();
  var year = now.year;
  var candidate = DateTime(year, month, day);
  if (candidate.isBefore(now.subtract(const Duration(days: 60)))) {
    candidate = DateTime(year + 1, month, day);
  }
  return candidate;
}

int? _chineseWeekdayNumber(String char) {
  const map = {
    '一': DateTime.monday,
    '二': DateTime.tuesday,
    '三': DateTime.wednesday,
    '四': DateTime.thursday,
    '五': DateTime.friday,
    '六': DateTime.saturday,
    '日': DateTime.sunday,
    '天': DateTime.sunday,
  };
  return map[char];
}

DateTime _nextWeekdayOnOrAfter(DateTime referenceDate, int weekday) {
  final from = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );
  var delta = weekday - from.weekday;
  if (delta < 0) {
    delta += 7;
  }
  return from.add(Duration(days: delta));
}

DateTime? _parseChineseRelativeDate(String text, DateTime referenceDate) {
  final today = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );
  if (text.contains('明天')) {
    return today.add(const Duration(days: 1));
  }
  if (text.contains('后天')) {
    return today.add(const Duration(days: 2));
  }
  if (text.contains('今天')) {
    return today;
  }

  final weekdayMatch = RegExp(r'拜([一二三四五六日天])|星期([一二三四五六日天])')
      .firstMatch(text);
  if (weekdayMatch != null) {
    final char = weekdayMatch.group(1) ?? weekdayMatch.group(2)!;
    final weekday = _chineseWeekdayNumber(char);
    if (weekday != null) {
      return _nextWeekdayOnOrAfter(referenceDate, weekday);
    }
  }
  return null;
}

String? _parseChineseTimeSlot(String text) {
  if (RegExp(r'两点前').hasMatch(text)) {
    return 'Before 2pm';
  }
  final pmMatch =
      RegExp(r'(\d{1,2})\s*pm', caseSensitive: false).firstMatch(text);
  if (pmMatch != null) {
    return '${pmMatch.group(1)}pm';
  }
  final amMatch =
      RegExp(r'(\d{1,2})\s*am', caseSensitive: false).firstMatch(text);
  if (amMatch != null) {
    return '${amMatch.group(1)}am';
  }
  return null;
}

String? _parseTimeRange(String text) {
  final patterns = [
    RegExp(
      r'(\d{1,2}\s*(?:am|pm))\s*-\s*(\d{1,2}\s*(?:am|pm))',
      caseSensitive: false,
    ),
    RegExp(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return '${match.group(1)!.trim()}-${match.group(2)!.trim()}';
    }
  }
  return null;
}

final _addressLinePattern = RegExp(
  r'^(?:blk\.?|block)\s*\d+|^\#\d|\d+\s+\w+\s+(?:street|st\.?|road|rd\.?|avenue|ave\.?|drive|dr\.?|lane|way|close|crescent|place)\b',
  caseSensitive: false,
);

String? _parseFreeFormAddress(List<String> lines) {
  for (final line in lines) {
    final cleaned = line.replaceAll(RegExp(r'@\s*$'), '').trim();
    if (_addressLinePattern.hasMatch(cleaned)) {
      return cleaned;
    }
  }
  for (var i = 0; i < lines.length - 1; i++) {
    if (lines[i].endsWith('@')) {
      final next = lines[i + 1].trim();
      if (next.isNotEmpty) {
        return next;
      }
    }
  }
  return null;
}

String? _parseWsClientName(List<String> lines) {
  for (final line in lines.reversed) {
    final match =
        RegExp(r'^ws[-\s]+(.+)$', caseSensitive: false).firstMatch(line);
    if (match != null) {
      return match.group(1)!.trim();
    }
  }
  return null;
}

String? _parseTfgCarouselClientName(List<String> lines) {
  for (final line in lines.reversed) {
    final match = RegExp(
      r'^([a-zA-Z][a-zA-Z0-9_]*)\s+TFG\b',
      caseSensitive: false,
    ).firstMatch(line);
    if (match != null) {
      return match.group(1)!.trim();
    }
  }
  return null;
}

bool _isClientIdentificationLine(String line) {
  if (RegExp(r'^ws[-\s]+', caseSensitive: false).hasMatch(line)) {
    return true;
  }
  return RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*\s+TFG\b',
    caseSensitive: false,
  ).hasMatch(line);
}

String? _parsePostalCode(String text) {
  final patterns = [
    RegExp(r'\bS?(\d{6})\b'),
    RegExp(r'\bs?\((\d{6})\)', caseSensitive: false),
    RegExp(r'\bSingapore\s*(\d{6})\b', caseSensitive: false),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

bool _needsReferencePhoto(String text) {
  return RegExp(r'如图|參考图|参考图|see photo|as shown', caseSensitive: false)
      .hasMatch(text);
}

double? _parseProductPrice(String text) {
  final patterns = [
    RegExp(r'[$＄]\s*(\d+(?:\.\d+)?)'),
    RegExp(r'(?:^|\s)(\d+(?:\.\d+)?)\s*手花'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match == null) {
      continue;
    }
    final price = double.tryParse(match.group(1)!);
    if (price != null && price > 0) {
      return price;
    }
  }
  return null;
}

String? _parseProductHint(List<String> lines) {
  for (final line in lines) {
    if (_isClientIdentificationLine(line)) {
      continue;
    }
    if (_isLabeledOrderFieldLine(line)) {
      continue;
    }
    if (_isShopifyReferenceLine(line)) {
      continue;
    }
    if (_addressLinePattern.hasMatch(line.replaceAll(RegExp(r'@\s*$'), ''))) {
      continue;
    }
    final hint = _stripSchedulingFromLine(line);
    if (hint.isNotEmpty) {
      return hint;
    }
  }
  return null;
}

List<String> normalizeWhatsAppLines(String text) {
  return text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
      .toList();
}

String _stripDateTimeFromLine(String line) => _stripSchedulingFromLine(line);

String _stripSchedulingFromLine(String line) {
  var result = line.replaceAll(RegExp(r'@\s*$'), '').trim();
  result = result.replaceFirst(
    RegExp(r'\b\d{1,2}\s*[A-Za-z]{3}\b', caseSensitive: false),
    '',
  );
  result = result.replaceFirst(
    RegExp(r'\b\d{1,2}[/.]\d{1,2}(?:[/.]\d{2,4})?\b'),
    '',
  );
  result = result.replaceFirst(RegExp(r'拜[一二三四五六日天]'), '');
  result = result.replaceFirst(RegExp(r'星期[一二三四五六日天]'), '');
  result = result.replaceFirst(RegExp(r'明天|后天|今天'), '');
  result = result.replaceFirst(RegExp(r'两点前'), '');
  result = result.replaceFirst(
    RegExp(
      r'\d{1,2}(?::\d{2})?\s*(?:am|pm)?\s*-\s*\d{1,2}(?::\d{2})?\s*(?:am|pm)?',
      caseSensitive: false,
    ),
    '',
  );
  result = result.replaceFirst(
    RegExp(r'\d{1,2}\s*(?:am|pm)(?:拿)?', caseSensitive: false),
    '',
  );
  result = result.replaceFirst(RegExp(r'如图|參考图|参考图'), '');
  result = result.replaceFirst(RegExp(r'[拿送]$'), '');
  result = result.replaceAll(RegExp(r'[（(][^）)]*[）)]'), '');
  return result.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isForFromLine(String line) {
  return RegExp(
    r'^For\s+.+,?\s*From\s+',
    caseSensitive: false,
  ).hasMatch(line.trim());
}

String? _parseRecipientFromForLine(List<String> lines) {
  for (final line in lines) {
    final match = RegExp(
      r'^For\s+(.+?),\s*From\s+.+?\s*$',
      caseSensitive: false,
    ).firstMatch(line.trim());
    if (match != null) {
      return match.group(1)!.trim();
    }
  }
  return null;
}

String? _parseCardSenderFromForLine(String line) {
  final match = RegExp(
    r'^For\s+.+?,?\s*From\s+(.+?)\s*$',
    caseSensitive: false,
  ).firstMatch(line.trim());
  if (match == null) {
    return null;
  }
  return 'From ${match.group(1)!.trim()}';
}

bool _isShopifyReferenceLine(String line) {
  return RegExp(r'^\s*shopify\s*#?\s*\d+', caseSensitive: false)
      .hasMatch(line.trim());
}

String? _parseShopifyClientReferenceFromLines(List<String> lines) {
  for (final line in lines) {
    if (!_isShopifyReferenceLine(line)) {
      continue;
    }
    final match = RegExp(
      r'shopify\s*#?\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(line.trim());
    if (match != null) {
      return 'Shopify #${match.group(1)}';
    }
  }
  return null;
}

bool _isLabeledOrderFieldLine(String line) {
  return RegExp(
    r'^\s*(?:address|recipient(?:\s*name)?|(?:customer\s*)?name|customer|client|(?:hp\s*)?(?:phone|contact|mobile)|hp|tel|postal(?:\s*code)?|postcode|region|area|(?:delivery\s*)?time|date|message|note|order\s*type|pickup|delivery)\s*[:\-]\s*',
    caseSensitive: false,
  ).hasMatch(line);
}

String? _sanitizeWhatsAppCardMessage(
  String? raw, {
  String? productHint,
}) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final kept = <String>[];
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    if (_isLabeledOrderFieldLine(trimmed) || _isShopifyReferenceLine(trimmed)) {
      continue;
    }
    if (productHint != null && productHint.isNotEmpty) {
      final stripped = _stripDateTimeFromLine(trimmed);
      if (stripped == productHint.trim() ||
          trimmed.contains(productHint.trim())) {
        continue;
      }
    }
    kept.add(trimmed);
  }
  if (kept.isEmpty) {
    return null;
  }
  return kept.join('\n');
}

String? _buildFreeFormNotes(
  List<String> lines, {
  required String? address,
  required String? clientName,
  String? productHint,
}) {
  final notes = <String>[];
  for (final line in lines) {
    if (line == address) {
      continue;
    }
    if (_isLabeledOrderFieldLine(line) || _isShopifyReferenceLine(line)) {
      continue;
    }
    if (clientName != null &&
        RegExp(r'^ws[-\s]+', caseSensitive: false).hasMatch(line)) {
      continue;
    }
    if (_isClientIdentificationLine(line)) {
      continue;
    }
    if (_isForFromLine(line)) {
      final sender = _parseCardSenderFromForLine(line);
      if (sender != null) {
        notes.add(sender);
      }
      continue;
    }
    if (productHint != null && productHint.isNotEmpty) {
      final stripped = _stripDateTimeFromLine(line);
      if (stripped == productHint.trim() || line.contains(productHint.trim())) {
        continue;
      }
    }
    final note = _stripDateTimeFromLine(line);
    if (note.isNotEmpty) {
      notes.add(note);
    }
  }
  if (notes.isEmpty) {
    return null;
  }
  return notes.join('\n');
}

String _stripParentheticalNotes(String text) {
  return text.replaceAll(RegExp(r'[（(][^）)]*[）)]'), '');
}

String? _sanitizeWhatsAppAddress(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return raw
      .trim()
      .replaceAll(RegExp(r'（[^）]*）'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _extractLabeledBlock(String text, RegExp labelLinePattern) {
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final match = labelLinePattern.firstMatch(lines[i].trim());
    if (match == null) {
      continue;
    }
    final buffer = <String>[];
    final inline = match.group(1)?.trim() ?? '';
    if (inline.isNotEmpty) {
      buffer.add(inline);
    }
    for (var j = i + 1; j < lines.length; j++) {
      final next = lines[j].trim();
      if (next.isEmpty) {
        if (buffer.isNotEmpty && buffer.last.isNotEmpty) {
          buffer.add('');
        }
        continue;
      }
      if (_isLabeledOrderFieldLine(next) ||
          _isClientIdentificationLine(next) ||
          _isShopifyReferenceLine(next)) {
        break;
      }
      buffer.add(next);
    }
    while (buffer.isNotEmpty && buffer.last.isEmpty) {
      buffer.removeLast();
    }
    if (buffer.isEmpty) {
      return null;
    }
    return buffer.join('\n');
  }
  return null;
}

String? _extractLabeledMessageBlock(String text) {
  return _extractLabeledBlock(
    text,
    RegExp(
      r'^\s*(?:message|note|card\s*message)\s*[:\-]\s*(.*)$',
      caseSensitive: false,
    ),
  );
}

String? _parseRecipientFromMessage(String? message) {
  if (message == null || message.trim().isEmpty) {
    return null;
  }
  final match = RegExp(
    r'^To\s+(.+?),?\s*$',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(message.trim());
  return match?.group(1)?.trim();
}

void _applyFreeFormWhatsAppFallback({
  required String text,
  required List<String> lines,
  required DateTime referenceDate,
  DateTime? Function()? getDeliveryDate,
  required void Function(DateTime? value) setDeliveryDate,
  String? Function()? getDeliveryTimeSlot,
  required void Function(String? value) setDeliveryTimeSlot,
  String? Function()? getAddress,
  required void Function(String? value) setAddress,
  String? Function()? getClientName,
  required void Function(String? value) setClientName,
  String? Function()? getPostalCode,
  required void Function(String? value) setPostalCode,
  String? Function()? getCardMessage,
  required void Function(String? value) setCardMessage,
  String? Function()? getOrderType,
  required void Function(String? value) setOrderType,
}) {
  var resolvedDate = getDeliveryDate?.call();
  resolvedDate ??= _parseDayMonthSlashDate(text, referenceDate);
  resolvedDate ??= _parseDayMonthAbbrevDate(text);
  resolvedDate ??= _parseChineseRelativeDate(text, referenceDate);
  if (resolvedDate != null) {
    setDeliveryDate(resolvedDate);
  }

  var resolvedTime = getDeliveryTimeSlot?.call();
  resolvedTime ??= _parseTimeRange(text);
  resolvedTime ??= _parseChineseTimeSlot(text);
  if (resolvedTime != null) {
    setDeliveryTimeSlot(resolvedTime);
  }

  var resolvedAddress = getAddress?.call();
  resolvedAddress ??= _parseFreeFormAddress(lines);
  if (resolvedAddress != null) {
    setAddress(resolvedAddress);
  }

  var resolvedPostal = getPostalCode?.call();
  resolvedPostal ??= _parsePostalCode(resolvedAddress ?? text);
  if (resolvedPostal != null) {
    setPostalCode(resolvedPostal);
  }

  var resolvedClient = getClientName?.call();
  resolvedClient ??= _parseWsClientName(lines);
  resolvedClient ??= _parseTfgCarouselClientName(lines);
  if (resolvedClient != null) {
    setClientName(resolvedClient);
  }

  var resolvedNotes = getCardMessage?.call();
  resolvedNotes ??= _buildFreeFormNotes(
    lines,
    address: resolvedAddress,
    clientName: resolvedClient,
    productHint: _parseProductHint(lines),
  );
  if (resolvedNotes != null) {
    setCardMessage(resolvedNotes);
  }

  var resolvedOrderType = getOrderType?.call();
  if (resolvedOrderType == null) {
    final typeText = _stripParentheticalNotes(text);
    final lower = typeText.toLowerCase();
    if (RegExp(r'拿').hasMatch(typeText) ||
        lower.contains('pickup') ||
        lower.contains('pick up')) {
      resolvedOrderType = 'PickUp';
    } else if (RegExp(r'送').hasMatch(typeText) ||
        lower.contains('on site') ||
        lower.contains('onsite') ||
        lower.contains('deliver')) {
      resolvedOrderType = 'Delivery';
    }
  }
  if (resolvedOrderType != null) {
    setOrderType(resolvedOrderType);
  }
}

String? _mapOrderType(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('pick')) {
    return 'PickUp';
  }
  if (lower.contains('retail') || lower.contains('walk')) {
    return 'Retail';
  }
  if (lower.contains('deliver')) {
    return 'Delivery';
  }
  return null;
}

WhatsAppParsedOrderDetails parseWhatsAppOrderText(
  String text, {
  DateTime? referenceDate,
}) {
  text = normalizeWhatsAppPasteText(text);
  final now = referenceDate ?? DateTime.now();
  final orderId = extractOrderIdFromWhatsAppText(text);
  String? clientName;
  String? recipientName;
  String? phone;
  String? address;
  String? postalCode;
  String? region;
  String? deliveryTimeSlot;
  String? cardMessage;
  DateTime? deliveryDate;
  String? orderType;

  if (RegExp(r'pickup order', caseSensitive: false).hasMatch(text)) {
    orderType = 'PickUp';
  }

  cardMessage ??= _extractLabeledMessageBlock(text);

  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }
    final labelMatch = RegExp(r'^\s*(.+?)\s*[:\-]\s*(.+?)\s*$').firstMatch(line);
    if (labelMatch == null) {
      continue;
    }
    final label = _normalizeLabel(labelMatch.group(1)!);
    final value = labelMatch.group(2)!.trim();
    if (value.isEmpty) {
      continue;
    }

    if (label.contains('recipient')) {
      recipientName ??= value;
    } else if (label == 'name' ||
        label.contains('customer') ||
        label.contains('client')) {
      clientName ??= value;
    } else if (label.contains('phone') ||
        label.contains('mobile') ||
        label.contains('contact') ||
        label.contains('hp') ||
        label == 'tel') {
      phone ??= value;
    } else if (label.contains('address')) {
      address ??= _sanitizeWhatsAppAddress(value);
    } else if (label.contains('postal') || label.contains('postcode')) {
      postalCode ??= value;
    } else if (label.contains('region') || label.contains('area')) {
      region ??= value;
    } else if (label.contains('time')) {
      deliveryTimeSlot ??= value;
    } else if (label.contains('message') || label.contains('note')) {
      cardMessage ??= value;
    } else if (label.contains('date')) {
      deliveryDate ??= _parseLooseDate(value);
    } else if (label.contains('type') ||
        label.contains('pickup') ||
        label.contains('delivery')) {
      orderType ??= _mapOrderType(value);
    }
  }

  // Fallback: standalone phone line (8-digit SG mobile).
  phone ??= RegExp(r'(?<!\d)([89]\d{7})(?!\d)').firstMatch(text)?.group(1);

  final nonEmptyLines = normalizeWhatsAppLines(text);

  _applyFreeFormWhatsAppFallback(
    text: text,
    lines: nonEmptyLines,
    referenceDate: now,
    getDeliveryDate: () => deliveryDate,
    setDeliveryDate: (value) => deliveryDate ??= value,
    getDeliveryTimeSlot: () => deliveryTimeSlot,
    setDeliveryTimeSlot: (value) => deliveryTimeSlot ??= value,
    getAddress: () => address,
    setAddress: (value) => address ??= value,
    getClientName: () => clientName,
    setClientName: (value) => clientName ??= value,
    getPostalCode: () => postalCode,
    setPostalCode: (value) => postalCode ??= value,
    getCardMessage: () => cardMessage,
    setCardMessage: (value) => cardMessage ??= value,
    getOrderType: () => orderType,
    setOrderType: (value) => orderType ??= value,
  );

  clientName ??= _parseShopifyClientReferenceFromLines(nonEmptyLines);

  recipientName ??= _parseRecipientFromForLine(nonEmptyLines);
  recipientName ??= _parseRecipientFromMessage(cardMessage);

  final productHint = _parseProductHint(nonEmptyLines);
  final productPrice =
      _parseProductPrice(text) ??
      (productHint != null ? _parseProductPrice(productHint) : null);
  final needsPhoto = _needsReferencePhoto(text);
  cardMessage = _sanitizeWhatsAppCardMessage(
    cardMessage,
    productHint: productHint,
  );

  return WhatsAppParsedOrderDetails(
    orderId: orderId,
    clientName: clientName,
    recipientName: recipientName,
    phone: phone,
    address: address,
    postalCode: postalCode,
    region: region,
    deliveryTimeSlot: deliveryTimeSlot,
    cardMessage: cardMessage,
    deliveryDate: deliveryDate,
    orderType: orderType,
    productHint: productHint,
    productPrice: productPrice,
    needsReferencePhoto: needsPhoto,
  );
}

bool _orderBelongsToActiveTenant(OrdersRecord order) {
  final active = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (active == null) {
    return true;
  }
  if (order.companyRef == null) {
    return true;
  }
  return order.companyRef!.path == active.path;
}

Future<OrdersRecord?> findOrderByOrderId(String orderId) async {
  final normalized = orderId.trim();
  if (normalized.isEmpty) {
    return null;
  }

  try {
    final snap = await OrdersRecord.collection
        .where('Order_Id', isEqualTo: normalized)
        .limit(10)
        .get();
    for (final doc in snap.docs) {
      final order = OrdersRecord.fromSnapshot(doc);
      if (_orderBelongsToActiveTenant(order)) {
        return order;
      }
    }
  } catch (_) {
    // Fall back to tenant-scoped in-memory scan if direct query fails.
  }

  final tenantOrders = await queryTenantOrdersRecordOnce(limit: 500);
  for (final order in tenantOrders) {
    if (order.orderId == normalized) {
      return order;
    }
  }
  return null;
}

Future<OrdersRecord?> resolveOrderFromWhatsAppText(String text) async {
  final parsed = parseWhatsAppOrderText(text);
  final orderId = parsed.orderId;
  if (orderId == null || orderId.isEmpty) {
    return null;
  }
  return findOrderByOrderId(orderId);
}

bool looksLikeKnownOrderId(String? orderId) {
  if (orderId == null || orderId.isEmpty) {
    return false;
  }
  return OrderIdService.isDeliveryOrderId(orderId) ||
      OrderIdService.isRetailOrderId(orderId);
}

const double whatsAppDeliveryFeeThreshold = 200;
const double whatsAppDeliveryFeeAmount = 15;

bool shouldAddWhatsAppDeliveryFee({
  required String? orderType,
  required double merchandiseSubtotal,
}) {
  if (orderType != 'Delivery') {
    return false;
  }
  return merchandiseSubtotal > 0 &&
      merchandiseSubtotal < whatsAppDeliveryFeeThreshold;
}
