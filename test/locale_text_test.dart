import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/l10n/locale_text.dart';

MaterialApp _localizedApp({
  required Locale locale,
  required Widget child,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('zh'), Locale('ms')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  testWidgets('loc returns zh by locale', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('zh'),
        child: Builder(
          builder: (context) {
            expect(loc(context, en: 'A', zh: '中', ms: 'M'), '中');
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('loc returns ms by locale', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('ms'),
        child: Builder(
          builder: (context) {
            expect(loc(context, en: 'A', zh: '中', ms: 'M'), 'M');
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('loc returns en by locale', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            expect(loc(context, en: 'A', zh: '中', ms: 'M'), 'A');
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  test('languageDisplayName covers supported codes', () {
    expect(languageDisplayName('en'), 'English');
    expect(languageDisplayName('zh'), '中文');
    expect(languageDisplayName('ms'), 'Bahasa Melayu');
  });
}
