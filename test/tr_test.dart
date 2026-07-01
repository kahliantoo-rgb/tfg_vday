import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/l10n/tr.dart';

MaterialApp _app(Widget child) {
  return MaterialApp(
    locale: const Locale('zh'),
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
  testWidgets('tr returns zh string with param substitution', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            expect(
              tr(
                context,
                'order.delete.success',
                params: {'count': '3'},
              ),
              '已删除 3 个订单，已归档至 deleted_orders。',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('tr falls back to en for unknown key', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            expect(tr(context, 'missing.key'), 'missing.key');
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
