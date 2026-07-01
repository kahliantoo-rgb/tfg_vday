import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/backend/audit_log_helpers.dart';
import 'package:tfg_vday/backend/audit_log_service.dart';
import 'package:tfg_vday/backend/schema/audit_logs_record.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(setupFirebaseForTests);

  group('auditActionLabel', () {
    test('maps known actions to readable labels', () {
      expect(auditActionLabel(AuditLogAction.createOrder), 'Create order');
      expect(auditActionLabel(AuditLogAction.printReceipt),
          'Print receipt / PDF invoice');
    });
  });

  group('auditLogPerformerLabel', () {
    test('prefers userName then userId', () {
      final withName = AuditLogsRecord.getDocumentFromData(
        {'userName': 'Alice Tan', 'userId': 'uid1'},
        AuditLogsRecord.collection.doc('log1'),
      );
      final withIdOnly = AuditLogsRecord.getDocumentFromData(
        {'userId': 'uid2'},
        AuditLogsRecord.collection.doc('log2'),
      );
      expect(auditLogPerformerLabel(withName), 'Alice Tan');
      expect(auditLogPerformerLabel(withIdOnly), 'uid2');
    });
  });

  group('formatReceiptCashierLine', () {
    test('formats staff name on cashier line', () {
      expect(formatReceiptCashierLine('Alice Tan'), 'Cashier: Alice Tan');
      expect(formatReceiptCashierLine(''), 'Cashier: Not set');
      expect(formatReceiptCashierLine('cashier'), 'Cashier: Not set');
    });
  });

  group('orderSnapshotFromEditForm', () {
    test('captures edited customer and delivery fields', () {
      final order = OrdersRecord.getDocumentFromData(
        {
          'Order_Id': 'TFG-JUN26-0001',
          'status': OrderStatus.pending.serialize(),
          'orderType': 'Delivery',
        },
        OrdersRecord.collection.doc('order1'),
      );

      final snapshot = orderSnapshotFromEditForm(
        order: order,
        clientName: 'Alice',
        recipientName: 'Bob',
        recipientPhone: '91234567',
        customerPhone: '87654321',
        address: '1 Main St',
        region: 'Central',
        postalCode: '123456',
        deliveryDate: DateTime(2026, 6, 7),
        deliveryTimeSlot: '2pm-4pm',
        cardMessage: 'Hi',
      );

      expect(snapshot['clientName'], 'Alice');
      expect(snapshot['recipientPhoneNumber'], '91234567');
      expect(snapshot['customerPhoneNumber'], '87654321');
      expect(snapshot['deliveryTimeSlot'], '2pm-4pm');
      expect(snapshot['orderId'], 'TFG-JUN26-0001');
    });
  });
}
