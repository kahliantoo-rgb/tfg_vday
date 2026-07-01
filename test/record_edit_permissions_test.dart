import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/record_edit_permissions.dart';
import 'package:tfg_vday/backend/invoice_list_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/invoices_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);

InvoicesRecord invoiceRecord({required String status}) => InvoicesRecord.getDocumentFromData(
      {
        'status': status,
        'invoice_number': 'INV-1',
        'total': 100,
      },
      FirebaseFirestore.instance.collection('invoices').doc('inv1'),
    );

OrdersRecord orderRecord({
  String invoicePaymentStatus = '',
  double amountPaid = 0,
  double balanceDue = 0,
  double totalAmount = 100,
}) =>
    OrdersRecord.getDocumentFromData(
      {
        'invoice_payment_status': invoicePaymentStatus,
        'amount_paid': amountPaid,
        'balance_due': balanceDue,
        'total_amount': totalAmount,
      },
      FirebaseFirestore.instance.collection('orders').doc('order1'),
    );

  group('paid invoice edit lock', () {
    test('director superadmin and admin can edit paid invoices', () {
      final paid = invoiceRecord(status: InvoiceStatus.paid);
      expect(canEditInvoiceRecord(UserRole.director, paid), isTrue);
      expect(canEditInvoiceRecord(UserRole.superadmin, paid), isTrue);
      expect(canEditInvoiceRecord(UserRole.admin, paid), isTrue);
    });

    test('manager account cannot edit paid invoices', () {
      final paid = invoiceRecord(status: InvoiceStatus.paid);
      expect(canEditInvoiceRecord(UserRole.manager, paid), isFalse);
      expect(canEditInvoiceRecord(UserRole.account, paid), isFalse);
    });

    test('unpaid invoice still editable with editInvoices permission', () {
      final pending = invoiceRecord(status: InvoiceStatus.pending);
      expect(canEditInvoiceRecord(UserRole.admin, pending), isTrue);
      expect(canEditInvoiceRecord(UserRole.account, pending), isTrue);
    });
  });

  group('paid order edit lock', () {
    test('director superadmin and admin can edit paid orders', () {
      final paid = orderRecord(
        invoicePaymentStatus: InvoiceStatus.paid,
        amountPaid: 100,
        balanceDue: 0,
      );
      expect(canEditOrderRecord(UserRole.director, paid), isTrue);
      expect(canEditOrderRecord(UserRole.superadmin, paid), isTrue);
      expect(canEditOrderRecord(UserRole.admin, paid), isTrue);
    });

    test('manager cannot edit paid orders', () {
      final paid = orderRecord(
        amountPaid: 100,
        balanceDue: 0,
        totalAmount: 100,
      );
      expect(canEditOrderRecord(UserRole.manager, paid), isFalse);
    });

    test('unpaid order still editable with editOrderDetails permission', () {
      final unpaid = orderRecord(balanceDue: 100);
      expect(canEditOrderRecord(UserRole.admin, unpaid), isTrue);
      expect(canEditOrderRecord(UserRole.manager, unpaid), isTrue);
    });
  });
}
