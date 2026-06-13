import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_import_helpers.dart';

void main() {
  group('parseCustomerImportFile', () {
    test('parses csv with header row', () {
      const csv = '''
Name,Phone,Billing address,UEN,Credit customer,Credit term
Alice Tan,91234567,123 Orchard Rd,201912345A,yes,30
Bob Lee,81234567,,,no,
''';
      final result = parseCustomerImportFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'customers.csv',
      );

      expect(result.rows, hasLength(2));
      expect(result.rows.first.name, 'Alice Tan');
      expect(result.rows.first.phone, '91234567');
      expect(result.rows.first.billingAddress, '123 Orchard Rd');
      expect(result.rows.first.uen, '201912345A');
      expect(result.rows.first.isCreditCustomer, isTrue);
      expect(result.rows.first.creditTerm, 'Credit 30 days');
      expect(result.rows.last.isCreditCustomer, isFalse);
      expect(result.validCount, 2);
    });

    test('marks invalid rows when phone too short', () {
      const csv = 'Name,Phone\nTest User,123\n';
      final result = parseCustomerImportFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'customers.csv',
      );

      expect(result.rows.single.error, isNotNull);
      expect(result.validCount, 0);
    });

    test('requires credit term when credit customer is yes', () {
      const csv = 'Name,Phone,Credit customer\nCredit Co,91234567,yes\n';
      final result = parseCustomerImportFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        filename: 'customers.csv',
      );

      expect(result.rows.single.error, isNotNull);
      expect(result.validCount, 0);
    });
  });
}
