import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/invoice_list_helpers.dart';
import 'package:tfg_vday/backend/invoice_status_display.dart';

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
  testWidgets('invoiceStatusDisplayLabel returns zh labels', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            expect(
              invoiceStatusDisplayLabel(context, InvoiceStatus.pending),
              '待付',
            );
            expect(
              invoiceStatusDisplayLabel(context, InvoiceStatus.paid),
              '已付',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
