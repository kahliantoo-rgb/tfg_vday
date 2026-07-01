import 'package:flutter/material.dart';

/// Supported app UI languages (stored in SharedPreferences via FFLocalizations).
const supportedAppLanguageCodes = ['en', 'zh', 'ms'];

String currentLanguageCode(BuildContext context) {
  return Localizations.localeOf(context).languageCode;
}

/// Pick one string for the active UI language.
String loc(
  BuildContext context, {
  required String en,
  required String zh,
  String? ms,
}) {
  switch (currentLanguageCode(context)) {
    case 'zh':
      return zh;
    case 'ms':
      return ms ?? en;
    default:
      return en;
  }
}

String languageDisplayName(String code) {
  switch (code) {
    case 'zh':
      return '中文';
    case 'ms':
      return 'Bahasa Melayu';
    default:
      return 'English';
  }
}
