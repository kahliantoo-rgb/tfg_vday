import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/invoice_payment_proof_helpers.dart';

void main() {
  test('invoicePaymentProofStoragePath includes company and invoice id', () {
    expect(
      invoicePaymentProofStoragePath('companyA', 'inv123', 'receipt.jpg'),
      'invoice_payment_proof_images/companyA/inv123/receipt.jpg',
    );
  });
}
