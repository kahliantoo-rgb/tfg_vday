import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/schema/product_record.dart';
import 'package:tfg_vday/backend/tenant_query_helpers.dart';

import 'firebase_test_setup.dart';

ProductRecord _product({
  required String id,
  required String name,
  DocumentReference? companyRef,
  bool isActive = true,
}) {
  return ProductRecord.getDocumentFromData(
    {
      'name': name,
      'isActive': isActive,
      if (companyRef != null) 'companyRef': companyRef,
    },
    FirebaseFirestore.instance.collection('product').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('filterProductsByCompanyRef keeps only matching company', () {
    final companyA =
        FirebaseFirestore.instance.collection('Companies').doc('companyA');
    final companyB =
        FirebaseFirestore.instance.collection('Companies').doc('companyB');

    final products = [
      _product(id: '1', name: '(R)3 Stalks Rose Bouquet', companyRef: companyA),
      _product(id: '2', name: '3 Stalks Rose Bouquet (C)', companyRef: companyB),
      _product(id: '3', name: 'Legacy product'),
    ];

    final filtered = filterProductsByCompanyRef(products, companyA);
    expect(filtered.length, 1);
    expect(filtered.first.name, '(R)3 Stalks Rose Bouquet');
  });

  test('filterProductsByCompanyRef returns empty when company is null', () {
    final products = [
      _product(
        id: '1',
        name: 'Rose',
        companyRef: FirebaseFirestore.instance.collection('Companies').doc('x'),
      ),
    ];
    expect(filterProductsByCompanyRef(products, null), isEmpty);
  });
}
