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

  // New schema fields
  String? _userId;
  String get userId => _userId ?? '';
  bool hasUserId() => _userId != null;

  String? _userName;
  String get userName => _userName ?? '';
  bool hasUserName() => _userName != null;

  String? _userRole;
  String get userRole => _userRole ?? '';
  bool hasUserRole() => _userRole != null;

  String? _action;
  String get action => _action ?? _actionType ?? '';
  bool hasAction() => _action != null || _actionType != null;

  String? _entityId;
  String get entityId => _entityId ?? _entityRef?.id ?? '';
  bool hasEntityId() => _entityId != null || _entityRef != null;

  String? _entityLabel;
  String get entityLabel => _entityLabel ?? '';
  bool hasEntityLabel() => _entityLabel != null;

  Map<String, dynamic>? _oldValue;
  Map<String, dynamic>? get oldValue => _oldValue;
  bool hasOldValue() => _oldValue != null;

  Map<String, dynamic>? _newValue;
  Map<String, dynamic>? get newValue => _newValue;
  bool hasNewValue() => _newValue != null;

  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  String? _companyId;
  String get companyId => _companyId ?? _companyRef?.id ?? '';
  bool hasCompanyId() => _companyId != null || _companyRef != null;

  // Legacy schema fields (backward compatible reads)
  String? _actionType;
  String get actionType => _actionType ?? _action ?? '';
  bool hasActionType() => _actionType != null || _action != null;

  String? _entityType;
  String get entityType => _entityType ?? '';
  bool hasEntityType() => _entityType != null;

  DocumentReference? _entityRef;
  DocumentReference? get entityRef => _entityRef;
  bool hasEntityRef() => _entityRef != null;

  DocumentReference? _entityRef2;
  DocumentReference? get entityRef2 => _entityRef2;
  bool hasEntityRef2() => _entityRef2 != null;

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  DocumentReference? _performedBy;
  DocumentReference? get performedBy => _performedBy;
  bool hasPerformedBy() => _performedBy != null;

  bool? _isImpersonated;
  bool get isImpersonated => _isImpersonated ?? false;
  bool hasIsImpersonated() => _isImpersonated != null;

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

  String? _afterValue;
  String get afterValue => _afterValue ?? '';
  bool hasAfterValue() => _afterValue != null;

  String? _beforeValue;
  String get beforeValue => _beforeValue ?? '';
  bool hasBeforeValue() => _beforeValue != null;

  void _initializeFields() {
    _userId = snapshotData['userId'] as String?;
    _userName = snapshotData['userName'] as String?;
    _userRole = snapshotData['userRole'] as String?;
    _action = snapshotData['action'] as String?;
    _entityId = snapshotData['entityId'] as String?;
    _entityLabel = snapshotData['entityLabel'] as String?;
    _oldValue = castToType<Map<String, dynamic>>(snapshotData['oldValue']);
    _newValue = castToType<Map<String, dynamic>>(snapshotData['newValue']);
    _description = snapshotData['description'] as String?;
    _companyId = snapshotData['companyId'] as String?;

    _actionType = snapshotData['action_type'] as String?;
    _entityType = snapshotData['entity_type'] as String?;
    _entityRef = snapshotData['entity_ref'] as DocumentReference?;
    _entityRef2 = snapshotData['entity_ref2'] as DocumentReference?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
    _performedBy = snapshotData['performed_by'] as DocumentReference?;
    _isImpersonated = snapshotData['is_impersonated'] as bool?;
    _createdAt = snapshotData['createdAt'] as DateTime? ??
        snapshotData['created_at'] as DateTime?;
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
  String? userId,
  String? userName,
  String? userRole,
  String? action,
  String? entityType,
  String? entityId,
  String? entityLabel,
  Map<String, dynamic>? oldValue,
  Map<String, dynamic>? newValue,
  String? description,
  String? companyId,
  dynamic createdAt,
  // Legacy fields kept for backward-compatible writes if needed.
  String? actionType,
  DocumentReference? entityRef,
  DocumentReference? entityRef2,
  DocumentReference? companyRef,
  DocumentReference? performedBy,
  bool? isImpersonated,
  String? afterValue,
  String? beforeValue,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'entityLabel': entityLabel,
      'oldValue': oldValue,
      'newValue': newValue,
      'description': description,
      'companyId': companyId,
      'createdAt': createdAt,
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
    return e1?.userId == e2?.userId &&
        e1?.userName == e2?.userName &&
        e1?.userRole == e2?.userRole &&
        e1?.action == e2?.action &&
        e1?.entityType == e2?.entityType &&
        e1?.entityId == e2?.entityId &&
        e1?.entityLabel == e2?.entityLabel &&
        const DeepCollectionEquality().equals(e1?.oldValue, e2?.oldValue) &&
        const DeepCollectionEquality().equals(e1?.newValue, e2?.newValue) &&
        e1?.description == e2?.description &&
        e1?.companyId == e2?.companyId &&
        e1?.createdAt == e2?.createdAt;
  }

  @override
  int hash(AuditLogsRecord? e) => const ListEquality().hash([
        e?.userId,
        e?.userName,
        e?.userRole,
        e?.action,
        e?.entityType,
        e?.entityId,
        e?.entityLabel,
        e?.oldValue,
        e?.newValue,
        e?.description,
        e?.companyId,
        e?.createdAt,
      ]);

  @override
  bool isValidKey(Object? o) => o is AuditLogsRecord;
}
