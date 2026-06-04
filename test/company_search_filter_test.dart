import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/company_query_helpers.dart';
import 'package:tfg_vday/backend/schema/companies_record.dart';

import 'firebase_test_setup.dart';

CompaniesRecord _company({
  required String id,
  required String name,
  String phone = '',
  String uen = '',
}) {
  return CompaniesRecord.getDocumentFromData(
    {
      'Company_name': name,
      'Company_phone': phone,
      'company_uen': uen,
      'is_active': true,
    },
    FirebaseFirestore.instance.collection('Companies').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('filterCompaniesBySearchQuery matches name phone and uen', () {
    final companies = [
      _company(id: 'a', name: 'Rose Florist', phone: '91234567', uen: 'UEN-A'),
      _company(id: 'b', name: 'Carnation Shop', phone: '87654321', uen: 'UEN-B'),
    ];

    expect(
      filterCompaniesBySearchQuery(companies, 'rose').map((c) => c.companyName),
      ['Rose Florist'],
    );
    expect(
      filterCompaniesBySearchQuery(companies, '8765').single.companyName,
      'Carnation Shop',
    );
    expect(
      filterCompaniesBySearchQuery(companies, 'uen-b').single.companyName,
      'Carnation Shop',
    );
    expect(filterCompaniesBySearchQuery(companies, ''), companies);
  });
}
