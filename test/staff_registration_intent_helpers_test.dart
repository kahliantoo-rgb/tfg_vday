import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/staff_registration_intent_helpers.dart';

void main() {
  group('staffRegistrationIntentDocId', () {
    test('normalizes email to lowercase trimmed key', () {
      expect(
        staffRegistrationIntentDocId('  NewHire@TFG-Vday.Test  '),
        'newhire@tfg-vday.test',
      );
    });
  });
}
