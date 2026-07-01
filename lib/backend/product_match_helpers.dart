import '/backend/order_whatsapp_import_helpers.dart' show normalizeWhatsAppPasteText;
import '/backend/schema/product_record.dart';

const _englishFlowerKeywords = {
  'rose': '玫瑰',
  'roses': '玫瑰',
  'bouquet': '花束',
  'corsage': '手花',
  'wrist': '手花',
  'hydrangea': '绣球',
  'lily': '百合',
  'tulip': '郁金香',
  'sunflower': '太阳花',
};

String compactProductLabel(String raw) {
  return normalizeWhatsAppPasteText(raw)
      .replaceAll(RegExp(r'\s+'), '')
      .toLowerCase();
}

/// Category-only Chinese fragments too short to identify a catalog SKU.
const _genericProductCategoryTerms = {
  '手花',
  '花束',
  '花',
};

/// True when a WhatsApp hint names a budget or category, not a specific product.
bool isVagueCatalogProductHint(String hint) {
  final trimmed = hint.trim();
  if (trimmed.isEmpty) {
    return true;
  }

  final afterPrice = trimmed
      .replaceFirst(RegExp(r'^[$＄]\d+(?:\.\d+)?'), '')
      .trim();
  if (RegExp(r'^[$＄]\d').hasMatch(trimmed)) {
    final category = normalizeProductSearchText(afterPrice);
    if (category.isEmpty || _genericProductCategoryTerms.contains(category)) {
      return true;
    }
  }

  final norm = normalizeProductSearchText(trimmed);
  if (norm.isEmpty || _genericProductCategoryTerms.contains(norm)) {
    return true;
  }

  final chinese = extractChineseProductFragment(trimmed);
  if (chinese != null) {
    final normalized = normalizeChineseProductText(chinese);
    final withoutLeadingDigits = normalized.replaceFirst(RegExp(r'^\d+'), '');
    if (_genericProductCategoryTerms.contains(normalized) ||
        _genericProductCategoryTerms.contains(withoutLeadingDigits)) {
      return true;
    }
  }

  return false;
}

/// Order quantity from a WhatsApp product line.
///
/// Spec counts such as `3支` or `3 stalk` describe the product (qty 1).
/// Only explicit multipliers like `*3`, `x3`, or `×3` set order qty.
int parseProductQtyFromHint(String? hint) {
  if (hint == null || hint.isEmpty) {
    return 1;
  }
  final match = RegExp(r'[*×x]\s*(\d+)\b', caseSensitive: false).firstMatch(
    hint.trim(),
  );
  if (match != null) {
    final qty = int.tryParse(match.group(1)!);
    if (qty != null && qty > 0) {
      return qty;
    }
  }
  return 1;
}

/// Removes explicit order multipliers before product-name matching.
String stripOrderQtyMultiplier(String hint) {
  return hint
      .replaceAll(RegExp(r'[*×x]\s*\d+\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String normalizeProductSearchText(String raw) {
  return normalizeWhatsAppPasteText(raw)
      .replaceAll(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp(r'[$＄]\d+(?:\.\d+)?'), '')
      .replaceAll(RegExp(r'如图|參考图|参考图'), '')
      .replaceAll(RegExp(r'\s+'), '')
      .trim()
      .toLowerCase();
}

String normalizeChineseProductText(String raw) {
  return raw.replaceAll(RegExp(r'\s+'), '').trim();
}

/// Longest Chinese fragment, e.g. `3朵玫瑰` from mixed English/Chinese text.
String? extractChineseProductFragment(String raw) {
  final matches = RegExp(r'\d*[\u4e00-\u9fff][\u4e00-\u9fff0-9]*')
      .allMatches(raw);
  if (matches.isEmpty) {
    return null;
  }
  return matches
      .map((match) => match.group(0)!)
      .reduce((a, b) => a.length >= b.length ? a : b);
}

String? _leadingNumber(String raw) {
  return RegExp(r'^(\d+)').firstMatch(normalizeProductSearchText(raw))?.group(1);
}

int _scoreEnglishToChineseKeywords(String hint, String productName) {
  final lowerHint = hint.toLowerCase();
  var score = 0;
  for (final entry in _englishFlowerKeywords.entries) {
    if (!lowerHint.contains(entry.key)) {
      continue;
    }
    if (productName.contains(entry.value)) {
      score += 60;
    }
  }
  if (lowerHint.contains('bouquet') &&
      (productName.contains('朵') || productName.contains('束'))) {
    score += 30;
  }
  return score;
}

int scoreProductMatch(String hint, ProductRecord product) {
  final productName = product.name.trim();
  if (productName.isEmpty) {
    return 0;
  }

  if (isVagueCatalogProductHint(hint)) {
    final hintKey = compactProductLabel(hint);
    final nameKey = compactProductLabel(productName);
    if (hintKey.isNotEmpty && hintKey == nameKey) {
      return 1000;
    }
    return 0;
  }

  var score = 0;
  final normHint = normalizeProductSearchText(hint);
  final normName = normalizeProductSearchText(productName);
  if (normHint.isNotEmpty && normHint == normName) {
    score = 1000;
  }
  if (normHint.isNotEmpty &&
      (normHint.contains(normName) || normName.contains(normHint))) {
    score = _maxScore(score, 500 + normName.length);
  }

  final chineseHint = extractChineseProductFragment(hint);
  final chineseName = extractChineseProductFragment(productName);
  if (chineseHint != null && chineseName != null) {
    final a = normalizeChineseProductText(chineseHint);
    final b = normalizeChineseProductText(chineseName);
    if (a == b) {
      score = _maxScore(score, 900);
    } else if (a.contains(b) || b.contains(a)) {
      score = _maxScore(score, 450 + b.length);
    }
  }
  if (chineseHint != null &&
      normalizeChineseProductText(productName).contains(
        normalizeChineseProductText(chineseHint),
      )) {
    score = _maxScore(score, 420 + chineseHint.length);
  }

  score = _maxScore(score, _scoreEnglishToChineseKeywords(hint, productName));
  final hintNumber = _leadingNumber(hint);
  final nameNumber = _leadingNumber(productName);
  if (hintNumber != null && hintNumber == nameNumber) {
    score += 35;
  }
  return score;
}

int _maxScore(int current, int candidate) =>
    candidate > current ? candidate : current;

/// Minimum score required to treat a catalog row as a match.
const productMatchScoreThreshold = 80;

/// Finds the best active catalog product for a WhatsApp product hint.
ProductRecord? findBestProductMatch(
  List<ProductRecord> products,
  String hint,
) {
  final trimmedHint = hint.trim();
  if (trimmedHint.isEmpty) {
    return null;
  }

  final activeProducts =
      products.where((product) => product.isActive).toList(growable: false);
  if (activeProducts.isEmpty) {
    return null;
  }

  ProductRecord? best;
  var bestScore = 0;
  for (final product in activeProducts) {
    final score = scoreProductMatch(trimmedHint, product);
    if (score > bestScore) {
      bestScore = score;
      best = product;
    }
  }

  if (bestScore < productMatchScoreThreshold) {
    return null;
  }
  return best;
}
