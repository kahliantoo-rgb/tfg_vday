import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Contract price list for credit / B2B customers (scheme 4).
class PriceListsRecord extends FirestoreRecord {
  PriceListsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  List<Map<String, dynamic>>? _priceLines;
  List<Map<String, dynamic>> get priceLines => _priceLines ?? const [];

  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  DateTime? _updatedTime;
  DateTime? get updatedTime => _updatedTime;
  bool hasUpdatedTime() => _updatedTime != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
    _priceLines = _parsePriceLines(snapshotData['price_lines']);
    _createdTime = snapshotData['created_time'] as DateTime?;
    _updatedTime = snapshotData['updated_time'] as DateTime?;
  }

  static List<Map<String, dynamic>>? _parsePriceLines(dynamic raw) {
    if (raw is! List) {
      return null;
    }
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('price_lists');

  static Stream<PriceListsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => PriceListsRecord.fromSnapshot(s));

  static Future<PriceListsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => PriceListsRecord.fromSnapshot(s));

  static PriceListsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      PriceListsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static PriceListsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      PriceListsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'PriceListsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is PriceListsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createPriceListsRecordData({
  String? name,
  DocumentReference? companyRef,
  List<Map<String, dynamic>>? priceLines,
  DateTime? createdTime,
  DateTime? updatedTime,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'name': name,
      'companyRef': companyRef,
      'price_lines': priceLines,
      'created_time': createdTime,
      'updated_time': updatedTime,
    }.withoutNulls,
  );
}

class PriceListsRecordDocumentEquality implements Equality<PriceListsRecord> {
  const PriceListsRecordDocumentEquality();

  @override
  bool equals(PriceListsRecord? e1, PriceListsRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.companyRef == e2?.companyRef &&
        const DeepCollectionEquality().equals(e1?.priceLines, e2?.priceLines);
  }

  @override
  int hash(PriceListsRecord? e) => const ListEquality().hash([
        e?.name,
        e?.companyRef,
        e?.priceLines,
      ]);

  @override
  bool isValidKey(Object? o) => o is PriceListsRecord;
}
