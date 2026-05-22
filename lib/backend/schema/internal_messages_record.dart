import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class InternalMessagesRecord extends FirestoreRecord {
  InternalMessagesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "message" field.
  String? _message;
  String get message => _message ?? '';
  bool hasMessage() => _message != null;

  // "sender" field.
  DocumentReference? _sender;
  DocumentReference? get sender => _sender;
  bool hasSender() => _sender != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "Order_ref" field.
  DocumentReference? _orderRef;
  DocumentReference? get orderRef => _orderRef;
  bool hasOrderRef() => _orderRef != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _message = snapshotData['message'] as String?;
    _sender = snapshotData['sender'] as DocumentReference?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _orderRef = snapshotData['Order_ref'] as DocumentReference?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('internal_messages')
          : FirebaseFirestore.instance.collectionGroup('internal_messages');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('internal_messages').doc(id);

  static Stream<InternalMessagesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => InternalMessagesRecord.fromSnapshot(s));

  static Future<InternalMessagesRecord> getDocumentOnce(
          DocumentReference ref) =>
      ref.get().then((s) => InternalMessagesRecord.fromSnapshot(s));

  static InternalMessagesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      InternalMessagesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static InternalMessagesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      InternalMessagesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'InternalMessagesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is InternalMessagesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createInternalMessagesRecordData({
  String? message,
  DocumentReference? sender,
  DateTime? createdTime,
  DocumentReference? orderRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'message': message,
      'sender': sender,
      'created_time': createdTime,
      'Order_ref': orderRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class InternalMessagesRecordDocumentEquality
    implements Equality<InternalMessagesRecord> {
  const InternalMessagesRecordDocumentEquality();

  @override
  bool equals(InternalMessagesRecord? e1, InternalMessagesRecord? e2) {
    return e1?.message == e2?.message &&
        e1?.sender == e2?.sender &&
        e1?.createdTime == e2?.createdTime &&
        e1?.orderRef == e2?.orderRef;
  }

  @override
  int hash(InternalMessagesRecord? e) => const ListEquality()
      .hash([e?.message, e?.sender, e?.createdTime, e?.orderRef]);

  @override
  bool isValidKey(Object? o) => o is InternalMessagesRecord;
}
