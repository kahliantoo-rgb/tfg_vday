import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class OrderItemRecord extends FirestoreRecord {
  OrderItemRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "orderRef" field.
  DocumentReference? _orderRef;
  DocumentReference? get orderRef => _orderRef;
  bool hasOrderRef() => _orderRef != null;

  // "productRef" field.
  DocumentReference? _productRef;
  DocumentReference? get productRef => _productRef;
  bool hasProductRef() => _productRef != null;

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "qty" field.
  int? _qty;
  int get qty => _qty ?? 0;
  bool hasQty() => _qty != null;

  // "subtotal" field.
  double? _subtotal;
  double get subtotal => _subtotal ?? 0.0;
  bool hasSubtotal() => _subtotal != null;

  // "sku" field.
  String? _sku;
  String get sku => _sku ?? '';
  bool hasSku() => _sku != null;

  // "price" field.
  double? _price;
  double get price => _price ?? 0.0;
  bool hasPrice() => _price != null;

  // "customProduct" field.
  DocumentReference? _customProduct;
  DocumentReference? get customProduct => _customProduct;
  bool hasCustomProduct() => _customProduct != null;

  // "Remark" field.
  String? _remark;
  String get remark => _remark ?? '';
  bool hasRemark() => _remark != null;

  // "client_name" field.
  String? _clientName;
  String get clientName => _clientName ?? '';
  bool hasClientName() => _clientName != null;

  // "orderId" field.
  String? _orderId;
  String get orderId => _orderId ?? '';
  bool hasOrderId() => _orderId != null;

  // "customerphonenumber" field.
  String? _customerphonenumber;
  String get customerphonenumber => _customerphonenumber ?? '';
  bool hasCustomerphonenumber() => _customerphonenumber != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  // "region" field.
  String? _region;
  String get region => _region ?? '';
  bool hasRegion() => _region != null;

  // "cardmessage" field.
  String? _cardmessage;
  String get cardmessage => _cardmessage ?? '';
  bool hasCardmessage() => _cardmessage != null;

  // "status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "deliverydate" field.
  DateTime? _deliverydate;
  DateTime? get deliverydate => _deliverydate;
  bool hasDeliverydate() => _deliverydate != null;

  void _initializeFields() {
    _orderRef = snapshotData['orderRef'] as DocumentReference?;
    _productRef = snapshotData['productRef'] as DocumentReference?;
    _name = snapshotData['name'] as String?;
    _qty = castToType<int>(snapshotData['qty']);
    _subtotal = castToType<double>(snapshotData['subtotal']);
    _sku = snapshotData['sku'] as String?;
    _price = castToType<double>(snapshotData['price']);
    _customProduct = snapshotData['customProduct'] as DocumentReference?;
    _remark = snapshotData['Remark'] as String?;
    _clientName = snapshotData['client_name'] as String?;
    _orderId = snapshotData['orderId'] as String?;
    _customerphonenumber = snapshotData['customerphonenumber'] as String?;
    _address = snapshotData['address'] as String?;
    _region = snapshotData['region'] as String?;
    _cardmessage = snapshotData['cardmessage'] as String?;
    _status = snapshotData['status'] as String?;
    _deliverydate = snapshotData['deliverydate'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Order_item');

  static Stream<OrderItemRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => OrderItemRecord.fromSnapshot(s));

  static Future<OrderItemRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => OrderItemRecord.fromSnapshot(s));

  static OrderItemRecord fromSnapshot(DocumentSnapshot snapshot) =>
      OrderItemRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static OrderItemRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      OrderItemRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'OrderItemRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is OrderItemRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createOrderItemRecordData({
  DocumentReference? orderRef,
  DocumentReference? productRef,
  String? name,
  int? qty,
  double? subtotal,
  String? sku,
  double? price,
  DocumentReference? customProduct,
  String? remark,
  String? clientName,
  String? orderId,
  String? customerphonenumber,
  String? address,
  String? region,
  String? cardmessage,
  String? status,
  DateTime? deliverydate,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'orderRef': orderRef,
      'productRef': productRef,
      'name': name,
      'qty': qty,
      'subtotal': subtotal,
      'sku': sku,
      'price': price,
      'customProduct': customProduct,
      'Remark': remark,
      'client_name': clientName,
      'orderId': orderId,
      'customerphonenumber': customerphonenumber,
      'address': address,
      'region': region,
      'cardmessage': cardmessage,
      'status': status,
      'deliverydate': deliverydate,
    }.withoutNulls,
  );

  return firestoreData;
}

class OrderItemRecordDocumentEquality implements Equality<OrderItemRecord> {
  const OrderItemRecordDocumentEquality();

  @override
  bool equals(OrderItemRecord? e1, OrderItemRecord? e2) {
    return e1?.orderRef == e2?.orderRef &&
        e1?.productRef == e2?.productRef &&
        e1?.name == e2?.name &&
        e1?.qty == e2?.qty &&
        e1?.subtotal == e2?.subtotal &&
        e1?.sku == e2?.sku &&
        e1?.price == e2?.price &&
        e1?.customProduct == e2?.customProduct &&
        e1?.remark == e2?.remark &&
        e1?.clientName == e2?.clientName &&
        e1?.orderId == e2?.orderId &&
        e1?.customerphonenumber == e2?.customerphonenumber &&
        e1?.address == e2?.address &&
        e1?.region == e2?.region &&
        e1?.cardmessage == e2?.cardmessage &&
        e1?.status == e2?.status &&
        e1?.deliverydate == e2?.deliverydate;
  }

  @override
  int hash(OrderItemRecord? e) => const ListEquality().hash([
        e?.orderRef,
        e?.productRef,
        e?.name,
        e?.qty,
        e?.subtotal,
        e?.sku,
        e?.price,
        e?.customProduct,
        e?.remark,
        e?.clientName,
        e?.orderId,
        e?.customerphonenumber,
        e?.address,
        e?.region,
        e?.cardmessage,
        e?.status,
        e?.deliverydate
      ]);

  @override
  bool isValidKey(Object? o) => o is OrderItemRecord;
}
