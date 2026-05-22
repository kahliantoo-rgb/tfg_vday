import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CountersRecord extends FirestoreRecord {
  CountersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "current" field.
  int? _current;
  int get current => _current ?? 0;
  bool hasCurrent() => _current != null;

  // "current1" field.
  int? _current1;
  int get current1 => _current1 ?? 0;
  bool hasCurrent1() => _current1 != null;

  // "orderRef" field.
  DocumentReference? _orderRef;
  DocumentReference? get orderRef => _orderRef;
  bool hasOrderRef() => _orderRef != null;

  void _initializeFields() {
    _current = castToType<int>(snapshotData['current']);
    _current1 = castToType<int>(snapshotData['current1']);
    _orderRef = snapshotData['orderRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('counters');

  static Stream<CountersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CountersRecord.fromSnapshot(s));

  static Future<CountersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CountersRecord.fromSnapshot(s));

  static CountersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CountersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CountersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CountersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CountersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CountersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCountersRecordData({
  int? current,
  int? current1,
  DocumentReference? orderRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'current': current,
      'current1': current1,
      'orderRef': orderRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class CountersRecordDocumentEquality implements Equality<CountersRecord> {
  const CountersRecordDocumentEquality();

  @override
  bool equals(CountersRecord? e1, CountersRecord? e2) {
    return e1?.current == e2?.current &&
        e1?.current1 == e2?.current1 &&
        e1?.orderRef == e2?.orderRef;
  }

  @override
  int hash(CountersRecord? e) =>
      const ListEquality().hash([e?.current, e?.current1, e?.orderRef]);

  @override
  bool isValidKey(Object? o) => o is CountersRecord;
}
