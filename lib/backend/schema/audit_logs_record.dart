import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AuditLogsRecord extends FirestoreRecord {
  AuditLogsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "action_type" field.
  String? _actionType;
  String get actionType => _actionType ?? '';
  bool hasActionType() => _actionType != null;

  // "entity_type" field.
  String? _entityType;
  String get entityType => _entityType ?? '';
  bool hasEntityType() => _entityType != null;

  // "entity_ref" field.
  DocumentReference? _entityRef;
  DocumentReference? get entityRef => _entityRef;
  bool hasEntityRef() => _entityRef != null;

  // "entity_ref2" field.
  DocumentReference? _entityRef2;
  DocumentReference? get entityRef2 => _entityRef2;
  bool hasEntityRef2() => _entityRef2 != null;

  // "companyRef" field.
  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  // "performed_by" field.
  DocumentReference? _performedBy;
  DocumentReference? get performedBy => _performedBy;
  bool hasPerformedBy() => _performedBy != null;

  // "is_impersonated" field.
  bool? _isImpersonated;
  bool get isImpersonated => _isImpersonated ?? false;
  bool hasIsImpersonated() => _isImpersonated != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  // "after_value" field.
  String? _afterValue;
  String get afterValue => _afterValue ?? '';
  bool hasAfterValue() => _afterValue != null;

  // "before_value" field.
  String? _beforeValue;
  String get beforeValue => _beforeValue ?? '';
  bool hasBeforeValue() => _beforeValue != null;

  void _initializeFields() {
    _actionType = snapshotData['action_type'] as String?;
    _entityType = snapshotData['entity_type'] as String?;
    _entityRef = snapshotData['entity_ref'] as DocumentReference?;
    _entityRef2 = snapshotData['entity_ref2'] as DocumentReference?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
    _performedBy = snapshotData['performed_by'] as DocumentReference?;
    _isImpersonated = snapshotData['is_impersonated'] as bool?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _afterValue = snapshotData['after_value'] as String?;
    _beforeValue = snapshotData['before_value'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('audit_logs');

  static Stream<AuditLogsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => AuditLogsRecord.fromSnapshot(s));

  static Future<AuditLogsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => AuditLogsRecord.fromSnapshot(s));

  static AuditLogsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      AuditLogsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static AuditLogsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      AuditLogsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'AuditLogsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is AuditLogsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createAuditLogsRecordData({
  String? actionType,
  String? entityType,
  DocumentReference? entityRef,
  DocumentReference? entityRef2,
  DocumentReference? companyRef,
  DocumentReference? performedBy,
  bool? isImpersonated,
  DateTime? createdAt,
  String? afterValue,
  String? beforeValue,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'action_type': actionType,
      'entity_type': entityType,
      'entity_ref': entityRef,
      'entity_ref2': entityRef2,
      'companyRef': companyRef,
      'performed_by': performedBy,
      'is_impersonated': isImpersonated,
      'created_at': createdAt,
      'after_value': afterValue,
      'before_value': beforeValue,
    }.withoutNulls,
  );

  return firestoreData;
}

class AuditLogsRecordDocumentEquality implements Equality<AuditLogsRecord> {
  const AuditLogsRecordDocumentEquality();

  @override
  bool equals(AuditLogsRecord? e1, AuditLogsRecord? e2) {
    return e1?.actionType == e2?.actionType &&
        e1?.entityType == e2?.entityType &&
        e1?.entityRef == e2?.entityRef &&
        e1?.entityRef2 == e2?.entityRef2 &&
        e1?.companyRef == e2?.companyRef &&
        e1?.performedBy == e2?.performedBy &&
        e1?.isImpersonated == e2?.isImpersonated &&
        e1?.createdAt == e2?.createdAt &&
        e1?.afterValue == e2?.afterValue &&
        e1?.beforeValue == e2?.beforeValue;
  }

  @override
  int hash(AuditLogsRecord? e) => const ListEquality().hash([
        e?.actionType,
        e?.entityType,
        e?.entityRef,
        e?.entityRef2,
        e?.companyRef,
        e?.performedBy,
        e?.isImpersonated,
        e?.createdAt,
        e?.afterValue,
        e?.beforeValue
      ]);

  @override
  bool isValidKey(Object? o) => o is AuditLogsRecord;
}
