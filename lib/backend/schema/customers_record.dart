import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CustomersRecord extends FirestoreRecord {
  CustomersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  String? _phone;
  String get phone => _phone ?? '';
  bool hasPhone() => _phone != null;

  String? _billingAddress;
  String get billingAddress => _billingAddress ?? '';
  bool hasBillingAddress() => _billingAddress != null;

  String? _uen;
  String get uen => _uen ?? '';
  bool hasUen() => _uen != null;

  bool? _isCreditCustomer;
  bool get isCreditCustomer => _isCreditCustomer ?? false;
  bool hasIsCreditCustomer() => _isCreditCustomer != null;

  String? _creditTerm;
  String get creditTerm => _creditTerm ?? '';
  bool hasCreditTerm() => _creditTerm != null;

  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _phone = snapshotData['phone'] as String?;
    _billingAddress = snapshotData['billing_address'] as String?;
    _uen = snapshotData['uen'] as String?;
    _isCreditCustomer = snapshotData['is_credit_customer'] as bool?;
    _creditTerm = snapshotData['credit_term'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _updatedTime = snapshotData['updated_time'] as DateTime?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('customers');

  static Stream<CustomersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CustomersRecord.fromSnapshot(s));

  static Future<CustomersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CustomersRecord.fromSnapshot(s));

  static CustomersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CustomersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CustomersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CustomersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CustomersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CustomersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCustomersRecordData({
  String? name,
  String? phone,
  String? billingAddress,
  String? uen,
  bool? isCreditCustomer,
  String? creditTerm,
  DateTime? createdTime,
  DateTime? updatedTime,
  DocumentReference? companyRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'phone': phone,
      'billing_address': billingAddress,
      'uen': uen,
      'is_credit_customer': isCreditCustomer,
      'credit_term': creditTerm,
      'created_time': createdTime,
      'updated_time': updatedTime,
      'companyRef': companyRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class CustomersRecordDocumentEquality implements Equality<CustomersRecord> {
  const CustomersRecordDocumentEquality();

  @override
  bool equals(CustomersRecord? e1, CustomersRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.phone == e2?.phone &&
        e1?.billingAddress == e2?.billingAddress &&
        e1?.uen == e2?.uen &&
        e1?.isCreditCustomer == e2?.isCreditCustomer &&
        e1?.creditTerm == e2?.creditTerm &&
        e1?.createdTime == e2?.createdTime &&
        e1?.updatedTime == e2?.updatedTime &&
        e1?.companyRef == e2?.companyRef;
  }

  @override
  int hash(CustomersRecord? e) => const ListEquality().hash([
        e?.name,
        e?.phone,
        e?.billingAddress,
        e?.uen,
        e?.isCreditCustomer,
        e?.creditTerm,
        e?.createdTime,
        e?.updatedTime,
        e?.companyRef,
      ]);

  @override
  bool isValidKey(Object? o) => o is CustomersRecord;
}
