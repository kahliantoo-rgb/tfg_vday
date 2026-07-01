import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'locale_text.dart';

/// Lookup a translated string by key for the active UI language.
String tr(
  BuildContext context,
  String key, {
  Map<String, String> params = const {},
}) {
  final lang = currentLanguageCode(context);
  final entry = kAppStrings[key];
  var text = entry?[lang] ?? entry?['en'] ?? key;
  for (final param in params.entries) {
    text = text.replaceAll('{${param.key}}', param.value);
  }
  return text;
}
