import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CounterRecord extends FirestoreRecord {
  CounterRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "current" field.
  int? _current;
  int get current => _current ?? 0;
  bool hasCurrent() => _current != null;

  // "comR" field — company reference (tenant marker on shared default_* counters).
  DocumentReference? _comR;
  DocumentReference? get comR => _comR;
  bool hasComR() => _comR != null;

  void _initializeFields() {
    _current = castToType<int>(snapshotData['current']);
    _comR = snapshotData['comR'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('counter');

  static Stream<CounterRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CounterRecord.fromSnapshot(s));

  static Future<CounterRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CounterRecord.fromSnapshot(s));

  static CounterRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CounterRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CounterRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CounterRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CounterRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CounterRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCounterRecordData({
  int? current,
  DocumentReference? comR,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'current': current,
      'comR': comR,
    }.withoutNulls,
  );

  return firestoreData;
}

class CounterRecordDocumentEquality implements Equality<CounterRecord> {
  const CounterRecordDocumentEquality();

  @override
  bool equals(CounterRecord? e1, CounterRecord? e2) {
    return e1?.current == e2?.current;
  }

  @override
  int hash(CounterRecord? e) => const ListEquality().hash([e?.current]);

  @override
  bool isValidKey(Object? o) => o is CounterRecord;
}
