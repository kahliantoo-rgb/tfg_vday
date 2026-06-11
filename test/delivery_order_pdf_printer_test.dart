import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/companies_record.dart';
import 'package:tfg_vday/backend/schema/customers_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';
import 'package:tfg_vday/custom_code/delivery_order_pdf_printer.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  String clientName = 'Alice',
  String customerPhone = '91234567',
  String recipientName = 'Bob',
  String recipientPhone = '87654321',
  String address = '31 Bangkit Road #17-03',
  String postalCode = '679973',
  String region = 'West',
}) {
  return OrdersRecord.getDocumentFromData(
    {
      'client_name': clientName,
      'customer_phone_number': customerPhone,
      'recipient_name': recipientName,
      'recipient_phone_number': recipientPhone,
      'address': address,
      'PostalCode': postalCode,
      'region': region,
      'delivery_date': DateTime(2026, 6, 7),
      'delivery_time_slot': '14:00-16:00',
    },
    FirebaseFirestore.instance.collection('orders').doc('order1'),
  );
}

CompaniesRecord _company({
  String address = '328 Sims Avenue S(387529)',
}) {
  return CompaniesRecord.getDocumentFromData(
    {
      'Company_name': 'The Flower Guy Pte Ltd',
      'company_uen': '202426657E',
      'Company_phone': '+65 8088 5335',
      'company_address': address,
    },
    FirebaseFirestore.instance.collection('companies').doc('co1'),
  );
}

CustomersRecord _customer({
  String name = 'Alice Tan',
  String phone = '91234567',
  String billingAddress = '10 Billing Street, Singapore 123456',
  String uen = '',
}) {
  return CustomersRecord.getDocumentFromData(
    {
      'name': name,
      'phone': phone,
      'billing_address': billingAddress,
      if (uen.isNotEmpty) 'uen': uen,
    },
    FirebaseFirestore.instance.collection('customers').doc('cust1'),
  );
}

void main() {
  setUpAll(() async {
    await setupFirebaseForTests();
  });

  test('billingAddressLines prefers linked customer profile', () {
    final lines = DeliveryOrderPdfPrinter.billingAddressLines(
      order: _order(),
      customer: _customer(),
    );
    expect(lines.join('\n'), contains('Alice Tan'));
    expect(lines.join('\n'), contains('10 Billing Street'));
  });

  test('billingAddressLines includes customer UEN when set', () {
    final lines = DeliveryOrderPdfPrinter.billingAddressLines(
      order: _order(),
      customer: _customer(uen: '201912345A'),
    );
    expect(lines.join('\n'), contains('UEN: 201912345A'));
  });

  test('recipientDetailLines includes delivery address and date', () {
    final lines = DeliveryOrderPdfPrinter.recipientDetailLines(_order());
    expect(lines.join('\n'), contains('Recipient: Bob'));
    expect(lines.join('\n'), contains('31 Bangkit Road #17-03'));
    expect(lines.join('\n'), contains('Delivery date: 2026-06-07'));
  });

  test('companyContactLines includes UEN, address, and phone', () {
    final lines = DeliveryOrderPdfPrinter.companyContactLines(_company());
    expect(lines.join('\n'), contains('UEN: 202426657E'));
    expect(lines.join('\n'), contains('328 Sims Avenue'));
    expect(lines.join('\n'), contains('Tel: +65 8088 5335'));
  });

  test('footer disclaimer uses corrected grammar', () {
    expect(
      DeliveryOrderPdfPrinter.footerDisclaimer,
      'This is a computer-generated invoice. No signature is required.',
    );
  });

  test('delivery slip footer omits pricing', () {
    expect(
      DeliveryOrderPdfPrinter.deliverySlipFooter,
      contains('Prices are not shown'),
    );
    expect(DeliveryOrderPdfPrinter.deliverySlipTitle, 'DELIVERY ORDER');
  });
}
