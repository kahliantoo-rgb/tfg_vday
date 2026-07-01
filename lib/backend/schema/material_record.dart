import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MaterialRecord extends FirestoreRecord {
  MaterialRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  String? _unit;
  String get unit => _unit ?? '';
  bool hasUnit() => _unit != null;

  String? _sku;
  String get sku => _sku ?? '';
  bool hasSku() => _sku != null;

  double? _cost;
  double get cost => _cost ?? 0.0;
  bool hasCost() => _cost != null;

  bool? _isActive;
  bool get isActive => _isActive ?? true;
  bool hasIsActive() => _isActive != null;

  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _unit = snapshotData['unit'] as String?;
    _sku = snapshotData['sku'] as String?;
    _cost = castToType<double>(snapshotData['cost']);
    _isActive = snapshotData['isActive'] as bool?;
    _category = snapshotData['category'] as String?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('materials');

  static Stream<MaterialRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MaterialRecord.fromSnapshot(s));

  static Future<MaterialRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MaterialRecord.fromSnapshot(s));

  static MaterialRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MaterialRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MaterialRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MaterialRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MaterialRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MaterialRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMaterialRecordData({
  String? name,
  String? unit,
  String? sku,
  double? cost,
  bool? isActive,
  String? category,
  DocumentReference? companyRef,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'name': name,
      'unit': unit,
      'sku': sku,
      'cost': cost,
      'isActive': isActive,
      'category': category,
      'companyRef': companyRef,
    }.withoutNulls,
  );
}

class MaterialRecordDocumentEquality implements Equality<MaterialRecord> {
  const MaterialRecordDocumentEquality();

  @override
  bool equals(MaterialRecord? e1, MaterialRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.unit == e2?.unit &&
        e1?.sku == e2?.sku &&
        e1?.cost == e2?.cost &&
        e1?.isActive == e2?.isActive &&
        e1?.category == e2?.category;
  }

  @override
  int hash(MaterialRecord? e) => const ListEquality()
      .hash([e?.name, e?.unit, e?.sku, e?.cost, e?.isActive, e?.category]);

  @override
  bool isValidKey(Object? o) => o is MaterialRecord;
}
