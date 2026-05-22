import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CompaniesRecord extends FirestoreRecord {
  CompaniesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Company_id" field.
  String? _companyId;
  String get companyId => _companyId ?? '';
  bool hasCompanyId() => _companyId != null;

  // "Company_name" field.
  String? _companyName;
  String get companyName => _companyName ?? '';
  bool hasCompanyName() => _companyName != null;

  // "Company_phone" field.
  String? _companyPhone;
  String get companyPhone => _companyPhone ?? '';
  bool hasCompanyPhone() => _companyPhone != null;

  // "company_address" field.
  String? _companyAddress;
  String get companyAddress => _companyAddress ?? '';
  bool hasCompanyAddress() => _companyAddress != null;

  // "company_uen" field.
  String? _companyUen;
  String get companyUen => _companyUen ?? '';
  bool hasCompanyUen() => _companyUen != null;

  // "is_active" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "logo" field.
  String? _logo;
  String get logo => _logo ?? '';
  bool hasLogo() => _logo != null;

  void _initializeFields() {
    _companyId = snapshotData['Company_id'] as String?;
    _companyName = snapshotData['Company_name'] as String?;
    _companyPhone = snapshotData['Company_phone'] as String?;
    _companyAddress = snapshotData['company_address'] as String?;
    _companyUen = snapshotData['company_uen'] as String?;
    _isActive = snapshotData['is_active'] as bool?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _logo = snapshotData['logo'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Companies');

  static Stream<CompaniesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CompaniesRecord.fromSnapshot(s));

  static Future<CompaniesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CompaniesRecord.fromSnapshot(s));

  static CompaniesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CompaniesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CompaniesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CompaniesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CompaniesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CompaniesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCompaniesRecordData({
  String? companyId,
  String? companyName,
  String? companyPhone,
  String? companyAddress,
  String? companyUen,
  bool? isActive,
  DateTime? createdAt,
  String? logo,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Company_id': companyId,
      'Company_name': companyName,
      'Company_phone': companyPhone,
      'company_address': companyAddress,
      'company_uen': companyUen,
      'is_active': isActive,
      'created_at': createdAt,
      'logo': logo,
    }.withoutNulls,
  );

  return firestoreData;
}

class CompaniesRecordDocumentEquality implements Equality<CompaniesRecord> {
  const CompaniesRecordDocumentEquality();

  @override
  bool equals(CompaniesRecord? e1, CompaniesRecord? e2) {
    return e1?.companyId == e2?.companyId &&
        e1?.companyName == e2?.companyName &&
        e1?.companyPhone == e2?.companyPhone &&
        e1?.companyAddress == e2?.companyAddress &&
        e1?.companyUen == e2?.companyUen &&
        e1?.isActive == e2?.isActive &&
        e1?.createdAt == e2?.createdAt &&
        e1?.logo == e2?.logo;
  }

  @override
  int hash(CompaniesRecord? e) => const ListEquality().hash([
        e?.companyId,
        e?.companyName,
        e?.companyPhone,
        e?.companyAddress,
        e?.companyUen,
        e?.isActive,
        e?.createdAt,
        e?.logo
      ]);

  @override
  bool isValidKey(Object? o) => o is CompaniesRecord;
}
