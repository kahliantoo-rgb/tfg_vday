import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DeletedOrdersRecord extends FirestoreRecord {
  DeletedOrdersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  String? _originalOrderId;
  String get originalOrderId => _originalOrderId ?? '';
  bool hasOriginalOrderId() => _originalOrderId != null;

  String? _originalOrderPath;
  String get originalOrderPath => _originalOrderPath ?? '';
  bool hasOriginalOrderPath() => _originalOrderPath != null;

  String? _orderId;
  String get orderId => _orderId ?? '';
  bool hasOrderId() => _orderId != null;

  Map<String, dynamic>? _orderData;
  Map<String, dynamic> get orderData => _orderData ?? const {};
  bool hasOrderData() => _orderData != null;

  List<dynamic>? _orderItems;
  List<dynamic> get orderItems => _orderItems ?? const [];
  bool hasOrderItems() => _orderItems != null;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _deletedAt;
  bool hasDeletedAt() => _deletedAt != null;

  String? _deletedByUid;
  String get deletedByUid => _deletedByUid ?? '';
  bool hasDeletedByUid() => _deletedByUid != null;

  String? _deletedByEmail;
  String get deletedByEmail => _deletedByEmail ?? '';
  bool hasDeletedByEmail() => _deletedByEmail != null;

  String? _deleteReason;
  String get deleteReason => _deleteReason ?? '';
  bool hasDeleteReason() => _deleteReason != null;

  String? _originalOrderStatus;
  String get originalOrderStatus => _originalOrderStatus ?? '';
  bool hasOriginalOrderStatus() => _originalOrderStatus != null;

  bool? _isRestored;
  bool get isRestored => _isRestored ?? false;
  bool hasIsRestored() => _isRestored != null;

  DateTime? _restoredAt;
  DateTime? get restoredAt => _restoredAt;
  bool hasRestoredAt() => _restoredAt != null;

  String? _restoredByUid;
  String get restoredByUid => _restoredByUid ?? '';
  bool hasRestoredByUid() => _restoredByUid != null;

  String? _restoredByEmail;
  String get restoredByEmail => _restoredByEmail ?? '';
  bool hasRestoredByEmail() => _restoredByEmail != null;

  List<dynamic>? _activityLog;
  List<dynamic> get activityLog => _activityLog ?? const [];
  bool hasActivityLog() => _activityLog != null;

  DocumentReference? _companyRef;
  DocumentReference? get companyRef => _companyRef;
  bool hasCompanyRef() => _companyRef != null;

  void _initializeFields() {
    _originalOrderId = snapshotData['original_order_id'] as String?;
    _originalOrderPath = snapshotData['original_order_path'] as String?;
    _orderId = snapshotData['order_id'] as String?;
    _orderData = snapshotData['order_data'] as Map<String, dynamic>?;
    _orderItems = snapshotData['order_items'] as List<dynamic>?;
    _deletedAt = snapshotData['deleted_at'] as DateTime?;
    _deletedByUid = snapshotData['deleted_by_uid'] as String?;
    _deletedByEmail = snapshotData['deleted_by_email'] as String?;
    _deleteReason = snapshotData['delete_reason'] as String?;
    _originalOrderStatus = snapshotData['original_order_status'] as String?;
    _isRestored = snapshotData['is_restored'] as bool?;
    _restoredAt = snapshotData['restored_at'] as DateTime?;
    _restoredByUid = snapshotData['restored_by_uid'] as String?;
    _restoredByEmail = snapshotData['restored_by_email'] as String?;
    _activityLog = snapshotData['activity_log'] as List<dynamic>?;
    _companyRef = snapshotData['companyRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('deleted_orders');

  static Stream<DeletedOrdersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DeletedOrdersRecord.fromSnapshot(s));

  static Future<DeletedOrdersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DeletedOrdersRecord.fromSnapshot(s));

  static DeletedOrdersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DeletedOrdersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DeletedOrdersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DeletedOrdersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DeletedOrdersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DeletedOrdersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDeletedOrdersRecordData({
  String? originalOrderId,
  String? originalOrderPath,
  String? orderId,
  Map<String, dynamic>? orderData,
  List<Map<String, dynamic>>? orderItems,
  DateTime? deletedAt,
  String? deletedByUid,
  String? deletedByEmail,
  String? deleteReason,
  String? originalOrderStatus,
  bool? isRestored,
  DateTime? restoredAt,
  String? restoredByUid,
  String? restoredByEmail,
  List<Map<String, dynamic>>? activityLog,
  DocumentReference? companyRef,
}) {
  return mapToFirestore(
    <String, dynamic>{
      'original_order_id': originalOrderId,
      'original_order_path': originalOrderPath,
      'order_id': orderId,
      'order_data': orderData,
      'order_items': orderItems,
      'deleted_at': deletedAt,
      'deleted_by_uid': deletedByUid,
      'deleted_by_email': deletedByEmail,
      'delete_reason': deleteReason,
      'original_order_status': originalOrderStatus,
      'is_restored': isRestored,
      'restored_at': restoredAt,
      'restored_by_uid': restoredByUid,
      'restored_by_email': restoredByEmail,
      'activity_log': activityLog,
      'companyRef': companyRef,
    }.withoutNulls,
  );
}

class DeletedOrdersRecordDocumentEquality
    implements Equality<DeletedOrdersRecord> {
  const DeletedOrdersRecordDocumentEquality();

  @override
  bool equals(DeletedOrdersRecord? e1, DeletedOrdersRecord? e2) =>
      e1?.reference == e2?.reference;

  @override
  int hash(DeletedOrdersRecord? e) => e?.reference.hashCode ?? 0;

  @override
  bool isValidKey(Object? o) => o is DeletedOrdersRecord;
}
