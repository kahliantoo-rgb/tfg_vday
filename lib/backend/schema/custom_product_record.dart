import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CustomProductRecord extends FirestoreRecord {
  CustomProductRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "Qty" field.
  int? _qty;
  int get qty => _qty ?? 0;
  bool hasQty() => _qty != null;

  // "Price" field.
  double? _price;
  double get price => _price ?? 0.0;
  bool hasPrice() => _price != null;

  // "Remark" field.
  String? _remark;
  String get remark => _remark ?? '';
  bool hasRemark() => _remark != null;

  // "orderRef" field.
  DocumentReference? _orderRef;
  DocumentReference? get orderRef => _orderRef;
  bool hasOrderRef() => _orderRef != null;

  // "orderItem" field.
  DocumentReference? _orderItem;
  DocumentReference? get orderItem => _orderItem;
  bool hasOrderItem() => _orderItem != null;

  void _initializeFields() {
    _name = snapshotData['Name'] as String?;
    _qty = castToType<int>(snapshotData['Qty']);
    _price = castToType<double>(snapshotData['Price']);
    _remark = snapshotData['Remark'] as String?;
    _orderRef = snapshotData['orderRef'] as DocumentReference?;
    _orderItem = snapshotData['orderItem'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('customProduct');

  static Stream<CustomProductRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => CustomProductRecord.fromSnapshot(s));

  static Future<CustomProductRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => CustomProductRecord.fromSnapshot(s));

  static CustomProductRecord fromSnapshot(DocumentSnapshot snapshot) =>
      CustomProductRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static CustomProductRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      CustomProductRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'CustomProductRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is CustomProductRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createCustomProductRecordData({
  String? name,
  int? qty,
  double? price,
  String? remark,
  DocumentReference? orderRef,
  DocumentReference? orderItem,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Name': name,
      'Qty': qty,
      'Price': price,
      'Remark': remark,
      'orderRef': orderRef,
      'orderItem': orderItem,
    }.withoutNulls,
  );

  return firestoreData;
}

class CustomProductRecordDocumentEquality
    implements Equality<CustomProductRecord> {
  const CustomProductRecordDocumentEquality();

  @override
  bool equals(CustomProductRecord? e1, CustomProductRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.qty == e2?.qty &&
        e1?.price == e2?.price &&
        e1?.remark == e2?.remark &&
        e1?.orderRef == e2?.orderRef &&
        e1?.orderItem == e2?.orderItem;
  }

  @override
  int hash(CustomProductRecord? e) => const ListEquality()
      .hash([e?.name, e?.qty, e?.price, e?.remark, e?.orderRef, e?.orderItem]);

  @override
  bool isValidKey(Object? o) => o is CustomProductRecord;
}
